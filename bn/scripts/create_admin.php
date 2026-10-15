<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') { http_response_code(404); exit; }
require_once dirname(__DIR__) . '/src/bootstrap.php';

$role = 'admin';
$arguments = [];
foreach (array_slice($argv, 1) as $argument) {
    if (str_starts_with($argument, '--role=')) {
        $role = substr($argument, 7);
    } else {
        $arguments[] = $argument;
    }
}
$username = $arguments[0] ?? '';
$displayName = $arguments[1] ?? '';
$password = getenv('SAFEVEGE_ADMIN_PASSWORD');
if (!in_array($role, ['admin', 'super_admin'], true) || $username === '' || $displayName === '' || $password === false || strlen($password) < 12) {
    fwrite(STDERR, "Usage: set SAFEVEGE_ADMIN_PASSWORD (12+ chars), then run: php create_admin.php [--role=admin|--role=super_admin] <username> <display-name>\n");
    exit(1);
}

try {
    run_sql(db(), 'INSERT INTO api_users (username, password_hash, display_name, role) VALUES (?, ?, ?, ?)', [$username, password_hash($password, PASSWORD_DEFAULT), $displayName, $role]);
    echo "Admin created with role: $role\n";
} catch (Throwable $error) {
    fwrite(STDERR, "Could not create admin: " . $error->getMessage() . "\n");
    exit(1);
}
