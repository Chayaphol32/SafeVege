<?php
declare(strict_types=1);

require_once __DIR__ . '/../src/bootstrap.php';

function api(string $method, string $path, ?array $body = null, ?string $token = null): array {
    $headers = ['Accept: application/json'];
    if ($body !== null) $headers[] = 'Content-Type: application/json';
    if ($token !== null) $headers[] = 'Authorization: Bearer ' . $token;
    $context = stream_context_create(['http' => [
        'method' => $method,
        'header' => implode("\r\n", $headers),
        'content' => $body === null ? '' : json_encode($body, JSON_UNESCAPED_UNICODE),
        'ignore_errors' => true,
        'timeout' => 10,
    ]]);
    $raw = file_get_contents('http://127.0.0.1:8081/api/v1' . $path, false, $context);
    if ($raw === false) throw new RuntimeException("HTTP request failed: $method $path");
    preg_match('/\s(\d{3})\s/', $http_response_header[0], $match);
    return [(int)($match[1] ?? 0), json_decode($raw, true)];
}

function expect_status(int $expected, array $response, string $step): array {
    if ($response[0] !== $expected) throw new RuntimeException("$step: expected $expected, got {$response[0]} " . json_encode($response[1], JSON_UNESCAPED_UNICODE));
    return $response[1];
}

function upload_certificate(int $requestId, string $token, int $resultId, string $number): array {
    $boundary = 'safevege-' . bin2hex(random_bytes(8));
    $fields = ['certificate_no' => $number, 'issued_at' => '2026-10-20', 'expires_at' => '2027-10-20', 'result_ids' => json_encode([$resultId])];
    $body = '';
    foreach ($fields as $key => $value) $body .= "--$boundary\r\nContent-Disposition: form-data; name=\"$key\"\r\n\r\n$value\r\n";
    $body .= "--$boundary\r\nContent-Disposition: form-data; name=\"file\"; filename=\"test.pdf\"\r\nContent-Type: application/pdf\r\n\r\n%PDF-1.4\n%%EOF\r\n--$boundary--\r\n";
    $context = stream_context_create(['http' => [
        'method' => 'POST',
        'header' => "Content-Type: multipart/form-data; boundary=$boundary\r\nAuthorization: Bearer $token",
        'content' => $body,
        'ignore_errors' => true,
        'timeout' => 10,
    ]]);
    $raw = file_get_contents("http://127.0.0.1:8081/api/v1/admin/requests/$requestId/certificates", false, $context);
    preg_match('/\s(\d{3})\s/', $http_response_header[0], $match);
    return [(int)($match[1] ?? 0), json_decode($raw ?: '{}', true)];
}

