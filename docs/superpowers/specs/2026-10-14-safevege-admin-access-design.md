# SafeVege Admin Access Design

**Date:** 2026-10-14  
**Status:** Approved in chat; implementation complete pending database integration verification

## Goal

เอา password recovery แบบ OTP ออกจาก SafeVege และเพิ่มระบบสิทธิ์ผู้ดูแลสองระดับ: `admin` สำหรับเจ้าหน้าที่ตรวจผัก และ `super_admin` สำหรับผู้ดูแลระบบตัวจริงที่เห็นข้อมูลรวม จัดการบัญชี เปลี่ยนรหัสผ่าน และแก้ค่าระบบผ่านเมนูเฉพาะ

## Role model

| Role | หน้าที่ | สิทธิ์หลัก |
|---|---|---|
| `shop` | เจ้าของร้าน | จัดการร้านและคำขอของร้านตัวเอง |
| `admin` | Admin ตรวจผัก | ดูคำขอทั้งหมด, นัดตรวจ, บันทึกผล, อัปโหลดใบรับรอง และเผยแพร่ผล |
| `super_admin` | Admin ตัวจริง | ดูข้อมูลทั้งหมด, จัดการบัญชี/role/รหัสผ่าน, จัดการร้านและคำขอ, ดู audit และตั้งค่าที่ระบบเปิดให้แก้ |

`super_admin` จะไม่ใช้รหัสพิเศษที่ฝังในแอป การเปิดเมนูพิเศษใช้ role ที่ backend ยืนยันจาก session token เท่านั้น การตรวจ role ใน Flutter เป็นเพียงการนำทาง ส่วนทุก endpoint ต้องตรวจสิทธิ์ซ้ำที่ backend

## Decisions

### 1. Remove OTP recovery completely

- ลบ route logic ของ `/auth/forgot-password`, `/auth/verify-otp` และ `/auth/reset-password`
- ลบปุ่ม/ลิงก์กู้รหัสผ่านออกจากหน้า login และลบ `AccountRecoveryScreen` ออกจาก flow ที่ผู้ใช้เข้าถึงได้
- ลบ `demo_otp`, OTP bypass และข้อความ/ตัวช่วย OTP ทั้งหมด
- ไม่สร้าง `password_resets` table ใหม่อีก; ถ้ามีตารางเก่าจากการใช้งานเดิมจะไม่ถูกอ่านหรือใช้เป็นช่องทาง authentication
- การลืมรหัสผ่านร้านค้า หรือ admin ตรวจผัก ให้ `super_admin` เปลี่ยนผ่านเมนูจัดการบัญชี
- การเปลี่ยนรหัสผ่านของผู้ใช้ที่ login อยู่ยังใช้ `/auth/change-password` ตามปกติ โดยไม่รับ OTP

### 2. Backend authorization

- เพิ่ม `super_admin` ใน role enum/schema และ mapping ของ session user
- ทำ role guard แบบ allow-list ที่รองรับ `admin` และ `super_admin` สำหรับ route งานตรวจที่ทั้งสอง roleต้องเห็น
- route จัดการผู้ใช้, role, reset password, settings และ audit ใช้ `super_admin` เท่านั้น
- ห้าม demote/deactivate/delete `super_admin` คนสุดท้าย
- ทุกการสร้างบัญชี, เปลี่ยน role, reset password, deactivate และแก้ settings เขียน audit event พร้อม actor และ target
- Password ใหม่ที่สร้างหรือ reset ต้องยาวอย่างน้อย 12 ตัวอักษรและ hash ด้วย `password_hash`
- ไม่ให้ API ส่ง password hash, reset secret หรือ server bootstrap secret กลับไปที่ client

### 3. Super Admin console

เพิ่มหน้า `SuperAdminDashboardScreen` และเมนูเฉพาะ role `super_admin` โดยมีส่วนต่อไปนี้:

- Overview: จำนวนร้าน, คำขอ, ใบรับรอง และบัญชีตามสถานะ
- User management: รายชื่อผู้ใช้, สร้าง Inspector Admin, เปิด/ปิดบัญชี, เปลี่ยน roleตาม policy, ตั้งรหัสผ่านใหม่
- Shops: ดูและแก้ข้อมูลร้านทั้งหมด
- Requests/certificates: ดูรายละเอียดทั้งหมดและเข้าถึง workflow ที่ backend อนุญาต
- Settings: แก้เฉพาะค่าที่มี schema ชัดเจน เช่น public base URL, maintenance flag และค่าเริ่มต้นของระบบ
- Audit: ดูกิจกรรมสำคัญย้อนหลังโดย filter actor/action/entity

UI ไม่แสดงเมนูนี้แก่ `shop` หรือ `admin` และไม่ใช้ hidden password/gesture เป็น access control

### 4. Account management API

เพิ่ม API ภายใต้ `/admin/users`:

- `GET /admin/users` — super admin ดูรายชื่อและ role โดยไม่ส่งข้อมูลลับ
- `POST /admin/users` — สร้างบัญชี `admin` หรือ `super_admin` ตาม policy; การสร้าง super admin ใหม่ต้องยืนยันด้วยรหัสผ่านปัจจุบันของผู้ทำรายการ
- `PATCH /admin/users/{id}` — แก้ display name, active state และ roleตาม policy
- `POST /admin/users/{id}/password` — super admin ตั้งรหัสผ่านใหม่ให้ร้านค้า/admin โดยไม่ใช้ OTP
- `GET /admin/audit` — อ่าน audit log แบบแบ่งหน้า

