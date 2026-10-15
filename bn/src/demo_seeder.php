<?php
declare(strict_types=1);

const SAFEVEGE_DEMO_PASSWORD = 'DemoSafeVege!2026';

/** Insert or update a clearly marked local demo dataset. */
function seed_demo_data(PDO $db): array {
    $certificateFile = ensure_demo_certificate_file();
    $db->beginTransaction();

    try {
        $users = [
            'admin' => demo_upsert_user($db, 'demo_admin', 'SafeVege Demo Administrator', 'admin'),
            'shop' => demo_upsert_user($db, 'demo_shop', 'SafeVege Demo Shop Owner', 'shop'),
            'market' => demo_upsert_user($db, 'demo_market', 'SafeVege Demo Market Owner', 'shop'),
        ];

        $shopSpecs = [
            'chiang_rai' => [
                'owner' => $users['shop'], 'name' => 'สวนผักบ้านดอย ออร์แกนิก (DEMO)',
                'first_name' => 'Demo', 'last_name' => 'Farm', 'phone' => '0810000101',
                'house_number' => '99/1', 'moo' => '4', 'street' => 'ถนนพหลโยธิน',
                'subdistrict' => 'รอบเวียง', 'district' => 'เมืองเชียงราย', 'province' => 'เชียงราย',
                'postal_code' => '57000', 'latitude' => 19.9100000, 'longitude' => 99.8320000,
            ],
            'market' => [
                'owner' => $users['market'], 'name' => 'ตลาดผักปลอดภัยริมกก (DEMO)',
                'first_name' => 'Demo', 'last_name' => 'Market', 'phone' => '0810000102',
                'house_number' => '12', 'moo' => null, 'street' => 'ถนนริมกก',
                'subdistrict' => 'เวียง', 'district' => 'เมืองเชียงราย', 'province' => 'เชียงราย',
                'postal_code' => '57000', 'latitude' => 19.9160000, 'longitude' => 99.8245000,
            ],
            'bangkok' => [
                'owner' => $users['shop'], 'name' => 'สวนผักสุขใจ กรุงเทพฯ (DEMO)',
                'first_name' => 'Demo', 'last_name' => 'Farm', 'phone' => '0810000103',
                'house_number' => '45', 'moo' => null, 'street' => 'ถนนพระราม 4',
                'subdistrict' => 'พระโขนง', 'district' => 'คลองเตย', 'province' => 'กรุงเทพมหานคร',
                'postal_code' => '10110', 'latitude' => 13.7150000, 'longitude' => 100.5900000,
            ],
        ];
        $shops = [];
        foreach ($shopSpecs as $key => $shop) $shops[$key] = demo_upsert_shop($db, $shop);

        $requestSpecs = [
            [
                'number' => 'DEMO-2026-001', 'shop' => 'chiang_rai', 'status' => 'published',
                'days_ago' => 14, 'items' => [
                    ['name' => 'ผักกาดหอม', 'outcome' => 'passed', 'note' => 'ผลตรวจตัวอย่างผ่านเกณฑ์'],
                    ['name' => 'คะน้า', 'outcome' => 'failed', 'note' => 'ผลตรวจตัวอย่างไม่ผ่านเกณฑ์'],
                ],
                'certificate' => ['number' => 'DEMO-CERT-001', 'item' => 'ผักกาดหอม'],
            ],
            [
                'number' => 'DEMO-2026-002', 'shop' => 'chiang_rai', 'status' => 'scheduled',
                'days_ago' => 3, 'appointment_days' => 4,
                'items' => [
                    ['name' => 'มะเขือเทศ', 'outcome' => null],
                    ['name' => 'ผักชี', 'outcome' => null],
                ],
            ],
            [
                'number' => 'DEMO-2026-003', 'shop' => 'chiang_rai', 'status' => 'submitted',
                'days_ago' => 1, 'items' => [
                    ['name' => 'แตงกวา', 'outcome' => null],
                ],
            ],
            [
                'number' => 'DEMO-2026-004', 'shop' => 'chiang_rai', 'status' => 'inspected',
                'days_ago' => 7, 'items' => [
                    ['name' => 'บรอกโคลี', 'outcome' => 'passed', 'note' => 'ผลตรวจตัวอย่าง รอออกใบรับรอง'],
                ],
            ],
            [
                'number' => 'DEMO-2026-005', 'shop' => 'market', 'status' => 'published',
                'days_ago' => 9, 'items' => [
                    ['name' => 'มะเขือเทศ', 'outcome' => 'passed', 'note' => 'ผลตรวจตัวอย่างผ่านเกณฑ์'],
                    ['name' => 'โหระพา', 'outcome' => 'passed', 'note' => 'ผลตรวจตัวอย่างผ่านเกณฑ์'],
                ],
                'certificate' => ['number' => 'DEMO-CERT-002', 'item' => 'มะเขือเทศ'],
            ],
        ];

        $requestIds = [];
        foreach ($requestSpecs as $spec) {
            $shop = $shopSpecs[$spec['shop']];
            $request = demo_upsert_request($db, [
                'number' => $spec['number'], 'shop_id' => $shops[$spec['shop']],
                'status' => $spec['status'], 'address' => demo_shop_address($shop),
                'latitude' => $shop['latitude'], 'longitude' => $shop['longitude'],
                'submitted_at' => gmdate('Y-m-d H:i:s', time() - ((int)$spec['days_ago'] * 86400)),
            ]);
            $requestIds[] = $request;
            $itemIds = [];
            foreach ($spec['items'] as $itemSpec) {
                $itemId = demo_upsert_request_item($db, $request, $itemSpec['name']);
                $itemIds[$itemSpec['name']] = $itemId;
                if ($itemSpec['outcome'] !== null) {
                    demo_upsert_result($db, $itemId, $users['admin'], $itemSpec['outcome'], $spec['days_ago'], $itemSpec['note'] ?? null);
                }
            }

            if (isset($spec['appointment_days'])) {
                demo_upsert_appointment($db, $request, $users['admin'], (int)$spec['appointment_days']);
            }

            if (isset($spec['certificate'])) {
                $result = demo_optional_row($db, 'SELECT id FROM api_inspection_results WHERE request_item_id = ? AND revision_no = 1', [$itemIds[$spec['certificate']['item']]]);
                if (!$result) throw new RuntimeException('A demo certificate needs a result item');
                demo_upsert_certificate($db, [
                    'request_id' => $request,
                    'number' => $spec['certificate']['number'],
                    'file_path' => $certificateFile,
                    'uploaded_by' => $users['admin'],
                    'result_id' => (int)$result['id'],
                ]);
            }
        }

        $db->commit();
        return ['users' => count($users), 'shops' => count($shops), 'requests' => count($requestIds), 'certificates' => 2];
    } catch (Throwable $error) {
        if ($db->inTransaction()) $db->rollBack();
        throw $error;
    }
}

