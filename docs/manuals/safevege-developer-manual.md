# คู่มือนักพัฒนา SafeVege

วันที่จัดทำ: 17 ตุลาคม 2026

คู่มือนี้อธิบายพฤติกรรมที่ตรวจจากไฟล์ในรีโป ณ วันที่จัดทำ ส่วนที่ระบุว่าเป็น “คำแนะนำ” หรือ “ข้อควรตรวจ” เป็นงานสำหรับการนำไปใช้ต่อ ไม่ใช่คุณสมบัติที่ยืนยันว่าระบบใช้งานจริงแล้ว คำสั่งติดตั้งและทดสอบด้านล่างเป็นคำสั่งที่มีเอกสารหรือไฟล์รองรับ แต่ไม่ได้รันระหว่างงานเขียนคู่มือนี้

## 1. ภาพรวมระบบและขอบเขต

SafeVege มีแอป Flutter สำหรับเว็บและมือถือ เชื่อม PHP REST API ผ่าน HTTP โดย PHP อ่านและเขียน MySQL แอปไม่เชื่อมฐานข้อมูลโดยตรง ส่วนแผนที่ใช้ OpenStreetMap และการคำนวณเส้นทางใช้ OSRM ซึ่งเป็นบริการภายนอก ไม่ใช่ส่วนของ API ร้านค้าและการตรวจรับรอง (`fn/safevege/lib/config/app_config.dart`, `fn/safevege/lib/services/osm_map_service.dart`)

```text
หน้าจอ Flutter → AppState → SafeVegeRepository → ApiClient
                                             ↓ HTTP /api/v1
bn/public/index.php → routes → auth/bootstrap → MySQL api_* views → ตารางจริง
                                      └→ bn/storage/certificates สำหรับไฟล์ใบรับรอง
```

ข้อมูลสาธารณะมีร้านที่เปิดเผยและใบรับรองที่ผ่านเงื่อนไขเผยแพร่ บัญชีร้านดูและแก้ไขข้อมูลของตน ผู้ตรวจการ (`admin`) ดำเนินงานตรวจ ส่วน `super_admin` ดูแลบัญชีและการตั้งค่าระบบ ชื่อ `guest` ใน Flutter หมายถึงการใช้งานโดยไม่ลงชื่อเข้าใช้ ไม่ใช่บทบาทในตาราง `users` (`fn/safevege/lib/models/app_models.dart`, `bn/schema.sql`)

## 2. แผนผังไดเรกทอรี

| พาธจากรากรีโป | หน้าที่ |
| --- | --- |
| `fn/safevege/lib/main.dart` | เริ่มแอป สร้าง `AppState` เรียก `initialize()` และวาด `MaterialApp` |
| `fn/safevege/lib/screens/`, `fn/safevege/lib/widgets/`, `fn/safevege/lib/theme/` | หน้าจอตามบทบาท วิดเจ็ตที่ใช้ร่วมกัน และธีม |
| `fn/safevege/lib/state/app_state.dart`, `fn/safevege/lib/state/remote_app_state.dart` | ส่งออกและจัดการสถานะ การเข้าสู่ระบบ รายการร้าน คำขอ และการแจ้งหน้าจอ |
| `fn/safevege/lib/data/repositories/safevege_repository.dart` | แปลงคำสั่งของแอปเป็น endpoint และแปลง JSON เป็นโมเดล |
| `fn/safevege/lib/data/api/api_client.dart`, `fn/safevege/lib/data/api/session_store.dart` | ส่ง HTTP/จัดการข้อผิดพลาด และเก็บ token กับร้านโปรด |
| `fn/safevege/lib/models/app_models.dart`, `fn/safevege/lib/config/` | โมเดล บทบาท สถานะ และการเลือก URL ของ API |
| `fn/safevege/test/` | ชุดทดสอบ Flutter สำหรับ API, repository, state, widget และ config |
| `bn/public/index.php` | จุดเข้าเว็บ ตรวจ CORS/maintenance, กระจาย route และส่งไฟล์ใบรับรอง |
| `bn/src/bootstrap.php`, `src/auth.php`, `src/helpers.php` | อ่านค่า `.env`, เชื่อม PDO, ตรวจ bearer token/สิทธิ์ และเครื่องมือร่วม |
| `bn/src/routes/` | แยก route ของ `auth`, `public`, `shop`, `admin` |
| `bn/schema.sql`, `bn/ER.md`, `bn/column_map.md`, `bn/migrations/` | โครงสร้างข้อมูล ผังความสัมพันธ์ รายการชื่อคอลัมน์ และ migration |
| `bn/scripts/`, `bn/src/demo_seeder.php`, `bn/tests/` | สร้างผู้ดูแล/ข้อมูลสาธิต และทดสอบฝั่ง PHP |
| `bn/storage/certificates/` | ที่เก็บไฟล์ PDF/JPG ฝั่งเซิร์ฟเวอร์; ฐานข้อมูลเก็บเพียงชื่อไฟล์ |

## 3. การไหลของข้อมูลในแอป

