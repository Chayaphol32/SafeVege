<?php
declare(strict_types=1);

function auth_routes(PDO $db, string $method, array $p): bool {
    if ($p === ['auth', 'register'] && $method === 'POST') {
        $body = json_body();
        $username = required_string($body, 'username', 100);
        $password = required_string($body, 'password', 255);
        if (strlen($password) < 12) throw new ApiError(422, 'Password must be at least 12 characters');
        $shop = $body['shop'] ?? null;
        if (!is_array($shop)) throw new ApiError(422, 'shop is required');
        foreach (['name' => 255, 'owner_first_name' => 100, 'owner_last_name' => 100, 'phone' => 30] as $key => $limit) required_string($shop, $key, $limit);
        $lat = $shop['latitude'] ?? null;
        $lng = $shop['longitude'] ?? null;
        if (!valid_coordinates($lat, $lng)) throw new ApiError(422, 'Invalid coordinates');
        $db->beginTransaction();
        try {
            run_sql($db, 'INSERT INTO api_users (username, password_hash, display_name, role) VALUES (?, ?, ?, ?)', [$username, password_hash($password, PASSWORD_DEFAULT), required_string($body, 'display_name', 150), 'shop']);
            $userId = (int)$db->lastInsertId();
            run_sql($db, 'INSERT INTO api_shops (owner_user_id, name, owner_first_name, owner_last_name, phone, house_number, moo, street, subdistrict, district, province, postal_code, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [
                $userId,
                $shop['name'],
                $shop['owner_first_name'],
                $shop['owner_last_name'],
                $shop['phone'],
                optional_string($shop, 'house_number', 100),
                optional_string($shop, 'moo', 30),
                optional_string($shop, 'street', 150),
                optional_string($shop, 'subdistrict', 150),
                optional_string($shop, 'district', 150),
                optional_string($shop, 'province', 150),
                optional_string($shop, 'postal_code', 10),
                $lat,
                $lng,
            ]);
            $shopId = (int)$db->lastInsertId();
            $db->commit();
        } catch (Throwable $error) { $db->rollBack(); throw $error; }
        send_json(201, ['user_id' => $userId, 'shop_id' => $shopId]);
    }
    if ($p === ['auth', 'login'] && $method === 'POST') {
        $body = json_body();
        $stmt = $db->prepare('SELECT id, username, display_name, role, is_active, password_hash FROM api_users WHERE username = ? LIMIT 1');
        $stmt->execute([required_string($body, 'username', 100)]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!is_string($body['password'] ?? null) || !$user || (int)$user['is_active'] !== 1 || !password_verify($body['password'], $user['password_hash'])) throw new ApiError(401, 'Invalid credentials');
        $token = issue_token($db, (int)$user['id']);
        unset($user['password_hash']);
        send_json(200, ['token' => $token, 'user' => $user]);
    }
    if ($p === ['auth', 'logout'] && $method === 'POST') {
        current_user($db);
        $token = preg_replace('/^Bearer\s+/', '', $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '');
        run_sql($db, 'DELETE FROM api_api_tokens WHERE token_hash = ?', [hash('sha256', $token)]);
        send_json(200, ['message' => 'Logged out']);
    }
    if ($p === ['auth', 'change-password'] && $method === 'POST') {
        $user = current_user($db);
        $userId = (int)$user['id'];
        $body = json_body();
        $oldPassword = required_string($body, 'old_password', 255);
        $newPassword = required_string($body, 'new_password', 255);
        if (strlen($newPassword) < 12) throw new ApiError(422, 'รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 12 ตัวอักษร');

        $stmt = $db->prepare('SELECT password_hash FROM api_users WHERE id = ? LIMIT 1');
        $stmt->execute([$userId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!$row || !password_verify($oldPassword, $row['password_hash'])) {
            throw new ApiError(401, 'รหัสผ่านเดิมไม่ถูกต้อง');
        }

        run_sql($db, 'UPDATE api_users SET password_hash = ? WHERE id = ?', [password_hash($newPassword, PASSWORD_DEFAULT), $userId]);
        audit($db, $userId, 'user', $userId, 'password_change', []);

        send_json(200, ['message' => 'เปลี่ยนรหัสผ่านเรียบร้อยแล้ว']);
    }
    if ($p === ['me'] && $method === 'GET') send_json(200, ['user' => current_user($db)]);
    return false;
}