สร้าง super admin คนแรกผ่าน server-side bootstrap command/config ที่ไม่อยู่ใน Flutter bundle; production จะไม่ใช้ default username/password

### 5. Settings API

- เพิ่ม `app_settings` persistence ที่เก็บ key, JSON value, updated_by และ updated_at
- backend รับเฉพาะ allow-listed keys และตรวจชนิด/ช่วงค่าก่อนบันทึก
- Flutter settings UI ใช้ schema ที่ backend ส่งกลับ ไม่เปิดช่องให้แก้ SQL, file path, role guard หรือ secret แบบ arbitrary
- secret ที่ใช้เชื่อมต่อระบบไม่แสดงหรือแก้จาก client; เปลี่ยนผ่าน server environment เท่านั้น

## Data flow

1. Login ส่ง username/password → backend คืน token + role → `AppState` map เป็น `shop`, `admin` หรือ `superAdmin`
2. `AppState` route ไป dashboard ตาม role; `superAdmin` เห็น `SuperAdminDashboardScreen`
3. ทุก request ใน console ส่ง bearer token → backend ตรวจ token และ `super_admin` → ทำ mutation → audit actor/target → คืนข้อมูล sanitized
4. การ reset password ส่ง `new_password` จาก super admin → backend hash และ revoke target sessions → audit → target ต้อง login ใหม่
5. การแก้ settings ส่ง key/value ตาม schema → backend validate allow-list/type → save + audit → broadcast/refresh state เฉพาะหน้าที่เกี่ยวข้อง

## Error handling and safety

- ไม่มี endpoint ใดใช้ OTP, `demo_otp`, magic password หรือ password ที่ฝังใน client
- password reset ของ super admin เองใช้ authenticated self-change; ถ้าลืมรหัส super admin ต้องใช้ server-side bootstrap/recovery procedure นอกแอป
- ตอบ 403 เมื่อ role ไม่พอ, 409 เมื่อพยายามแก้ super admin คนสุดท้ายหรือทำ state transition ที่ชนกัน, 422 เมื่อ input ไม่ผ่าน validation
- ป้องกัน self-demotion/self-deactivation เมื่อจะทำให้ไม่มี super admin เหลือ
- ทุก mutation ทำ transaction เมื่อจำเป็น และไม่เปิดเผยว่า user เป้าหมายมีอยู่หรือไม่เกินข้อมูลที่ route อนุญาต

## Files and boundaries

Backend:

- `bn/src/routes/auth_routes.php` — login/me/change-password และลบ OTP routes
- `bn/src/routes/admin_routes.php` — existing inspector workflow plus super admin user/settings/audit routes
- `bn/src/auth.php` และ `bn/src/helpers.php` — role guards and authorization helpers
- `bn/schema.sql` และ migration — `super_admin`, `app_settings`, indexes/constraints
- `bn/src/demo_seeder.php` หรือ server bootstrap utility — local/demo super admin setup without hardcoded production secret
- `bn/tests/*` — authorization and account-management regressions

Flutter:

- `fn/safevege/lib/models/app_models.dart` — add `UserRole.superAdmin`
- `fn/safevege/lib/data/repositories/safevege_repository.dart` — role parsing and admin management API methods
- `fn/safevege/lib/state/remote_app_state.dart` — super admin state, user/settings/audit operations, remove OTP methods
- `fn/safevege/lib/screens/admin/admin_login_screen.dart` and `shop_login_screen.dart` — remove recovery entry and route by role
- `fn/safevege/lib/screens/admin/super_admin_dashboard_screen.dart` — new protected console
- `fn/safevege/lib/screens/admin/*` — reuse inspector screens only where role policy allows
- `fn/safevege/lib/screens/common/account_recovery_screen.dart` — remove from active product flow and delete demo helper UI
- Flutter tests — role parsing, menu gating, user-management payloads and OTP removal regressions

## Testing strategy

- TDD cycle for each role/endpoint/UI behavior: write a failing regression test, run it, implement the smallest change, run the focused test, then run the full suite
- PHP tests cover: `super_admin` authorization, inspector/admin separation, last-super-admin guard, user creation, password reset session revocation, settings allow-list, audit records, and removal of OTP routes
- Flutter tests cover: role mapping, super admin menu visibility, inspector menu exclusion, repository payloads, and absence of recovery actions on login screens
- Run `flutter analyze`, `flutter test`, PHP helper/CORS tests, and integration tests where the environment has the required MySQL PDO driver
- If the current PHP CLI still lacks `pdo_mysql`, report that integration limitation separately instead of treating unexecuted DB tests as passing

## Explicit non-goals

- ไม่ฝัง password พิเศษ, API key หรือ bootstrap secret ใน Flutter
- ไม่ทำระบบ arbitrary settings ที่แก้ role guard, database, filesystem หรือ secrets จาก UI
- ไม่เปลี่ยนชื่อ role เดิม `admin` เพื่อรักษา compatibility; `admin` คือ Inspector Admin และเพิ่ม `super_admin` เป็น role ใหม่
- ไม่สร้าง SMS/email recovery provider เพราะผู้ใช้เลือกถอด OTP ออก