1. `main.dart` สร้าง `AppState()` และเรียก `initialize()` โดยไม่รอให้หน้าแรกหยุดวาด `AppState` เป็น `ChangeNotifier` จึงแจ้งหน้าจอเมื่อข้อมูลหรือสถานะโหลดเปลี่ยน (`fn/safevege/lib/main.dart`, `fn/safevege/lib/state/remote_app_state.dart`)
2. `AppState` สร้าง `SafeVegeRepository` ที่ใช้ `ApiClient(baseUrl: AppConfig.apiBaseUrl)` และ `SecureSessionStore` ขณะเริ่มต้นจะอ่านร้านโปรดและ token ที่เก็บไว้ หากมี token จะเรียก `GET /me` เพื่อตรวจบัญชี แล้วโหลดข้อมูลตามบทบาท; หาก API ตอบ `401`/`403` จะล้าง token และกลับไปบทบาท `guest` (`fn/safevege/lib/state/remote_app_state.dart`)
3. หน้าจอเรียกเมธอดของ `AppState` เช่น `addInspectionRequest()` จากนั้น state เรียก repository เพื่อส่ง JSON หรือ multipart ไปยัง route ที่เกี่ยวข้อง เมื่อได้รับผลจะแปลงเป็น `ShopModel`, `InspectionRequestModel`, `CertificateModel` แล้วแจ้งผู้ฟัง (`fn/safevege/lib/state/remote_app_state.dart`, `fn/safevege/lib/data/repositories/safevege_repository.dart`)
4. `ApiClient` เติม `Accept: application/json` และ `Authorization: Bearer <token>` เมื่อมี token ใช้เวลารอคำขอ 20 วินาที แปลง HTTP ที่ไม่ใช่ 2xx เป็น `ApiException` พร้อม status และข้อความจาก `error`/`message` (`fn/safevege/lib/data/api/api_client.dart`)
5. `bn/public/index.php` ตรวจ `/api/v1`, เปิด PDO, ใช้ route ที่ตรงคำขอ และส่ง JSON กลับ `ApiClient` สำหรับไฟล์ใบรับรองจะอ่านจาก `bn/storage/certificates` ผ่าน route เฉพาะหลังตรวจสิทธิ์ (`bn/public/index.php`)

ตัวอย่างการส่งคำขอตรวจ: `AppState.addInspectionRequest()` → `SafeVegeRepository.createInspectionRequest()` → `POST /api/v1/my/shops/{id}/requests` → `inspection_requests` และ `inspection_request_items` เมื่อ API ส่ง `id` กลับ repository จะอ่านรายละเอียดคำขออีกครั้งก่อนคืนโมเดลให้ state (`fn/safevege/lib/state/remote_app_state.dart`, `fn/safevege/lib/data/repositories/safevege_repository.dart`, `bn/src/routes/shop_routes.php`)

## 4. บทบาท การยืนยันตัวตน และขอบเขตสิทธิ์

| ผู้ใช้ | ขอบเขตใน API |
| --- | --- |
| ผู้เยี่ยมชม/ผู้บริโภค (`guest` ในแอป) | `GET` รายการร้าน รายละเอียดร้าน ใบรับรองที่เผยแพร่ และไฟล์สาธารณะ ไม่ต้องมี token |
| ร้านค้า (`shop`) | ลงทะเบียน/เข้าสู่ระบบ; `/my/*` จำกัดด้วย `owner_user_id` จึงเข้าถึงเฉพาะร้านและคำขอของบัญชีตน |
| ผู้ตรวจการ (`admin`) | `/admin/shops`, `/admin/requests` และขั้นนัดหมาย บันทึกผล อัปโหลดใบรับรอง เผยแพร่ |
| ผู้ดูแลระบบสูงสุด (`super_admin`) | สิทธิ์งานตรวจทั้งหมด และ `/admin/users`, `/admin/audit`, `/admin/settings` |

`POST /auth/login` ตรวจ `password_verify()` และบัญชี `is_active` แล้วออก token แบบสุ่ม เก็บเฉพาะ SHA-256 hash ใน `api_tokens` โดยหมดอายุหลัง 30 วัน `current_user()` ตรวจรูปแบบ bearer token, hash, วันหมดอายุ และสถานะบัญชีทุกครั้ง (`bn/src/routes/auth_routes.php`, `bn/src/auth.php`) `SecureSessionStore` ใช้ `flutter_secure_storage` เก็บ token และร้านโปรด; `MemorySessionStore` ใช้สำหรับทดสอบหรือฉีดแทน (`fn/safevege/lib/data/api/session_store.dart`)

การซ่อนเมนูใน Flutter ช่วยนำทาง แต่สิทธิ์จริงตรวจที่ PHP: `shop_routes.php` บังคับ `shop` และ ownership, `admin_routes.php` บังคับ `admin` หรือ `super_admin` แล้วตรวจ `super_admin` ซ้ำในกลุ่มเฉพาะ `POST /auth/logout` ลบ hash ของ token ปัจจุบัน การรีเซ็ตรหัสผ่านผู้อื่นผ่าน Super Admin ลบ token ของเป้าหมายทั้งหมด และป้องกันการปิด/ลดบทบาท Super Admin ที่ยังใช้งานอยู่คนสุดท้าย (`bn/src/auth.php`, `bn/src/routes/shop_routes.php`, `bn/src/routes/admin_routes.php`)

