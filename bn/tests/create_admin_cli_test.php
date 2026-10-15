<?php
declare(strict_types=1);

$source = file_get_contents(__DIR__ . '/../scripts/create_admin.php');
if ($source === false) throw new RuntimeException('Cannot read create_admin.php');

foreach (['--role=admin', '--role=super_admin', 'SAFEVEGE_ADMIN_PASSWORD'] as $required) {
    if (!str_contains($source, $required)) throw new RuntimeException("Missing CLI role contract: $required");
}
if (str_contains($source, "'password'")) throw new RuntimeException('CLI must not embed a password');

echo "create-admin CLI contract tests passed\n";
