<?php
declare(strict_types=1);

function public_routes(PDO $db, string $method, array $p): bool {
    if ($method !== 'GET') return false;
    if ($p === ['certificates']) {
        $certificates = all_rows($db, "SELECT c.id, c.certificate_no, c.issued_at, c.expires_at, s.id AS shop_id, s.name AS shop_name FROM api_certificates c JOIN api_inspection_requests r ON r.id = c.request_id JOIN api_shops s ON s.id = r.shop_id WHERE r.status = 'published' AND c.is_public = 1 AND (c.expires_at IS NULL OR c.expires_at >= CURDATE()) ORDER BY c.issued_at DESC, c.id DESC LIMIT 200");
        send_json(200, ['data' => $certificates]);
    }
    if (($p[0] ?? '') !== 'shops') return false;
    if (count($p) === 1) {
        $q = trim((string)($_GET['q'] ?? ''));
        if (text_length($q) > 100) throw new ApiError(422, 'Search query is too long');
        $search = '%' . addcslashes($q, '%_\\') . '%';
        $lat = $_GET['lat'] ?? null; $lng = $_GET['lng'] ?? null;
        if ($lat !== null || $lng !== null) {
            if (!valid_coordinates($lat, $lng) || $lat === null || $lng === null) throw new ApiError(422, 'lat and lng are both required');
            $radius = $_GET['radius_km'] ?? 25;
            if (!is_numeric($radius) || (float)$radius < 1 || (float)$radius > 100) throw new ApiError(422, 'radius_km must be 1 to 100');
            $shops = all_rows($db, 'SELECT id, name, phone, subdistrict, district, province, latitude, longitude, (6371 * ACOS(LEAST(1, GREATEST(-1, COS(RADIANS(?)) * COS(RADIANS(latitude)) * COS(RADIANS(longitude) - RADIANS(?)) + SIN(RADIANS(?)) * SIN(RADIANS(latitude)))))) AS distance_km FROM api_shops WHERE is_public = 1 AND latitude IS NOT NULL AND longitude IS NOT NULL AND (name LIKE ? OR subdistrict LIKE ? OR district LIKE ? OR province LIKE ? OR EXISTS (SELECT 1 FROM api_inspection_results ir JOIN api_inspection_request_items ii ON ii.id = ir.request_item_id JOIN api_inspection_requests rq ON rq.id = ii.request_id JOIN api_certificate_results cr ON cr.result_id = ir.id JOIN api_certificates c ON c.id = cr.certificate_id WHERE rq.shop_id = api_shops.id AND rq.status = \'published\' AND ir.outcome = \'passed\' AND c.is_public = 1 AND (c.expires_at IS NULL OR c.expires_at >= CURDATE()) AND ii.vegetable_name LIKE ?)) HAVING distance_km <= ? ORDER BY distance_km LIMIT 100', [(float)$lat, (float)$lng, (float)$lat, $search, $search, $search, $search, $search, (float)$radius]);
        } else {
            $shops = all_rows($db, 'SELECT id, name, phone, subdistrict, district, province, latitude, longitude FROM api_shops WHERE is_public = 1 AND (name LIKE ? OR subdistrict LIKE ? OR district LIKE ? OR province LIKE ? OR EXISTS (SELECT 1 FROM api_inspection_results ir JOIN api_inspection_request_items ii ON ii.id = ir.request_item_id JOIN api_inspection_requests rq ON rq.id = ii.request_id JOIN api_certificate_results cr ON cr.result_id = ir.id JOIN api_certificates c ON c.id = cr.certificate_id WHERE rq.shop_id = api_shops.id AND rq.status = \'published\' AND ir.outcome = \'passed\' AND c.is_public = 1 AND (c.expires_at IS NULL OR c.expires_at >= CURDATE()) AND ii.vegetable_name LIKE ?)) ORDER BY name LIMIT 100', [$search, $search, $search, $search, $search]);
        }
        send_json(200, ['data' => $shops]);
    }
    if (count($p) === 2 && ctype_digit($p[1])) {
        $shop = find_row($db, 'SELECT id, name, phone, house_number, moo, street, subdistrict, district, province, postal_code, latitude, longitude FROM api_shops WHERE id = ? AND is_public = 1', [(int)$p[1]]);
        $shop['results'] = all_rows($db, "SELECT ri.vegetable_name, r.outcome, r.inspected_at, c.id AS certificate_id, c.certificate_no, c.issued_at, c.expires_at FROM api_inspection_results r JOIN api_inspection_request_items ri ON ri.id = r.request_item_id JOIN api_inspection_requests req ON req.id = ri.request_id JOIN api_certificate_results cr ON cr.result_id = r.id JOIN api_certificates c ON c.id = cr.certificate_id WHERE req.shop_id = ? AND req.status = 'published' AND r.outcome = 'passed' AND c.is_public = 1 AND (c.expires_at IS NULL OR c.expires_at >= CURDATE()) ORDER BY r.inspected_at DESC", [(int)$p[1]]);
        send_json(200, ['data' => $shop]);
    }
    if (count($p) === 3 && ctype_digit($p[1]) && $p[2] === 'certificates') {
        find_row($db, 'SELECT id FROM api_shops WHERE id = ? AND is_public = 1', [(int)$p[1]]);
        $items = all_rows($db, 'SELECT c.id, c.certificate_no, c.issued_at, c.expires_at FROM api_certificates c JOIN api_inspection_requests r ON r.id = c.request_id WHERE r.shop_id = ? AND r.status = ? AND c.is_public = 1 AND (c.expires_at IS NULL OR c.expires_at >= CURDATE()) ORDER BY c.issued_at DESC', [(int)$p[1], 'published']);
        send_json(200, ['data' => $items]);
    }
    return false;
}