`POST /auth/change-password` ตรวจรหัสเดิมและกำหนดรหัสใหม่อย่างน้อย 12 ตัวอักษร ส่วน API กู้คืนด้วย OTP ไม่มีใน route ปัจจุบัน การเปลี่ยนรหัสผ่านด้วยตนเองใน route นี้ไม่ได้ลบ token เดิมในโค้ดปัจจุบัน จึงควรประเมินนโยบาย session ก่อนใช้ในระบบจริง (`bn/src/routes/auth_routes.php`, `bn/docs/super-admin-operations.md`)

## 5. กลุ่ม API และรูปแบบคำขอ

ทุกพาธในตารางเติม prefix `/api/v1`; JSON ใช้ `Content-Type: application/json` เมื่อส่ง body และ route ไฟล์ใช้ `multipart/form-data` รายการนี้สรุปจาก route ปัจจุบัน ไม่ใช่สัญญาว่าทุก endpoint พร้อมสำหรับ production (`bn/public/index.php`, `bn/src/routes/`)

| กลุ่ม | Method และพาธสำคัญ | พฤติกรรม |
| --- | --- | --- |
| สาธารณะ | `GET /health`; `GET /shops?q=&lat=&lng=&radius_km=`; `GET /shops/{id}`; `GET /shops/{id}/certificates`; `GET /certificates`; `GET /certificates/{id}/file` | ตรวจฐานข้อมูล ค้นหาร้านสาธารณะและเอกสาร; ไฟล์ที่ไม่สาธารณะต้องเป็นเจ้าของหรือ admin |
| บัญชี | `POST /auth/register`; `POST /auth/login`; `POST /auth/logout`; `POST /auth/change-password`; `GET /me` | สมัครร้าน/รับ token/สิ้นสุด token/เปลี่ยนรหัสผ่าน/อ่านบัญชีปัจจุบัน |
| ร้านค้า | `GET /my/shops`; `PATCH /my/shops/{id}`; `POST /my/shops/{id}/requests`; `GET /my/requests`; `GET /my/requests/{id}`; `POST /my/account/delete` | จัดการร้านและคำขอของเจ้าของบัญชี; การลบบัญชีในโค้ดเป็นการปิดบัญชี ซ่อนร้าน และถอน token ไม่ได้ลบประวัติออกจากฐาน |
| งานตรวจ | `GET /admin/shops`; `POST /admin/shops`; `PATCH /admin/shops/{id}`; `DELETE /admin/shops/{id}`; `GET /admin/requests`; `GET /admin/requests/{id}`; `POST /admin/requests/{id}/appointment`; `POST /admin/requests/{id}/results`; `POST /admin/requests/{id}/certificates`; `POST /admin/requests/{id}/publish` | บัญชี `admin` และ `super_admin` ดำเนินงานตรวจ; การลบร้านที่มีประวัติคำขอถูกปฏิเสธ |
| จัดการระบบ | `GET /admin/users`; `POST /admin/users`; `PATCH /admin/users/{id}`; `POST /admin/users/{id}/password`; `GET /admin/audit`; `GET /admin/settings`; `PATCH /admin/settings` | เฉพาะ `super_admin`; จัดการบัญชี ประวัติการเปลี่ยนแปลง และค่าที่อนุญาต |

`POST /my/shops/{id}/requests` รับ `vegetables` เป็นรายการชื่อ 1–30 รายการ, `address_snapshot` และพิกัด (`latitude`, `longitude`) โดย route ใช้พิกัดร้านเมื่อไม่ส่งพิกัดมาและคัดชื่อผักซ้ำออก ผลตอบกลับ `201` มี `id`, `request_no`, `status: submitted` (`bn/src/routes/shop_routes.php`, `bn/src/helpers.php`) API ส่งข้อผิดพลาดเป็น JSON `error`; `401` หมายถึงไม่มี/หมดอายุ token, `403` ไม่มีสิทธิ์, `404` ไม่พบข้อมูล, `409` ข้อมูลขัดแย้งหรือลำดับงานไม่ถูกต้อง, `422` ค่าคำขอไม่ผ่านการตรวจ และ `503` ใช้กับฐานข้อมูลไม่พร้อมหรือ maintenance ตาม route ที่เกี่ยวข้อง (`bn/public/index.php`, `bn/src/routes/`)

`PATCH /admin/settings` รับ `values` เฉพาะ `maintenance_mode` (boolean), `public_app_base_url` (ข้อความไม่ว่าง) และ `default_certificate_expiry_days` (จำนวนเต็ม 1–3650) `maintenance_mode` ใน `index.php` ตอบ `503` แก่ผู้ใช้ทั่วไปใน route ที่ไม่ใช่ admin โดยยังเปิด `POST /auth/login`; admin ผ่านได้ ค่า URL สาธารณะอ่านใน Flutter บางจุด แต่ควรตรวจการใช้ค่าตั้งค่าทุกจุดก่อนถือว่าบังคับใช้ทั่วระบบ (`bn/src/routes/admin_routes.php`, `bn/public/index.php`, `fn/safevege/lib/state/remote_app_state.dart`)

