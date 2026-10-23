import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import 'admin_dashboard_screen.dart';
import 'super_admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasPasswordError = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_errorMessage != null || _hasPasswordError) {
      setState(() {
        _errorMessage = null;
        _hasPasswordError = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty && password.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกชื่อผู้ใช้และรหัสผ่านก่อนเข้าสู่ระบบ';
        _hasPasswordError = true;
      });
      AppFeedback.showError(
        context,
        'กรุณากรอกชื่อผู้ใช้และรหัสผ่านก่อนเข้าสู่ระบบ',
      );
      return;
    }

    if (username.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกชื่อผู้ใช้ผู้ดูแลก่อนเข้าสู่ระบบ';
        _hasPasswordError = false;
      });
      AppFeedback.showError(context, 'กรุณากรอกชื่อผู้ใช้ก่อนเข้าสู่ระบบ');
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'กรุณากรอกรหัสผ่านก่อนเข้าสู่ระบบ';
        _hasPasswordError = true;
      });
      AppFeedback.showError(context, 'กรุณากรอกรหัสผ่านก่อนเข้าสู่ระบบ');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasPasswordError = false;
    });

    try {
      await widget.appState.loginAdmin(
        username,
        password,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'เข้าสู่ระบบผู้ดูแลสำเร็จ');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => widget.appState.isSuperAdmin
              ? SuperAdminDashboardScreen(appState: widget.appState)
              : AdminDashboardScreen(appState: widget.appState),
        ),
      );
    } catch (error) {
      if (mounted) {
        final rawMsg = widget.appState.errorMessage ?? error.toString();
        final displayMsg = AppState.localizeErrorMessage(rawMsg);
        final isAuthFailure = displayMsg.contains('รหัสผ่าน') ||
            displayMsg.contains('ชื่อผู้ใช้') ||
            rawMsg.toLowerCase().contains('credential');

        setState(() {
          _errorMessage = displayMsg;
          _hasPasswordError = isAuthFailure;
        });

        // แสดงแจ้งเตือนแถบล่าง SnackBar
        AppFeedback.showError(context, displayMsg);
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
          'เข้าสู่ระบบผู้ดูแล',
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
                  'เข้าสู่ระบบผู้ดูแลระบบ',
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
                  'ระบบจัดการตรวจสอบผักปลอดสารพิษ SafeVege Admin',
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
                      color: _errorMessage != null
                          ? AppColors.danger.withOpacity(0.4)
                          : AppColors.borderOf(context),
                      width: _errorMessage != null ? 1.2 : 0.8,
                    ),
                    boxShadow: AppShadows.cardOf(context),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.danger.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  CupertinoIcons.exclamationmark_circle_fill,
                                  color: AppColors.danger,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อผู้ใช้ผู้ดูแล (Username)',
                          hintText: 'กรอกชื่อผู้ใช้',
                          prefixIcon: Icon(CupertinoIcons.shield, size: 20),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _login(),
                        decoration: InputDecoration(
                          labelText: 'รหัสผ่าน (Password)',
                          hintText: 'กรอกรหัสผ่าน',
                          errorText: _hasPasswordError ? 'รหัสผ่านไม่ถูกต้อง' : null,
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
                      const SizedBox(height: 8),

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
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('กลับไปหน้าร้านค้า / หน้าหลัก'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
