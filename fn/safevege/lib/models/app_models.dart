import 'dart:math' as math;

enum UserRole { guest, shop, admin, superAdmin }

class AdminUserModel {
  const AdminUserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  final String id;
  final String username;
  final String displayName;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;
}

class AuditEventModel {
  const AuditEventModel({
    required this.id,
    required this.actorUserId,
    required this.actorUsername,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.details,
    required this.createdAt,
  });

  final String id;
  final String actorUserId;
  final String actorUsername;
  final String entityType;
  final String entityId;
  final String action;
  final Map<String, dynamic> details;
  final DateTime? createdAt;
}

enum RequestStatus {
  pending('รอดำเนินการ'),
  scheduled('นัดหมายแล้ว'),
  inProgress('กำลังตรวจสอบ'),
  completed('เสร็จสิ้น'),
  cancelled('ยกเลิกแล้ว');

  final String label;
  const RequestStatus(this.label);
}

class VegetableInspection {
  final String name;
  final int? requestItemId;
  final int? resultId;
  String? outcome;
  bool? passed;
  DateTime? inspectionDate;
  String? certNo;
  String? notes;
  String? details;

  VegetableInspection({
    required this.name,
    this.requestItemId,
    this.resultId,
    this.outcome,
    this.passed,
    this.inspectionDate,
    this.certNo,
    this.notes,
    this.details,
  });

  VegetableInspection copyWith({
    String? name,
    int? requestItemId,
    int? resultId,
    String? outcome,
    bool clearOutcome = false,
    bool? passed,
    bool clearPassed = false,
    DateTime? inspectionDate,
    String? certNo,
    String? notes,
    String? details,
  }) {
    return VegetableInspection(
      name: name ?? this.name,
      requestItemId: requestItemId ?? this.requestItemId,
      resultId: resultId ?? this.resultId,
      outcome: clearOutcome ? null : outcome ?? this.outcome,
      passed: clearPassed ? null : passed ?? this.passed,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      certNo: certNo ?? this.certNo,
      notes: notes ?? this.notes,
      details: details ?? this.details,
    );
  }
}

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  Map<String, double> toMapLocation() => {'lat': latitude, 'lon': longitude};

  double distanceKmTo(GeoPoint other) {
    const earthRadiusKm = 6371.0088;
    const degreesToRadians = math.pi / 180;
    final latitudeDelta = (other.latitude - latitude) * degreesToRadians;
    final longitudeDelta = (other.longitude - longitude) * degreesToRadians;
    final latitudeRadians = latitude * degreesToRadians;
    final otherLatitudeRadians = other.latitude * degreesToRadians;

    final haversine =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(latitudeRadians) *
            math.cos(otherLatitudeRadians) *
            math.pow(math.sin(longitudeDelta / 2), 2);
    final boundedHaversine = haversine.clamp(0.0, 1.0).toDouble();
    return 2 * earthRadiusKm * math.asin(math.sqrt(boundedHaversine));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          runtimeType == other.runtimeType &&
          (latitude - other.latitude).abs() < 0.000001 &&
          (longitude - other.longitude).abs() < 0.000001;

  @override
  int get hashCode =>
      Object.hash((latitude * 100000).round(), (longitude * 100000).round());
}

class PublicInspectionResult {
  const PublicInspectionResult({
    required this.vegetableName,
    required this.certificateId,
    required this.certificateNumber,
    this.inspectedAt,
    this.issuedAt,
    this.expiresAt,
  });

  final String vegetableName;
  final String certificateId;
  final String certificateNumber;
  final DateTime? inspectedAt;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
}

class InspectionResultDraft {
  InspectionResultDraft({
    required List<VegetableInspection> results,
    this.certificateFileName,
    this.certificateNumber,
  }) : results = List.unmodifiable(results.map(_copyInspection));

  final List<VegetableInspection> results;
  final String? certificateFileName;
  final String? certificateNumber;

