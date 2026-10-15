# SafeVege Admin Access Implementation Plan

> For agentic workers: REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax (- [ ]) for tracking.

Goal: Remove OTP recovery and deliver a server-authorized super_admin console that manages users, passwords, shops, requests, settings, and audit data while preserving the existing admin inspector workflow.

Architecture: Keep the existing PHP route/bootstrap architecture and add strict role allow-lists at the backend boundary. Keep admin as the Inspector Admin role for compatibility, add super_admin, and let Flutter render the special console only after the server returns that role in the authenticated session. Password changes and settings remain server mutations with audit records; no secret is embedded in the Flutter bundle.

Implementation status: role contract, OTP removal, server routes, Flutter state/repository, Super Admin console, account/settings/audit screens, documentation, and focused regressions are implemented. Full Flutter verification and PHP unit/contract verification pass; database-backed PHP integration remains pending because this machine's PHP CLI has no PDO MySQL driver.

Tech Stack: PHP 8.3, PDO/MySQL 5.7+, existing SafeVege API routes, Flutter/Dart 3.13, ChangeNotifier AppState, ApiClient, flutter_test, existing PHP test scripts.

## Global Constraints

- Role values are exactly shop, admin, and super_admin; existing admin remains the Inspector Admin role.
- Every privileged operation must be authorized again by PHP; Flutter role checks only control navigation and visibility.
- Passwords are hashed with password_hash and must be at least 12 characters when created or reset.
- OTP endpoints, demo_otp, magic passwords, and recovery UI are removed; no password secret is stored in the Flutter app.
- A super admin cannot demote, deactivate, or delete the last remaining super admin.
- Existing MySQL 5.7 compatibility and api_* compatibility views must remain intact.
- The workspace is not a Git repository, so checkpoints are filesystem diffs and fresh test output rather than commits.

---

### Task 1: Add the role contract and authorization primitives

Files:
- Modify: fn/safevege/lib/models/app_models.dart:3
- Modify: fn/safevege/lib/data/repositories/safevege_repository.dart:6-36
- Modify: fn/safevege/lib/state/remote_app_state.dart:9-40,650-740
- Modify: bn/schema.sql role enum and compatibility views
- Modify: bn/src/auth.php
- Create: bn/tests/admin_access_contract_test.php
- Create: fn/safevege/test/api/admin_access_test.dart

Interfaces:
- Produces UserRole.superAdmin, SessionUser.fromJson({'role': 'super_admin'}), require_any_role(array $user, array $roles), and require_super_admin(array $user).
- Existing require_role($user, 'admin') callers continue to work for Inspector Admin routes.

- [ ] Step 1: Write the failing Flutter role-mapping test

~~~dart
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
~~~

- [ ] Step 2: Run the focused test and verify the expected red failure

Run from fn/safevege:

~~~powershell
flutter test test/api/admin_access_test.dart
~~~

Expected: FAIL because UserRole.superAdmin and the super_admin mapping do not exist.

- [ ] Step 3: Write and run the failing PHP authorization test

Create bn/tests/admin_access_contract_test.php:

~~~php
<?php
declare(strict_types=1);

require __DIR__ . '/../src/auth.php';

function expect_forbidden(callable $callback, string $message): void {
    try { $callback(); } catch (ApiError $error) {
        if ($error->status === 403) return;
        throw new RuntimeException($message . ': wrong status ' . $error->status);
    }
    throw new RuntimeException($message . ': no error');
}

require_any_role(['role' => 'super_admin'], ['admin', 'super_admin']);
require_super_admin(['role' => 'super_admin']);
expect_forbidden(fn() => require_super_admin(['role' => 'admin']), 'admin guard');
echo "admin access contract tests passed\n";
~~~

Run from bn:

~~~powershell
$php = 'C:\MAMP\bin\php\php8.3.1\php.exe'
& $php tests/admin_access_contract_test.php
~~~

Expected: FAIL because the guards are missing.

- [ ] Step 4: Implement the minimum role contract

Add:

~~~dart
enum UserRole { guest, shop, admin, superAdmin }
~~~

