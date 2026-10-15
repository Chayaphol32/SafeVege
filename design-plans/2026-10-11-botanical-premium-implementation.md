# Botanical Premium Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox syntax for tracking. No delegation is required.

**Goal:** ยกระดับทุกหน้า SafeVege ตาม Botanical Premium ที่ผู้ใช้อนุมัติ พร้อม micro-animations และ Light/Dark ที่สอดคล้องกัน

**Architecture:** ปรับ AppTheme และ shared widgets ที่มีอยู่ก่อนขยายไปหน้าของแต่ละบทบาท รักษา AppState, repository, API และข้อมูลเดิม ใช้ motion primitives เดิมโดยไม่สร้างระบบ animation คู่ขนาน

**Tech Stack:** Flutter/Dart, Material 3, flutter_map, PHP APIs เดิม

## Global Constraints

- Approved spec: design-plans/2026-10-11-botanical-premium-redesign.md ที่ workspace root; อนุมัติวันที่ 11 ตุลาคม 2026
- ทุก path ของ product ด้านล่างอ้างอิงจาก fn/safevege; ทุก command รันใน directory นี้
- primary #0F5A3C, background #F5F6F2, surface #FFFEFC, accent #A6C85A
- spacing 4/8/12/16/24/32/48; padding mobile 20–24; card radius 18–24; input/button 14–16; primary height 52; touch target >=48
- Thai typography: heading 24–32, section 18–20, body 15–16, metadata 12–13; line height 1.45–1.6; ไม่บีบ letter spacing ไทย
- micro 150ms, stateChange 220ms, entrance 320ms, tabChange 200ms, easeOutCubic; exit 120–180ms easeInCubic
- viewport 360/390/768/1024/1440; rail เริ่ม 840; content max 1200; detail/form max 720
- Reduced motion ตัด scale/slide/stagger/pulse; แสดง final state ทันที
- ไม่เพิ่มคะแนนรีวิว favorites ขั้นตอน backend หรือข้อความรับรองความปลอดภัยที่ข้อมูลไม่มี
- เก็บข้อมูลเดิมระหว่าง refresh และแสดง error/retry ตามผลจริง
- ไม่ต้องเขียน unit test ที่สะท้อนค่าตกแต่งเท่านั้น; ทดสอบ interaction/state ที่มีโอกาส regression
- ใช้ graph tools ก่อนค้นหา source; index ใหม่หากผลเก่าไม่ตรง source
- ไม่ commit เอกสารหรือ code หากยังไม่ยืนยัน Git root; ไม่รวมไฟล์ผู้ใช้อื่นใน commit

## Task 1: Baseline และ visual reference

**Files:** Create: design-plans/botanical-premium-screen-matrix.md ที่ workspace root; เก็บภาพใน design-plans/botanical-premium-evidence/
**Consumes:** approved spec และ screen inventory
**Produces:** route/state/viewport matrix และ visual reference 4 หน้า

- [ ] ตรวจ runtime routes ผ่าน graph และ AppState ที่เปิดแต่ละบทบาท; ทำเครื่องหมาย wrapper/unreachable ด้วยเหตุผลและ caller
- [ ] บันทึก baseline feed, shop details, shop dashboard, admin request details ใน Light/Dark ที่ 390 และ 1440 พร้อมข้อมูลตัวอย่างเดิม
- [ ] สร้าง mockup 4 หน้าดังกล่าวตาม spec: feed ใช้ภาพร้านและ search เด่น; details ให้ผลตรวจและวันที่อยู่เหนือ CTA; shop dashboard เน้นงานที่ต้องทำ; admin request details ใช้ action area ชัดเจน
- [ ] ตรวจภาพเทียบ palette/type/spacing และแต่ละหน้ามี primary action ตามงานจริง ก่อนขยายไปทั้งแอป
- [ ] บันทึกทุกหน้าใน matrix: class, entry route, role, states, viewport, before/after evidence, completion status; ไม่รวมภาพ renderer ที่ยังไม่ได้เปิดตรวจ

## Task 2: Design foundations และ shared states

