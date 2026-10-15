<?php
declare(strict_types=1);

$source = file_get_contents(__DIR__ . '/../src/routes/auth_routes.php');
if ($source === false) throw new RuntimeException('Cannot read auth routes');

foreach (['forgot-password', 'verify-otp', 'demo_otp', "=== '123456'"] as $forbidden) {
    if (str_contains($source, $forbidden)) {
        throw new RuntimeException("OTP recovery marker remains: $forbidden");
    }
}

echo "OTP removal contract tests passed\n";
