import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import '../state/app_state.dart';
import '../models/app_models.dart';
import 'guest/explore_screen.dart';
import 'shop/shop_login_screen.dart';
import 'admin/admin_login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.appState,
    this.isFirstLaunch = false,
  });

  final AppState appState;
  final bool isFirstLaunch;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: canPop && !isFirstLaunch
          ? AppBar(
              title: const Text('เกี่ยวกับ SafeVege'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo (iOS Unclipped Squircle)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.borderOf(context),
                        width: 0.8,
                      ),
                      boxShadow: AppShadows.cardOf(context),
                    ),
                    child: Image.asset(
                      'assets/safevege_logo.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Brand title
                  Text(
                    'ยินดีต้อนรับสู่ SafeVege',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryOf(context),
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    'ค้นหาร้านค้าผักปลอดสารพิษที่ผ่านการตรวจสอบ\nพร้อมดูผลตรวจและเส้นทางไปยังร้านค้า',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textSecondaryOf(context),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Graphic feature badges (iOS Minimal Segment)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.borderOf(context),
                        width: 0.8,
                      ),
                      boxShadow: AppShadows.cardOf(context),
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _buildFeaturePill(
                          context,
                          CupertinoIcons.search,
                          'ค้นหาร้านค้า',
                        ),
                        Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                        _buildFeaturePill(
                          context,
                          CupertinoIcons.checkmark_seal_fill,
                          'ตรวจสอบผล',
                        ),
                        Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                        _buildFeaturePill(
                          context,
                          CupertinoIcons.location_fill,
                          'นำทาง',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Start Exploring (Guest G02)
                  FilledButton.icon(
                    onPressed: () {
                      appState.setRole(UserRole.guest);
                      if (canPop && !isFirstLaunch) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExploreScreen(appState: appState),
                          ),
                        );
                      }
                    },
                    icon: const Icon(CupertinoIcons.compass_fill, size: 20),
                    label: const Text('เริ่มต้นใช้งาน (ผู้ใช้ทั่วไป)'),
                  ),
                  const SizedBox(height: 12),

                  // Shop Login (S01)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShopLoginScreen(appState: appState),
                        ),
                      );
                    },
                    icon: const Icon(CupertinoIcons.building_2_fill, size: 18),
                    label: const Text('เข้าสู่ระบบร้านค้า'),
                  ),
                  const SizedBox(height: 10),

                  // Admin Login (A01)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminLoginScreen(appState: appState),
                        ),
                      );
                    },
                    icon: const Icon(CupertinoIcons.shield_fill, size: 18),
                    label: const Text('เข้าสู่ระบบผู้ดูแล'),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    'ผู้ใช้ทั่วไปสามารถเข้าถึงข้อมูลร้านค้าได้โดยไม่ต้องสมัครสมาชิก',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedOf(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }
}