## 6. วงจรคำขอตรวจ ผลตรวจ และใบรับรอง

| สถานะในฐาน/API | เกิดเมื่อ | สิ่งที่ยังต้องตรวจ |
| --- | --- | --- |
| `submitted` | ร้านส่งคำขอพร้อมรายการผักและตำแหน่ง | ยังไม่มีนัดหรือผลตรวจ |
| `scheduled` | admin ส่ง `appointment_at` รูปแบบ UTC `YYYY-MM-DD HH:MM:SS`; นัดใหม่เก็บเป็นแถวใหม่ | ใช้รายการนัดล่าสุดเมื่อแสดงรายละเอียด |
| `inspected` | admin บันทึกผล `passed`, `failed` หรือ `inconclusive` ให้รายการผัก; ผลแก้ไขเก็บเป็น revision ใหม่ | สถานะนี้ยังไม่แปลว่ามีใบรับรองสาธารณะ |
| `published` | admin เผยแพร่คำขอที่ `inspected` และมีใบรับรองที่ยังไม่หมดอายุ | route เปิด `is_public` ของใบรับรองที่ยังใช้ได้และร้าน; การมองเห็นสาธารณะยังตรวจวันหมดอายุซ้ำ |
| `cancelled` | มีค่าใน enum และตัวกรองรายการ | ไม่พบ route เปลี่ยนคำขอเป็น `cancelled` ในชุด route ปัจจุบัน |

`POST /admin/requests/{id}/results` รับ `items` 1–30 รายการที่เป็นของคำขอและ `inspected_at` แบบ UTC; แต่ละรายการต้องมี `request_item_id` และ `outcome` ที่ถูกต้อง `POST /admin/requests/{id}/certificates` รับ `certificate_no`, `issued_at` (`YYYY-MM-DD`), `expires_at` ที่เลือกได้, `result_ids` เป็น JSON array string และไฟล์ PDF/JPG ไม่เกิน 5 MB `result_ids` ต้องชี้ผล `passed` ของคำขอเดียวกัน ถ้าไม่ส่งวันหมดอายุ API ใช้ `default_certificate_expiry_days` หรือ 365 วัน (`bn/src/routes/admin_routes.php`)

ในแอป `AppState.recordInspectionResults()` เรียกบันทึกผลก่อน หากมีไฟล์จึงอัปโหลดและเรียก publish ต่อ ดังนั้นความล้มเหลวกลางทางอาจทิ้งคำขอไว้ที่ `inspected` หรือมีใบรับรองที่ยังไม่เผยแพร่ ผู้พัฒนาควรอ่าน `GET /admin/requests/{id}` ก่อนลองซ้ำ ไม่ควรสมมติว่าทั้งสามคำขอเป็นธุรกรรมเดียวกัน ใน Flutter `inspected` และ `published` ถูกแสดงเป็น `RequestStatus.completed` เหมือนกัน ส่วน `RequestStatus.inProgress` ไม่มีค่า API ที่ map เข้าในโค้ดปัจจุบัน (`fn/safevege/lib/state/remote_app_state.dart`, `fn/safevege/lib/data/repositories/safevege_repository.dart`)

รายการสาธารณะของใบรับรองต้องมี `request.status = published`, `certificate.is_public = 1` และไม่หมดอายุ; รายละเอียดร้านสาธารณะต้องมี `shop.is_public = 1` โดยผลที่แสดงกับร้านต้องเป็น `passed` ที่ผูกกับใบรับรองสาธารณะและยังใช้ได้ `GET /certificates/{id}/file` ให้เจ้าของร้านหรือ admin เปิดไฟล์ที่ยังไม่สาธารณะได้หลังยืนยันตัวตน (`bn/src/routes/public_routes.php`, `bn/public/index.php`)

## 7. ฐานข้อมูล ความสัมพันธ์ และ migration

`bn/schema.sql` กำหนด MySQL 5.7 ขึ้นไป, InnoDB และ `utf8mb4` ตารางจริงใช้ชื่อคอลัมน์มี prefix ส่วน view `api_*` เปิดชื่อคอลัมน์แบบที่ PHP/JSON ใช้อยู่ เช่น `users.use_id` → `api_users.id`, `users.use_password` → `api_users.password_hash`, `inspection_requests.req_status` → `api_inspection_requests.status` และ `certificates.cert_file_path` → `api_certificates.file_path` รายการแปลงชื่อครบอยู่ที่ `bn/column_map.md` (`bn/schema.sql`)