  static VegetableInspection _copyInspection(VegetableInspection result) =>
      VegetableInspection(
        name: result.name,
        requestItemId: result.requestItemId,
        resultId: result.resultId,
        outcome: result.outcome,
        passed: result.passed,
        inspectionDate: result.inspectionDate,
        certNo: result.certNo,
        notes: result.notes,
        details: result.details,
      );
}

class ShopModel {
  String id;
  String name;
  String ownerFirstName;
  String ownerLastName;
  String phone;
  String houseNo;
  String moo;
  String road;
  String subDistrict;
  String district;
  String province;
  double latitude;
  double longitude;
  bool isVerified;
  bool hasCoordinates;
  String distanceText;
  List<String> verifiedVegetables;
  List<PublicInspectionResult> publicResults;
  DateTime createdAt;

  ShopModel({
    required this.id,
    required this.name,
    required this.ownerFirstName,
    required this.ownerLastName,
    required this.phone,
    required this.houseNo,
    this.moo = '',
    this.road = '',
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.latitude,
    required this.longitude,
    this.isVerified = true,
    this.hasCoordinates = true,
    this.distanceText = '—',
    this.verifiedVegetables = const [],
    this.publicResults = const [],
    required this.createdAt,
  });

  String get ownerFullName => '$ownerFirstName $ownerLastName'.trim();

  String get fullAddress {
    final buffer = StringBuffer();
    if (houseNo.isNotEmpty) buffer.write('เลขที่ $houseNo ');
    if (moo.isNotEmpty) buffer.write('หมู่ $moo ');
    if (road.isNotEmpty) buffer.write('ถ.$road ');
    if (subDistrict.isNotEmpty) buffer.write('ต.$subDistrict ');
    if (district.isNotEmpty) buffer.write('อ.$district ');
    if (province.isNotEmpty) buffer.write('จ.$province');
    return buffer.toString().trim();
  }

  String get shortArea => 'อ.$district จ.$province';
}

class InspectionRequestModel {
  final String id;
  final String? requestNumber;
  final String shopId;
  String shopName;
  final List<String> vegetables;
  RequestStatus status;
  final DateTime submissionDate;
  DateTime? appointmentDate;
  String? appointmentNotes;
  DateTime? inspectionDate;
  String? inspectorName;
  List<VegetableInspection> results;
  String? certificateFileName;
  String? certificateId;
  String? certificateNumber;
  DateTime? certificateExpiryDate;
  String shopAddress;
  double latitude;
  double longitude;

  InspectionRequestModel({
    required this.id,
    this.requestNumber,
    required this.shopId,
    required this.shopName,
    this.vegetables = const [],
    this.status = RequestStatus.pending,
    required this.submissionDate,
    this.appointmentDate,
    this.appointmentNotes,
    this.inspectionDate,
    this.inspectorName,
    List<VegetableInspection>? results,
    this.certificateFileName,
    this.certificateId,
    this.certificateNumber,
    this.certificateExpiryDate,
    required this.shopAddress,
    required this.latitude,
    required this.longitude,
  }) : results = results ?? [];

  bool get isCompleted => status == RequestStatus.completed;
  bool get isScheduled => status == RequestStatus.scheduled;
  bool get isInProgress => status == RequestStatus.inProgress;
  bool get isPending => status == RequestStatus.pending;
  bool get isCancelled => status == RequestStatus.cancelled;

  bool get allPassed =>
      results.isNotEmpty && results.every((r) => r.passed == true);

  bool get hasCertificate =>
      isCompleted &&
      results.isNotEmpty &&
      results.every((result) => result.passed != null) &&
      results.any((result) => result.passed == true) &&
      ((certificateId?.trim().isNotEmpty ?? false) ||
          (certificateFileName?.trim().isNotEmpty ?? false)) &&
      (certificateNumber?.trim().isNotEmpty ?? false);
}

class CertificateModel {
  final String id;
  final String shopId;
  final String shopName;
  final String certificateNumber;
  final DateTime issuedAt;
  final DateTime? expiresAt;
  final bool isPublic;
  final List<String> vegetables;

  const CertificateModel({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.certificateNumber,
    required this.issuedAt,
    this.expiresAt,
    this.isPublic = true,
    this.vegetables = const [],
  });
}