function demo_upsert_user(PDO $db, string $username, string $displayName, string $role): int {
    $existing = demo_optional_row($db, 'SELECT id, display_name, role FROM api_users WHERE username = ?', [$username]);
    if ($existing) {
        if (!str_starts_with((string)$existing['display_name'], 'SafeVege Demo ') || $existing['role'] !== $role) {
            throw new RuntimeException("Refusing to overwrite non-demo user '$username'");
        }
        run_sql($db, 'UPDATE api_users SET password_hash = ?, display_name = ?, is_active = 1 WHERE id = ?', [password_hash(SAFEVEGE_DEMO_PASSWORD, PASSWORD_DEFAULT), $displayName, (int)$existing['id']]);
        return (int)$existing['id'];
    }
    run_sql($db, 'INSERT INTO api_users (username, password_hash, display_name, role) VALUES (?, ?, ?, ?)', [$username, password_hash(SAFEVEGE_DEMO_PASSWORD, PASSWORD_DEFAULT), $displayName, $role]);
    return (int)$db->lastInsertId();
}

function demo_upsert_shop(PDO $db, array $shop): int {
    $existing = demo_optional_row($db, 'SELECT id FROM api_shops WHERE owner_user_id = ? AND name = ?', [$shop['owner'], $shop['name']]);
    $values = [
        $shop['owner'], $shop['name'], $shop['first_name'], $shop['last_name'], $shop['phone'],
        $shop['house_number'], $shop['moo'], $shop['street'], $shop['subdistrict'],
        $shop['district'], $shop['province'], $shop['postal_code'], $shop['latitude'], $shop['longitude'],
    ];
    if ($existing) {
        run_sql($db, 'UPDATE api_shops SET owner_user_id = ?, name = ?, owner_first_name = ?, owner_last_name = ?, phone = ?, house_number = ?, moo = ?, street = ?, subdistrict = ?, district = ?, province = ?, postal_code = ?, latitude = ?, longitude = ?, is_public = 1 WHERE id = ?', [...$values, (int)$existing['id']]);
        return (int)$existing['id'];
    }
    run_sql($db, 'INSERT INTO api_shops (owner_user_id, name, owner_first_name, owner_last_name, phone, house_number, moo, street, subdistrict, district, province, postal_code, latitude, longitude, is_public) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)', $values);
    return (int)$db->lastInsertId();
}