| ตารางจริง | ความสัมพันธ์และหน้าที่ | prefix |
| --- | --- | --- |
| `users` | บัญชีร้าน/ผู้ดูแล; หนึ่งบัญชีร้านเป็นเจ้าของหลายร้านได้ | `use_` |
| `api_tokens` | token hash หลายรายการต่อผู้ใช้; ลบตามผู้ใช้เมื่อผู้ใช้ถูกลบ | `tok_` |
| `shops` | อ้าง `users` เป็นเจ้าของ; แยกธง `is_public` | `shop_` |
| `inspection_requests` | คำขอหลายรายการต่อร้าน; เก็บ snapshot ที่อยู่/พิกัดขณะส่ง | `req_` |
| `inspection_request_items` | รายการผักหลายชนิดต่อคำขอ | `item_` |
| `inspection_appointments` | ประวัตินัดหลายครั้งต่อคำขอและผู้บันทึก | `apt_` |
| `inspection_results` | ผลหลาย revision ต่อรายการผักและผู้บันทึก | `res_` |
| `certificates` | ใบรับรองต่อคำขอ เลขใบรับรองไม่ซ้ำ เก็บชื่อไฟล์และผู้ส่ง | `cert_` |
| `certificate_results` | ตารางเชื่อมใบรับรองกับ revision ของผลตรวจ | `cr_` |
| `audit_events` | ผู้กระทำ ประเภท/รหัสรายการ การกระทำ และรายละเอียดที่ไม่ควรมีความลับ | `aud_` |
| `app_settings` | ค่าระบบและผู้ปรับปรุง | `set_` |

`bn/ER.md` เป็นผัง ER ที่ติดป้าย “draft”; ให้ตรวจ `bn/schema.sql` เมื่อต้องการข้อกำหนดคีย์จริง `certificates.file_path` คือชื่อไฟล์ภายใน `bn/storage/certificates` ไม่ใช่ URL สาธารณะ และเนื้อไฟล์ไม่ได้เก็บใน MySQL (`bn/public/index.php`, `bn/src/routes/admin_routes.php`)

ข้อควรระวัง: `schema.sql` ระบุให้ใช้กับฐานใหม่และ `CREATE TABLE IF NOT EXISTS` ไม่ได้ย้ายข้อมูลเก่าเอง เอกสาร `bn/README.md` ระบุว่ายังไม่ได้ย้ายข้อมูลจากตารางเก่า `admin`, `shops`, `requests`, `results` ส่วน `bn/migrations/2026-10-14-super-admin-access.sql` เพิ่มบทบาท `super_admin`, ตาราง `app_settings` และ view ที่เกี่ยวข้องให้ฐานเดิมที่ใช้ schema แบบมี prefix; ต้องสำรองข้อมูล ตรวจโครงสร้างจริง และทดสอบ migration กับสำเนาฐานก่อนใช้กับข้อมูลที่มีอยู่

เมื่อตรวจแล้วว่าฐานเดิมตรงกับโครงสร้างที่ migration คาดหวัง คำสั่งตัวอย่างจาก `bn` ตาม `bn/docs/super-admin-operations.md` คือคำสั่งด้านล่าง ซึ่งไม่ได้รันในงานคู่มือนี้:

```powershell
Get-Content -Raw .\migrations\2026-10-14-super-admin-access.sql |
  & 'C:\MAMP\bin\mysql\bin\mysql.exe' --user=YOUR_MYSQL_USER --password safevege
```

## 8. ตั้งค่าเครื่องพัฒนา

ขั้นตอนนี้เป็นคำสั่งที่รีโปบันทึกไว้สำหรับ Windows/MAMP และไม่ได้รันระหว่างงานคู่มือนี้ ตัวอย่างให้รันจากไดเรกทอรี `bn` เว้นแต่ระบุให้ย้ายไป `fn/safevege` (`bn/README.md`, `fn/safevege/docs/api-setup.md`)

1. เตรียม MySQL 5.7+ และ PHP 8.1+ ที่มี PDO MySQL บนฐานใหม่ให้ import `bn/schema.sql` ด้วยบัญชีที่มีสิทธิ์สร้างฐานข้อมูล อย่า import ซ้ำบนฐานเดิมที่มีข้อมูลโดยไม่ตรวจ migration
2. คัดลอก `bn/.env.example` เป็น `bn/.env` แล้วกรอกค่าเฉพาะเครื่อง `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `APP_DEBUG`, `CORS_ORIGIN` ไฟล์ `.env` ต้องอยู่ฝั่งเซิร์ฟเวอร์และไม่อยู่ใน commit `bootstrap.php` ให้ environment variable มีลำดับเหนือค่าในไฟล์
3. เปิด PHP โดยชี้ document root ไปที่ `bn/public` เท่านั้น แล้วตรวจ `GET http://127.0.0.1:8081/api/v1/health` ซึ่งจะลองเชื่อมฐานข้อมูลและตอบ `{"status":"ok"}` เมื่อสำเร็จ

```powershell
# รันจาก bn; คำสั่งตัวอย่าง ยังไม่ได้รันในงานคู่มือนี้
Get-Content -Raw .\schema.sql | & 'C:\MAMP\bin\mysql\bin\mysql.exe' --user=YOUR_MYSQL_USER --password
Copy-Item .\.env.example .\.env
& 'C:\MAMP\bin\php\php8.3.1\php.exe' -c 'C:\MAMP\conf\php8.3.1\php.ini' -S 127.0.0.1:8081 -t .\public .\public\index.php
```