Map the API role:

~~~dart
final role = switch (json['role']?.toString()) {
  'shop' => UserRole.shop,
  'admin' => UserRole.admin,
  'super_admin' => UserRole.superAdmin,
  _ => UserRole.guest,
};
~~~

Add backend guards:

~~~php
function require_any_role(array $user, array $roles): void {
    if (!in_array($user['role'] ?? null, $roles, true)) {
        throw new ApiError(403, 'Forbidden');
    }
}

function require_super_admin(array $user): void {
    require_any_role($user, ['super_admin']);
}
~~~

Change the schema role definition to ENUM('shop','admin','super_admin') and keep the api_users view exposing role.

- [ ] Step 5: Run focused tests and existing repository tests

~~~powershell
& $php tests/admin_access_contract_test.php
Set-Location ..\fn\safevege
flutter test test/api/admin_access_test.dart test/api/safevege_repository_test.dart
~~~

Expected: role tests pass and existing repository tests remain green.

---

### Task 2: Remove OTP recovery and all client recovery entry points

Files:
- Modify: bn/src/routes/auth_routes.php:57-135
- Modify: fn/safevege/lib/data/repositories/safevege_repository.dart:80-120
- Modify: fn/safevege/lib/state/remote_app_state.dart:250-315
- Modify: fn/safevege/lib/screens/admin/admin_login_screen.dart
- Modify: fn/safevege/lib/screens/shop/shop_login_screen.dart
- Delete: fn/safevege/lib/screens/common/account_recovery_screen.dart
- Modify: bn/tests/integration.php
- Create: fn/safevege/test/widgets/login_recovery_removed_test.dart

Interfaces:
- /auth/login, /auth/logout, /auth/change-password, and /me remain.
- Repository/AppState no longer expose requestPasswordResetOtp, verifyPasswordResetOtp, or OTP-based resetPassword.

- [ ] Step 1: Write the failing login regression test

~~~dart
testWidgets('admin login does not expose OTP recovery', (tester) async {
  final state = AppState(sessionStore: MemorySessionStore());
  await tester.pumpWidget(MaterialApp(home: AdminLoginScreen(appState: state)));

  expect(find.text('ลืมรหัสผ่าน?'), findsNothing);
  expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
});
~~~

- [ ] Step 2: Run it and verify it fails because the recovery button exists

~~~powershell
flutter test test/widgets/login_recovery_removed_test.dart
~~~

Expected: FAIL on the existing ลืมรหัสผ่าน? widget.

- [ ] Step 3: Add the failing API regression to the PHP integration test

~~~php
expect_status(404, api('POST', '/auth/forgot-password', ['account' => $shopUsername]), 'OTP route removed');
~~~

Run php tests/integration.php; before implementation it should fail because the route still responds.

- [ ] Step 4: Remove the production recovery paths

Delete the three OTP branches from auth_routes.php; remove the three repository/AppState methods and recovery imports/buttons from both login screens; delete account_recovery_screen.dart. Do not replace them with a magic password.

- [ ] Step 5: Run focused tests and forbidden-string checks

~~~powershell
flutter test test/widgets/login_recovery_removed_test.dart
Set-Location ..\..\bn
& $php tests/helpers_test.php
& $php tests/integration.php
~~~

Use graph-augmented code search for demo_otp, verify-otp, forgot-password, and 123456; expected production matches are zero. If the PHP CLI lacks pdo_mysql, record that exact limitation.

---

### Task 3: Add super-admin account management, password reset, audit, and settings API

Files:
- Modify: bn/src/routes/admin_routes.php
- Modify: bn/src/auth.php
- Modify: bn/schema.sql
- Create: bn/migrations/2026-10-14-super-admin-access.sql
- Modify: bn/scripts/create_admin.php
- Modify: bn/src/demo_seeder.php only for local role setup
- Create: bn/tests/super_admin_routes_test.php
- Modify: bn/tests/integration.php

