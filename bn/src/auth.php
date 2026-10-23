<?php
declare(strict_types=1);

require_once __DIR__ . '/helpers.php';

function current_user(PDO $db): array {
    $authorization = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if (!preg_match('/^Bearer\s+([A-Za-z0-9_-]{40,})$/', $authorization, $match)) throw new ApiError(401, 'Authentication required');
    $user = find_token_user($db, $match[1]);
    if (!$user) throw new ApiError(401, 'Invalid or expired token');
    return $user;
}

function find_token_user(PDO $db, string $token): ?array {
    $stmt = $db->prepare('SELECT u.id, u.username, u.display_name, u.role, u.is_active FROM api_api_tokens t JOIN api_users u ON u.id = t.user_id WHERE t.token_hash = ? AND t.expires_at > UTC_TIMESTAMP() LIMIT 1');
    $stmt->execute([hash('sha256', $token)]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    return $user && (int)$user['is_active'] === 1 ? $user : null;
}

function require_role(array $user, string $role): void {
    if ($user['role'] !== $role) throw new ApiError(403, 'Forbidden');
}

function require_any_role(array $user, array $roles): void {
    if (!in_array($user['role'] ?? null, $roles, true)) {
        throw new ApiError(403, 'Forbidden');
    }
}

function require_super_admin(array $user): void {
    require_any_role($user, ['super_admin']);
}

function can_change_last_super_admin(
    int $activeSuperAdminCount,
    string $targetRole,
    bool $targetIsActive,
    array $changes,
): bool {
    if ($targetRole === 'super_admin') return false;
    if ($targetRole !== 'super_admin' || !$targetIsActive) return true;
    $nextRole = $changes['role'] ?? $targetRole;
    $nextIsActive = array_key_exists('is_active', $changes)
        ? (bool)$changes['is_active']
        : true;
    $removesActiveSuperAdmin = $nextRole !== 'super_admin' || !$nextIsActive;
    return !$removesActiveSuperAdmin || $activeSuperAdminCount > 1;
}

function issue_token(PDO $db, int $userId): string {
    $token = bin2hex(random_bytes(32));
    run_sql($db, 'INSERT INTO api_api_tokens (user_id, token_hash, expires_at) VALUES (?, ?, DATE_ADD(UTC_TIMESTAMP(), INTERVAL 30 DAY))', [$userId, hash('sha256', $token)]);
    return $token;
}