`CORS_ORIGIN` ใช้รายการ origin ของเว็บแบบตรงตัวคั่นด้วย comma เช่น `http://localhost:3000,http://127.0.0.1:3000` โค้ด `cors_allowed_origin()` รองรับ `*` ด้วย แต่จะสะท้อน origin ที่ขอเข้ามา; คำแนะนำคือกำหนดเฉพาะ origin ที่อนุญาตและหลีกเลี่ยง `*` โดยเฉพาะเมื่อเผยแพร่ระบบ (`bn/.env.example`, `bn/src/helpers.php`, `bn/public/index.php`)

`AppConfig.apiBaseUrl` อ่าน `--dart-define=API_BASE_URL=YOUR_API_URL` หากไม่กำหนดใน debug จะใช้ `http://10.0.2.2:8081/api/v1` บน Android Emulator และ `http://127.0.0.1:8081/api/v1` บนเว็บ/เครื่องอื่น; release ที่ไม่กำหนด URL จะโยน `StateError` (`fn/safevege/lib/config/api_endpoint.dart`, `fn/safevege/lib/config/app_config.dart`) ตัวอย่างคำสั่งจาก `fn/safevege`:

```powershell
flutter pub get
flutter run -d chrome --web-port 3000 --dart-define=API_BASE_URL=http://127.0.0.1:8081/api/v1
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081/api/v1
```

โทรศัพท์จริงต้องใช้ URL ที่เข้าถึงเครื่องเซิร์ฟเวอร์ได้ เช่น IP ใน LAN พร้อมเปิดพอร์ต/ไฟร์วอลล์ให้ตรง; `127.0.0.1` และ `10.0.2.2` ไม่ใช่ที่อยู่เซิร์ฟเวอร์จากโทรศัพท์จริง ข้อยกเว้น HTTP แบบไม่เข้ารหัสอยู่ใน `fn/safevege/android/app/src/debug/AndroidManifest.xml` เท่านั้น คำแนะนำสำหรับ release คือใช้ API ผ่าน HTTPS และกำหนด `API_BASE_URL` ที่ทั้งเว็บและมือถือเข้าถึงได้ โดยตั้ง `CORS_ORIGIN` เป็น origin ของเว็บที่เผยแพร่ (`fn/safevege/docs/api-setup.md`, `bn/README.md`)

## 9. ผู้ดูแลคนแรกและข้อมูลสาธิตเฉพาะเครื่อง

หลังสร้าง schema แล้ว ให้ใช้ `bn/scripts/create_admin.php` จาก CLI ฝั่งเซิร์ฟเวอร์เพื่อสร้าง `admin` หรือ `super_admin` คนแรก ตั้งรหัสผ่านอย่างน้อย 12 ตัวอักษรใน `SAFEVEGE_ADMIN_PASSWORD` ของ shell ปัจจุบัน สคริปต์ hash รหัสผ่านก่อนบันทึก ไม่มีรหัสเริ่มต้นใน Flutter (`bn/scripts/create_admin.php`, `bn/docs/super-admin-operations.md`)

```powershell
# ตัวอย่างจาก bn; ให้กำหนดค่าลับจริงใน shell ของตน ไม่บันทึกลงรีโป
$env:SAFEVEGE_ADMIN_PASSWORD = '<set-a-unique-password-of-at-least-12-characters>'
& 'C:\MAMP\bin\php\php8.3.1\php.exe' -c 'C:\MAMP\conf\php8.3.1\php.ini' scripts/create_admin.php --role=super_admin root-admin 'SafeVege System Owner'
Remove-Item Env:SAFEVEGE_ADMIN_PASSWORD
```

`bn/scripts/seed_demo.php --local-demo` จำกัดการรันจาก CLI ที่ `DB_HOST` เป็น loopback และ `DB_NAME=safevege` เท่านั้น สคริปต์สร้างบัญชีสาธิต `demo_admin`, `demo_shop`, `demo_market`, ร้าน 3 แห่ง คำขอ 5 รายการ และใบรับรองสาธิต 2 ฉบับ; ชุดข้อมูลมีเครื่องหมาย `DEMO` และ PDF ระบุว่าไม่ใช่หลักฐานรับรองจริง สคริปต์อัปเดตรายการสาธิตของตนเมื่อรันซ้ำ และปฏิเสธการทับบัญชีที่ไม่ใช่บัญชีสาธิต (`bn/scripts/seed_demo.php`, `bn/src/demo_seeder.php`)

```powershell
# ตัวอย่างจาก bn; ใช้ฐานพัฒนาเฉพาะเครื่องเท่านั้น
& 'C:\MAMP\bin\php\php8.3.1\php.exe' -c 'C:\MAMP\conf\php8.3.1\php.ini' scripts/seed_demo.php --local-demo
```

สคริปต์สาธิตมีรหัสผ่านตัวอย่างอยู่ใน source และพิมพ์หลังรัน จึงไม่ควรนำบัญชีสาธิตหรือข้อมูลนี้ขึ้นระบบจริง คู่มือนี้ไม่คัดลอกรหัสผ่านดังกล่าว ไม่คัดลอก `.env` ที่กรอกแล้ว และไม่แสดง token จริง

