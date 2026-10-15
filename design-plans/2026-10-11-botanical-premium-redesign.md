# SafeVege — Botanical Premium UI Redesign

วันที่: 11 ตุลาคม 2026
สถานะ: ผู้ใช้อนุมัติดีไซน์วันที่ 11 ตุลาคม 2026; ยังไม่เริ่มแก้ UI
ทิศทางที่ผู้ใช้เลือก: Botanical Premium — เขียวเข้ม ครีม ภาพร้านเด่น เรียบหรู
Written against: commit unavailable; workspace root is not a Git repository.

## เป้าหมายและหลักฐาน

ออกแบบใหม่ทุกหน้าของ Flutter SafeVege ทั้งผู้ใช้ทั่วไป ร้านค้า และผู้ดูแล ให้แบรนด์เดียวกัน แต่ปรับความหนาแน่นตามงานของแต่ละบทบาท พร้อม micro-animations ที่อธิบายการเปลี่ยนสถานะและตอบสนองการกระทำ

ตรวจผ่าน codebase-memory-mcp: main.dart ใช้ AppTheme.lightTheme/darkTheme และ SplashScreen/MainNavigationScreen; MainNavigationScreen ประกอบ ExploreFeedTab, ExploreMapTab, AccountPortalTab และเปิด CertificatesHubTab ได้ ปัจจุบันใช้ NavigationRail เมื่อกว้างตั้งแต่ 840 ขึ้นไป และ IndexedStack รักษาแท็บไว้

เจ้าของฐานดีไซน์: fn/safevege/lib/theme/app_theme.dart มี AppColors, AppDarkColors, AppGradients, AppShadows, AppTheme; fn/safevege/lib/widgets/common_widgets.dart มี MarketplaceShopCard, FeaturedFarmCard, StatusBadge, EmptyStateView, ConfirmActionDialog, AppFeedback; interactive_map.dart มี SafeVegeInteractiveMap

อ่าน interactive_animations.dart โดยตรงหลัง graph ค้นหา MotionTokens ไม่พบ: มี MotionTokens, SafeVegePageTransitionsBuilder, PressableScale, PulseBadge และตรวจ disableAnimations อยู่แล้ว

เอกสารเดิม docs/superpowers/plans/2026-10-11-premium-ui-motion.md เป็นแผนทั่วไป เอกสารนี้ขยายเป็นข้อเสนอรายหน้า ไม่ถือว่าแผนเดิมเป็น design contract ที่ยืนยันแล้ว ไม่มีภาพ runtime ที่ตรวจในรอบนี้ จึงไม่อ้างว่าหน้าปัจจุบันมีปัญหาด้านความสวยหรือ usability ที่พิสูจน์แล้ว ต้องตรวจ mockup และหน้าจอจริงก่อนลงมือ

## ทางเลือกและข้อสรุป

1. Botanical Premium (เลือก): เขียว evergreen พื้นครีม ภาพร้านใหญ่และหลักฐานผลตรวจชัด เหมาะกับตัวตน SafeVege ต้องมีแนวทางภาพและ fallback ที่ดี
2. Modern Minimal: ขาวโปร่ง ข้อมูลกระชับ พัฒนาได้ง่าย แต่เอกลักษณ์ธรรมชาติน้อยกว่า
3. Dark Luxury: พื้นเข้มและ accent เด่น เหมาะกับภาพลักษณ์หรู แต่ข้อมูลตรวจจำนวนมากต้องควบคุม contrast และความล้า

ใช้ข้อ 1 เป็นฐานทั้ง Light/Dark; Dark ใช้ forest charcoal และเขียวอ่อนที่อ่านง่าย ไม่เพิ่ม glow ทั่วหน้า

## ระบบภาพรวมที่เสนอ