$db = db();
$suffix = bin2hex(random_bytes(5));
$shopUsername = 'test_shop_' . $suffix;
$adminUsername = 'test_admin_' . $suffix;
$superAdminUsername = 'test_super_' . $suffix;
$shopId = null; $requestId = null; $adminId = null; $shopUserId = null; $certificateId = null;
$superAdminId = null; $adminCreatedShopId = null; $adminCreatedUserId = null; $managedAdminId = null;
try {
    expect_status(200, api('GET', '/health'), 'health');
    expect_status(404, api('POST', '/auth/forgot-password', ['account' => $shopUsername]), 'OTP forgot route removed');
    expect_status(404, api('POST', '/auth/verify-otp', ['account' => $shopUsername, 'otp' => '000000']), 'OTP verify route removed');
    expect_status(404, api('POST', '/auth/reset-password', ['account' => $shopUsername, 'password' => 'new-password-123']), 'OTP reset route removed');
    $registered = expect_status(201, api('POST', '/auth/register', [
        'username' => $shopUsername, 'password' => 'test-only-password-123', 'display_name' => 'Test Shop Owner',
        'shop' => ['name' => 'Integration Test Shop', 'owner_first_name' => 'Test', 'owner_last_name' => 'Owner', 'phone' => '0000000000', 'house_number' => '123', 'district' => 'Mueang', 'province' => 'Chiang Rai', 'latitude' => 19.91, 'longitude' => 99.83],
    ]), 'register');
    $shopUserId = (int)$registered['user_id']; $shopId = (int)$registered['shop_id'];
    $login = expect_status(200, api('POST', '/auth/login', ['username' => $shopUsername, 'password' => 'test-only-password-123']), 'shop login');
    $shopToken = $login['token'];
    $myShops = expect_status(200, api('GET', '/my/shops', null, $shopToken), 'my shops');
    if (($myShops['data'][0]['house_number'] ?? null) !== '123') throw new RuntimeException('Registration address was not saved');
    $request = expect_status(201, api('POST', "/my/shops/$shopId/requests", ['address_snapshot' => 'Chiang Rai', 'vegetables' => ['คะน้า', 'ผักกาดหอม']], $shopToken), 'create request');
    $requestId = (int)$request['id'];
    $summaries = expect_status(200, api('GET', '/my/requests', null, $shopToken), 'request summaries');
    if (($summaries['data'][0]['shop_id'] ?? null) !== $shopId || ($summaries['data'][0]['vegetables'] ?? []) !== ['คะน้า', 'ผักกาดหอม']) {
        throw new RuntimeException('Request summary is missing its shop or vegetable names');
    }
    $detail = expect_status(200, api('GET', "/my/requests/$requestId", null, $shopToken), 'request detail');
    if (count($detail['data']['items']) !== 2) throw new RuntimeException('Request items were not saved');

    run_sql($db, 'INSERT INTO api_users (username, password_hash, display_name, role) VALUES (?, ?, ?, ?)', [$adminUsername, password_hash('test-only-password-123', PASSWORD_DEFAULT), 'Test Admin', 'admin']);
    $adminId = (int)$db->lastInsertId();
    $adminLogin = expect_status(200, api('POST', '/auth/login', ['username' => $adminUsername, 'password' => 'test-only-password-123']), 'admin login');
    $adminToken = $adminLogin['token'];
    run_sql($db, 'INSERT INTO api_users (username, password_hash, display_name, role) VALUES (?, ?, ?, ?)', [$superAdminUsername, password_hash('super-only-password-123', PASSWORD_DEFAULT), 'Test Super Admin', 'super_admin']);
    $superAdminId = (int)$db->lastInsertId();
    $superLogin = expect_status(200, api('POST', '/auth/login', ['username' => $superAdminUsername, 'password' => 'super-only-password-123']), 'super admin login');
    $superToken = $superLogin['token'];
    expect_status(403, api('GET', '/admin/users', null, $adminToken), 'inspector user management guard');
    $users = expect_status(200, api('GET', '/admin/users', null, $superToken), 'super admin user list');
    if (!array_filter($users['data'], static fn ($row) => $row['username'] === $adminUsername)) throw new RuntimeException('Super admin user list is incomplete');
    $managedAdmin = expect_status(201, api('POST', '/admin/users', [
        'username' => 'managed_admin_' . $suffix,
        'display_name' => 'Managed Inspector',
        'password' => 'managed-admin-password-123',
        'role' => 'admin',
    ], $superToken), 'super admin create inspector');
    $managedAdminId = (int)$managedAdmin['id'];
    $managedAdminLogin = expect_status(200, api('POST', '/auth/login', ['username' => 'managed_admin_' . $suffix, 'password' => 'managed-admin-password-123']), 'managed inspector login');
    if (($managedAdminLogin['user']['role'] ?? null) !== 'admin') throw new RuntimeException('Super admin-created account is not an inspector');
    expect_status(200, api('PATCH', "/admin/users/$managedAdminId", ['display_name' => 'Updated Inspector'], $superToken), 'super admin update user');
    expect_status(200, api('PATCH', "/admin/users/$managedAdminId", ['is_active' => false], $superToken), 'super admin deactivate user');
    expect_status(401, api('POST', '/auth/login', ['username' => 'managed_admin_' . $suffix, 'password' => 'managed-admin-password-123']), 'deactivated user guard');
    expect_status(200, api('PATCH', "/admin/users/$managedAdminId", ['is_active' => true], $superToken), 'super admin reactivate user');
    expect_status(200, api('POST', "/admin/users/$managedAdminId/password", ['new_password' => 'managed-admin-reset-123'], $superToken), 'super admin reset inspector password');
    expect_status(200, api('POST', '/auth/login', ['username' => 'managed_admin_' . $suffix, 'password' => 'managed-admin-reset-123']), 'reset inspector login');
    expect_status(200, api('POST', "/admin/users/$shopUserId/password", ['new_password' => 'managed-shop-reset-123'], $superToken), 'super admin reset shop password');
    expect_status(200, api('POST', '/auth/login', ['username' => $shopUsername, 'password' => 'managed-shop-reset-123']), 'reset shop login');
    expect_status(409, api('PATCH', "/admin/users/$superAdminId", ['is_active' => false], $superToken), 'last super admin guard');
    expect_status(200, api('PATCH', '/admin/settings', ['values' => [
        'maintenance_mode' => false,
        'public_app_base_url' => 'https://safevege.example',
        'default_certificate_expiry_days' => 365,
    ]], $superToken), 'super admin update settings');
    $settings = expect_status(200, api('GET', '/admin/settings', null, $superToken), 'super admin read settings');
    if (($settings['data']['default_certificate_expiry_days'] ?? null) !== 365) throw new RuntimeException('Super admin settings were not persisted');
    $audit = expect_status(200, api('GET', '/admin/audit?action=created', null, $superToken), 'super admin audit log');
    if (!$audit['data']) throw new RuntimeException('Super admin audit log is empty');
    $managedUsername = 'managed_shop_' . $suffix;
    $managedShop = expect_status(201, api('POST', '/admin/shops', [
        'username' => $managedUsername,
        'password' => 'managed-shop-password-123',
        'display_name' => 'Managed Shop Owner',
        'name' => 'Admin Created Shop',
        'owner_first_name' => 'Managed',
        'owner_last_name' => 'Owner',
        'phone' => '0000000001',
        'house_number' => '44',
        'subdistrict' => 'Rim Kok',
        'district' => 'Mueang',
        'province' => 'Chiang Rai',
        'latitude' => 19.92,
        'longitude' => 99.84,
    ], $adminToken), 'admin create shop account');
    $adminCreatedShopId = (int)$managedShop['id'];
    $adminCreatedUserId = (int)$managedShop['owner_user_id'];
    $managedLogin = expect_status(200, api('POST', '/auth/login', ['username' => $managedUsername, 'password' => 'managed-shop-password-123']), 'managed shop login');
    if (($managedLogin['user']['role'] ?? null) !== 'shop') throw new RuntimeException('Admin-created account is not a shop account');
    $adminShops = expect_status(200, api('GET', '/admin/shops', null, $adminToken), 'admin shops');
    $managedShopRow = array_values(array_filter($adminShops['data'], static fn ($row) => (int)$row['id'] === $adminCreatedShopId))[0] ?? null;
    if (($managedShopRow['house_number'] ?? null) !== '44' || ($managedShopRow['latitude'] ?? null) === null) {
        throw new RuntimeException('Admin shop list did not return editable shop details');
    }
    expect_status(201, api('POST', "/admin/requests/$requestId/appointment", ['appointment_at' => '2026-10-20 09:00:00'], $adminToken), 'set appointment');
    $items = $detail['data']['items'];
    expect_status(201, api('POST', "/admin/requests/$requestId/results", ['inspected_at' => '2026-10-20 10:00:00', 'items' => [
        ['request_item_id' => (int)$items[0]['id'], 'outcome' => 'passed'],
        ['request_item_id' => (int)$items[1]['id'], 'outcome' => 'failed'],
    ]], $adminToken), 'record results');
    $after = expect_status(200, api('GET', "/admin/requests/$requestId", null, $adminToken), 'admin detail');
    if (count($after['data']['results']) !== 2) throw new RuntimeException('Results were not saved');
    $passed = array_values(array_filter($after['data']['results'], static fn($result) => $result['outcome'] === 'passed'));
    $certificate = expect_status(201, upload_certificate($requestId, $adminToken, (int)$passed[0]['id'], 'TEST-' . $suffix), 'upload certificate');
    $certificateId = (int)$certificate['id'];
    expect_status(200, api('POST', "/admin/requests/$requestId/publish", [], $adminToken), 'publish results');
    $public = expect_status(200, api('GET', '/shops?q=Integration'), 'public shops');
    if (count($public['data']) !== 1) throw new RuntimeException('Published shop is not visible');
    $areaSearch = expect_status(200, api('GET', '/shops?q=Chiang'), 'shop area search');
    if (count($areaSearch['data']) !== 1) throw new RuntimeException('Shop area search failed');
    $vegetableSearch = expect_status(200, api('GET', '/shops?q=' . rawurlencode('คะน้า')), 'vegetable search');
    if (count($vegetableSearch['data']) !== 1) throw new RuntimeException('Certified vegetable search failed');
    $nearby = expect_status(200, api('GET', '/shops?lat=19.91&lng=99.83&radius_km=10'), 'nearby shops');
    $nearbyShopIds = array_map(static fn ($row) => (int)$row['id'], $nearby['data']);
    if (!in_array($shopId, $nearbyShopIds, true)) throw new RuntimeException('Nearby search failed');
    $publicDetail = expect_status(200, api('GET', "/shops/$shopId"), 'public shop detail');
    if (count($publicDetail['data']['results']) !== 1 || (int)$publicDetail['data']['results'][0]['certificate_id'] !== $certificateId) {
        throw new RuntimeException('Public result or certificate details were not returned');
    }
    $publicCertificates = expect_status(200, api('GET', "/shops/$shopId/certificates"), 'public certificates');
    if (count($publicCertificates['data']) !== 1) throw new RuntimeException('Public certificate filter failed');
    $certificateDirectory = expect_status(200, api('GET', '/certificates'), 'public certificate directory');
    $directoryCertificate = array_values(array_filter($certificateDirectory['data'], static fn ($row) => (int)$row['id'] === $certificateId))[0] ?? null;
    if (($directoryCertificate['shop_name'] ?? null) !== 'Integration Test Shop') throw new RuntimeException('Public certificate directory is missing the shop name');
    $fileResponse = get_headers("http://127.0.0.1:8081/api/v1/certificates/$certificateId/file", true);
    if (!str_contains($fileResponse[0], '200')) throw new RuntimeException('Certificate file is not public');
    echo "integration tests passed\n";
} finally {
    if ($certificateId !== null) {
        $stored = find_row($db, 'SELECT file_path FROM api_certificates WHERE id = ?', [$certificateId]);
        run_sql($db, 'DELETE FROM api_certificate_results WHERE certificate_id = ?', [$certificateId]);
        run_sql($db, 'DELETE FROM api_certificates WHERE id = ?', [$certificateId]);
        @unlink(dirname(__DIR__) . '/storage/certificates/' . $stored['file_path']);
    }
    if ($requestId !== null) {
        run_sql($db, 'DELETE r FROM api_inspection_results r JOIN api_inspection_request_items i ON i.id = r.request_item_id WHERE i.request_id = ?', [$requestId]);
        run_sql($db, 'DELETE FROM api_inspection_appointments WHERE request_id = ?', [$requestId]);
        run_sql($db, 'DELETE FROM api_inspection_request_items WHERE request_id = ?', [$requestId]);
        run_sql($db, 'DELETE FROM api_inspection_requests WHERE id = ?', [$requestId]);
    }
    if ($shopId !== null) run_sql($db, 'DELETE FROM api_shops WHERE id = ?', [$shopId]);
    if ($adminCreatedShopId !== null) run_sql($db, 'DELETE FROM api_shops WHERE id = ?', [$adminCreatedShopId]);
    if ($adminCreatedUserId !== null) run_sql($db, 'DELETE FROM api_users WHERE id = ?', [$adminCreatedUserId]);
    if ($managedAdminId !== null) run_sql($db, 'DELETE FROM api_users WHERE id = ?', [$managedAdminId]);
    if ($shopUserId !== null) run_sql($db, 'DELETE FROM api_users WHERE id = ?', [$shopUserId]);
    if ($superAdminId !== null) {
        run_sql($db, 'DELETE FROM api_app_settings WHERE setting_updated_by = ?', [$superAdminId]);
        run_sql($db, 'DELETE FROM api_audit_events WHERE actor_user_id = ?', [$superAdminId]);
        run_sql($db, 'DELETE FROM api_users WHERE id = ?', [$superAdminId]);
    }
    if ($adminId !== null) {
        run_sql($db, 'DELETE FROM api_audit_events WHERE actor_user_id = ?', [$adminId]);
        run_sql($db, 'DELETE FROM api_users WHERE id = ?', [$adminId]);
    }
}
