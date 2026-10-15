# SafeVege Feature Completion Design

**Date:** 2026-10-14  
**Status:** Superseded by `2026-10-14-safevege-admin-access-design.md`

## Goal

ทำให้ flow สำคัญของ SafeVege ใช้งานได้จริงและปลอดภัยขึ้น โดยแก้ระบบกู้รหัสผ่าน, สัญญาข้อมูลใบรับรอง, การเปิดไฟล์ที่มีสิทธิ์, ผลตรวจ, การจัดการหลายร้าน, QR ร้าน และการยกเลิกคำขอ พร้อมเพิ่ม regression tests ให้ทุกจุดที่เคยพบข้อผิดพลาด

## Decisions

### 1. Password recovery ใช้ secure provider-ready flow

- ลบ `demo_otp` และ bypass `123456` ออกจาก backend และ Flutter
- ย้ายตาราง `password_resets` จากการสร้างระหว่าง request ไปไว้ใน `bn/schema.sql` และ migration สำหรับฐานข้อมูลที่มีอยู่แล้ว
- เก็บเฉพาะ `password_hash` ของ OTP และ hash ของ reset token; ไม่เก็บ OTP plain text
- OTP มีอายุ 15 นาที, ใช้ได้ครั้งเดียว, และ invalidate OTP เก่าทันทีเมื่อขอใหม่
- `verify-otp` คืน `reset_token` เมื่อ OTP ถูกต้อง
- `reset-password` รับ `reset_token` แทนการรับ OTP ซ้ำ และ invalidate token หลังเปลี่ยนรหัสผ่าน
- การส่ง OTP แยกเป็น delivery boundary: local ใช้ log ได้เมื่อเปิดโหมดทดสอบอย่างชัดเจนเท่านั้น; production ที่ยังไม่มี provider จะตอบ error ที่ชัดเจนและจะไม่คืน OTP ใน response
- Flutter จะเก็บ reset token เฉพาะใน state ของ flow และจะไม่แสดง OTP จาก response ของ API

### 2. QR ร้านต้องเป็น QR ที่สแกนได้จริง

