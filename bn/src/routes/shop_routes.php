<?php
declare(strict_types=1);

function owned_shop(PDO $db, int $shopId, int $userId): array {
    return find_row($db, 'SELECT * FROM api_shops WHERE id = ? AND owner_user_id = ?', [$shopId, $userId]);
}

function shop_routes(PDO $db, string $method, array $p): bool {
    if (($p[0] ?? '') !== 'my') return false;
    $user = current_user($db);
    require_role($user, 'shop');
    $userId = (int)$user['id'];
    if ($p === ['my', 'shops'] && $method === 'GET') send_json(200, ['data' => all_rows($db, 'SELECT * FROM api_shops WHERE owner_user_id = ? ORDER BY id', [$userId])]);
    if (count($p) === 3 && $p[1] === 'shops' && ctype_digit($p[2]) && $method === 'PATCH') {
        $shopId = (int)$p[2]; owned_shop($db, $shopId, $userId);
        $body = json_body();
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
        if (!$updates) throw new ApiError(422, 'No editable fields supplied');
        $values[] = $shopId;
        run_sql($db, 'UPDATE api_shops SET ' . implode(', ', $updates) . ' WHERE id = ?', $values);
        send_json(200, ['data' => owned_shop($db, $shopId, $userId)]);
    }
    if (count($p) === 4 && $p[1] === 'shops' && ctype_digit($p[2]) && $p[3] === 'requests' && $method === 'POST') {
        $shop = owned_shop($db, (int)$p[2], $userId);
        $body = json_body();
        $vegetables = vegetable_names($body['vegetables'] ?? null);
        $address = required_string($body, 'address_snapshot', 500);
        $lat = $body['latitude'] ?? $shop['latitude']; $lng = $body['longitude'] ?? $shop['longitude'];
        if (!valid_coordinates($lat, $lng)) throw new ApiError(422, 'Invalid coordinates');
        $db->beginTransaction();
        try {
            $requestNo = 'SV-' . gmdate('Ymd') . '-' . strtoupper(bin2hex(random_bytes(4)));
            run_sql($db, 'INSERT INTO api_inspection_requests (shop_id, request_no, address_snapshot, latitude_snapshot, longitude_snapshot) VALUES (?, ?, ?, ?, ?)', [(int)$shop['id'], $requestNo, $address, $lat, $lng]);
            $requestId = (int)$db->lastInsertId();
            foreach ($vegetables as $name) run_sql($db, 'INSERT INTO api_inspection_request_items (request_id, vegetable_name) VALUES (?, ?)', [$requestId, $name]);
            $db->commit();
        } catch (Throwable $error) { $db->rollBack(); throw $error; }
        send_json(201, ['id' => $requestId, 'request_no' => $requestNo, 'status' => 'submitted']);
    }
    if ($p === ['my', 'requests'] && $method === 'GET') {
        $rows = all_rows($db, 'SELECT r.id, r.request_no, r.status, r.submitted_at, s.id AS shop_id, s.name AS shop_name FROM api_inspection_requests r JOIN api_shops s ON s.id = r.shop_id WHERE s.owner_user_id = ? ORDER BY r.submitted_at DESC, r.id DESC LIMIT 100', [$userId]);
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
    if (count($p) === 3 && $p[1] === 'requests' && ctype_digit($p[2]) && $method === 'GET') {
        $request = find_row($db, 'SELECT r.*, s.name AS shop_name FROM api_inspection_requests r JOIN api_shops s ON s.id = r.shop_id WHERE r.id = ? AND s.owner_user_id = ?', [(int)$p[2], $userId]);
        $request['items'] = all_rows($db, 'SELECT i.id, i.vegetable_name, r.outcome, r.inspected_at FROM api_inspection_request_items i LEFT JOIN api_inspection_results r ON r.request_item_id = i.id AND r.revision_no = (SELECT MAX(r2.revision_no) FROM api_inspection_results r2 WHERE r2.request_item_id = i.id) WHERE i.request_id = ? ORDER BY i.id', [(int)$p[2]]);
        $request['appointments'] = all_rows($db, 'SELECT appointment_at, note, created_at FROM api_inspection_appointments WHERE request_id = ? ORDER BY created_at DESC, id DESC', [(int)$p[2]]);
        $request['certificates'] = all_rows($db, 'SELECT id, certificate_no, issued_at, expires_at FROM api_certificates WHERE request_id = ? ORDER BY issued_at DESC', [(int)$p[2]]);
        send_json(200, ['data' => $request]);
    }
    return false;
}
