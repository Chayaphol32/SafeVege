import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import 'shop_registration_screen.dart';
import 'shop_dashboard_screen.dart';
import '../admin/admin_login_screen.dart';
import '../guest/explore_screen.dart';

class ShopLoginScreen extends StatefulWidget {
  const ShopLoginScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<ShopLoginScreen> createState() => _ShopLoginScreenState();
}

class _ShopLoginScreenState extends State<ShopLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      AppFeedback.showError(
        context,
        'กรอกชื่อผู้ใช้และรหัสผ่านก่อนเข้าสู่ระบบ',
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await widget.appState.loginShop(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'เข้าสู่ระบบร้านค้าสำเร็จ');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ShopDashboardScreen(appState: widget.appState),
        ),
      );
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(
          context,
          widget.appState.errorMessage ?? error.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text(
          'เข้าสู่ระบบร้านค้า',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.borderOf(context),
                        width: 0.8,
                      ),
                      boxShadow: AppShadows.cardOf(context),
                    ),
                    child: Image.asset(
                      'assets/safevege_logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'เข้าสู่ระบบร้านค้า',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryOf(context),
                    letterSpacing: 0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'จัดการข้อมูลร้านค้าและติดตามผลการตรวจสอบผัก',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Card container for inputs (iOS Inset Grouped)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.borderOf(context),
                      width: 0.8,
                    ),
                    boxShadow: AppShadows.cardOf(context),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อผู้ใช้',
                          hintText: 'กรอกชื่อผู้ใช้',
                          prefixIcon: Icon(CupertinoIcons.person, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'รหัสผ่าน',
                          hintText: 'กรอกรหัสผ่าน',
                          prefixIcon: const Icon(CupertinoIcons.lock, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? CupertinoIcons.eye_slash
                                  : CupertinoIcons.eye,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      FilledButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('เข้าสู่ระบบ'),
                      ),
                      const SizedBox(height: 10),

                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShopRegistrationScreen(
                              appState: widget.appState,
                            ),
                          ),
                        ),
                        child: const Text('สมัครสมาชิกร้านค้าใหม่'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Other Actions
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminLoginScreen(appState: widget.appState),
                        ),
                      ),
                      icon: const Icon(CupertinoIcons.shield, size: 16),
                      label: const Text('เข้าสู่ระบบผู้ดูแล'),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ExploreScreen(appState: widget.appState),
                        ),
                      ),
                      icon: const Icon(CupertinoIcons.search, size: 16),
                      label: const Text('กลับไปค้นหาร้านค้า'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