function demo_upsert_request(PDO $db, array $request): int {
    $existing = demo_optional_row($db, 'SELECT id, shop_id FROM api_inspection_requests WHERE request_no = ?', [$request['number']]);
    if ($existing && (int)$existing['shop_id'] !== (int)$request['shop_id']) {
        throw new RuntimeException("Refusing to move demo request '{$request['number']}' to another shop");
    }
    if ($existing) {
        run_sql($db, 'UPDATE api_inspection_requests SET status = ?, address_snapshot = ?, latitude_snapshot = ?, longitude_snapshot = ?, submitted_at = ? WHERE id = ?', [$request['status'], $request['address'], $request['latitude'], $request['longitude'], $request['submitted_at'], (int)$existing['id']]);
        return (int)$existing['id'];
    }
    run_sql($db, 'INSERT INTO api_inspection_requests (shop_id, request_no, status, address_snapshot, latitude_snapshot, longitude_snapshot, submitted_at) VALUES (?, ?, ?, ?, ?, ?, ?)', [$request['shop_id'], $request['number'], $request['status'], $request['address'], $request['latitude'], $request['longitude'], $request['submitted_at']]);
    return (int)$db->lastInsertId();
}

function demo_upsert_request_item(PDO $db, int $requestId, string $name): int {
    $existing = demo_optional_row($db, 'SELECT id FROM api_inspection_request_items WHERE request_id = ? AND vegetable_name = ? ORDER BY id LIMIT 1', [$requestId, $name]);
    if ($existing) return (int)$existing['id'];
    run_sql($db, 'INSERT INTO api_inspection_request_items (request_id, vegetable_name) VALUES (?, ?)', [$requestId, $name]);
    return (int)$db->lastInsertId();
}

function demo_upsert_result(PDO $db, int $itemId, int $adminId, string $outcome, int $daysAgo, ?string $note): int {
    $existing = demo_optional_row($db, 'SELECT id FROM api_inspection_results WHERE request_item_id = ? AND revision_no = 1', [$itemId]);
    $inspectedAt = gmdate('Y-m-d H:i:s', time() - ((int)$daysAgo * 86400) + 36000);
    if ($existing) {
        run_sql($db, 'UPDATE api_inspection_results SET outcome = ?, inspected_at = ?, recorded_by = ?, note = ? WHERE id = ?', [$outcome, $inspectedAt, $adminId, $note, (int)$existing['id']]);
        return (int)$existing['id'];
    }
    run_sql($db, 'INSERT INTO api_inspection_results (request_item_id, revision_no, outcome, inspected_at, recorded_by, note) VALUES (?, 1, ?, ?, ?, ?)', [$itemId, $outcome, $inspectedAt, $adminId, $note]);
    return (int)$db->lastInsertId();
}

function demo_upsert_appointment(PDO $db, int $requestId, int $adminId, int $daysAhead): void {
    $existing = demo_optional_row($db, 'SELECT id FROM api_inspection_appointments WHERE request_id = ? ORDER BY id LIMIT 1', [$requestId]);
    $appointmentAt = gmdate('Y-m-d', time() + ($daysAhead * 86400)) . ' 10:00:00';
    if ($existing) {
        run_sql($db, 'UPDATE api_inspection_appointments SET appointment_at = ?, note = ?, scheduled_by = ? WHERE id = ?', [$appointmentAt, 'นัดตรวจตัวอย่างสำหรับทดสอบระบบ', $adminId, (int)$existing['id']]);
        return;
    }
    run_sql($db, 'INSERT INTO api_inspection_appointments (request_id, appointment_at, note, scheduled_by) VALUES (?, ?, ?, ?)', [$requestId, $appointmentAt, 'นัดตรวจตัวอย่างสำหรับทดสอบระบบ', $adminId]);
}

