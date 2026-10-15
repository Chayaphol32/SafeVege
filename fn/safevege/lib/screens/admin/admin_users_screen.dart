import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

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
    _load();
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
    final values = await _showCreateDialog();
    if (values == null || !mounted) return;
    try {
      await appState.createAdminUser(
        username: values.username,
        displayName: values.displayName,
        password: values.password,
        role: UserRole.admin,
      );
      if (mounted) _showMessage('สร้างบัญชีแอดมินตรวจผักแล้ว');
    } catch (error) {
      if (mounted) _showMessage(_errorText(error), isError: true);
    }
  }

  Future<void> _resetPassword(AdminUserModel user) async {
    final password = await _showPasswordDialog(user);
    if (password == null || !mounted) return;
    try {
      await appState.resetAdminUserPassword(user.id, password);
      if (mounted) _showMessage('เปลี่ยนรหัสผ่านให้ ${user.username} แล้ว');
    } catch (error) {
      if (mounted) _showMessage(_errorText(error), isError: true);
    }
  }

  Future<void> _toggleActive(AdminUserModel user, bool isActive) async {
    try {
      await appState.updateAdminUser(user.id, isActive: isActive);
      if (mounted) {
        _showMessage(isActive ? 'เปิดใช้งานบัญชีแล้ว' : 'ปิดใช้งานบัญชีแล้ว');
      }
    } catch (error) {
      if (mounted) _showMessage(_errorText(error), isError: true);
    }
  }

  Future<_CreateUserValues?> _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final username = TextEditingController();
    final displayName = TextEditingController();
    final password = TextEditingController();

    return showDialog<_CreateUserValues>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('สร้างแอดมินตรวจผัก'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: username,
                  decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'กรอกชื่อผู้ใช้'
                      : null,
                ),
                TextFormField(
                  controller: displayName,
                  decoration: const InputDecoration(labelText: 'ชื่อที่แสดง'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'กรอกชื่อที่แสดง'
                      : null,
                ),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'รหัสผ่านเริ่มต้น',
                    helperText: 'อย่างน้อย 12 ตัวอักษร',
                  ),
                  validator: (value) => value == null || value.length < 12
                      ? 'รหัสผ่านต้องมีอย่างน้อย 12 ตัวอักษร'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(
                dialogContext,
                _CreateUserValues(
                  username: username.text.trim(),
                  displayName: displayName.text.trim(),
                  password: password.text,
                ),
              );
            },
            child: const Text('สร้างบัญชี'),
          ),
        ],
      ),
    ).whenComplete(() {
      username.dispose();
      displayName.dispose();
      password.dispose();
    });
  }

  Future<String?> _showPasswordDialog(AdminUserModel user) {
    final formKey = GlobalKey<FormState>();
    final password = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('เปลี่ยนรหัสผ่าน ${user.username}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'รหัสผ่านใหม่',
              helperText: 'อย่างน้อย 12 ตัวอักษร',
            ),
            validator: (value) => value == null || value.length < 12
                ? 'รหัสผ่านต้องมีอย่างน้อย 12 ตัวอักษร'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(dialogContext, password.text);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    ).whenComplete(password.dispose);
  }

  @override
  Widget build(BuildContext context) {
    if (!appState.isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('จัดการบัญชีผู้ใช้')),
        body: const Center(child: Text('ไม่มีสิทธิ์เข้าถึงเมนูนี้')),
      );
    }

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
                      tooltip: 'เปลี่ยนรหัสผ่าน',
                      onPressed: user.username == appState.username
                          ? null
                          : () => _resetPassword(user),
                      icon: const Icon(Icons.key_rounded),
                    ),
                    Switch(
                      value: user.isActive,
                      onChanged: user.username == appState.username
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

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : AppColors.success,
        ),
      );
  }

  static String _errorText(Object error) =>
      error.toString().replaceFirst('ApiException: ', '');

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

class _CreateUserValues {
  const _CreateUserValues({
    required this.username,
    required this.displayName,
    required this.password,
  });

  final String username;
  final String displayName;
  final String password;
}