**Files:**
- Modify: lib/theme/app_theme.dart, lib/widgets/common_widgets.dart, pubspec.yaml
- Create: lib/theme/design_tokens.dart, assets/fonts/NotoSansThai-Variable.ttf, assets/fonts/OFL.txt
- Test existing: test/overflow_test.dart

**Consumes:** AppTheme, AppColors, AppDarkColors, AppShadows และ shared widget constructors เดิม
**Produces:** theme ทั้งสองโหมด; shared cards/input/buttons/badge/dialog/feedback ที่ใช้ API เดิม; spacing/radius tokens

- [ ] ตรวจ font จากแหล่งทางการและ license ก่อนบรรจุ; เก็บไฟล์ font และ license จริง ไม่เพิ่ม runtime font download
- [ ] เพิ่ม fonts ใน pubspec และตั้ง fontFamily ใน Light/Dark โดยคง fallback เดิม
- [ ] เพิ่ม owner สำหรับ spacing/radius ใน lib/theme/design_tokens.dart แล้วใช้กับ shared widgets ก่อนหน้ารายบทบาท:

```dart
abstract final class AppSpacing {
  static const double xs = 4, sm = 8, md = 12, lg = 16;
  static const double xl = 24, xxl = 32, section = 48;
}
abstract final class AppRadii {
  static const double control = 16, card = 24;
}
```

- [ ] ปรับ TextTheme ให้ body 16/15, metadata 13, heading 32/24, section 20/18; height 1.5 และ letterSpacing 0 สำหรับไทย
- [ ] ปรับ card/button/input/chip/navigation/dialog styles ใน AppTheme ตาม constraints; ไม่เปลี่ยน API ของ widget เพื่อการตกแต่ง
- [ ] ปรับ MarketplaceShopCard และ FeaturedFarmCard ให้ใช้ภาพอัตราส่วนคงที่และ fallback sage+store icon; ใช้ StatusBadge พร้อมข้อความและวันที่จริง
- [ ] ตรวจ EmptyStateView, AppFeedback และ ConfirmActionDialog ใน loading/empty/error/disabled; ไม่ให้ green badge แปลว่าปลอดภัยถ้า backend ไม่ระบุ
- [ ] รัน flutter analyze และ flutter test test/overflow_test.dart; ต้องไม่มี error และ overflow tests ผ่าน
- [ ] ตรวจภาพ shared components ในสองธีม พร้อมชื่อร้านไทยยาว ภาพเสีย และ text scale 2.0

## Task 3: Motion primitives

**Files:** Modify lib/widgets/interactive_animations.dart; create test/widgets/botanical_motion_test.dart
**Consumes:** MotionTokens, PressableScale และ SafeVegePageTransitionsBuilder
**Produces:** reduced-motion-safe primitive เดิมพร้อม interruption/cancel behavior

- [ ] เพิ่ม regression test ก่อนแก้ primitive สำหรับ PressableScale: press แล้ว AnimatedScale ลดลง, pointer cancel คืน 1, disabled ไม่เรียก callback และ disableAnimations ใช้ Duration.zero
- [ ] รัน flutter test test/widgets/botanical_motion_test.dart ให้เห็น failure สำหรับพฤติกรรมใหม่ที่ต้องแก้; หากพฤติกรรมมีอยู่แล้ว ใช้ test เป็น regression และไม่แก้โดยไม่มีเหตุ
- [ ] รักษา durations เดิมและ route fade/slide; reduced motion คืน child ทันที; cancel คืน state ไม่ว่าจะปล่อยออกนอกพื้นที่กดหรือเปลี่ยนหน้า
- [ ] เปลี่ยนการใช้ PulseBadge สำหรับ verified เป็น badge นิ่งใน consumers; ไม่ลบ primitive ถ้ายังมี consumers ที่จำเป็น
- [ ] จำกัด entrance stagger 35ms เฉพาะ 4 รายการแรก; ไม่ replay เมื่อ refresh/search; ปิด ticker ของหน้าที่ซ่อนด้วย TickerMode
- [ ] รัน motion test และ flutter analyze; ตรวจ tap รัว/back ระหว่าง transition และเปลี่ยน reduced motion ระหว่างเปิดหน้า
- [ ] เก็บหลักฐาน profile สำหรับ map และรายการยาว; ใช้ transform/opacity และไม่ animate blur/shadow บนพื้นที่ใหญ่

