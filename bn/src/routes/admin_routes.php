<?php
declare(strict_types=1);

function admin_routes(PDO $db, string $method, array $p): bool {
    if (($p[0] ?? '') !== 'admin') return false;
    $user = current_user($db);
    require_any_role($user, ['admin', 'super_admin']);

    if ($p === ['admin', 'users'] && $method === 'GET') {
        require_super_admin($user);
        $limit = (int)($_GET['limit'] ?? 200);
        $offset = (int)($_GET['offset'] ?? 0);
        if ($limit < 1 || $limit > 200 || $offset < 0) throw new ApiError(422, 'Invalid pagination');
        $rows = all_rows($db, "SELECT id, username, display_name, role, is_active, created_at FROM api_users ORDER BY id DESC LIMIT $limit OFFSET $offset");
        send_json(200, ['data' => $rows]);
    }
    if ($p === ['admin', 'users'] && $method === 'POST') {
        require_super_admin($user);
        $body = json_body();
        $username = required_string($body, 'username', 100);
        $displayName = required_string($body, 'display_name', 150);
        $password = required_string($body, 'password', 255);
        $role = required_string($body, 'role', 20);
        if (!in_array($role, ['admin', 'super_admin'], true)) throw new ApiError(422, 'Invalid admin role');
        if (strlen($password) < 12) throw new ApiError(422, 'Password must be at least 12 characters');
        if (all_rows($db, 'SELECT id FROM api_users WHERE username = ? LIMIT 1', [$username])) throw new ApiError(409, 'Username already exists');
        if ($role === 'super_admin') verify_current_password($db, (int)$user['id'], $body);
        $db->beginTransaction();
        try {
            run_sql($db, 'INSERT INTO api_users (username, password_hash, display_name, role) VALUES (?, ?, ?, ?)', [$username, password_hash($password, PASSWORD_DEFAULT), $displayName, $role]);
            $newId = (int)$db->lastInsertId();
            audit($db, (int)$user['id'], 'user', $newId, 'created', ['role' => $role]);
            $db->commit();
        } catch (Throwable $error) { $db->rollBack(); throw $error; }
        send_json(201, ['id' => $newId, 'username' => $username, 'display_name' => $displayName, 'role' => $role, 'is_active' => 1]);
    }
    if (count($p) === 3 && $p[1] === 'users' && ctype_digit($p[2]) && $method === 'PATCH') {
        require_super_admin($user);
        $targetId = (int)$p[2];
        $body = json_body();
        $changes = [];
        if (array_key_exists('display_name', $body)) $changes['display_name'] = required_string($body, 'display_name', 150);
        if (array_key_exists('role', $body)) {
            $changes['role'] = required_string($body, 'role', 20);
            if (!in_array($changes['role'], ['admin', 'super_admin'], true)) throw new ApiError(422, 'Invalid admin role');
        }
        if (array_key_exists('is_active', $body)) {
            if (!is_bool($body['is_active'])) throw new ApiError(422, 'is_active must be a boolean');
            $changes['is_active'] = $body['is_active'] ? 1 : 0;
        }
        if (!$changes) throw new ApiError(422, 'No editable fields supplied');
        $db->beginTransaction();
        try {
            $target = find_row($db, 'SELECT id, role, is_active FROM api_users WHERE id = ? FOR UPDATE', [$targetId]);
            if ($targetId === (int)$user['id'] && (($changes['role'] ?? $target['role']) !== 'super_admin' || (array_key_exists('is_active', $changes) && (int)$changes['is_active'] !== 1))) {
                throw new ApiError(409, 'Use change-password before changing your own super-admin account');
            }
            if (($changes['role'] ?? null) === 'super_admin' && $target['role'] !== 'super_admin') verify_current_password($db, (int)$user['id'], $body);
            $activeCount = count(all_rows($db, "SELECT id FROM api_users WHERE role = 'super_admin' AND is_active = 1 FOR UPDATE"));
            if (!can_change_last_super_admin($activeCount, $target['role'], (int)$target['is_active'] === 1, $changes)) throw new ApiError(409, 'At least one active super admin is required');
            $assignments = [];
            $values = [];
            foreach ($changes as $field => $value) { $assignments[] = "$field = ?"; $values[] = $value; }
            $values[] = $targetId;
            run_sql($db, 'UPDATE api_users SET ' . implode(', ', $assignments) . ' WHERE id = ?', $values);
            audit($db, (int)$user['id'], 'user', $targetId, 'updated', ['fields' => array_keys($changes)]);
            $db->commit();
        } catch (Throwable $error) { if ($db->inTransaction()) $db->rollBack(); throw $error; }
        send_json(200, ['message' => 'User updated']);
    }
    if (count($p) === 4 && $p[1] === 'users' && ctype_digit($p[2]) && $p[3] === 'password' && $method === 'POST') {
        require_super_admin($user);
        $targetId = (int)$p[2];
        if ($targetId === (int)$user['id']) throw new ApiError(409, 'Use change-password for your own account');
        find_row($db, 'SELECT id FROM api_users WHERE id = ?', [$targetId]);
        $body = json_body();
        $password = required_string($body, 'new_password', 255);
        if (strlen($password) < 12) throw new ApiError(422, 'Password must be at least 12 characters');
        $db->beginTransaction();
        try {
            run_sql($db, 'UPDATE api_users SET password_hash = ? WHERE id = ?', [password_hash($password, PASSWORD_DEFAULT), $targetId]);
            run_sql($db, 'DELETE FROM api_api_tokens WHERE user_id = ?', [$targetId]);
            audit($db, (int)$user['id'], 'user', $targetId, 'password_reset_by_super_admin', []);
            $db->commit();
        } catch (Throwable $error) { if ($db->inTransaction()) $db->rollBack(); throw $error; }
        send_json(200, ['message' => 'Password updated']);
    }
    if ($p === ['admin', 'audit'] && $method === 'GET') {
        require_super_admin($user);
        $limit = (int)($_GET['limit'] ?? 100);
        $offset = (int)($_GET['offset'] ?? 0);
        if ($limit < 1 || $limit > 200 || $offset < 0) throw new ApiError(422, 'Invalid pagination');
        $where = [];
        $params = [];
        foreach (['actor_id' => 'a.actor_user_id', 'action' => 'a.action', 'entity_type' => 'a.entity_type'] as $queryKey => $column) {
            if (!array_key_exists($queryKey, $_GET) || $_GET[$queryKey] === '') continue;
            if ($queryKey === 'actor_id' && (!is_string($_GET[$queryKey]) || !ctype_digit($_GET[$queryKey]) || (int)$_GET[$queryKey] < 1)) throw new ApiError(422, 'Invalid actor_id');
            $where[] = "$column = ?";
            $params[] = $queryKey === 'actor_id' ? (int)$_GET[$queryKey] : (string)$_GET[$queryKey];
        }
        $sql = 'SELECT a.id, a.actor_user_id, u.username AS actor_username, a.entity_type, a.entity_id, a.action, a.details, a.created_at FROM api_audit_events a JOIN api_users u ON u.id = a.actor_user_id';
        if ($where) $sql .= ' WHERE ' . implode(' AND ', $where);
        $sql .= " ORDER BY a.created_at DESC, a.id DESC LIMIT $limit OFFSET $offset";
        send_json(200, ['data' => all_rows($db, $sql, $params)]);
    }
    if ($p === ['admin', 'settings'] && $method === 'GET') {
        require_super_admin($user);
        $settings = [];
        foreach (all_rows($db, 'SELECT setting_key, setting_value FROM api_app_settings ORDER BY setting_key') as $row) {
            $settings[$row['setting_key']] = json_decode((string)$row['setting_value'], true);
        }
        send_json(200, ['data' => (object)$settings]);
    }
    if ($p === ['admin', 'settings'] && $method === 'PATCH') {
        require_super_admin($user);
        $body = json_body();
        $values = $body['values'] ?? $body;
        if (!is_array($values) || !$values) throw new ApiError(422, 'Settings values are required');
        $normalized = normalize_admin_settings($values);
        $db->beginTransaction();
        try {
            foreach ($normalized as $key => $value) {
                run_sql($db, 'INSERT INTO api_app_settings (setting_key, setting_value, setting_updated_by) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value), setting_updated_by = VALUES(setting_updated_by)', [$key, json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES), (int)$user['id']]);
            }
            audit($db, (int)$user['id'], 'setting', 0, 'updated', ['keys' => array_keys($normalized)]);
            $db->commit();
        } catch (Throwable $error) { $db->rollBack(); throw $error; }
        send_json(200, ['message' => 'Settings updated', 'data' => $normalized]);
    }
    if ($p === ['admin', 'requests'] && $method === 'GET') {
        $status = $_GET['status'] ?? null;
        $allowed = ['submitted','scheduled','inspected','published','cancelled'];
        if ($status !== null && !in_array($status, $allowed, true)) throw new ApiError(422, 'Invalid status');
        $sql = 'SELECT r.id, r.request_no, r.status, r.submitted_at, s.id AS shop_id, s.name AS shop_name FROM api_inspection_requests r JOIN api_shops s ON s.id = r.shop_id';
        $params = [];
        if ($status !== null) { $sql .= ' WHERE r.status = ?'; $params[] = $status; }
        $sql .= ' ORDER BY r.submitted_at DESC, r.id DESC LIMIT 200';
        $rows = all_rows($db, $sql, $params);
        if ($rows) {
            $requestIds = array_map(static fn (array $row): int => (int)$row['id'], $rows);
            $placeholders = implode(',', array_fill(0, count($requestIds), '?'));
            $items = all_rows($db, "SELECT request_id, vegetable_name FROM api_inspection_request_items WHERE request_id IN ($placeholders) ORDER BY id", $requestIds);
            $vegetablesByRequest = [];
            foreach ($items as $item) $vegetablesByRequest[(int)$item['request_id']][] = $item['vegetable_name'];
            foreach ($rows as &$row) $row['vegetables'] = $vegetablesByRequest[(int)$row['id']] ?? [];
            unset($row);
        }
        send_json(200, ['data' => $rows]);
    }
    if ($p === ['admin', 'shops'] && $method === 'GET') send_json(200, ['data' => all_rows($db, 'SELECT id, owner_user_id, name, owner_first_name, owner_last_name, phone, house_number, moo, street, subdistrict, district, province, postal_code, latitude, longitude, is_public, created_at FROM api_shops ORDER BY id DESC LIMIT 200')]);
    if ($p === ['admin', 'shops'] && $method === 'POST') {
        $body = json_body();
        $ownerId = filter_var($body['owner_user_id'] ?? null, FILTER_VALIDATE_INT);
        $username = null;
        $password = null;
        $displayName = null;
        if ($ownerId) {
            find_row($db, "SELECT id FROM api_users WHERE id = ? AND role = 'shop' AND is_active = 1", [(int)$ownerId]);
        } else {
            $username = required_string($body, 'username', 100);
            $password = required_string($body, 'password', 255);
            if (strlen($password) < 12) throw new ApiError(422, 'Password must be at least 12 characters');
            $displayName = required_string($body, 'display_name', 150);
            if (all_rows($db, 'SELECT id FROM api_users WHERE username = ? LIMIT 1', [$username])) {
                throw new ApiError(409, 'Username already exists');
            }
        }
        $name = required_string($body, 'name');
        $first = required_string($body, 'owner_first_name', 100);
        $last = required_string($body, 'owner_last_name', 100);
        $phone = required_string($body, 'phone', 30);
        $lat = $body['latitude'] ?? null; $lng = $body['longitude'] ?? null;
        if (!valid_coordinates($lat, $lng)) throw new ApiError(422, 'Invalid coordinates');
        $db->beginTransaction();
        try {
            if (!$ownerId) {
                run_sql($db, 'INSERT INTO api_users (username, password_hash, display_name, role) VALUES (?, ?, ?, ?)', [$username, password_hash($password, PASSWORD_DEFAULT), $displayName, 'shop']);
                $ownerId = (int)$db->lastInsertId();
            }
            run_sql($db, 'INSERT INTO api_shops (owner_user_id, name, owner_first_name, owner_last_name, phone, house_number, moo, street, subdistrict, district, province, postal_code, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', [
                (int)$ownerId,
                $name,
                $first,
                $last,
                $phone,
                optional_string($body, 'house_number', 100),
                optional_string($body, 'moo', 30),
                optional_string($body, 'street', 150),
                optional_string($body, 'subdistrict', 150),
                optional_string($body, 'district', 150),
                optional_string($body, 'province', 150),
                optional_string($body, 'postal_code', 10),
                $lat,
                $lng,
            ]);
            $shopId = (int)$db->lastInsertId();
            audit($db, (int)$user['id'], 'shop', $shopId, 'created', ['owner_user_id' => (int)$ownerId]);
            $db->commit();
        } catch (Throwable $error) { $db->rollBack(); throw $error; }
        send_json(201, ['id' => $shopId, 'owner_user_id' => (int)$ownerId]);
    }
    if (count($p) === 3 && $p[1] === 'shops' && ctype_digit($p[2]) && $method === 'PATCH') {
        $body = json_body();
        $shopId = (int)$p[2]; find_row($db, 'SELECT id FROM api_shops WHERE id = ?', [$shopId]);
        $fields = ['name' => 255, 'owner_first_name' => 100, 'owner_last_name' => 100, 'phone' => 30, 'house_number' => 100, 'moo' => 30, 'street' => 150, 'subdistrict' => 150, 'district' => 150, 'province' => 150, 'postal_code' => 10];
        $updates = []; $values = [];
        foreach ($fields as $field => $limit) {
            if (!array_key_exists($field, $body)) continue;
            $values[] = in_array($field, ['name','owner_first_name','owner_last_name','phone'], true) ? required_string($body, $field, $limit) : optional_string($body, $field, $limit);
            $updates[] = "$field = ?";
        }
        if (array_key_exists('latitude', $body) || array_key_exists('longitude', $body)) {
            $lat = $body['latitude'] ?? null; $lng = $body['longitude'] ?? null;
            if (!valid_coordinates($lat, $lng)) throw new ApiError(422, 'Invalid coordinates');
            $updates[] = 'latitude = ?'; $values[] = $lat;
            $updates[] = 'longitude = ?'; $values[] = $lng;
        }
        if (array_key_exists('is_public', $body)) {
            if (!is_bool($body['is_public'])) throw new ApiError(422, 'is_public must be a boolean');
            $updates[] = 'is_public = ?'; $values[] = $body['is_public'] ? 1 : 0;
        }
        if (!$updates) throw new ApiError(422, 'No editable fields supplied');
        if (($body['is_public'] ?? false) === true) {
            $published = all_rows($db, "SELECT c.id FROM api_certificates c JOIN api_inspection_requests r ON r.id = c.request_id WHERE r.shop_id = ? AND r.status = 'published' AND c.is_public = 1 AND (c.expires_at IS NULL OR c.expires_at >= CURDATE()) LIMIT 1", [$shopId]);
            if (!$published) throw new ApiError(409, 'A public shop needs a valid published certificate');
        }
        $values[] = $shopId;
        run_sql($db, 'UPDATE api_shops SET ' . implode(', ', $updates) . ' WHERE id = ?', $values);
        audit($db, (int)$user['id'], 'shop', $shopId, 'updated', ['fields' => array_keys($body)]);
        send_json(200, ['message' => 'Shop updated']);
    }
    if (count($p) === 3 && $p[1] === 'shops' && ctype_digit($p[2]) && $method === 'DELETE') {
        $shopId = (int)$p[2]; find_row($db, 'SELECT id FROM api_shops WHERE id = ?', [$shopId]);
        if (all_rows($db, 'SELECT id FROM api_inspection_requests WHERE shop_id = ? LIMIT 1', [$shopId])) throw new ApiError(409, 'Shop with inspection history cannot be deleted');
        run_sql($db, 'DELETE FROM api_shops WHERE id = ?', [$shopId]);
        audit($db, (int)$user['id'], 'shop', $shopId, 'deleted', []);
        send_json(200, ['message' => 'Shop deleted']);
    }
    if (count($p) < 3 || $p[1] !== 'requests' || !ctype_digit($p[2])) return false;
    $requestId = (int)$p[2];
    $request = find_row($db, 'SELECT r.*, s.name AS shop_name FROM api_inspection_requests r JOIN api_shops s ON s.id = r.shop_id WHERE r.id = ?', [$requestId]);
    if (count($p) === 3 && $method === 'GET') {
        $request['items'] = all_rows($db, 'SELECT id, vegetable_name FROM api_inspection_request_items WHERE request_id = ?', [$requestId]);
        $request['appointments'] = all_rows($db, 'SELECT * FROM api_inspection_appointments WHERE request_id = ? ORDER BY id DESC', [$requestId]);
        $request['results'] = all_rows($db, 'SELECT r.* FROM api_inspection_results r JOIN api_inspection_request_items i ON i.id = r.request_item_id WHERE i.request_id = ? ORDER BY r.created_at DESC, r.id DESC', [$requestId]);
        $request['certificates'] = all_rows($db, 'SELECT id, certificate_no, issued_at, expires_at, is_public FROM api_certificates WHERE request_id = ?', [$requestId]);
        send_json(200, ['data' => $request]);
    }
    if (count($p) === 4 && $p[3] === 'appointment' && $method === 'POST') {
        if (!in_array($request['status'], ['submitted','scheduled'], true)) throw new ApiError(409, 'Request cannot be scheduled');
        $body = json_body(); $date = DateTimeImmutable::createFromFormat('!Y-m-d H:i:s', required_string($body, 'appointment_at', 19), new DateTimeZone('UTC'));
        if (!$date || $date->format('Y-m-d H:i:s') !== $body['appointment_at']) throw new ApiError(422, 'appointment_at must be UTC YYYY-MM-DD HH:MM:SS');
        $db->beginTransaction();
        try {
            run_sql($db, 'INSERT INTO api_inspection_appointments (request_id, appointment_at, note, scheduled_by) VALUES (?, ?, ?, ?)', [$requestId, $date->format('Y-m-d H:i:s'), optional_string($body, 'note', 500), (int)$user['id']]);
            run_sql($db, "UPDATE api_inspection_requests SET status = 'scheduled' WHERE id = ?", [$requestId]);
            audit($db, (int)$user['id'], 'request', $requestId, 'appointment_set', ['appointment_at' => $date->format('Y-m-d H:i:s')]);
            $db->commit();
        } catch (Throwable $error) { $db->rollBack(); throw $error; }
        send_json(201, ['message' => 'Appointment saved']);
    }
    if (count($p) === 4 && $p[3] === 'results' && $method === 'POST') {
        if (!in_array($request['status'], ['scheduled','inspected'], true)) throw new ApiError(409, 'Request must be scheduled first');
        $body = json_body(); $items = $body['items'] ?? null;
        if (!is_array($items) || count($items) < 1 || count($items) > 30) throw new ApiError(422, 'items must contain 1 to 30 results');
        $validOutcomes = ['passed','failed','inconclusive'];
        $seen = [];
        foreach ($items as $item) {
            if (!is_array($item) || !isset($item['request_item_id']) || !filter_var($item['request_item_id'], FILTER_VALIDATE_INT) || !in_array($item['outcome'] ?? null, $validOutcomes, true)) throw new ApiError(422, 'Invalid result item');
            $itemId = (int)$item['request_item_id'];
            if (in_array($itemId, $seen, true)) throw new ApiError(422, 'Duplicate request item');
            $seen[] = $itemId;
            find_row($db, 'SELECT id FROM api_inspection_request_items WHERE id = ? AND request_id = ?', [$itemId, $requestId]);
        }
        $inspectedAt = required_string($body, 'inspected_at', 19);
        $date = DateTimeImmutable::createFromFormat('!Y-m-d H:i:s', $inspectedAt, new DateTimeZone('UTC'));
        if (!$date || $date->format('Y-m-d H:i:s') !== $inspectedAt) throw new ApiError(422, 'inspected_at must be UTC YYYY-MM-DD HH:MM:SS');
        $db->beginTransaction();
        try {
            foreach ($items as $item) {
                $itemId = (int)$item['request_item_id'];
                find_row($db, 'SELECT id FROM api_inspection_request_items WHERE id = ? FOR UPDATE', [$itemId]);
                $next = (int)all_rows($db, 'SELECT COALESCE(MAX(revision_no), 0) + 1 AS revision_no FROM api_inspection_results WHERE request_item_id = ?', [$itemId])[0]['revision_no'];
                run_sql($db, 'INSERT INTO api_inspection_results (request_item_id, revision_no, outcome, inspected_at, recorded_by, note) VALUES (?, ?, ?, ?, ?, ?)', [$itemId, $next, $item['outcome'], $inspectedAt, (int)$user['id'], optional_string($item, 'note', 10000)]);
            }
            run_sql($db, "UPDATE api_inspection_requests SET status = 'inspected' WHERE id = ?", [$requestId]);
            audit($db, (int)$user['id'], 'request', $requestId, 'results_recorded', ['item_ids' => $seen]);
            $db->commit();
        } catch (Throwable $error) { $db->rollBack(); throw $error; }
        send_json(201, ['message' => 'Results saved']);
    }
    if (count($p) === 4 && $p[3] === 'certificates' && $method === 'POST') {
        if (!in_array($request['status'], ['inspected','published'], true)) throw new ApiError(409, 'Results must be recorded first');
        $number = required_string($_POST, 'certificate_no', 64);
        $issued = required_string($_POST, 'issued_at', 10);
        $issuedDate = DateTimeImmutable::createFromFormat('!Y-m-d', $issued);
        if (!$issuedDate || $issuedDate->format('Y-m-d') !== $issued) throw new ApiError(422, 'Invalid issued_at date');
        $expires = optional_string($_POST, 'expires_at', 10);
        if ($expires !== null) { $expiry = DateTimeImmutable::createFromFormat('!Y-m-d', $expires); if (!$expiry || $expiry->format('Y-m-d') !== $expires || $expires < $issued) throw new ApiError(422, 'Invalid expires_at date'); }
        $resultIds = json_decode((string)($_POST['result_ids'] ?? ''), true);
        if (!is_array($resultIds) || count($resultIds) < 1 || count($resultIds) > 30) throw new ApiError(422, 'result_ids must be a JSON array');
        $resultIds = array_values(array_unique(array_map('intval', $resultIds)));
        foreach ($resultIds as $resultId) find_row($db, "SELECT r.id FROM api_inspection_results r JOIN api_inspection_request_items i ON i.id = r.request_item_id WHERE r.id = ? AND i.request_id = ? AND r.outcome = 'passed'", [$resultId, $requestId]);
        $file = $_FILES['file'] ?? null;
        if (!$file || $file['error'] !== UPLOAD_ERR_OK || $file['size'] > 5242880 || $file['size'] < 1 || !is_uploaded_file($file['tmp_name'])) throw new ApiError(422, 'Upload a file up to 5 MB');
        $signature = file_get_contents($file['tmp_name'], false, null, 0, 8);
        $mime = str_starts_with((string)$signature, '%PDF-') ? 'application/pdf' : (str_starts_with((string)$signature, "\xFF\xD8\xFF") ? 'image/jpeg' : null);
        if ($mime === null) throw new ApiError(422, 'Only PDF or JPG is accepted');
        $directory = dirname(__DIR__, 2) . '/storage/certificates';
        if (!is_dir($directory) && !mkdir($directory, 0770, true)) throw new RuntimeException('Cannot create certificate storage');
        $fileName = bin2hex(random_bytes(16)) . ($mime === 'application/pdf' ? '.pdf' : '.jpg');
        $path = $directory . '/' . $fileName;
        if (!move_uploaded_file($file['tmp_name'], $path)) throw new RuntimeException('Cannot save certificate');
        try {
            $db->beginTransaction();
            run_sql($db, 'INSERT INTO api_certificates (request_id, certificate_no, file_path, mime_type, issued_at, expires_at, uploaded_by) VALUES (?, ?, ?, ?, ?, ?, ?)', [$requestId, $number, $fileName, $mime, $issued, $expires, (int)$user['id']]);
            $certificateId = (int)$db->lastInsertId();
            foreach ($resultIds as $resultId) run_sql($db, 'INSERT INTO api_certificate_results (certificate_id, result_id) VALUES (?, ?)', [$certificateId, $resultId]);
            audit($db, (int)$user['id'], 'certificate', $certificateId, 'uploaded', ['request_id' => $requestId]);
            $db->commit();
        } catch (Throwable $error) { if ($db->inTransaction()) $db->rollBack(); unlink($path); throw $error; }
        send_json(201, ['id' => $certificateId, 'certificate_no' => $number]);
    }
    if (count($p) === 4 && $p[3] === 'publish' && $method === 'POST') {
        if ($request['status'] !== 'inspected') throw new ApiError(409, 'Request must be inspected first');
        $certificates = all_rows($db, 'SELECT id FROM api_certificates WHERE request_id = ? AND (expires_at IS NULL OR expires_at >= CURDATE())', [$requestId]);
        if (!$certificates) throw new ApiError(409, 'Upload a valid certificate first');
        $db->beginTransaction();
        try {
            run_sql($db, 'UPDATE api_certificates SET is_public = 1 WHERE request_id = ? AND (expires_at IS NULL OR expires_at >= CURDATE())', [$requestId]);
            run_sql($db, "UPDATE api_inspection_requests SET status = 'published' WHERE id = ?", [$requestId]);
            run_sql($db, 'UPDATE api_shops SET is_public = 1 WHERE id = ?', [(int)$request['shop_id']]);
            audit($db, (int)$user['id'], 'request', $requestId, 'published', []);
            $db->commit();
        } catch (Throwable $error) { $db->rollBack(); throw $error; }
        send_json(200, ['message' => 'Results published']);
    }
    return false;
}

