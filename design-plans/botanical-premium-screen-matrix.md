# SafeVege Botanical Premium — Screen Coverage

ตรวจ inventory จาก codebase graph ได้ 32 screen/tab files รายการด้านล่างรับ design foundation จาก `AppTheme`, `AppColors`, typography, shared cards/forms/states และ page transitions ส่วนคอลัมน์สุดท้ายแยกการปรับเฉพาะหน้าที่ทำเพิ่มไว้ให้เห็นชัดเจน

| บทบาท | Screen / tab | การปรับเฉพาะหน้า |
|---|---|---|
| Admin | `lib/screens/admin/admin_dashboard_screen.dart` | NavigationRail เมื่อจอกว้าง, จำกัด content 1200 px, เปลี่ยนแท็บแบบ fade/lift และจัด metric/quick actions เป็น responsive grid |
| Admin | `lib/screens/admin/admin_history_screen.dart` | จำกัดพื้นที่รายการและตัวกรองไว้กึ่งกลาง ไม่เกิน 1120 px |
| Admin | `lib/screens/admin/admin_login_screen.dart` | ปรับ typography ให้เหมาะกับภาษาไทยและแบบฟอร์มพรีเมียม |
| Admin | `lib/screens/admin/admin_request_details_screen.dart` | จำกัดความกว้างหน้ารายละเอียดไว้ 720 px |
| Admin | `lib/screens/admin/admin_shop_details_screen.dart` | จำกัดความกว้างฟอร์ม/รายละเอียดไว้ 720 px |
| Admin | `lib/screens/admin/inspection_requests_screen.dart` | จำกัดพื้นที่รายการและตัวกรองไว้กึ่งกลาง ไม่เกิน 1120 px |
| Admin | `lib/screens/admin/inspection_scheduling_screen.dart` | จำกัดความกว้างหน้าจัดนัดหมายไว้ 720 px |
| Admin | `lib/screens/admin/record_result_screen.dart` | จำกัดความกว้างฟอร์มบันทึกผลไว้ 720 px |
| Admin | `lib/screens/admin/result_management_screen.dart` | จำกัดความกว้างหน้ารายละเอียดผลตรวจไว้ 720 px |
| Admin | `lib/screens/admin/shop_management_screen.dart` | จำกัดพื้นที่รายการร้านค้าและตัวกรองไว้กึ่งกลาง ไม่เกิน 1120 px |
| Common | `lib/screens/common/account_portal_tab.dart` | ปรับข้อความและ spacing ภาษาไทยให้สอดคล้องกับระบบใหม่ |
| Common | `lib/screens/common/account_recovery_screen.dart` | ใช้ foundation ร่วม; มี form width 480 px อยู่แล้ว |
| Guest | `lib/screens/guest/certificate_viewer_screen.dart` | จำกัดความกว้างหน้าเอกสารไว้ 720 px |
| Guest | `lib/screens/guest/certificates_hub_tab.dart` | จำกัดรายการไว้ 900 px และเพิ่ม staggered entrance ที่เคารพ reduced motion |
| Guest | `lib/screens/guest/explore_feed_tab.dart` | feed กว้างไม่เกิน 1080 px, ปรับลำดับภาพเด่น/หัวข้อ และระยะห่างการ์ดร้าน |
| Guest | `lib/screens/guest/explore_map_tab.dart` | ปรับตัวอักษรและ spacing; คงแผนที่เต็มพื้นที่ |
| Guest | `lib/screens/guest/explore_screen.dart` | ใช้ shell การนำทางและธีมร่วมของแอป |
| Guest | `lib/screens/guest/inspection_history_screen.dart` | จำกัดความกว้างหน้าประวัติไว้ 720 px |
| Guest | `lib/screens/guest/route_navigation_screen.dart` | ใช้สีพื้นผิวและสถานะร่วม; คงแผนที่นำทางเต็มพื้นที่ |
| Guest | `lib/screens/guest/shop_details_screen.dart` | จำกัดความกว้างหน้ารายละเอียดร้านไว้ 720 px |
| Shared | `lib/screens/main_navigation_screen.dart` | content กลางจอไม่เกิน 1200 px และลดความทึบของแถบนำทาง |
| Shop | `lib/screens/shop/create_request_screen.dart` | จำกัดความกว้างฟอร์มไว้ 720 px |
| Shop | `lib/screens/shop/location_picker_screen.dart` | ใช้ theme ร่วม; คงแผนที่เลือกพิกัดเต็มพื้นที่ |
| Shop | `lib/screens/shop/my_requests_screen.dart` | จำกัดพื้นที่รายการและตัวกรองไว้กึ่งกลาง ไม่เกิน 1120 px |
| Shop | `lib/screens/shop/request_tracking_screen.dart` | จำกัดความกว้างหน้าติดตามคำขอไว้ 720 px และปรับเส้น timeline ตามธีมมืด/สว่าง |
| Shop | `lib/screens/shop/shop_dashboard_screen.dart` | NavigationRail เมื่อจอกว้าง, จำกัด content 1200 px และเปลี่ยนแท็บแบบ fade/lift |
| Shop | `lib/screens/shop/shop_login_screen.dart` | ปรับ typography ให้เหมาะกับภาษาไทยและแบบฟอร์มพรีเมียม |
| Shop | `lib/screens/shop/shop_profile_screen.dart` | จำกัดความกว้างฟอร์มไว้ 720 px และปรับพื้นหลังช่องกรอกตามธีม |
| Shop | `lib/screens/shop/shop_registration_screen.dart` | จำกัดความกว้างฟอร์มไว้ 720 px |
| Shop | `lib/screens/shop/shop_results_screen.dart` | จำกัดความกว้างหน้าผลตรวจไว้ 720 px |
| Entry | `lib/screens/splash_screen.dart` | ปรับตัวอักษรและ spacing ให้ตรงกับแบรนด์ใหม่ |
| Entry | `lib/screens/welcome_screen.dart` | ปรับตัวอักษรและ spacing ให้ตรงกับแบรนด์ใหม่ |

