<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/src/bootstrap.php';
require_once dirname(__DIR__) . '/src/auth.php';
require_once dirname(__DIR__) . '/src/routes/auth_routes.php';
require_once dirname(__DIR__) . '/src/routes/public_routes.php';
require_once dirname(__DIR__) . '/src/routes/shop_routes.php';
require_once dirname(__DIR__) . '/src/routes/admin_routes.php';

$origin = $_SERVER['HTTP_ORIGIN'] ?? null;
$allowedOrigin = cors_allowed_origin($origin, config('CORS_ORIGIN'));
if ($allowedOrigin !== null) {
    header('Access-Control-Allow-Origin: ' . $allowedOrigin);
    header('Vary: Origin');
    header('Access-Control-Allow-Headers: Authorization, Content-Type');
    header('Access-Control-Allow-Methods: GET, POST, PATCH, DELETE, OPTIONS');
}
header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store');

try {
    if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') send_json(204, []);
    $path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
    $segments = path_parts((string)$path);
    $apiIndex = array_search('api', $segments, true);
    if ($apiIndex === false || ($segments[$apiIndex + 1] ?? null) !== 'v1') not_found();
    $p = array_slice($segments, $apiIndex + 2);
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
    if ($p === ['health'] && $method === 'GET') {
        db()->query('SELECT 1');
        send_json(200, ['status' => 'ok']);
    }
    $db = db();
    $maintRow = all_rows($db, "SELECT setting_value FROM api_app_settings WHERE setting_key = 'maintenance_mode' LIMIT 1");
    $isMaintenance = false;
    if ($maintRow) {
        $maintVal = json_decode((string)$maintRow[0]['setting_value'], true);
        $isMaintenance = ($maintVal === true || $maintVal === 1 || $maintVal === 'true');
    }
    if ($isMaintenance) {
        $isHealth = ($p === ['health']);
        $isAdminRoute = (($p[0] ?? '') === 'admin');
        if (!$isHealth && !$isAdminRoute) {
            $user = null;
            try { $user = current_user($db); } catch (Throwable) {}
            if (!$user || !in_array($user['role'] ?? '', ['admin', 'super_admin'], true)) {
                if (!($p === ['auth', 'login'] && $method === 'POST')) {
                    send_json(503, [
                        'error' => 'ระบบกำลังปิดปรับปรุงชั่วคราว (Maintenance Mode)',
                        'maintenance' => true,
                    ]);
                }
            }
        }
    }
    auth_routes($db, $method, $p);
    public_routes($db, $method, $p);
    shop_routes($db, $method, $p);
    admin_routes($db, $method, $p);
    if (count($p) === 3 && $p[0] === 'certificates' && ctype_digit($p[1]) && $p[2] === 'file' && $method === 'GET') {
        $certificate = find_row($db, 'SELECT c.*, r.status AS request_status, s.owner_user_id FROM api_certificates c JOIN api_inspection_requests r ON r.id = c.request_id JOIN api_shops s ON s.id = r.shop_id WHERE c.id = ?', [(int)$p[1]]);
        $public = (int)$certificate['is_public'] === 1 && $certificate['request_status'] === 'published' && ($certificate['expires_at'] === null || $certificate['expires_at'] >= gmdate('Y-m-d'));
        if (!$public) {
            $user = current_user($db);
            if (!in_array($user['role'], ['admin', 'super_admin'], true) && (int)$user['id'] !== (int)$certificate['owner_user_id']) throw new ApiError(403, 'Forbidden');
        }
        $root = dirname(__DIR__) . '/storage/certificates';
        $fileName = basename($certificate['file_path']);
        if ($fileName !== $certificate['file_path']) throw new RuntimeException('Invalid stored file path');
        $filePath = $root . '/' . $fileName;
        if (!is_file($filePath)) not_found();
        header('Content-Type: ' . $certificate['mime_type']);
        header('Content-Disposition: inline; filename="certificate-' . (int)$certificate['id'] . ($certificate['mime_type'] === 'application/pdf' ? '.pdf' : '.jpg') . '"');
        header('Content-Length: ' . filesize($filePath));
        readfile($filePath);
        exit;
    }
    not_found();
} catch (ApiError $error) {
    send_json($error->status, ['error' => $error->getMessage()]);
} catch (PDOException $error) {
    $duplicate = $error->getCode() === '23000';
    send_json($duplicate ? 409 : 503, ['error' => $duplicate ? 'Duplicate or conflicting data' : 'Database unavailable']);
} catch (Throwable $error) {
    error_log('SafeVege API error: ' . $error->getMessage());
    send_json(500, ['error' => config('APP_DEBUG', 'false') === 'true' ? $error->getMessage() : 'Internal server error']);
}