- ลบ painter ที่วาด matrix คงที่ออก
- ใช้ `qr_flutter: ^4.1.0` เพื่อ render QR จาก data จริง; package รองรับ Flutter platform ที่โปรเจกต์ใช้และมี `QrImageView` สำหรับ widget rendering ([เอกสาร package](https://pub.dev/documentation/qr_flutter/latest/))
- data ที่ encode คือ `PUBLIC_APP_BASE_URL/shops/<shopId>` ผ่านค่าคอนฟิก ไม่ hard-code host ใน widget
- ถ้าไม่มี public base URL ให้แสดงสถานะตั้งค่าไม่ครบแทนการสร้าง QR ปลอม

### 3. Public certificate contract ต้องรวมผัก

- `/certificates` จะคืน `vegetables` เป็น array ของชื่อผักที่ผูกกับผลตรวจของใบรับรอง
- backend ใช้ query ที่เข้ากันได้กับ MySQL 5.7 และแปลงค่ากลับเป็น array ใน PHP
- Flutter model/parser จะรับทั้ง array และค่า legacy ที่อาจพบระหว่าง rollout เพื่อไม่ทำให้ข้อมูลเก่าพัง

### 4. Protected certificate download ต้องใช้ authenticated client

- หน้าดูใบรับรองจะไม่เปิด protected URL ด้วย external browser โดยตรง
- เพิ่ม callback สำหรับโหลด bytes ผ่าน `ApiClient` ที่แนบ bearer token แล้วให้หน้าจอแสดงข้อผิดพลาด/สถานะดาวน์โหลดตามผลลัพธ์
- public certificate ยังคงเปิด URL ได้โดยไม่ต้อง login; protected certificate ใช้ authenticated path เท่านั้น
- ไม่ลดสิทธิ์ตรวจสอบ owner/admin ใน `bn/public/index.php`

### 5. ผลตรวจต้องมี identity และ note ที่ถูกต้อง

- `/shop/...` จะคืน `result_id` และ `note` จาก `api_inspection_results`
- Flutter parser จะใช้ `result_id` เป็น `VegetableInspection.resultId` และ fallback ไปใช้ `id` เฉพาะ payload legacy ที่ไม่มี `result_id`
- เพิ่ม regression test ที่ตรวจทั้ง result id และ note

### 6. รองรับหลายร้านของบัญชีเดียว

- เพิ่ม `selectShop(String shopId)` ใน `AppState` โดยยอมรับเฉพาะร้านที่อยู่ใน `_shops`
- รักษาร้านที่เลือกไว้ใน session store และ restore หลัง login/initialize ถ้าร้านนั้นยังอยู่ในรายการ
- เพิ่มตัวเลือกสลับร้านใน dashboard/profile เมื่อบัญชีมีมากกว่าหนึ่งร้าน
- request list, create request, profile update และ QR ใช้ `currentShop` ที่เลือกอยู่เสมอ

### 7. ยกเลิกคำขออย่างมีเงื่อนไข

- เพิ่ม `POST /admin/requests/{id}/cancel`
- อนุญาตยกเลิกเฉพาะ `submitted` และ `scheduled`; สถานะ `inspected`, `published`, `cancelled` จะตอบ 409
- ตรวจสิทธิ์ admin/owner ตาม route ที่มีอยู่ และเขียน audit event `request_cancelled`
- เพิ่ม repository, AppState และปุ่มในหน้าที่ผู้มีสิทธิ์เห็นคำขอ เพื่อให้สถานะเปลี่ยนจริงและ refresh ข้อมูล

### 8. Backend ต้องรับผลตรวจครบทุก item

- ก่อนบันทึกผลตรวจ ให้โหลด item IDs ของ request แล้วตรวจว่า payload มีครบทุก item และไม่มี item ซ้ำหรือ item จาก request อื่น
- ถ้าไม่ครบ/เกิน/ซ้ำ ให้ตอบ 422 และไม่เปลี่ยนสถานะ request
- เมื่อครบแล้วจึงบันทึกผลและเปลี่ยนเป็น `inspected` ตาม flow เดิม

## Data flow

1. Flutter recovery screen ขอ OTP → backend หา account → hash และบันทึก OTP → delivery adapter ส่ง/เขียน log ตาม environment → response มีเพียง message/ref code
2. Flutter ส่ง OTP → backend ตรวจ hash และ expiry → บันทึก verified state → คืน reset token หนึ่งครั้ง
3. Flutter ส่ง reset token + password ใหม่ → backend ตรวจ hash/expiry/used state → เปลี่ยน password, revoke sessions, mark reset used
4. Shop dashboard สร้าง URL public จาก config + shop ID → `QrImageView` render data จริง → scanner เปิด public shop route
5. Public certificate endpoint คืน certificate + vegetables → repository map ไป `CertificateModel`
6. Authenticated viewer เรียก `AppState.downloadCertificate` → `ApiClient.getBytes` แนบ token → UI แสดง/บันทึกผลตาม platform

## Error handling

- API คงรูปแบบ `ApiError` และ status code ที่มีอยู่
- Recovery ใช้ข้อความทั่วไปเมื่อ provider ไม่พร้อม โดยไม่เปิดเผย OTP, token hash หรือข้อมูลภายใน
- QR ไม่สร้าง fallback image ที่ดูเหมือนใช้งานได้เมื่อ config ขาด
- การเปลี่ยนสถานะที่ไม่อนุญาตตอบ 409; payload ไม่ครบตอบ 422
- Flutter แสดง error ผ่าน existing `ApiException`/error message flow และไม่กลืน error ที่ต้องให้ผู้ใช้แก้ไข

## Files and boundaries

Backend:

- `bn/src/routes/auth_routes.php` — recovery state machine และ delivery boundary
- `bn/src/routes/public_routes.php` — public certificate vegetables
- `bn/src/routes/shop_routes.php` — result identity/note contract
- `bn/src/routes/admin_routes.php` — cancellation และ complete-result validation
- `bn/schema.sql` และ migration file — persistent recovery table
- `bn/public/index.php` — คง access control และทดสอบ authenticated download contract

Flutter:

- `fn/safevege/lib/data/repositories/safevege_repository.dart` — API payloads/parsers
- `fn/safevege/lib/state/remote_app_state.dart` — reset token, shop selection, cancellation/download orchestration
- `fn/safevege/lib/screens/common/account_recovery_screen.dart` — ไม่มี demo OTP UI
- `fn/safevege/lib/screens/shop/shop_dashboard_screen.dart` — real QR และ shop selector
- `fn/safevege/lib/screens/shop/shop_profile_screen.dart` — shop selector entry point
- `fn/safevege/lib/screens/guest/certificate_viewer_screen.dart` — authenticated download callback
- `fn/safevege/lib/config/api_endpoint.dart` และ `fn/safevege/pubspec.yaml` — public URL config และ QR dependency

## Testing strategy

- เขียน regression tests ก่อน production code ตาม TDD
- Flutter unit tests ครอบคลุม recovery payload, public certificate vegetables, shop result mapping, reset token flow และ shop selection
- PHP tests ครอบคลุม OTP bypass removal, reset table shape, complete-result validation, cancellation transitions, and public certificate query contract
- รัน `flutter analyze`, `flutter test`, PHP helper/CORS tests และ integration testsที่ environment รองรับ
- ถ้า PHP CLI ไม่มี `pdo_mysql` เหมือนที่พบในการตรวจครั้งก่อน ให้รายงานเป็น environment limitation แยกจากผลของโค้ด ไม่ปิดบังว่า integration test ยังไม่ได้รัน

## Explicit non-goals

- ไม่สร้าง SMS/email provider หรือฝัง credential ใน repository; จุดเชื่อมต่อจะพร้อมให้ตั้งค่าภายหลัง
- ไม่เดา application ID, keystore หรือ release signing secret; การตั้งค่าปล่อยแอปจริงต้องใช้ค่าจากเจ้าของระบบ
- ไม่เปลี่ยน schema/route อื่นที่ไม่เกี่ยวกับแปดปัญหานี้