- รักษาสีฐานที่มี: primary #0F5A3C, background #F5F6F2, surface #FFFEFC, accent #A6C85A; ใช้ accent เฉพาะ highlight ไม่ใช้แทนสีสถานะ
- พรีเมียมผ่านลำดับข้อมูล พื้นที่ว่าง ภาพคุณภาพดี และรายละเอียดเส้นขอบ ใช้ gradient เฉพาะ hero สำคัญหนึ่งจุดต่อหน้า
- Typography เสนอให้บรรจุ Noto Sans Thai เป็น font หลักในแอปหลังตรวจ license และขนาดไฟล์ แทนการพึ่ง fallback ของเครื่อง; heading 24–32, section 18–20, body 15–16, metadata 12–13; line-height ไทย 1.45–1.6 และไม่บีบ letter spacing ภาษาไทย
- Spacing scale 4/8/12/16/24/32/48; padding มือถือ 20–24; card radius 18–24, input/button 14–16, chip แบบ pill; ปุ่มหลักสูง 52 และพื้นที่แตะอย่างน้อย 48
- การ์ดร้านใช้ภาพอัตราส่วนคงที่ ชื่อร้าน ตำแหน่ง ข้อมูลระยะทางเมื่อมีจริง และสถานะตรวจพร้อมวันที่ ไม่สร้างข้อมูลความปลอดภัยหรือคะแนนเพิ่มเอง
- Badge ใช้ icon + ข้อความ + สี แยกสถานะคำขอ ผลตรวจ และใบรับรอง ไม่สื่อว่าปลอดภัยจากสีเขียวอย่างเดียว
- รูปไม่มี/โหลดไม่สำเร็จใช้พื้น sage และ icon ร้าน ห้ามใช้ภาพผักสวยเพื่อแอบอ้างว่าเป็นภาพร้านจริง
- Light/Dark ใช้ semantic roles เดียวกัน; รูป เอกสาร และแผนที่รักษาสีข้อมูลต้นฉบับ
- Mobile <600: คอลัมน์เดียวและ bottom navigation; 600–839: grid ตามพื้นที่; >=840: rail และพื้นที่เนื้อหาสูงสุดประมาณ 1200; detail/form จำกัดประมาณ 720 และแยกสองคอลัมน์เฉพาะเมื่ออ่านได้
- ให้ desktop ใช้ hover/focus และ mobile ใช้ press; ไม่วางข้อมูลจำเป็นไว้ใน hover

## แผนทุกหน้าและแท็บ

ชื่อด้านล่างอ้างอิง class/file ที่พบใน graph; ต้องยืนยันเส้นทางเข้าถึงจริงอีกครั้งก่อนทำแต่ละชุด โดยเฉพาะ WelcomeScreen และ ExploreScreen ที่อาจเป็น wrapper/เส้นทางสำรอง

