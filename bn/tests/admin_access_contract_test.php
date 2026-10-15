<?php
declare(strict_types=1);

require __DIR__ . '/../src/auth.php';

function expect_forbidden(callable $callback, string $message): void {
    try {
        $callback();
    } catch (ApiError $error) {
        if ($error->status === 403) return;
        throw new RuntimeException($message . ': wrong status ' . $error->status);
    }
    throw new RuntimeException($message . ': no error');
}

require_any_role(['role' => 'super_admin'], ['admin', 'super_admin']);
require_super_admin(['role' => 'super_admin']);
expect_forbidden(
    fn() => require_super_admin(['role' => 'admin']),
    'admin guard',
);
echo "admin access contract tests passed\n";
