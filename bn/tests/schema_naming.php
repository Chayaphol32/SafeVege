<?php
declare(strict_types=1);

require_once __DIR__ . '/../src/bootstrap.php';

$prefixes = [
    'users' => 'use_',
    'api_tokens' => 'tok_',
    'shops' => 'shop_',
    'inspection_requests' => 'req_',
    'inspection_request_items' => 'item_',
    'inspection_appointments' => 'apt_',
    'inspection_results' => 'res_',
    'certificates' => 'cert_',
    'certificate_results' => 'cr_',
    'audit_events' => 'aud_',
    'app_settings' => 'set_',
];

$db = db();
foreach ($prefixes as $table => $prefix) {
    $stmt = $db->prepare('SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? ORDER BY ORDINAL_POSITION');
    $stmt->execute([$table]);
    $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    if (!$columns) throw new RuntimeException("Missing table $table");
    foreach ($columns as $column) if (!str_starts_with($column, $prefix)) throw new RuntimeException("Column $table.$column needs prefix $prefix");
}
$columns = $db->query("SHOW COLUMNS FROM users LIKE 'use_password'")->fetchAll();
if (count($columns) !== 1) throw new RuntimeException('users.use_password is missing');
echo "prefixed database columns verified\n";
