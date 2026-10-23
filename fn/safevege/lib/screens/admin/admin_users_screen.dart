import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  String? _error;

  AppState get appState => widget.appState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await appState.loadAdminUsers();
    } catch (error) {
      _error = _errorText(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createInspector() async {
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CreateAdminUserDialog(appState: appState),
    );
    if (success == true && mounted) {
      AppFeedback.showSuccess(context, 'สร้างบัญชีแอดมินตรวจผักเรียบร้อยแล้ว');
      _load();
    }
  }

  Future<void> _resetPassword(AdminUserModel user) async {
    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ResetUserPasswordDialog(
        user: user,
        appState: appState,
      ),
    );
    if (success == true && mounted) {
      AppFeedback.showSuccess(
        context,
        'เปลี่ยนรหัสผ่านให้ ${user.username} สำเร็จแล้ว',
      );
      _load();
    }
  }

  String? _updatingUserId;

  Future<void> _toggleActive(AdminUserModel user, bool isActive) async {
    setState(() => _updatingUserId = user.id);
    try {
      await appState.updateAdminUser(user.id, isActive: isActive);
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          isActive ? 'เปิดใช้งานบัญชีแล้ว' : 'ปิดใช้งานบัญชีแล้ว',
        );
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(context, _errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => _updatingUserId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!appState.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('จัดการบัญชีผู้ใช้')),
        body: const Center(child: Text('ไม่มีสิทธิ์เข้าถึงเมนูนี้')),
      );
    }

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            title: const Text(
              'จัดการบัญชีผู้ใช้',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: 'รีเฟรช',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _loading ? null : _createInspector,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('สร้างแอดมินตรวจผัก'),
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: FilledButton.tonalIcon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: Text('โหลดไม่สำเร็จ: $_error'),
        ),
      );
    }
    if (appState.adminUsers.isEmpty) {
      return const Center(child: Text('ยังไม่มีบัญชีในระบบ'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: appState.adminUsers.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = appState.adminUsers[index];
          final isCurrentUser = user.username == appState.username;
          final isSuperAdminAccount = user.role == UserRole.superAdmin;
          final canEditUser = !isCurrentUser && !isSuperAdminAccount;

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: user.isActive
                    ? AppColors.successBgOf(context)
                    : AppColors.dangerBgOf(context),
                foregroundColor: user.isActive
                    ? AppColors.success
                    : AppColors.danger,
                child: Icon(_roleIcon(user.role)),
              ),
              title: Text(
                user.displayName.isEmpty ? user.username : user.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${user.username} • ${_roleLabel(user.role)}'),
              trailing: SizedBox(
                width: 132,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: isSuperAdminAccount
                          ? 'บัญชี Super Admin แก้ไขไม่ได้'
                          : isCurrentUser
                              ? 'ไม่สามารถเปลี่ยนรหัสผ่านตนเองที่นี่'
                              : 'เปลี่ยนรหัสผ่าน',
                      onPressed: canEditUser
                          ? () => _resetPassword(user)
                          : null,
                      icon: const Icon(Icons.key_rounded),
                    ),
                    if (_updatingUserId == user.id)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      Switch(
                        value: user.isActive,
                        onChanged: !canEditUser || _updatingUserId != null
                            ? null
                            : (value) => _toggleActive(user, value),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _errorText(Object error) =>
      AppState.localizeErrorMessage(error.toString().replaceFirst('ApiException: ', ''));

  static String _roleLabel(UserRole role) => switch (role) {
    UserRole.shop => 'ร้านค้า',
    UserRole.admin => 'แอดมินตรวจผัก',
    UserRole.superAdmin => 'Super Admin',
    UserRole.guest => 'ผู้ใช้ทั่วไป',
  };

  static IconData _roleIcon(UserRole role) => switch (role) {
    UserRole.shop => Icons.storefront_rounded,
    UserRole.admin => Icons.fact_check_rounded,
    UserRole.superAdmin => Icons.admin_panel_settings_rounded,
    UserRole.guest => Icons.person_rounded,
  };
}

/// Dialog for changing a user's password with username confirmation
class _ResetUserPasswordDialog extends StatefulWidget {
  const _ResetUserPasswordDialog({
    required this.user,
    required this.appState,
  });

  final AdminUserModel user;
  final AppState appState;

  @override
  State<_ResetUserPasswordDialog> createState() =>
      _ResetUserPasswordDialogState();
}

class _ResetUserPasswordDialogState extends State<_ResetUserPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _confirmUsernameController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _confirmUsernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.appState.resetAdminUserPassword(
        widget.user.id,
        _newPasswordController.text,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = AppState.localizeErrorMessage(
            error.toString().replaceFirst('ApiException: ', ''),
          );
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryOf(context).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.key_rounded,
              color: AppColors.primaryOf(context),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'เปลี่ยนรหัสผ่าน ${user.username}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderOf(context),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'กำลังเปลี่ยนรหัสผ่านให้: ${user.username}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (user.displayName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'ชื่อที่แสดง: ${user.displayName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // New Password
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่านใหม่',
                    helperText: 'ต้องมีความยาวอย่างน้อย 12 ตัวอักษร',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _obscureNewPassword = !_obscureNewPassword,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสผ่านใหม่';
                    }
                    if (value.length < 12) {
                      return 'รหัสผ่านต้องมีอย่างน้อย 12 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'ยืนยันรหัสผ่านใหม่อีกครั้ง',
                    prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณายืนยันรหัสผ่านใหม่';
                    }
                    if (value != _newPasswordController.text) {
                      return 'รหัสผ่านทั้งสองช่องไม่ตรงกัน';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Username Section (Required by User: "ทำยืนยันอีกรอบด้วยการใส่ชื่อuser อีกรอบ")
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningBgOf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'เพื่อยืนยัน กรุณาพิมพ์ชื่อผู้ใช้ "${user.username}" อีกครั้ง',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.isDark(context)
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _confirmUsernameController,
                  decoration: InputDecoration(
                    labelText: 'พิมพ์ชื่อผู้ใช้ (${user.username}) เพื่อยืนยัน',
                    hintText: user.username,
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณาพิมพ์ชื่อผู้ใช้ "${user.username}" เพื่อยืนยัน';
                    }
                    if (value.trim() != user.username) {
                      return 'ชื่อผู้ใช้ไม่ตรงกัน กรุณาพิมพ์ "${user.username}"';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('ยืนยันเปลี่ยนรหัสผ่าน'),
        ),
      ],
    );
  }
}

/// Dialog for creating inspector admin
class _CreateAdminUserDialog extends StatefulWidget {
  const _CreateAdminUserDialog({required this.appState});

  final AppState appState;

  @override
  State<_CreateAdminUserDialog> createState() => _CreateAdminUserDialogState();
}

class _CreateAdminUserDialogState extends State<_CreateAdminUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.appState.createAdminUser(
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        password: _passwordController.text,
        role: UserRole.admin,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = AppState.localizeErrorMessage(
            error.toString().replaceFirst('ApiException: ', ''),
          );
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.person_add_alt_1_rounded, size: 24),
          SizedBox(width: 10),
          Text(
            'สร้างแอดมินตรวจผัก',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.danger.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้ (Username)'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'กรุณากรอกชื่อผู้ใช้'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'ชื่อที่แสดง (Display Name)'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'กรุณากรอกชื่อที่แสดง'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่านเริ่มต้น',
                    helperText: 'อย่างน้อย 12 ตัวอักษร',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.length < 12
                      ? 'รหัสผ่านต้องมีอย่างน้อย 12 ตัวอักษร'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('สร้างบัญชี'),
        ),
      ],
    );
  }
}