| หน้าหรือแท็บ | โครงสร้างใหม่ | Micro-animation |
|---|---|---|
| SplashScreen | โลโก้กลาง พื้นครีม/forest และสถานะเริ่มต้นเมื่อจำเป็น | fade/scale ครั้งเดียว ไม่มี delay เพิ่มเพื่อโชว์ animation |
| WelcomeScreen | ภาพ/โลโก้ หัวเรื่องสั้น ตัวเลือกใช้งานที่ชัด | hero fade แล้ว CTA ตาม ไม่เล่นวน |
| MainNavigationScreen | shell และ active indicator เดียวกันทุกขนาด รักษาสถานะแท็บ | indicator 200ms; fade เนื้อหาโดยไม่สร้างแท็บใหม่ |
| ExploreScreen / ExploreFeedTab | header กระชับ search เด่น ตัวกรอง ร้านและหลักฐานตรวจใน card | chip state 220ms; entrance เฉพาะชุดแรก |
| ExploreMapTab | แผนที่เต็มพื้นที่ search ด้านบน ร้านที่เลือกใน bottom sheet; desktop list ข้าง map | marker selection + sheet 220–320ms; ไม่ replay map |
| AccountPortalTab | สรุปบัญชี/บทบาท กลุ่มเมนู การตั้งค่าธีม และออกจากระบบแยกชัด | theme/state fade; ปุ่มตอบสนองสั้น |
| CertificatesHubTab | ค้นหา/กรอง รายการใบรับรองและสถานะพร้อมวันที่จริง | crossfade รายการเมื่อเปลี่ยนตัวกรอง |
| ShopDetailsScreen | รูปร้าน ชื่อ/สถานะ ข้อมูลติดต่อ ผลตรวจ ใบรับรอง และปุ่มนำทาง | รูป shared transition ถ้าข้อมูลและ tag ตรงกัน |
| InspectionHistoryScreen | สรุปล่าสุด timeline ผลตรวจและรายละเอียดแต่ละรายการ | expand/fade รายละเอียด ไม่ animate ทั้งประวัติ |
| CertificateViewerScreen | เอกสารเด่น metadata และเครื่องมือดู/ดาวน์โหลดตามที่มี | toolbar fade; ไม่ animate ตัวเอกสาร |
| RouteNavigationScreen | แผนที่ จุดหมาย สรุปเส้นทาง และ CTA เปิดนำทาง | สรุปข้อมูล fade; ไม่ขยับกล้องเพราะ rebuild |
| ShopLoginScreen / AdminLoginScreen | แบบฟอร์มตระกูลเดียวกัน แยกหัวเรื่องบทบาท label ถาวร error ใต้ช่อง | focus border; loading→success เมื่อผลจริงกลับมา |
| AccountRecoveryScreen | คำอธิบายและขั้นตอนที่ backend รองรับ CTA เด่น | state crossfade; ไม่เพิ่ม recovery flow ที่ยังไม่มี |
| ShopRegistrationScreen | กลุ่มข้อมูลบัญชี/ร้าน/ตำแหน่ง progress ที่สะท้อนขั้นตอนจริง | step transition 220ms หลัง validation |
| ShopDashboardScreen | สรุปสถานะร้าน งานที่ต้องทำ คำขอล่าสุด และผลล่าสุด | fade ของข้อมูลใหม่; ไม่ count-up ทุก refresh |
| ShopProfileScreen | preview ร้านและส่วนแก้ไขแยกกลุ่ม จุดบันทึกชัด | preview crossfade; บันทึกสำเร็จ feedback สั้น |
| LocationPickerScreen | แผนที่ pin กลาง สรุปตำแหน่ง ปุ่มยืนยันที่มองเห็น | pin settle เฉพาะจบการลาก; ปิดเมื่อ reduced motion |
| CreateRequestScreen | กลุ่มข้อมูล รายการผัก เอกสารแนบ และสรุปก่อนส่ง | เพิ่มแถว/ไฟล์ fade; progress ตามอัปโหลดจริง |
| MyRequestsScreen | ตัวกรองสถานะ card มีวันที่และ next step ที่มีข้อมูลจริง | chip indicator + list crossfade |
| RequestTrackingScreen | สถานะปัจจุบัน ขั้นตอนถัดไป timeline และรายละเอียด | highlight ขั้นปัจจุบันครั้งเดียว; ไม่ pulse ถาวร |
| ShopResultsScreen | ผลล่าสุด รายการตรวจ ค่า/หน่วยและคำอธิบายจากข้อมูลจริง | result detail expand; ไม่ animate ค่าจนอ่านคลาดเคลื่อน |
| AdminDashboardScreen | overview งานรอ รายการต้องดำเนินการ และทางลัด | สถานะใหม่ fade; ตัวเลขอัปเดตทันที |
| InspectionRequestsScreen | filter bar รายการคำขอและ metadata ชัด; desktop ใช้ตารางเมื่อเหมาะ | selected row และ filter 220ms |
| AdminRequestDetailsScreen | สรุปคำขอ ข้อมูลร้าน เอกสาร ประวัติ และ action area | panel fade; confirmation dialog scale/fade |
| InspectionSchedulingScreen | วันนัดและสรุปร้าน ตัวเลือกเวลาที่ backend รองรับ | selected date/time 150–220ms |
| RecordResultScreen | กลุ่มผลตรวจ หน่วย แนบเอกสาร สรุปและบันทึก | เพิ่มรายการ fade; inline validation ไม่สั่นฟอร์ม |
| ResultManagementScreen | รายการผลตรวจ filter และ action ที่ชัด | status crossfade หลังบันทึกสำเร็จ |
| ShopManagementScreen | รายการร้านค้นหาได้ สถานะและการจัดการแยกจากกัน | row/card selection feedback |
| AdminShopDetailsScreen | summary ร้าน tabs ข้อมูล/ประวัติ/ใบรับรองตามข้อมูลที่มี | tab indicator และ detail fade |
| AdminHistoryScreen | activity/history timeline พร้อม filter และวันที่ | expand detail; รายการเก่าไม่เล่น entrance ซ้ำ |

