import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_map.dart';
import '../shop/location_picker_screen.dart';

class AdminShopDetailsScreen extends StatefulWidget {
  const AdminShopDetailsScreen({
    super.key,
    this.shop,
    required this.appState,
    this.isAddMode = false,
  });

  final ShopModel? shop;
  final AppState appState;
  final bool isAddMode;

  @override
  State<AdminShopDetailsScreen> createState() => _AdminShopDetailsScreenState();
}

class _AdminShopDetailsScreenState extends State<AdminShopDetailsScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  bool _locationSelected = false;

  late TextEditingController _nameController;
  late TextEditingController _ownerFirstController;
  late TextEditingController _ownerLastController;
  late TextEditingController _phoneController;
  late TextEditingController _houseNoController;
  late TextEditingController _subDistrictController;
  late TextEditingController _districtController;
  late TextEditingController _provinceController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  late double _latitude;
  late double _longitude;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.isAddMode;

    if (widget.shop != null) {
      final s = widget.shop!;
      _nameController = TextEditingController(text: s.name);
      _ownerFirstController = TextEditingController(text: s.ownerFirstName);
      _ownerLastController = TextEditingController(text: s.ownerLastName);
      _phoneController = TextEditingController(text: s.phone);
      _houseNoController = TextEditingController(text: s.houseNo);
      _subDistrictController = TextEditingController(text: s.subDistrict);
      _districtController = TextEditingController(text: s.district);
      _provinceController = TextEditingController(text: s.province);
      _latitude = s.latitude;
      _longitude = s.longitude;
      _locationSelected = s.hasCoordinates;
    } else {
      _nameController = TextEditingController();
      _ownerFirstController = TextEditingController();
      _ownerLastController = TextEditingController();
      _phoneController = TextEditingController();
      _houseNoController = TextEditingController();
      _subDistrictController = TextEditingController();
      _districtController = TextEditingController();
      _provinceController = TextEditingController();
      _latitude = 0;
      _longitude = 0;
    }
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerFirstController.dispose();
    _ownerLastController.dispose();
    _phoneController.dispose();
    _houseNoController.dispose();
    _subDistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final res = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLatitude: _locationSelected ? _latitude : 13.7563,
          initialLongitude: _locationSelected ? _longitude : 100.5018,
        ),
      ),
    );

    if (res != null && mounted) {
      setState(() {
        _latitude = res.latitude;
        _longitude = res.longitude;
        _locationSelected = true;
      });
      AppFeedback.showSuccess(context, 'เลือกพิกัดร้านค้าแล้ว');
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppFeedback.showError(context, 'กรุณากรอกชื่อร้านค้า');
      return;
    }
    if (_ownerFirstController.text.trim().isEmpty ||
        _ownerLastController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      AppFeedback.showError(context, 'กรุณากรอกชื่อเจ้าของและเบอร์โทรศัพท์');
      return;
    }
    if (!_locationSelected) {
      AppFeedback.showError(context, 'กรุณาเลือกพิกัดร้านค้าบนแผนที่');
      return;
    }
    if (widget.isAddMode && _passwordController.text.length < 12) {
      AppFeedback.showError(context, 'รหัสผ่านต้องมีอย่างน้อย 12 ตัวอักษร');
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.isAddMode) {
        final newShop = ShopModel(
          id: '',
          name: name,
          ownerFirstName: _ownerFirstController.text.trim(),
          ownerLastName: _ownerLastController.text.trim(),
          phone: _phoneController.text.trim(),
          houseNo: _houseNoController.text.trim(),
          subDistrict: _subDistrictController.text.trim(),
          district: _districtController.text.trim(),
          province: _provinceController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          isVerified: false,
          verifiedVegetables: [],
          createdAt: DateTime.now(),
        );
        final username = _usernameController.text.trim();
        if (username.isEmpty) {
          AppFeedback.showError(context, 'กรุณากำหนดชื่อผู้ใช้สำหรับร้านค้า');
          return;
        }
        await widget.appState.addShopByAdmin(
          shop: newShop,
          username: username,
          password: _passwordController.text,
        );
        if (!mounted) return;
        AppFeedback.showSuccess(context, 'สร้างบัญชีและเพิ่มร้านค้าแล้ว');
        Navigator.pop(context, true);
      } else {
        final shop = widget.shop!;
        final updatedShop = ShopModel(
          id: shop.id,
          name: name,
          ownerFirstName: _ownerFirstController.text.trim(),
          ownerLastName: _ownerLastController.text.trim(),
          phone: _phoneController.text.trim(),
          houseNo: _houseNoController.text.trim(),
          subDistrict: _subDistrictController.text.trim(),
          district: _districtController.text.trim(),
          province: _provinceController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          isVerified: shop.isVerified,
          hasCoordinates: _locationSelected,
          distanceText: shop.distanceText,
          verifiedVegetables: shop.verifiedVegetables,
          createdAt: shop.createdAt,
        );
        await widget.appState.updateAdminShop(updatedShop);
        if (!mounted) return;
        setState(() => _isEditing = false);
        AppFeedback.showSuccess(context, 'บันทึกการแก้ไขร้านค้าเรียบร้อยแล้ว');
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(
          context,
          AppState.localizeErrorMessage(
            error.toString().replaceFirst('ApiException: ', ''),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteShop() async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'ยืนยันการลบร้านค้า?',
      message: 'การดำเนินการนี้จะลบร้านค้าและอาจส่งผลกระทบต่อประวัติคำขอและผลตรวจในระบบ',
      confirmLabel: 'ลบร้านค้า',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      try {
        await widget.appState.deleteShop(widget.shop!.id);
        if (!mounted) return;
        AppFeedback.showSuccess(context, 'ลบร้านค้าออกจากระบบแล้ว');
        Navigator.pop(context, true);
      } catch (error) {
        if (mounted) {
          AppFeedback.showError(
            context,
            AppState.localizeErrorMessage(
              error.toString().replaceFirst('ApiException: ', ''),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(widget.isAddMode ? 'เพิ่มร้านค้าใหม่' : 'ข้อมูลร้านค้า'),
        actions: [
          if (!widget.isAddMode && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'แก้ไขร้านค้า',
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
              // Header card
              if (!widget.isAddMode && shop != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundOf(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.borderOf(context),
                            ),
                          ),
                          child: Icon(
                            Icons.storefront_rounded,
                            color: AppColors.primaryOf(context),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                              Text(
                                'รหัสร้านค้า: ${shop.id} • ${shop.shortArea}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          status: shop.isVerified ? 'ผ่านการตรวจ' : 'รอนัดตรวจ',
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),

              // Form Fields
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ข้อมูลทั่วไป',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (widget.isAddMode) ...[
                        const Text(
                          'บัญชีเข้าสู่ระบบของร้าน',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _usernameController,
                          enabled: _isEditing && !_isSaving,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'ชื่อผู้ใช้ *',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _passwordController,
                          enabled: _isEditing && !_isSaving,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'รหัสผ่านเริ่มต้น *',
                            helperText: 'อย่างน้อย 12 ตัวอักษร',
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _nameController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อร้านค้า *',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ownerFirstController,
                              enabled: _isEditing,
                              decoration: const InputDecoration(
                                labelText: 'ชื่อจริงเจ้าของ',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _ownerLastController,
                              enabled: _isEditing,
                              decoration: const InputDecoration(
                                labelText: 'นามสกุล',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneController,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'เบอร์โทรศัพท์',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _houseNoController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(
                          labelText: 'บ้านเลขที่ / ที่อยู่',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subDistrictController,
                              enabled: _isEditing,
                              decoration: const InputDecoration(
                                labelText: 'ตำบล',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _districtController,
                              enabled: _isEditing,
                              decoration: const InputDecoration(
                                labelText: 'อำเภอ',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _provinceController,
                        enabled: _isEditing,
                        decoration: const InputDecoration(labelText: 'จังหวัด'),
                      ),
                      const SizedBox(height: 16),

                      // Map Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _locationSelected
                                ? 'พิกัด Lat: ${_latitude.toStringAsFixed(4)}, Lng: ${_longitude.toStringAsFixed(4)}'
                                : 'ยังไม่ได้เลือกพิกัดร้านค้า',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                          if (_isEditing)
                            TextButton.icon(
                              onPressed: _pickLocation,
                              icon: const Icon(
                                Icons.edit_location_alt,
                                size: 16,
                              ),
                              label: const Text('แก้ไขพิกัด'),
                            ),
                        ],
                      ),
                      if (_locationSelected && shop != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 120,
                            child: SafeVegeInteractiveMap(
                              height: 120,
                              compact: true,
                              shops: [shop],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_isEditing) ...[
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.isAddMode ? 'เพิ่มร้านค้า' : 'บันทึกการแก้ไข',
                        ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    if (widget.isAddMode) {
                      Navigator.pop(context);
                    } else {
                      setState(() => _isEditing = false);
                    }
                  },
                  child: const Text('ยกเลิก'),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit),
                  label: const Text('แก้ไขข้อมูลร้านค้า'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _deleteShop,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('ลบร้านค้าออกจากระบบ'),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
