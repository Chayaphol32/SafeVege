import 'package:flutter_test/flutter_test.dart';
import 'package:safevege/data/repositories/safevege_repository.dart';
import 'package:safevege/models/app_models.dart';

void main() {
  test('maps the super_admin API role to UserRole.superAdmin', () {
    final user = SessionUser.fromJson({
      'id': 4,
      'username': 'root-admin',
      'display_name': 'ผู้ดูแลระบบ',
      'role': 'super_admin',
      'is_active': 1,
    });

    expect(user.role, UserRole.superAdmin);
    expect(user.isActive, isTrue);
  });
}
