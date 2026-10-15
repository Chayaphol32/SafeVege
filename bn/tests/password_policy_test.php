<?php
declare(strict_types=1);

$source = file_get_contents(__DIR__ . '/../src/routes/auth_routes.php');
if ($source === false) throw new RuntimeException('Cannot read auth routes');
if (!str_contains($source, 'strlen($newPassword) < 12')) {
    throw new RuntimeException('Password changes must require 12 characters');
}
if (str_contains($source, 'strlen($newPassword) < 6') || str_contains($source, 'UPDATE users SET use_password')) {
    throw new RuntimeException('Weak or unmapped password change policy remains');
}

echo "password policy tests passed\n";