Interfaces:
- GET /admin/users
- POST /admin/users with username, display_name, password, role
- PATCH /admin/users/{id} with display_name, role, is_active
- POST /admin/users/{id}/password with new_password
- GET /admin/audit?actor_id=&action=&entity_type=&limit=&offset=
- GET /admin/settings
- PATCH /admin/settings with an allow-listed key/value map

- [ ] Step 1: Add failing integration scenarios

After the current admin login setup in bn/tests/integration.php, create a super_admin, then assert that it can create an inspector and reset its password, while the inspector gets 403:

~~~php
$superLogin = expect_status(200, api('POST', '/auth/login', [
    'username' => $superUsername,
    'password' => 'super-password-123',
]), 'super admin login');
$superToken = $superLogin['token'];

$createdInspector = expect_status(201, api('POST', '/admin/users', [
    'username' => 'inspector_' . $suffix,
    'display_name' => 'Inspector',
    'password' => 'inspector-password-123',
    'role' => 'admin',
], $superToken), 'super admin creates inspector');

expect_status(403, api('POST', '/admin/users', [
    'username' => 'blocked_' . $suffix,
    'display_name' => 'Blocked',
    'password' => 'blocked-password-123',
    'role' => 'admin',
], $adminToken), 'inspector cannot create users');

expect_status(201, api('POST', '/admin/users/' . $createdInspector['id'] . '/password', [
    'new_password' => 'new-inspector-password-123',
], $superToken), 'super admin resets inspector password');
~~~

- [ ] Step 2: Run integration and verify the new route fails

~~~powershell
$php = 'C:\MAMP\bin\php\php8.3.1\php.exe'
& $php tests/integration.php
~~~

Expected: FAIL at /admin/users with 404. If DB driver is unavailable, use the pure policy test below for the red proof.

- [ ] Step 3: Add failing pure policy tests

In bn/tests/super_admin_routes_test.php, assert require_super_admin(['role' => 'admin']) and require_super_admin(['role' => 'shop']) throw 403. Add a pure last-super-admin policy helper and assert that demoting/deactivating the only active super admin returns false, while changing a normal inspector returns true.

- [ ] Step 4: Add schema and migration objects

Add to bn/schema.sql:

~~~sql
CREATE TABLE IF NOT EXISTS app_settings (
  setting_key VARCHAR(100) NOT NULL,
  setting_value JSON NOT NULL,
  setting_updated_by BIGINT UNSIGNED NOT NULL,
  setting_updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (setting_key),
  CONSTRAINT fk_app_settings_user FOREIGN KEY (setting_updated_by) REFERENCES users(use_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
~~~

Add the same role alteration and table creation to bn/migrations/2026-10-14-super-admin-access.sql using a guarded ALTER TABLE users MODIFY use_role ENUM('shop','admin','super_admin') NOT NULL and CREATE TABLE IF NOT EXISTS.

- [ ] Step 5: Implement guarded routes

At the start of admin_routes, use require_any_role($user, ['admin', 'super_admin']). Before user/settings/audit branches, call require_super_admin($user). Use parameterized SQL, existing validators, password_hash, and the existing audit() function. Return only sanitized user fields.

Protect the last active super admin in a transaction by counting active super_admin users before a role/deactivation change; reject a change that would make the count zero with 409. Delete target api_api_tokens after a password reset.

Implement settings with this explicit allow-list and type checks:

~~~php
$allowedSettings = [
    'maintenance_mode' => 'bool',
    'public_app_base_url' => 'string',
    'default_certificate_expiry_days' => 'positive_int',
];
~~~

Reject unknown keys or invalid values with 422; do not expose environment secrets.

- [ ] Step 6: Extend the CLI bootstrap without embedding passwords

Update bn/scripts/create_admin.php to accept --role=admin or --role=super_admin, read SAFEVEGE_ADMIN_PASSWORD only from the server environment, reject passwords shorter than 12 characters, and keep admin as the default role. Never add a password literal to Flutter or production seed data.

- [ ] Step 7: Run focused PHP tests and integration

~~~powershell
& $php tests/admin_access_contract_test.php
& $php tests/super_admin_routes_test.php
& $php tests/helpers_test.php
& $php tests/integration.php
~~~

Expected: pure policy tests pass; integration passes when pdo_mysql is available, otherwise report that limitation.

---

### Task 4: Wire Flutter repository and AppState operations

Files:
- Modify: fn/safevege/lib/models/app_models.dart
- Modify: fn/safevege/lib/data/repositories/safevege_repository.dart
- Modify: fn/safevege/lib/state/remote_app_state.dart
- Create: fn/safevege/test/api/super_admin_repository_test.dart
- Create: fn/safevege/test/state/super_admin_state_test.dart

Interfaces:
- Future<List<AdminUserModel>> getAdminUsers()
- Future<AdminUserModel> createAdminUser({required String username, required String displayName, required String password, required UserRole role})
- Future<void> updateAdminUser(String userId, {String? displayName, UserRole? role, bool? isActive})
- Future<void> resetAdminUserPassword(String userId, String newPassword)
- Future<List<AuditEventModel>> getAuditEvents({int? actorId, String? action, String? entityType})
- Future<Map<String, dynamic>> getAdminSettings() and Future<void> updateAdminSettings(Map<String, dynamic> values)
- AppState.isSuperAdmin, AppState.adminUsers, and matching orchestration methods

- [ ] Step 1: Write the failing repository request test

~~~dart
test('creates an inspector admin with the server role value', () async {
  final api = ApiClient(
    baseUrl: 'http://localhost/api/v1',
    httpClient: MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/v1/admin/users');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['role'], 'admin');
      expect(body['password'], 'inspector-password-123');
      return http.Response(
        '{"id":9,"username":"inspector","role":"admin","is_active":1}',
        201,
      );
    }),
  )..accessToken = 'super-token';

  final user = await SafeVegeRepository(api: api).createAdminUser(
    username: 'inspector',
    displayName: 'Inspector',
    password: 'inspector-password-123',
    role: UserRole.admin,
  );

  expect(user.role, UserRole.admin);
});
~~~