## Task 4: Public navigation

**Files — Modify:**
- lib/screens/main_navigation_screen.dart
- lib/screens/splash_screen.dart
- lib/screens/welcome_screen.dart
- lib/screens/guest/explore_screen.dart
- lib/screens/guest/explore_feed_tab.dart
- lib/screens/guest/explore_map_tab.dart

**Consumes:** approved spec, AppTheme และ shared widgets จาก Task 2; motion primitives จาก Task 3
**Produces:** screens เดิมและ constructor parameters เดิม พร้อม layout/state/motion ที่ตรวจแล้ว
**Dependencies:** Tasks 1–3; ดำเนินตามลำดับ journey ภายในชุด

- [ ] เปิด source ของแต่ละหน้าผ่าน graph และตรวจ constructor/callback/repository ที่ใช้อยู่ก่อนแก้; ไม่สมมติชื่อ method ใหม่
- [ ] ปรับ layout ตามนี้: ใช้ shell เดิมและ IndexedStack; feed เรียง search→filter→ร้าน; map มี search และ selected-shop sheet; splash ไม่เพิ่มเวลารอ; Welcome/Explore wrapper ต้องยืนยันเส้นทางจริง
- [ ] ใช้ theme/tokens/shared widgets เดิม และ padding/width ตาม Global Constraints; mobile ไม่ให้ table ล้น; desktop ให้ข้อมูลอ่านได้ในคอลัมน์ที่เหมาะสม
- [ ] ต่อ motion ตามนี้: tab indicator 200ms; entrance 320ms เฉพาะครั้งแรก; map ไม่ขยับกล้องจาก rebuild
- [ ] ตรวจ loading/empty/error/retry/disabled/success ที่แต่ละหน้ามีจริง; ฟอร์มรักษาค่าหลัง error และ feedback สำเร็จเกิดหลัง server response เท่านั้น
- [ ] ตรวจ journey ของชุดนี้ด้วยข้อมูลเดิมทั้ง Light/Dark ที่ 390 และ 1440 แล้วตรวจ layout 360/768/1024 และ text scale 2.0
- [ ] รัน flutter analyze และ flutter test test/overflow_test.dart test/certificate_readiness_test.dart; เพิ่ม behavioral regression เฉพาะเมื่อมีการแก้ navigation/state interaction
- [ ] บันทึก after screenshot ของแต่ละหน้าที่เข้าถึงได้และผลตรวจใน screen matrix; หน้าที่เข้าไม่ถึงต้องมี caller/route evidence ไม่ปล่อยผ่านเงียบ ๆ

## Task 5: Public details

**Files — Modify:**
- lib/screens/guest/shop_details_screen.dart
- lib/screens/guest/inspection_history_screen.dart
- lib/screens/guest/certificates_hub_tab.dart
- lib/screens/guest/certificate_viewer_screen.dart
- lib/screens/guest/route_navigation_screen.dart

**Consumes:** approved spec, AppTheme และ shared widgets จาก Task 2; motion primitives จาก Task 3
**Produces:** screens เดิมและ constructor parameters เดิม พร้อม layout/state/motion ที่ตรวจแล้ว
**Dependencies:** Tasks 1–3; ดำเนินตามลำดับ journey ภายในชุด

