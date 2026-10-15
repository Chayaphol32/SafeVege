<?php
declare(strict_types=1);

require_once __DIR__ . '/helpers.php';

function load_env(string $file): array {
    $values = [];
    if (!is_file($file)) return $values;
    foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
        $line = trim($line);
        if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) continue;
        [$key, $value] = explode('=', $line, 2);
        $values[trim($key)] = trim($value, " \t\n\r\0\x0B\"'");
    }
    return $values;
}

function config(string $name, ?string $default = null): ?string {
    static $local = null;
    $local ??= load_env(dirname(__DIR__) . '/.env');
    $system = getenv($name);
    return $system !== false ? $system : ($local[$name] ?? $default);
}

function db(): PDO {
    $host = config('DB_HOST', '127.0.0.1');
    $port = config('DB_PORT', '3306');
    $name = config('DB_NAME', 'safevege');
    $user = config('DB_USER');
    $pass = config('DB_PASSWORD');
    if ($user === null || $user === '') throw new ApiError(503, 'Database is not configured');
    return new PDO("mysql:host=$host;port=$port;dbname=$name;charset=utf8mb4", $user, $pass ?? '', [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
}
