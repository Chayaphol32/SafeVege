<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') { http_response_code(404); exit(1); }
require_once dirname(__DIR__) . '/src/bootstrap.php';
require_once dirname(__DIR__) . '/src/demo_seeder.php';

if (($argv[1] ?? '') !== '--local-demo') {
    fwrite(STDERR, "Usage: php scripts/seed_demo.php --local-demo\nThis command only seeds a loopback MySQL database named safevege.\n");
    exit(2);
}

$host = strtolower((string)config('DB_HOST', '127.0.0.1'));
$database = (string)config('DB_NAME', 'safevege');
if (!in_array($host, ['127.0.0.1', 'localhost', '::1'], true) || $database !== 'safevege') {
    fwrite(STDERR, "Refusing to seed: the configured database is not the local safevege database.\n");
    exit(2);
}

try {
    $summary = seed_demo_data(db());
    echo "Local demo data is ready: {$summary['users']} accounts, {$summary['shops']} shops, {$summary['requests']} requests, {$summary['certificates']} sample certificates.\n";
    echo "Login: demo_admin or demo_shop or demo_market | Password: " . SAFEVEGE_DEMO_PASSWORD . "\n";
    echo "The certificate files and records are visibly marked DEMO and are not real inspection evidence.\n";
} catch (Throwable $error) {
    fwrite(STDERR, "Demo seeding failed: " . $error->getMessage() . "\n");
    exit(1);
}
