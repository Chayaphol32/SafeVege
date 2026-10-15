<?php
declare(strict_types=1);

require_once __DIR__ . '/../src/helpers.php';

$cases = [
    ['http://localhost:3000', 'http://localhost:3000,http://127.0.0.1:3000', 'http://localhost:3000'],
    ['http://127.0.0.1:3000', 'http://localhost:3000,http://127.0.0.1:3000', 'http://127.0.0.1:3000'],
    ['http://localhost:5000', 'http://localhost:3000,http://127.0.0.1:3000', null],
    [null, 'http://localhost:3000', null],
    ['http://localhost:3000', '', null],
];

foreach ($cases as [$origin, $configuredOrigins, $expected]) {
    $actual = cors_allowed_origin($origin, $configuredOrigins);
    if ($actual !== $expected) {
        throw new RuntimeException(sprintf(
            'Expected %s for origin %s, got %s',
            var_export($expected, true),
            var_export($origin, true),
            var_export($actual, true),
        ));
    }
}

echo "CORS policy tests passed\n";