- [ ] Step 2: Run it and verify it fails because models/methods do not exist

~~~powershell
flutter test test/api/super_admin_repository_test.dart
~~~

- [ ] Step 3: Implement sanitized models and repository methods

Add AdminUserModel and AuditEventModel; map super_admin to UserRole.superAdmin; implement the listed methods with ApiClient. Add patchJson only if the client has no existing PATCH helper. Never retain a password in a model or AppState field.

- [ ] Step 4: Write the failing AppState permission test, then implement

~~~dart
test('super admin state exposes management data', () {
  final state = AppState.forTest(currentRole: UserRole.superAdmin);
  expect(state.isSuperAdmin, isTrue);
  expect(state.canManageUsers, isTrue);
});
~~~

If the constructor has no test seam, add an injected repository/session constructor rather than a production-only setter. Set _isAdminLoggedIn for both admin roles, set _adminName for either role, branch _loadRoleData for super admin, and make management calls fail fast locally for non-super-admin while retaining backend authorization.

- [ ] Step 5: Run focused Flutter tests

~~~powershell
flutter test test/api/super_admin_repository_test.dart test/state/super_admin_state_test.dart test/api/safevege_repository_test.dart
~~~

---

### Task 5: Build the protected Super Admin UI and remove inspector recovery UI

Files:
- Create: fn/safevege/lib/screens/admin/super_admin_dashboard_screen.dart
- Create: fn/safevege/lib/screens/admin/admin_users_screen.dart
- Create: fn/safevege/lib/screens/admin/admin_settings_screen.dart
- Create: fn/safevege/lib/screens/admin/admin_audit_screen.dart
- Modify: fn/safevege/lib/screens/admin/admin_login_screen.dart
- Modify: fn/safevege/lib/screens/shop/shop_login_screen.dart
- Modify: fn/safevege/lib/screens/admin/admin_dashboard_screen.dart
- Create: fn/safevege/test/widgets/super_admin_menu_test.dart

Interfaces:
- SuperAdminDashboardScreen({required AppState appState}) renders management sections and navigates to user/settings/audit screens.
- Admin login redirects to the super console when appState.currentRole == UserRole.superAdmin; otherwise it redirects to the existing Inspector Admin dashboard.