## 10. ทดสอบและตรวจผล

คำสั่งในตารางเป็นแนวทางจากไฟล์ทดสอบ/เอกสารปัจจุบัน **ไม่ได้รันระหว่างงานเขียนคู่มือนี้** ให้รัน PHP จาก `bn` และ Flutter จาก `fn/safevege`; แทน `php` ด้วย PHP ที่เปิด PDO MySQL เมื่อทดสอบฐานข้อมูลบน MAMP (`bn/tests/`, `fn/safevege/test/`, `bn/README.md`)

| คำสั่ง | สิ่งที่ตรวจและเงื่อนไข |
| --- | --- |
| `flutter pub get` | ดึง dependency ตาม `fn/safevege/pubspec.yaml` ก่อนวิเคราะห์/ทดสอบ |
| `flutter analyze` | วิเคราะห์ Dart แบบคงที่; ไม่แทนการทดสอบ HTTP จริง |
| `flutter test` | รันชุด `fn/safevege/test/` รวม API client, repository, state, config และ widget; ส่วนใหญ่ใช้ client จำลอง |
| `php tests/helpers_test.php` และ `php tests/cors_policy_test.php` | ตรวจ helper และนโยบาย CORS โดยไม่ต้องเปิด API |
| `php tests/admin_access_contract_test.php`, `php tests/super_admin_routes_test.php`, `php tests/password_policy_test.php`, `php tests/otp_removed_test.php`, `php tests/create_admin_cli_test.php` | ตรวจเงื่อนไขบทบาท ค่าตั้งค่า นโยบายรหัสผ่าน และ CLI ตามแต่ละไฟล์ |
| `php tests/schema_naming.php` | เชื่อมฐานที่ import แล้ว ตรวจ prefix ทุกตารางและ `users.use_password`; ต้องมี PDO MySQL |
| `php tests/integration.php` | ตรวจ workflow ผ่าน API จริงที่ `127.0.0.1:8081`; สร้างข้อมูลทดสอบและล้างข้อมูล/ไฟล์ของการทดสอบใน `finally`; ใช้ฐานพัฒนาแยกจากข้อมูลสำคัญ |
| `php tests/demo_seed_test.php` | ตรวจการ seed ซ้ำ รายการ API และไฟล์สาธิต; ต้องใช้ฐาน loopback `safevege` และ API ที่พอร์ต 8081; มีการเขียนข้อมูลสาธิต |
| `flutter build web --release --dart-define=API_BASE_URL=https://api.your-domain.example/api/v1` และ `flutter build apk --release --dart-define=API_BASE_URL=https://api.your-domain.example/api/v1` | ตัวอย่างการสร้าง release โดยแทน URL ตัวอย่างด้วย HTTPS API จริง; คำสั่ง build ไม่ยืนยันว่า deployment ใช้งานได้ |

หลังตั้งระบบในเครื่องที่ได้รับอนุญาต ให้ตรวจ `GET /api/v1/health` แล้วทดสอบเส้นทางตามบทบาทและผลที่ฐานข้อมูล/ไฟล์เปลี่ยนจริง โดยเฉพาะส่งคำขอ บันทึกผล อัปโหลด และเผยแพร่ คำแนะนำนี้เป็นขั้นตรวจรับ ไม่ใช่ผลการทดสอบที่เกิดขึ้นในงานคู่มือนี้

## 11. แนวทางขยายฟีเจอร์อย่างปลอดภัย

1. ระบุบทบาท เจ้าของข้อมูล สถานะ และฟิลด์ที่ต้องเปลี่ยนก่อนแก้โค้ด ตรวจ route และตารางเดิมที่เกี่ยวข้อง (`bn/src/routes/`, `bn/schema.sql`)
2. หากเปลี่ยนข้อมูล ให้กำหนดวิธี migration สำหรับฐานเดิมและ view `api_*` ที่ PHP ใช้ พร้อมคงความหมายของคอลัมน์ JSON ที่ Flutter อ่าน; อย่าแก้เฉพาะตารางหรือเฉพาะโมเดล (`bn/column_map.md`, `fn/safevege/lib/data/repositories/safevege_repository.dart`)
3. เพิ่ม validation, ownership และ role check ที่ PHP ทุก endpoint ใหม่ แล้วเพิ่มเมธอด repository และ state ตามลำดับ ให้หน้าจอแสดงข้อผิดพลาดจาก `ApiException` โดยไม่ถือว่าการซ่อนปุ่มเป็นการคุ้มครองข้อมูล (`bn/src/auth.php`, `fn/safevege/lib/data/api/api_client.dart`)
4. ทดสอบกรณีสำเร็จและถูกปฏิเสธตามบทบาท รวมถึงผลหลัง retry หรือคำขอหลายขั้น โดยเฉพาะการสร้างไฟล์และการเผยแพร่ ตรวจทั้ง response และข้อมูลที่เก็บจริงก่อนปล่อยใช้

## 12. ความปลอดภัย การเผยแพร่ และข้อจำกัด