- [ ] เปิด source ของแต่ละหน้าผ่าน graph และตรวจ constructor/callback/repository ที่ใช้อยู่ก่อนแก้; ไม่สมมติชื่อ method ใหม่
- [ ] ปรับ layout ตามนี้: รายละเอียดเรียงภาพ→ชื่อและสถานะ→ผลตรวจพร้อมวันที่→ใบรับรอง→ติดต่อ/นำทาง; timeline อ่านค่าและหน่วยจริง; เอกสารรักษาสีต้นฉบับและเครื่องมือที่มี
- [ ] ใช้ theme/tokens/shared widgets เดิม และ padding/width ตาม Global Constraints; mobile ไม่ให้ table ล้น; desktop ให้ข้อมูลอ่านได้ในคอลัมน์ที่เหมาะสม
- [ ] ต่อ motion ตามนี้: route fade/slide 220–320ms; expand detail 220ms; เอกสารไม่ animate
- [ ] ตรวจ loading/empty/error/retry/disabled/success ที่แต่ละหน้ามีจริง; ฟอร์มรักษาค่าหลัง error และ feedback สำเร็จเกิดหลัง server response เท่านั้น
- [ ] ตรวจ journey ของชุดนี้ด้วยข้อมูลเดิมทั้ง Light/Dark ที่ 390 และ 1440 แล้วตรวจ layout 360/768/1024 และ text scale 2.0
- [ ] รัน flutter analyze และ flutter test test/overflow_test.dart test/certificate_readiness_test.dart; เพิ่ม behavioral regression เฉพาะเมื่อมีการแก้ navigation/state interaction
- [ ] บันทึก after screenshot ของแต่ละหน้าที่เข้าถึงได้และผลตรวจใน screen matrix; หน้าที่เข้าไม่ถึงต้องมี caller/route evidence ไม่ปล่อยผ่านเงียบ ๆ

## Task 6: Account and authentication

**Files — Modify:**
- lib/screens/common/account_portal_tab.dart
- lib/screens/common/account_recovery_screen.dart
- lib/screens/shop/shop_login_screen.dart
- lib/screens/admin/admin_login_screen.dart
- lib/screens/shop/shop_registration_screen.dart

**Consumes:** approved spec, AppTheme และ shared widgets จาก Task 2; motion primitives จาก Task 3
**Produces:** screens เดิมและ constructor parameters เดิม พร้อม layout/state/motion ที่ตรวจแล้ว
**Dependencies:** Tasks 1–3; ดำเนินตามลำดับ journey ภายในชุด

- [ ] เปิด source ของแต่ละหน้าผ่าน graph และตรวจ constructor/callback/repository ที่ใช้อยู่ก่อนแก้; ไม่สมมติชื่อ method ใหม่
- [ ] ปรับ layout ตามนี้: label ถาวร; error ใต้ช่อง; บทบาทแยกด้วยหัวเรื่อง; ฟอร์มจัดกลุ่มบัญชี ร้าน และตำแหน่ง; recovery ใช้ขั้นตอนที่ backend รองรับเท่านั้น; ไม่ล้างค่าฟอร์มเมื่อผิดพลาด
- [ ] ใช้ theme/tokens/shared widgets เดิม และ padding/width ตาม Global Constraints; mobile ไม่ให้ table ล้น; desktop ให้ข้อมูลอ่านได้ในคอลัมน์ที่เหมาะสม
- [ ] ต่อ motion ตามนี้: focus 150ms; state 220ms; registration step เปลี่ยนหลัง validation
- [ ] ตรวจ loading/empty/error/retry/disabled/success ที่แต่ละหน้ามีจริง; ฟอร์มรักษาค่าหลัง error และ feedback สำเร็จเกิดหลัง server response เท่านั้น
- [ ] ตรวจ journey ของชุดนี้ด้วยข้อมูลเดิมทั้ง Light/Dark ที่ 390 และ 1440 แล้วตรวจ layout 360/768/1024 และ text scale 2.0
- [ ] รัน flutter analyze และ flutter test test/overflow_test.dart test/certificate_readiness_test.dart; เพิ่ม behavioral regression เฉพาะเมื่อมีการแก้ navigation/state interaction
- [ ] บันทึก after screenshot ของแต่ละหน้าที่เข้าถึงได้และผลตรวจใน screen matrix; หน้าที่เข้าไม่ถึงต้องมี caller/route evidence ไม่ปล่อยผ่านเงียบ ๆ

## Task 7: Shop dashboard and profile

**Files — Modify:**
- lib/screens/shop/shop_dashboard_screen.dart
- lib/screens/shop/shop_profile_screen.dart
- lib/screens/shop/location_picker_screen.dart

**Consumes:** approved spec, AppTheme และ shared widgets จาก Task 2; motion primitives จาก Task 3
**Produces:** screens เดิมและ constructor parameters เดิม พร้อม layout/state/motion ที่ตรวจแล้ว
**Dependencies:** Tasks 1–3; ดำเนินตามลำดับ journey ภายในชุด

