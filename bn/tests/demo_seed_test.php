<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/src/bootstrap.php';
require_once dirname(__DIR__) . '/src/demo_seeder.php';

function seed_test_expect(bool $condition, string $message): void {
    if (!$condition) throw new RuntimeException($message);
}

function seed_test_api(string $method, string $path, ?array $body = null, ?string $token = null): array {
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

function seed_test_counts(PDO $db): array {
    return [
        'users' => (int)find_row($db, "SELECT COUNT(*) AS total FROM api_users WHERE username IN ('demo_admin','demo_shop','demo_market')", [])['total'],
        'shops' => (int)find_row($db, "SELECT COUNT(*) AS total FROM api_shops WHERE name LIKE '%(DEMO)%'", [])['total'],
        'requests' => (int)find_row($db, "SELECT COUNT(*) AS total FROM api_inspection_requests WHERE request_no LIKE 'DEMO-2026-%'", [])['total'],
        'certificates' => (int)find_row($db, "SELECT COUNT(*) AS total FROM api_certificates WHERE certificate_no LIKE 'DEMO-CERT-%'", [])['total'],
    ];
}

$dbHost = strtolower((string)config('DB_HOST', '127.0.0.1'));
if (!in_array($dbHost, ['127.0.0.1', 'localhost', '::1'], true) || config('DB_NAME', 'safevege') !== 'safevege') {
    throw new RuntimeException('Demo seed tests only run against the local safevege database');
}

$db = db();
seed_demo_data($db);
$firstCounts = seed_test_counts($db);
seed_demo_data($db);
$secondCounts = seed_test_counts($db);
seed_test_expect($firstCounts === $secondCounts, 'Running the demo seeder twice created duplicate records');
seed_test_expect($secondCounts === ['users' => 3, 'shops' => 3, 'requests' => 5, 'certificates' => 2], 'The expected demo records are missing');

[$status, $shops] = seed_test_api('GET', '/shops?q=DEMO');
seed_test_expect($status === 200 && count($shops['data'] ?? []) === 3, 'Demo shops are not visible through the public API');

[$status, $certificateDirectory] = seed_test_api('GET', '/certificates');
$demoCertificates = array_values(array_filter($certificateDirectory['data'] ?? [], static fn ($row) => str_starts_with((string)($row['certificate_no'] ?? ''), 'DEMO-CERT-')));
seed_test_expect($status === 200 && count($demoCertificates) === 2, 'Demo certificates are not visible through the public API');
$file = file_get_contents('http://127.0.0.1:8081/api/v1/certificates/' . (int)$demoCertificates[0]['id'] . '/file');
seed_test_expect(is_string($file) && str_starts_with($file, '%PDF-1.4'), 'The sample certificate PDF is not downloadable');

[$status, $shopLogin] = seed_test_api('POST', '/auth/login', ['username' => 'demo_shop', 'password' => 'DemoSafeVege!2026']);
seed_test_expect($status === 200 && !empty($shopLogin['token']), 'Demo shop login failed');
[$status, $shopRequests] = seed_test_api('GET', '/my/requests', null, $shopLogin['token']);
seed_test_expect($status === 200 && count($shopRequests['data'] ?? []) === 4, 'Demo shop requests are not visible to the shop account');

[$status, $adminLogin] = seed_test_api('POST', '/auth/login', ['username' => 'demo_admin', 'password' => 'DemoSafeVege!2026']);
seed_test_expect($status === 200 && !empty($adminLogin['token']), 'Demo admin login failed');
[$status, $adminShops] = seed_test_api('GET', '/admin/shops', null, $adminLogin['token']);
seed_test_expect($status === 200 && count($adminShops['data'] ?? []) >= 3, 'Demo shops are not visible to the admin account');

echo "demo seed tests passed\n";