เก็บ `bn/.env`, รหัสผ่าน และ token นอก source control ใช้รหัสผ่านไม่ซ้ำและ HTTPS สำหรับ API ที่เผยแพร่ ให้เว็บเซิร์ฟเวอร์เปิดเฉพาะ `bn/public` และป้องกัน `bn/src`, `.env`, `bn/storage` จากการเข้าถึงโดยตรง กำหนดสิทธิ์เขียน `bn/storage/certificates` เฉพาะกระบวนการที่จำเป็น สำรองทั้งฐานข้อมูลและไฟล์ใบรับรอง เพราะสำรองฐานอย่างเดียวไม่ครอบคลุมเอกสาร (`bn/README.md`, `bn/public/index.php`, `bn/src/routes/admin_routes.php`)

ข้อควรตรวจสำหรับ deployment: ค่า `APP_DEBUG` ควรเป็น `false`; ควบคุม `CORS_ORIGIN` ด้วย origin ที่เจาะจง; ทดสอบ HTTPS, การหมดอายุ token, สิทธิ์เข้าถึงใบรับรอง และการกู้คืนข้อมูลจากสำรองในสภาพแวดล้อมปลายทาง คำแนะนำเหล่านี้ยังไม่ได้ผ่านการทดสอบ deployment ในงานคู่มือนี้ (`bn/.env.example`, `bn/public/index.php`)

ข้อจำกัดที่เห็นในโค้ดปัจจุบัน: `ER.md` และ `bn/README.md` ยังระบุส่วนของ schema/การย้ายข้อมูลเป็นร่าง; ไม่พบ route เปลี่ยนคำขอเป็น `cancelled`; Flutter รวม `inspected` กับ `published` เป็นป้าย “เสร็จสิ้น”; งานผลตรวจ–ไฟล์–เผยแพร่ไม่มีธุรกรรมร่วมข้าม HTTP; การเปลี่ยนรหัสผ่านตนเองไม่ได้ถอน token เดิม; โหมด `motorcycle` ของบริการแผนที่ใช้เส้นทาง `routed-bike`/`bicycle` ซึ่งไม่ใช่เครือข่ายเส้นทางจักรยานยนต์โดยเฉพาะ (`bn/ER.md`, `bn/README.md`, `bn/src/routes/admin_routes.php`, `fn/safevege/lib/data/repositories/safevege_repository.dart`, `fn/safevege/lib/services/osm_map_service.dart`)

งานถัดไปที่แนะนำ: จัดทำและทดสอบ migration ข้อมูลเก่าก่อนใช้งานฐานเดิม, ทบทวนความสอดคล้องของสถานะ/การเผยแพร่และวิธีกู้จากความล้มเหลวกลางทาง, แล้วทดสอบการติดตั้ง release กับ API HTTPS และการสำรอง/กู้คืนจริง ทั้งหมดเป็นข้อเสนอ ไม่ใช่งานที่ดำเนินการแล้ว

## 13. แหล่งอ้างอิงในรีโป

อ้างอิง ณ 17 ตุลาคม 2026; ทุกพาธต่อไปนี้นับจากรากรีโป SafeVege:

| หัวข้อ | ไฟล์ต้นทาง |
| --- | --- |
| ขอบเขตคู่มือและข้อเท็จจริงตั้งต้น | `notes.md`, `.superpowers/sdd/task-2-brief.md` |
| ภาพรวม backend และวิธีตั้งเครื่อง | `bn/README.md`, `bn/.env.example`, `fn/safevege/README.md`, `fn/safevege/docs/api-setup.md` |
| โครงสร้างข้อมูล | `bn/schema.sql`, `bn/ER.md`, `bn/column_map.md`, `bn/migrations/2026-10-14-super-admin-access.sql` |
| จุดเข้า API, สิทธิ์ และ route | `bn/public/index.php`, `bn/src/bootstrap.php`, `bn/src/auth.php`, `bn/src/helpers.php`, `bn/src/routes/auth_routes.php`, `bn/src/routes/public_routes.php`, `bn/src/routes/shop_routes.php`, `bn/src/routes/admin_routes.php` |
| การสร้างบัญชีและข้อมูลสาธิต | `bn/scripts/create_admin.php`, `bn/scripts/seed_demo.php`, `bn/src/demo_seeder.php`, `bn/docs/super-admin-operations.md` |
| Flutter และโมเดล | `fn/safevege/lib/main.dart`, `fn/safevege/lib/state/app_state.dart`, `fn/safevege/lib/state/remote_app_state.dart`, `fn/safevege/lib/data/repositories/safevege_repository.dart`, `fn/safevege/lib/data/api/api_client.dart`, `fn/safevege/lib/data/api/session_store.dart`, `fn/safevege/lib/models/app_models.dart`, `fn/safevege/lib/config/api_endpoint.dart`, `fn/safevege/lib/config/app_config.dart`, `fn/safevege/lib/services/osm_map_service.dart`, `fn/safevege/android/app/src/debug/AndroidManifest.xml`, `fn/safevege/pubspec.yaml` |
| การทดสอบ | `bn/tests/`, `fn/safevege/test/` |
