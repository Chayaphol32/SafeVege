import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_map.dart';
import 'location_picker_screen.dart';

class ShopProfileScreen extends StatefulWidget {
  const ShopProfileScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen> {
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _ownerFirstController;
  late TextEditingController _ownerLastController;
  late TextEditingController _phoneController;
  late TextEditingController _houseNoController;
  late TextEditingController _mooController;
  late TextEditingController _roadController;
  late TextEditingController _subDistrictController;
  late TextEditingController _districtController;
  late TextEditingController _provinceController;

  late double _latitude;
  late double _longitude;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  void _loadShopData() {
    final shop = widget.appState.currentShop;
    _nameController = TextEditingController(text: shop.name);
    _ownerFirstController = TextEditingController(text: shop.ownerFirstName);
    _ownerLastController = TextEditingController(text: shop.ownerLastName);
    _phoneController = TextEditingController(text: shop.phone);
    _houseNoController = TextEditingController(text: shop.houseNo);
    _mooController = TextEditingController(text: shop.moo);
    _roadController = TextEditingController(text: shop.road);
    _subDistrictController = TextEditingController(text: shop.subDistrict);
    _districtController = TextEditingController(text: shop.district);
    _provinceController = TextEditingController(text: shop.province);
    _latitude = shop.latitude;
    _longitude = shop.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerFirstController.dispose();
    _ownerLastController.dispose();
    _phoneController.dispose();
    _houseNoController.dispose();
    _mooController.dispose();
    _roadController.dispose();
    _subDistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  Future<void> _changeLocation() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
      AppFeedback.showSuccess(
        context,
        'อัปเดตพิกัดร้านค้าแล้ว (อย่าลืมกดบันทึก)',
      );
    }
  }