## Shared behavior

- Light/Dark Botanical palette, Noto Sans Thai variable font, typography, spacing/radius tokens, card/input/button/dialog/navigation styles ใช้จาก theme กลาง
- route transitions, press feedback, tab switching และ entrance animation รองรับ `disableAnimations`
- ไม่มีการเปลี่ยน API, model, repository, สิทธิ์ผู้ใช้ หรือความหมายผลตรวจ
- `ShopModel` ยังไม่มี URL/field รูปร้าน การ์ดจึงใช้ภาพประกอบพฤกษศาสตร์แบบกลาง ไม่สื่อว่าเป็นภาพถ่ายของร้านจริง

## Verification and limits

- `flutter analyze`: ผ่าน ไม่มี issue
- `flutter test`: ผ่าน 32 tests รวม overflow ที่ 320–412 px และ responsive admin dashboard
- `flutter build web --release`: ผ่าน; ยืนยันหลังการแก้ไข UI ล่าสุด
- ตรวจ local release preview ด้วย browser ที่ 1280×720 แล้ว: แผนที่และ feed แสดงผลหลัง splash; feed ขณะตรวจมีร้าน 0 รายการ จึงยังไม่ได้ตรวจการ์ดร้านจริงใน browser และไม่ได้บันทึก screenshot ลง repo
- ยังไม่ได้ตรวจ Light mode ด้วย browser หรือเปิดทุก state/ทุก viewport ด้วยสายตา; overflow tests ครอบคลุมหน้าจอ 320–412 px และยังไม่ได้ทำ profile-mode frame-time measurement บนอุปกรณ์จริง
- ยังไม่ได้ทำ profile-mode frame-time measurement บนอุปกรณ์จริง