- [ ] เปิด source ของแต่ละหน้าผ่าน graph และตรวจ constructor/callback/repository ที่ใช้อยู่ก่อนแก้; ไม่สมมติชื่อ method ใหม่
- [ ] ปรับ layout ตามนี้: dashboard เรียงสถานะร้าน→งานต้องทำ→คำขอล่าสุด→ผลล่าสุด; profile แยก preview/แก้ไข; location มี pin และสรุปตำแหน่งพร้อมปุ่มยืนยัน
- [ ] ใช้ theme/tokens/shared widgets เดิม และ padding/width ตาม Global Constraints; mobile ไม่ให้ table ล้น; desktop ให้ข้อมูลอ่านได้ในคอลัมน์ที่เหมาะสม
- [ ] ต่อ motion ตามนี้: ข้อมูลใหม่ fade; ไม่ count-up ตัวเลขทุก refresh; pin settle เมื่อหยุดลาก
- [ ] ตรวจ loading/empty/error/retry/disabled/success ที่แต่ละหน้ามีจริง; ฟอร์มรักษาค่าหลัง error และ feedback สำเร็จเกิดหลัง server response เท่านั้น
- [ ] ตรวจ journey ของชุดนี้ด้วยข้อมูลเดิมทั้ง Light/Dark ที่ 390 และ 1440 แล้วตรวจ layout 360/768/1024 และ text scale 2.0
- [ ] รัน flutter analyze และ flutter test test/overflow_test.dart test/certificate_readiness_test.dart; เพิ่ม behavioral regression เฉพาะเมื่อมีการแก้ navigation/state interaction
- [ ] บันทึก after screenshot ของแต่ละหน้าที่เข้าถึงได้และผลตรวจใน screen matrix; หน้าที่เข้าไม่ถึงต้องมี caller/route evidence ไม่ปล่อยผ่านเงียบ ๆ

## Task 8: Shop request journey

**Files — Modify:**
- lib/screens/shop/create_request_screen.dart
- lib/screens/shop/my_requests_screen.dart
- lib/screens/shop/request_tracking_screen.dart
- lib/screens/shop/shop_results_screen.dart

**Consumes:** approved spec, AppTheme และ shared widgets จาก Task 2; motion primitives จาก Task 3
**Produces:** screens เดิมและ constructor parameters เดิม พร้อม layout/state/motion ที่ตรวจแล้ว
**Dependencies:** Tasks 1–3; ดำเนินตามลำดับ journey ภายในชุด

- [ ] เปิด source ของแต่ละหน้าผ่าน graph และตรวจ constructor/callback/repository ที่ใช้อยู่ก่อนแก้; ไม่สมมติชื่อ method ใหม่
- [ ] ปรับ layout ตามนี้: สร้างคำขอจัดกลุ่มข้อมูล/ผัก/ไฟล์/สรุป; รายการคำขอแสดงวันที่และสถานะ; tracking ใช้ timeline; ผลตรวจแสดงค่าหน่วยและคำอธิบายจริง
- [ ] ใช้ theme/tokens/shared widgets เดิม และ padding/width ตาม Global Constraints; mobile ไม่ให้ table ล้น; desktop ให้ข้อมูลอ่านได้ในคอลัมน์ที่เหมาะสม
- [ ] ต่อ motion ตามนี้: เพิ่มแถวและไฟล์ fade 220ms; filter crossfade; timeline highlight ครั้งเดียว
- [ ] ตรวจ loading/empty/error/retry/disabled/success ที่แต่ละหน้ามีจริง; ฟอร์มรักษาค่าหลัง error และ feedback สำเร็จเกิดหลัง server response เท่านั้น
- [ ] ตรวจ journey ของชุดนี้ด้วยข้อมูลเดิมทั้ง Light/Dark ที่ 390 และ 1440 แล้วตรวจ layout 360/768/1024 และ text scale 2.0
- [ ] รัน flutter analyze และ flutter test test/overflow_test.dart test/certificate_readiness_test.dart; เพิ่ม behavioral regression เฉพาะเมื่อมีการแก้ navigation/state interaction
- [ ] บันทึก after screenshot ของแต่ละหน้าที่เข้าถึงได้และผลตรวจใน screen matrix; หน้าที่เข้าไม่ถึงต้องมี caller/route evidence ไม่ปล่อยผ่านเงียบ ๆ