- [ ] Step 1: Write failing widget tests

~~~dart
testWidgets('super admin sees the special management menu', (tester) async {
  final state = AppState.forTest(currentRole: UserRole.superAdmin);
  await tester.pumpWidget(
    MaterialApp(home: SuperAdminDashboardScreen(appState: state)),
  );

  expect(find.text('จัดการบัญชีผู้ใช้'), findsOneWidget);
  expect(find.text('ตั้งค่าระบบ'), findsOneWidget);
  expect(find.text('ประวัติการใช้งาน'), findsOneWidget);
});

testWidgets('inspector admin does not see super admin menu', (tester) async {
  final state = AppState.forTest(currentRole: UserRole.admin);
  await tester.pumpWidget(
    MaterialApp(home: AdminDashboardScreen(appState: state)),
  );

  expect(find.text('จัดการบัญชีผู้ใช้'), findsNothing);
});
~~~

- [ ] Step 2: Run them and verify they fail because the console does not exist

~~~powershell
flutter test test/widgets/super_admin_menu_test.dart
~~~

- [ ] Step 3: Implement the protected console

Use existing theme tokens, cards, buttons, loading/error feedback, and navigation patterns. Guard the screen body:

~~~dart
if (!appState.isSuperAdmin) {
  return const Scaffold(body: Center(child: Text('ไม่มีสิทธิ์เข้าถึง')));
}
~~~

Add user list/create/edit/reset-password forms, the three allow-listed settings, and an audit list with filters. Client validation is only for usability; backend authorization remains authoritative. Do not add a hidden password or emergency code to any widget.

- [ ] Step 4: Update login routing and remove recovery imports/buttons

After login, use the server role to choose the destination. Remove AccountRecoveryScreen imports and recovery copy from both login screens.

- [ ] Step 5: Run focused widgets, analyzer, and full Flutter tests

~~~powershell
flutter test test/widgets/super_admin_menu_test.dart test/widgets/login_recovery_removed_test.dart
flutter analyze
flutter test
~~~

Expected: no analyzer errors and all Flutter tests pass.

---

### Task 6: Complete bootstrap documentation and fresh verification

Files:
- Modify: bn/README.md
- Create: bn/docs/super-admin-operations.md
- Modify: bn/scripts/create_admin.php
- Update: docs/superpowers/specs/2026-10-14-safevege-admin-access-design.md with verified implementation notes only

- [ ] Step 1: Document the first super-admin bootstrap

Document this server-only flow:

~~~powershell
$env:SAFEVEGE_ADMIN_PASSWORD = '<12+ character secret supplied at deployment time>'
php scripts/create_admin.php --role=super_admin root-admin 'SafeVege Owner'
~~~

State that the value is supplied through the server environment, never committed, never put in Flutter --dart-define, and never returned by the API.

- [ ] Step 2: Add cleanup and security checks to integration tests

Delete test users/tokens/audit rows in finally; assert reset password revokes the target token, an inspector receives 403 for user/settings/audit routes, and the last active super admin cannot be demoted/deactivated.

- [ ] Step 3: Run the complete verification set

~~~powershell
Set-Location 'C:\Users\Chaya\verse\y4.1\wap\code\Flutter\SafeVege\fn\safevege'
flutter analyze
flutter test

Set-Location '..\..\bn'
$php = 'C:\MAMP\bin\php\php8.3.1\php.exe'
& $php tests/helpers_test.php
& $php tests/cors_policy_test.php
& $php tests/demo_seed_test.php
& $php tests/admin_access_contract_test.php
& $php tests/super_admin_routes_test.php
& $php tests/integration.php
~~~

Read every exit code and output. Report exact failures, especially if pdo_mysql is unavailable. Do not claim completion from a partial run.

- [ ] Step 4: Review plan coverage

Check that every spec requirement has a test and implementation location: OTP removal, role separation, special console, account creation, password reset, settings allow-list, audit, last-super-admin protection, server-only bootstrap, and no client secret.