## Motion specification

ใช้ MotionTokens เดิมเป็นฐาน: micro 150ms, stateChange 220ms, entrance 320ms, tabChange 200ms, easeOutCubic; exit เสนอ 120–180ms easeInCubic

| Trigger | การเคลื่อนไหว | ข้อกำหนด |
|---|---|---|
| กดปุ่ม/การ์ด | scale 1→0.985→1, 150ms | ใช้ PressableScale; cancel คืนสภาพ และปุ่ม disabled ไม่ตอบสนอง |
| เลือก chip/tab | สีและ indicator 200–220ms | เปลี่ยนสถานะทันที ไม่รอ animation ก่อนใช้ข้อมูล |
| เปิดหน้า | fade + translate 8–12px, 220–320ms | ใช้ SafeVegePageTransitionsBuilder; ตรวจ back gesture |
| เปิด dialog/sheet | opacity + scale 0.98→1 หรือ slide ตามตำแหน่ง, 220ms | ปิดได้ระหว่าง animation และรักษา focus |
| เข้าเนื้อหาครั้งแรก | fade + rise 8px, 320ms | stagger 35ms เฉพาะ 4 รายการแรก; งด replay หลังค้นหา/refresh |
| โหลดข้อมูล | skeleton ตามโครง layout | ไม่ทำแสงวิ่งทั่วหน้า; reduced motion ใช้ skeleton นิ่ง |
| บันทึกสำเร็จ | check icon + feedback, 220ms | แสดงเมื่อ server ยืนยัน; ระบุ error เมื่อไม่สำเร็จ |
| แผนที่เลือก marker | outline/scale สั้นและ sheet เปลี่ยนร้าน | ไม่ animate marker ทุกตัว และรักษากล้องของผู้ใช้ |

PulseBadge ไม่ควรเล่นวนเพื่อบอก verified เพราะใบรับรองเป็นสถานะคงที่; เสนอใช้ badge นิ่ง ใช้ motion ชั่วคราวเฉพาะสถานะที่เพิ่งเปลี่ยนจริง

Reduced motion: ตัด scale/slide/stagger/pulse และแสดง final state ทันที; loading และ error ยังมีข้อความชัด Animations ต้องไม่ขวาง tap การเลื่อน หรือการกลับหน้า เคารพการเปลี่ยนค่าระหว่างใช้งาน

หยุด ticker ของแท็บที่ไม่แสดงและ controller เมื่อ dispose; ใช้ opacity/transform เป็นหลัก ไม่ animate blur/shadow พื้นที่ใหญ่และไม่ rebuild แผนที่ทุกเฟรม ตั้งเป้า frame budget ประมาณ 16.7ms บนอุปกรณ์ 60Hz และตรวจ profile จริง

## Shared states และภาษา

ทุกหน้าที่โหลดข้อมูลต้องมี loading, empty, error/retry, success และ disabled ตามบริบท; ถ้า refresh ขณะมีข้อมูลให้แสดงข้อมูลเดิมพร้อมสถานะโหลด ไม่ล้างทั้งหน้า ฟอร์มต้องครอบคลุมคีย์บอร์ด การส่งซ้ำ error และข้อความไทยยาว

ข้อความปุ่มใช้กริยาเฉพาะ เช่น ส่งคำขอตรวจ บันทึกผลตรวจ ดูใบรับรอง; ป้ายสถานะตรงกับข้อมูล backend และไม่เปลี่ยนผลตรวจให้เป็นคำโฆษณา ความปลอดภัยและวันที่ต้องไม่ถูกสรุปเกินข้อมูลที่มี

## การนำไปทำและการใช้ของเดิม