  Future<void> _saveChanges() async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'ต้องการบันทึกการเปลี่ยนแปลงหรือไม่?',
      message: 'ข้อมูลร้านค้าและพิกัดที่ปรับปรุงใหม่จะถูกอัปเดตในระบบ',
      confirmLabel: 'บันทึก',
    );

    if (confirmed && mounted) {
      try {
        await widget.appState.updateCurrentShop(
          name: _nameController.text.trim(),
          ownerFirstName: _ownerFirstController.text.trim(),
          ownerLastName: _ownerLastController.text.trim(),
          phone: _phoneController.text.trim(),
          houseNo: _houseNoController.text.trim(),
          moo: _mooController.text.trim(),
          road: _roadController.text.trim(),
          subDistrict: _subDistrictController.text.trim(),
          district: _districtController.text.trim(),
          province: _provinceController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        );
        if (!mounted) return;
        setState(() => _isEditing = false);
        AppFeedback.showSuccess(context, 'บันทึกข้อมูลร้านค้าเรียบร้อยแล้ว');
      } catch (error) {
        if (mounted) AppFeedback.showError(context, error.toString());
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'ต้องการออกจากระบบหรือไม่?',
      message: 'คุณจะต้องเข้าสู่ระบบใหม่อีกครั้งเพื่อจัดการข้อมูลร้านค้า',
      confirmLabel: 'ออกจากระบบ',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      await widget.appState.logoutShop();
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
      AppFeedback.showSuccess(context, 'ออกจากระบบร้านค้าแล้ว');
    }
  }

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('เปลี่ยนรหัสผ่าน'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: obscureOld,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่านปัจจุบัน',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOld ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscureOld = !obscureOld),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่านใหม่ (อย่างน้อย 6 ตัว)',
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setDialogState(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureNew,
                  decoration: const InputDecoration(
                    labelText: 'ยืนยันรหัสผ่านใหม่',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () async {
                final oldP = oldPasswordController.text;
                final newP = newPasswordController.text;
                final confirmP = confirmPasswordController.text;

                if (oldP.isEmpty) {
                  AppFeedback.showError(ctx, 'กรุณากรอกรหัสผ่านปัจจุบัน');
                  return;
                }
                if (newP.length < 6) {
                  AppFeedback.showError(
                    ctx,
                    'รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 6 ตัวอักษร',
                  );
                  return;
                }
                if (newP != confirmP) {
                  AppFeedback.showError(
                    ctx,
                    'รหัสผ่านใหม่และการยืนยันไม่ตรงกัน',
                  );
                  return;
                }
                try {
                  await widget.appState.changePassword(
                    oldPassword: oldP,
                    newPassword: newP,
                  );
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (error) {
                  if (ctx.mounted) AppFeedback.showError(ctx, error.toString());
                }
              },
              child: const Text('บันทึกรหัสผ่านใหม่'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      AppFeedback.showSuccess(context, 'เปลี่ยนรหัสผ่านเรียบร้อยแล้ว');
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'ต้องการขอลบบัญชีผู้ใช้งานหรือไม่?',
      message: 'บัญชีร้านค้าและข้อมูลการเข้าใช้งานของคุณจะถูกระงับและลบออกจากระบบอย่างถาวร โดยไม่สามารถกู้คืนได้อีก',
      confirmLabel: 'ขอลบบัญชีถาวร',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await widget.appState.deleteCurrentAccount();
        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
        AppFeedback.showSuccess(
          context,
          'ส่งคำขอลบบัญชีและระงับการใช้งานเรียบร้อยแล้ว',
        );
      } catch (error) {
        if (mounted) AppFeedback.showError(context, error.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.appState.currentShop;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('ข้อมูลร้านค้าของฉัน'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'แก้ไขข้อมูล',
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: AppContentWidth.form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Shop Summary Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundOf(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderOf(context),
                          ),
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          color: AppColors.primaryOf(context),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'รหัสร้านค้า: ${shop.id}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            StatusBadge(
                              status: shop.isVerified
                                  ? 'ผ่านการตรวจสอบ'
                                  : 'รอการตรวจสอบ',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Form fields
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ข้อมูลทั่วไปและที่ตั้ง',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (_isEditing)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warningBgOf(context),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'โหมดแก้ไข',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildField(
                        'ชื่อร้านค้า',
                        _nameController,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'ชื่อจริงเจ้าของ',
                              _ownerFirstController,
                              enabled: _isEditing,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildField(
                              'นามสกุล',
                              _ownerLastController,
                              enabled: _isEditing,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        'เบอร์โทรศัพท์',
                        _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'บ้านเลขที่',
                              _houseNoController,
                              enabled: _isEditing,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildField(
                              'หมู่',
                              _mooController,
                              enabled: _isEditing,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildField('ถนน', _roadController, enabled: _isEditing),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              'ตำบล',
                              _subDistrictController,
                              enabled: _isEditing,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildField(
                              'อำเภอ',
                              _districtController,
                              enabled: _isEditing,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        'จังหวัด',
                        _provinceController,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),

                      // Map Section
                      const Text(
                        'พิกัดที่ตั้งร้าน:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundOf(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.borderOf(context),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.primaryOf(context),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lat: ${_latitude.toStringAsFixed(6)}, Lng: ${_longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (_isEditing)
                              TextButton(
                                onPressed: _changeLocation,
                                child: const Text('เปลี่ยนพิกัด'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 130,
                          child: SafeVegeInteractiveMap(
                            height: 130,
                            compact: true,
                            shops: [shop],
                            selectedShop: shop,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              if (_isEditing) ...[
                FilledButton(
                  onPressed: _saveChanges,
                  child: const Text('บันทึกการเปลี่ยนแปลง'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    _loadShopData();
                    setState(() => _isEditing = false);
                  },
                  child: const Text('ยกเลิกการแก้ไข'),
                ),
                const SizedBox(height: 16),
              ] else ...[
                FilledButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('แก้ไขข้อมูลร้านค้า'),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              const SectionHeader(title: 'ความปลอดภัยของบัญชี'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.lock_outline_rounded, size: 18),
                        label: const Text('เปลี่ยนรหัสผ่านบัญชี'),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _deleteAccount,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                        icon: const Icon(
                          Icons.delete_forever_outlined,
                          size: 18,
                        ),
                        label: const Text(
                          'ขอลบบัญชีผู้ใช้งาน (Delete Account)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('ออกจากระบบ'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        fillColor: enabled
            ? AppColors.surfaceOf(context)
            : AppColors.backgroundOf(context),
      ),
    );
  }
}