function demo_upsert_certificate(PDO $db, array $certificate): void {
    $existing = demo_optional_row($db, 'SELECT id, request_id FROM api_certificates WHERE certificate_no = ?', [$certificate['number']]);
    if ($existing && (int)$existing['request_id'] !== (int)$certificate['request_id']) {
        throw new RuntimeException("Refusing to move demo certificate '{$certificate['number']}' to another request");
    }
    $issued = gmdate('Y-m-d', time() - (5 * 86400));
    $expires = gmdate('Y-m-d', time() + (360 * 86400));
    if ($existing) {
        $id = (int)$existing['id'];
        run_sql($db, 'UPDATE api_certificates SET file_path = ?, mime_type = ?, issued_at = ?, expires_at = ?, is_public = 1, uploaded_by = ? WHERE id = ?', [$certificate['file_path'], 'application/pdf', $issued, $expires, $certificate['uploaded_by'], $id]);
    } else {
        run_sql($db, 'INSERT INTO api_certificates (request_id, certificate_no, file_path, mime_type, issued_at, expires_at, is_public, uploaded_by) VALUES (?, ?, ?, ?, ?, ?, 1, ?)', [$certificate['request_id'], $certificate['number'], $certificate['file_path'], 'application/pdf', $issued, $expires, $certificate['uploaded_by']]);
        $id = (int)$db->lastInsertId();
    }
    run_sql($db, 'DELETE FROM api_certificate_results WHERE certificate_id = ?', [$id]);
    run_sql($db, 'INSERT INTO api_certificate_results (certificate_id, result_id) VALUES (?, ?)', [$id, $certificate['result_id']]);
}

function demo_optional_row(PDO $db, string $sql, array $params = []): ?array {
    $statement = $db->prepare($sql);
    $statement->execute($params);
    $row = $statement->fetch(PDO::FETCH_ASSOC);
    return $row ?: null;
}

function demo_shop_address(array $shop): string {
    return implode(' ', array_filter([$shop['house_number'], $shop['moo'] ? 'หมู่ ' . $shop['moo'] : null, $shop['street'], $shop['subdistrict'], $shop['district'], $shop['province'], $shop['postal_code']]));
}

function ensure_demo_certificate_file(): string {
    $directory = dirname(__DIR__) . '/storage/certificates';
    if (!is_dir($directory) && !mkdir($directory, 0770, true) && !is_dir($directory)) {
        throw new RuntimeException('Cannot create certificate storage for demo data');
    }
    $fileName = 'demo-safevege-sample-certificate.pdf';
    $path = $directory . '/' . $fileName;
    if (is_file($path)) {
        $existing = file_get_contents($path, false, null, 0, 64);
        if (!is_string($existing) || !str_starts_with($existing, "%PDF-1.4\n% SafeVege Demo Fixture")) {
            throw new RuntimeException('Refusing to overwrite an existing non-demo certificate file');
        }
        return $fileName;
    }

    $stream = implode("\n", [
        'BT /F1 22 Tf 56 760 Td (SAFEVEGE - SAMPLE CERTIFICATE) Tj ET',
        'BT /F1 15 Tf 56 720 Td (DEMO ONLY - NOT A VALID CERTIFICATE) Tj ET',
        'BT /F1 11 Tf 56 680 Td (This file is generated for local application testing.) Tj ET',
        'BT /F1 11 Tf 56 655 Td (Do not use as evidence of food safety or certification.) Tj ET',
    ]);
    $objects = [
        '<< /Type /Catalog /Pages 2 0 R >>',
        '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
        '<< /Length ' . strlen($stream) . " >>\nstream\n$stream\nendstream",
    ];
    $pdf = "%PDF-1.4\n% SafeVege Demo Fixture\n";
    $offsets = [0];
    foreach ($objects as $index => $object) {
        $offsets[] = strlen($pdf);
        $pdf .= ($index + 1) . " 0 obj\n$object\nendobj\n";
    }
    $xrefOffset = strlen($pdf);
    $pdf .= "xref\n0 6\n0000000000 65535 f \n";
    for ($index = 1; $index < count($offsets); $index++) $pdf .= sprintf("%010d 00000 n \n", $offsets[$index]);
    $pdf .= "trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n";
    if (file_put_contents($path, $pdf, LOCK_EX) === false) throw new RuntimeException('Cannot write the demo certificate PDF');
    return $fileName;
}