function audit(PDO $db, int $actor, string $type, int $id, string $action, array $details): void {
    run_sql($db, 'INSERT INTO api_audit_events (actor_user_id, entity_type, entity_id, action, details) VALUES (?, ?, ?, ?, ?)', [$actor, $type, $id, $action, json_encode($details, JSON_UNESCAPED_UNICODE)]);
}

function verify_current_password(PDO $db, int $userId, array $body): void {
    $currentPassword = required_string($body, 'current_password', 255);
    $row = find_row($db, 'SELECT password_hash FROM api_users WHERE id = ?', [$userId]);
    if (!password_verify($currentPassword, (string)$row['password_hash'])) throw new ApiError(403, 'Current password is required');
}

function normalize_admin_settings(array $values): array {
    $allowed = [
        'maintenance_mode' => 'bool',
        'public_app_base_url' => 'string',
        'default_certificate_expiry_days' => 'positive_int',
    ];
    $normalized = [];
    foreach ($values as $key => $value) {
        if (!isset($allowed[$key])) throw new ApiError(422, 'Unknown setting');
        switch ($allowed[$key]) {
            case 'bool':
                if (!is_bool($value)) throw new ApiError(422, "$key must be a boolean");
                $normalized[$key] = $value;
                break;
            case 'string':
                if (!is_string($value) || trim($value) === '' || text_length(trim($value)) > 500) throw new ApiError(422, "$key must be a non-empty string");
                $normalized[$key] = trim($value);
                break;
            case 'positive_int':
                if (!is_int($value) && !(is_string($value) && ctype_digit($value))) throw new ApiError(422, "$key must be a positive integer");
                $integer = (int)$value;
                if ($integer < 1 || $integer > 3650) throw new ApiError(422, "$key must be between 1 and 3650");
                $normalized[$key] = $integer;
                break;
        }
    }
    return $normalized;
}
