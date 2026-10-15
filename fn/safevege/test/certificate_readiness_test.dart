import 'package:flutter_test/flutter_test.dart';
import 'package:safevege/models/app_models.dart';

InspectionRequestModel request({
  RequestStatus status = RequestStatus.completed,
  String? fileName = 'report.pdf',
  String? certificateId,
  String? certificateNumber = 'SV-001',
  List<bool?> outcomes = const [true, true],
}) {
  return InspectionRequestModel(
    id: 'REQ-1',
    shopId: 'SHOP-1',
    shopName: 'ร้านตัวอย่าง',
    vegetables: ['คะน้า', 'ผักกาด'],
    status: status,
    submissionDate: DateTime(2026, 1, 1),
    results: [
      for (var index = 0; index < outcomes.length; index++)
        VegetableInspection(name: 'ผัก $index', passed: outcomes[index]),
    ],
    certificateFileName: fileName,
    certificateId: certificateId,
    certificateNumber: certificateNumber,
    shopAddress: 'ที่อยู่ตัวอย่าง',
    latitude: 13.75,
    longitude: 100.5,
  );
}

void main() {
  test(
    'a certificate requires a completed result, a passing item, and metadata',
    () {
      expect(request().hasCertificate, isTrue);
      expect(request(status: RequestStatus.inProgress).hasCertificate, isFalse);
      expect(request(outcomes: [true, false]).hasCertificate, isTrue);
      expect(request(outcomes: [false, false]).hasCertificate, isFalse);
      expect(request(outcomes: [true, null]).hasCertificate, isFalse);
      expect(request(fileName: null).hasCertificate, isFalse);
      expect(
        request(fileName: null, certificateId: '5').hasCertificate,
        isTrue,
      );
      expect(request(certificateNumber: ' ').hasCertificate, isFalse);
    },
  );
}
