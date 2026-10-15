import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStore {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> clearToken();
  Future<Set<String>> readFavorites();
  Future<void> writeFavorites(Set<String> favorites);
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'safevege_session_token';
  static const _favoritesKey = 'safevege_favorite_shops';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  @override
  Future<Set<String>> readFavorites() async {
    final raw = await _storage.read(key: _favoritesKey);
    if (raw == null || raw.isEmpty) return <String>{};
    return raw.split(',').where((id) => id.isNotEmpty).toSet();
  }

  @override
  Future<void> writeFavorites(Set<String> favorites) =>
      _storage.write(key: _favoritesKey, value: favorites.join(','));
}

class MemorySessionStore implements SessionStore {
  String? _token;
  Set<String> _favorites = {};

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async => _token = token;

  @override
  Future<void> clearToken() async => _token = null;

  @override
  Future<Set<String>> readFavorites() async => _favorites;

  @override
  Future<void> writeFavorites(Set<String> favorites) async =>
      _favorites = Set.from(favorites);
}
