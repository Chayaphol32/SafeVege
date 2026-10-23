<?php
declare(strict_types=1);

require __DIR__ . '/../src/auth.php';
require __DIR__ . '/../src/routes/admin_routes.php';

function expect_forbidden_again(callable $callback, string $message): void {
    try {
        $callback();
    } catch (ApiError $error) {
        if ($error->status === 403) return;
        throw new RuntimeException($message . ': wrong status ' . $error->status);
    }
    throw new RuntimeException($message . ': no error');
}

expect_forbidden_again(
    fn() => require_super_admin(['role' => 'admin']),
    'inspector cannot manage users',
);
expect_forbidden_again(
    fn() => require_super_admin(['role' => 'shop']),
    'shop cannot manage users',
);

if (can_change_last_super_admin(1, 'super_admin', true, ['role' => 'admin'])) {
    throw new RuntimeException('the only super admin could be demoted');
}
if (can_change_last_super_admin(1, 'super_admin', true, ['is_active' => false])) {
    throw new RuntimeException('the only super admin could be deactivated');
}
if (can_change_last_super_admin(2, 'super_admin', true, ['role' => 'admin'])) {
    throw new RuntimeException('a super admin account could still be changed');
}
if (!can_change_last_super_admin(1, 'admin', true, ['role' => 'super_admin'])) {
    throw new RuntimeException('an inspector could not be promoted');
}

$settings = normalize_admin_settings([
    'maintenance_mode' => true,
    'public_app_base_url' => 'https://safevege.example',
    'default_certificate_expiry_days' => '30',
]);
if ($settings['default_certificate_expiry_days'] !== 30 || $settings['maintenance_mode'] !== true) {
    throw new RuntimeException('admin settings were not normalized');
}
try {
    normalize_admin_settings(['unknown_setting' => true]);
    throw new RuntimeException('unknown settings were accepted');
} catch (ApiError $error) {
    if ($error->status !== 422) throw $error;
}

$adminRoutes = file_get_contents(__DIR__ . '/../src/routes/admin_routes.php');
if ($adminRoutes === false) throw new RuntimeException('Cannot read admin routes');
foreach (['UPDATE users SET', 'use_password', 'use_id'] as $forbidden) {
    if (str_contains($adminRoutes, $forbidden)) throw new RuntimeException("Prefixed table write remains: $forbidden");
}

echo "super admin policy tests passed\n";