## Task 9: Admin review and scheduling

**Files — Modify:**
- lib/screens/admin/admin_dashboard_screen.dart
- lib/screens/admin/inspection_requests_screen.dart
- lib/screens/admin/admin_request_details_screen.dart
- lib/screens/admin/inspection_scheduling_screen.dart

**Consumes:** approved spec, AppTheme และ shared widgets จาก Task 2; motion primitives จาก Task 3
**Produces:** screens เดิมและ constructor parameters เดิม พร้อม layout/state/motion ที่ตรวจแล้ว
**Dependencies:** Tasks 1–3; ดำเนินตามลำดับ journey ภายในชุด

- [ ] เปิด source ของแต่ละหน้าผ่าน graph และตรวจ constructor/callback/repository ที่ใช้อยู่ก่อนแก้; ไม่สมมติชื่อ method ใหม่
- [ ] ปรับ layout ตามนี้: dashboard เน้นงานรอ; desktop ใช้ตารางตามพื้นที่ mobile ใช้ card; รายละเอียดเรียงร้าน/คำขอ/เอกสาร/ประวัติ/action; นัดหมายใช้วันเวลาที่ระบบรองรับ
- [ ] ใช้ theme/tokens/shared widgets เดิม และ padding/width ตาม Global Constraints; mobile ไม่ให้ table ล้น; desktop ให้ข้อมูลอ่านได้ในคอลัมน์ที่เหมาะสม
- [ ] ต่อ motion ตามนี้: selected row/chip 220ms; dialog 220ms; selected date 150ms
- [ ] ตรวจ loading/empty/error/retry/disabled/success ที่แต่ละหน้ามีจริง; ฟอร์มรักษาค่าหลัง error และ feedback สำเร็จเกิดหลัง server response เท่านั้น
- [ ] ตรวจ journey ของชุดนี้ด้วยข้อมูลเดิมทั้ง Light/Dark ที่ 390 และ 1440 แล้วตรวจ layout 360/768/1024 และ text scale 2.0
- [ ] รัน flutter analyze และ flutter test test/overflow_test.dart test/certificate_readiness_test.dart; เพิ่ม behavioral regression เฉพาะเมื่อมีการแก้ navigation/state interaction
- [ ] บันทึก after screenshot ของแต่ละหน้าที่เข้าถึงได้และผลตรวจใน screen matrix; หน้าที่เข้าไม่ถึงต้องมี caller/route evidence ไม่ปล่อยผ่านเงียบ ๆ

## Task 10: Admin results and history

**Files — Modify:**
- lib/screens/admin/record_result_screen.dart
- lib/screens/admin/result_management_screen.dart
- lib/screens/admin/shop_management_screen.dart
- lib/screens/admin/admin_shop_details_screen.dart
- lib/screens/admin/admin_history_screen.dart

**Consumes:** approved spec, AppTheme และ shared widgets จาก Task 2; motion primitives จาก Task 3
**Produces:** screens เดิมและ constructor parameters เดิม พร้อม layout/state/motion ที่ตรวจแล้ว
**Dependencies:** Tasks 1–3; ดำเนินตามลำดับ journey ภายในชุด

