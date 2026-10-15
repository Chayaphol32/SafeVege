import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
  });

  final String message;
  final int? statusCode;
  final bool isNetworkError;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _baseUri = Uri.parse(baseUrl.trim()),
       _httpClient = httpClient ?? http.Client();

  final Uri _baseUri;
  final http.Client _httpClient;
  final Duration timeout;
  String? accessToken;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) => _jsonRequest('GET', path, queryParameters: queryParameters);

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, Object?> body,
  ) => _jsonRequest('POST', path, body: body);

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, Object?> body,
  ) => _jsonRequest('PATCH', path, body: body);

  Future<Map<String, dynamic>> deleteJson(String path) =>
      _jsonRequest('DELETE', path);

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required Uint8List fileBytes,
    required String fileName,
    String fileField = 'file',
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.headers.addAll(_headers());
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName),
    );
    final response = await _send(request);
    return _decodeJsonResponse(response);
  }

  Future<Uint8List> getBytes(String path) async {
    final request = http.Request('GET', _uri(path));
    request.headers.addAll(_headers());
    final response = await _send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFromResponse(response);
    }
    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> _jsonRequest(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Map<String, Object?>? body,
  }) async {
    final request = http.Request(method, _uri(path, queryParameters));
    request.headers.addAll(_headers());
    if (body != null) {
      request.headers['content-type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    return _decodeJsonResponse(await _send(request));
  }

  Future<http.Response> _send(http.BaseRequest request) async {
    try {
      final streamed = await _httpClient.send(request).timeout(timeout);
      return await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        'เซิร์ฟเวอร์ใช้เวลาตอบกลับนานเกินไป กรุณาลองอีกครั้ง',
        isNetworkError: true,
      );
    } on http.ClientException {
      throw const ApiException(
        'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบเครือข่ายและที่อยู่ API',
        isNetworkError: true,
      );
    }
  }

  Map<String, String> _headers() => {
    'accept': 'application/json',
    if (accessToken case final token? when token.isNotEmpty)
      'authorization': 'Bearer $token',
  };

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final prefix = _baseUri.path.endsWith('/')
        ? _baseUri.path
        : '${_baseUri.path}/';
    final relativePath = path.startsWith('/') ? path.substring(1) : path;
    return _baseUri.replace(
      path: '$prefix$relativePath',
      queryParameters: queryParameters,
    );
  }

  Map<String, dynamic> _decodeJsonResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFromResponse(response);
    }
    if (response.body.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      throw const ApiException('เซิร์ฟเวอร์ส่งข้อมูลที่อ่านไม่ได้');
    }
    throw const ApiException('รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง');
  }

  ApiException _errorFromResponse(http.Response response) {
    String message = 'คำขอไม่สำเร็จ (${response.statusCode})';
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        final error = decoded['error'];
        final apiMessage = error is String
            ? error
            : decoded['message'] is String
            ? decoded['message'] as String
            : null;
        if (apiMessage != null && apiMessage.trim().isNotEmpty) {
          message = apiMessage.trim();
        }
      }
    } on FormatException {
      // Keep the user-facing status message for non-JSON server errors.
    }
    return ApiException(message, statusCode: response.statusCode);
  }

  void close() => _httpClient.close();
}
