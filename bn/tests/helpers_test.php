<?php
declare(strict_types=1);

require __DIR__ . '/../src/helpers.php';

function same($expected, $actual, string $message): void {
    if ($expected !== $actual) {
        throw new RuntimeException($message . ': expected ' . var_export($expected, true) . ', got ' . var_export($actual, true));
    }
}

same(['shops', '42'], path_parts('/shops/42/'), 'path parts');
same([], path_parts('/'), 'root path');
same(['คะน้า', 'ผักกาดหอม'], vegetable_names([' คะน้า ', 'ผักกาดหอม']), 'trim vegetable names');
same(false, valid_coordinates(91, 100), 'invalid latitude');
same(true, valid_coordinates(19.91, 99.83), 'valid coordinates');
same(false, valid_coordinates(null, 99.83), 'partial coordinates');
same('ร้านผัก', required_string(['name' => ' ร้านผัก '], 'name'), 'trim required text');
same(7, text_length('ร้านผัก'), 'count Thai code points');
try {
    vegetable_names([]);
    throw new RuntimeException('Empty vegetable list was accepted');
} catch (ApiError $error) {
    same(422, $error->status, 'empty vegetables error');
}
echo "helpers tests passed\n";
