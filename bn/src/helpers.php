<?php
declare(strict_types=1);

final class ApiError extends RuntimeException {
    public function __construct(public int $status, string $message) { parent::__construct($message); }
}

function cors_allowed_origin(?string $origin, ?string $configuredOrigins): ?string {
    if ($origin === null || $origin === '' || $configuredOrigins === null) return null;
    $allowedOrigins = array_filter(array_map('trim', explode(',', $configuredOrigins)));
    if (in_array('*', $allowedOrigins, true)) return $origin;
    return in_array($origin, $allowedOrigins, true) ? $origin : null;
}

function path_parts(string $path): array {
    return array_values(array_filter(explode('/', trim($path, '/')), static fn($part) => $part !== ''));
}

function vegetable_names($input): array {
    if (!is_array($input)) throw new ApiError(422, 'vegetables must be an array');
    $items = [];
    foreach ($input as $name) {
        if (!is_string($name)) throw new ApiError(422, 'Every vegetable must have a name');
        $name = trim($name);
        if ($name !== '' && !in_array($name, $items, true)) $items[] = $name;
    }
    if (count($items) < 1 || count($items) > 30) throw new ApiError(422, 'Add 1 to 30 vegetables');
    foreach ($items as $name) if (text_length($name) > 255) throw new ApiError(422, 'Vegetable name is too long');
    return $items;
}

function text_length(string $value): int {
    $count = preg_match_all('/./us', $value);
    if ($count === false) throw new ApiError(422, 'Invalid text encoding');
    return $count;
}

function valid_coordinates($lat, $lng): bool {
    if ($lat === null && $lng === null) return true;
    return is_numeric($lat) && is_numeric($lng) && (float)$lat >= -90 && (float)$lat <= 90 && (float)$lng >= -180 && (float)$lng <= 180;
}

function required_string(array $data, string $key, int $max = 255): string {
    $value = $data[$key] ?? null;
    if (!is_string($value) || trim($value) === '' || text_length(trim($value)) > $max) throw new ApiError(422, "$key is required (max $max characters)");
    return trim($value);
}

function optional_string(array $data, string $key, int $max = 255): ?string {
    if (!array_key_exists($key, $data) || $data[$key] === null) return null;
    if (!is_string($data[$key]) || text_length(trim($data[$key])) > $max) throw new ApiError(422, "$key must be a string (max $max characters)");
    return trim($data[$key]);
}

function json_body(): array {
    $raw = file_get_contents('php://input');
    $body = json_decode($raw ?: '{}', true);
    if (!is_array($body) || json_last_error() !== JSON_ERROR_NONE) throw new ApiError(400, 'Invalid JSON body');
    return $body;
}

function send_json(int $status, $body): never {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function not_found(): never { throw new ApiError(404, 'Not found'); }

function find_row(PDO $db, string $sql, array $params): array {
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$row) not_found();
    return $row;
}

function all_rows(PDO $db, string $sql, array $params = []): array {
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    return $stmt->fetchAll(PDO::FETCH_ASSOC);
}

function run_sql(PDO $db, string $sql, array $params = []): int {
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    return $stmt->rowCount();
}