1. ยืนยัน inventory กับ runtime และทำ baseline screenshots: public, shop, admin, ทุกหน้าที่เข้าถึงได้ รวม Light/Dark และ dialog/sheet
2. ทำ mockup ตัวแทน 4 หน้า: feed, shop details, shop dashboard, admin request details เพื่อยืนยัน palette/type/card/form/motion ร่วมกันก่อนขยาย
3. ปรับ AppTheme และ shared widgets เดิม; แยก token spacing/type/radius เป็นเจ้าของร่วมเมื่อของเดิมยังไม่มี ไม่สร้างระบบธีมคู่ขนาน
4. ออกแบบ shell และ public journey: สำรวจ→ร้าน→ผลตรวจ→ใบรับรอง→นำทาง รวมบัญชีและ auth
5. ออกแบบ shop journey: ลงทะเบียน→โปรไฟล์→สร้างคำขอ→ติดตาม→ดูผล
6. ออกแบบ admin journey: คำขอ→รายละเอียด→นัดหมาย→บันทึกผล→จัดการและประวัติ
7. เติม motion ผ่าน primitive เดิม ตรวจ reduced motion ทุกกลุ่ม และแก้ภาพ fallback/สถานะที่ยังไม่ครบ
8. ตรวจทุกหน้าและทุก flow เทียบ mockup พร้อมเก็บ screenshot หลังทำให้ครบ

แต่ละชุดต้องส่ง: mockup/screen specification, token/component ที่ใช้, mapping ไปยังไฟล์, state matrix, motion trigger และหลักฐานตรวจหน้าจอ ก่อนย้ายไปชุดถัดไป

ขอบเขตเป็น presentation และ interaction feedback ใช้ AppState, repositories, PHP APIs และข้อมูลเดิม หากการออกแบบต้องเพิ่มข้อมูล/สิทธิ์/ขั้นตอนที่ backend ไม่มี ให้ยกเป็นข้อเสนอแยก ไม่สมมติว่าทำได้

## เกณฑ์ผ่านก่อนถือว่าเสร็จ

- Inventory ทุกหน้า/แท็บมีภาพหลังปรับ หรือระบุและพิสูจน์ว่าเป็น wrapper/เส้นทางที่ไม่ใช้งาน; ห้ามสรุปว่าครบจากการเปลี่ยน theme อย่างเดียว
- ตรวจ 360, 390, 768, 1024, 1440 logical pixels ทั้ง Light/Dark; keyboard, safe areas, long Thai text, text scale 1.0/1.5/2.0 และรูปไม่มี
- ทุก flow เดิมสำเร็จด้วยข้อมูลจริง/fixture ที่ครอบคลุม loading, empty และ server error; คำขอและผลตรวจไม่เปลี่ยนความหมาย
- navigation รักษา scroll/search และไม่โหลดแผนที่ใหม่โดยไม่จำเป็น; tap รัว ยกเลิก และย้อนกลับระหว่าง transition ไม่ทำให้หน้าค้าง
- รองรับ keyboard/focus, readable contrast และไม่ใช้สีอย่างเดียวบอกผล; จุดกดขั้นต่ำ 48 logical pixels
- reduced motion ปิด nonessential motion ทุก primitive และทุกหน้าที่ใช้
- ตรวจ profile mode บนอุปกรณ์เป้าหมาย โดยเฉพาะ map, dashboard และรายการยาว
- จาก fn/safevege: flutter analyze; flutter test รวม overflow_test.dart และ certificate_readiness_test.dart; build debug บนแพลตฟอร์มเป้าหมายที่ตั้งค่าไว้ ต้องตรวจผลจริงก่อนอ้างว่าผ่าน

## สิ่งที่ต้องตัดสินใจก่อน implementation

ผู้ใช้อนุมัติรายละเอียดในเอกสารนี้แล้ววันที่ 11 ตุลาคม 2026 ใช้เป็นฐาน implementation โดยไม่ต้องขออนุมัติทิศทางเดิมซ้ำ ไม่ต้องเพิ่ม onboarding, favorites, ratings หรือ dark-only experience เพื่อทำให้พรีเมียม

เอกสารนี้เป็นแผน redesign ไม่ใช่รายงานข้อบกพร่องที่ตรวจด้วย rendered evidence; หลังอนุมัติจึงแตกเป็น implementation tasks ตามไฟล์และ dependencies ของแต่ละชุด
