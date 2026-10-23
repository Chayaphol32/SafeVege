<?php
declare(strict_types=1);

require_once __DIR__ . '/../src/bootstrap.php';
require_once __DIR__ . '/../src/routes/admin_routes.php';

$db = db();
$rows = all_rows($db, admin_users_list_sql(200, 0));
$shopOwners = array_map(
    'intval',
    array_column(
        all_rows(
            $db,
            'SELECT DISTINCT owner_user_id FROM api_shops WHERE owner_user_id IS NOT NULL',
        ),
        'owner_user_id',
    ),
);

foreach ($rows as $row) {
    if ($row['role'] === 'shop' && !in_array((int)$row['id'], $shopOwners, true)) {
        throw new RuntimeException('an orphaned shop account is visible in the admin user list');
    }
}

echo "admin user visibility tests passed\n";