- [ ] เปิด source ของแต่ละหน้าผ่าน graph และตรวจ constructor/callback/repository ที่ใช้อยู่ก่อนแก้; ไม่สมมติชื่อ method ใหม่
- [ ] ปรับ layout ตามนี้: บันทึกผลจัดกลุ่มค่าและหน่วย/เอกสาร/สรุป; จัดการผลและร้านมี filter; รายละเอียดร้านแยกข้อมูล ประวัติ ใบรับรอง; ประวัติแสดงวันที่จริง
- [ ] ใช้ theme/tokens/shared widgets เดิม และ padding/width ตาม Global Constraints; mobile ไม่ให้ table ล้น; desktop ให้ข้อมูลอ่านได้ในคอลัมน์ที่เหมาะสม
- [ ] ต่อ motion ตามนี้: status crossfade หลัง server ยืนยัน; detail expand 220ms; ไม่ replay รายการเก่า
- [ ] ตรวจ loading/empty/error/retry/disabled/success ที่แต่ละหน้ามีจริง; ฟอร์มรักษาค่าหลัง error และ feedback สำเร็จเกิดหลัง server response เท่านั้น
- [ ] ตรวจ journey ของชุดนี้ด้วยข้อมูลเดิมทั้ง Light/Dark ที่ 390 และ 1440 แล้วตรวจ layout 360/768/1024 และ text scale 2.0
- [ ] รัน flutter analyze และ flutter test test/overflow_test.dart test/certificate_readiness_test.dart; เพิ่ม behavioral regression เฉพาะเมื่อมีการแก้ navigation/state interaction
- [ ] บันทึก after screenshot ของแต่ละหน้าที่เข้าถึงได้และผลตรวจใน screen matrix; หน้าที่เข้าไม่ถึงต้องมี caller/route evidence ไม่ปล่อยผ่านเงียบ ๆ

## Task 11: End-to-end acceptance

**Files:** Update design-plans/botanical-premium-screen-matrix.md และ evidence ที่ workspace root; แก้เฉพาะ product files ที่มี failure พิสูจน์แล้ว
**Consumes:** screens ทั้งหมดจาก Tasks 4–10
**Produces:** completed screen matrix และ verification report

- [ ] เทียบทุก row ใน approved spec กับ matrix ต้องครบ 32 screen/tab files ที่ค้นพบ รวม wrapper ที่ตรวจยืนยันแล้ว
- [ ] ตรวจ guest: สำรวจ→ร้าน→ผลตรวจ→ใบรับรอง→นำทาง; shop: login/register→profile→request→tracking→results; admin: login→request→schedule→record→history
- [ ] ตรวจ keyboard/focus, safe area, error response, long Thai text, image fallback, text scale 1.0/1.5/2.0 และ reduced motion ทุกชุด
- [ ] รัน flutter analyze และ flutter test จาก fn/safevege; ต้องตรวจ exit code และรายละเอียด failure ไม่อ้างว่าผ่านจากการเริ่ม command
- [ ] รัน flutter build apk --debug เมื่อ Android toolchain พร้อม; หากเป้าหมายจริงเป็น web ให้ใช้ flutter build web --debug และตรวจ runtime บน web; บันทึก platform limitation เมื่อ build ไม่ได้
- [ ] ตรวจ profile mode map/dashboard/รายการยาวบนอุปกรณ์เป้าหมาย; รายงาน frame time และการตอบสนองจริง แยกจาก debug measurements
- [ ] ตรวจ diff ให้เฉพาะงาน redesign; ไม่เปลี่ยน PHP APIs, auth privileges หรือความหมายผลตรวจ
- [ ] สรุปจำนวนหน้าที่ตรวจจริง ผล tests/build/profile และข้อจำกัดที่ยังมี ไม่เรียกงานเสร็จหากมีหน้าที่ไม่ได้ตรวจและยังไม่ยืนยันว่าไม่ใช้งาน

## Execution status

ผู้ใช้อนุมัติทิศทาง Botanical Premium และสั่งให้ปรับ UI จริงในบทสนทนานี้แล้ว จึงลงมือแก้ product source โดยคง AppState, repository, API และข้อมูลเดิมไว้ ผลการทำงานที่ตรวจแล้วอยู่ใน [screen coverage matrix](botanical-premium-screen-matrix.md) งานที่ยังไม่มีหลักฐานภาพจริงหรือ profile-mode ระบุไว้เป็นข้อจำกัด ห้ามทำเครื่องหมายเสร็จจาก theme เพียงอย่างเดียว

## Self-review

Coverage: Task 1 baseline/mockups; Task 2 color/type/components/fonts/shared states; Task 3 motion/performance/reduced motion; Tasks 4–10 every screen/tab; Task 11 responsive/flows/verification. Existing class constructors และ callbacks ต้องรักษาไว้ การเปลี่ยน code รายหน้าให้เขียนหลังอ่าน source ปัจจุบัน ไม่ใช้ snippets ที่เดาชื่อ API ขึ้นมา

