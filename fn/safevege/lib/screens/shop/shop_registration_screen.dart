import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../state/app_state.dart';
import '../../services/user_location_service.dart';
import '../../widgets/common_widgets.dart';
import 'location_picker_screen.dart';

class ShopRegistrationScreen extends StatefulWidget {
  const ShopRegistrationScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<ShopRegistrationScreen> createState() => _ShopRegistrationScreenState();
}

class _ShopRegistrationScreenState extends State<ShopRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Owner
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Shop Info
  final _shopNameController = TextEditingController();
  final _houseNoController = TextEditingController();
  final _mooController = TextEditingController();
  final _roadController = TextEditingController();
  final _subDistrictController = TextEditingController();
  final _districtController = TextEditingController();
  final _provinceController = TextEditingController(text: 'เชียงราย');

  // Coordinates
  double _latitude = 19.9112;
  double _longitude = 99.8354;
  bool _hasLocation = false;

  // Account
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _houseNoController.dispose();
    _mooController.dispose();
    _roadController.dispose();
    _subDistrictController.dispose();
    _districtController.dispose();
    _provinceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
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
        _hasLocation = true;
      });
      AppFeedback.showSuccess(context, 'บันทึกตำแหน่งร้านค้าสำเร็จ');
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final location = await const UserLocationService().getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
        _hasLocation = true;
      });
      AppFeedback.showSuccess(context, 'ใช้ตำแหน่งปัจจุบันแล้ว');
    } on UserLocationException catch (error) {
      if (mounted) AppFeedback.showError(context, error.message);
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      AppFeedback.showError(context, 'กรุณากรอกข้อมูลที่จำเป็นให้ครบถ้วน');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      AppFeedback.showError(context, 'รหัสผ่านและการยืนยันรหัสผ่านไม่ตรงกัน');
      return;
    }
    if (!_hasLocation) {
      AppFeedback.showError(context, 'กรุณาเลือกตำแหน่งร้านค้าบนแผนที่');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.appState.registerShop(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        name: _shopNameController.text.trim(),
        ownerFirstName: _firstNameController.text.trim(),
        ownerLastName: _lastNameController.text.trim(),
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
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(
          context,
          widget.appState.errorMessage ?? error.toString(),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (!mounted) return;

    // Show Success Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'สมัครสมาชิกสำเร็จ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'บัญชีร้านค้าถูกสร้างแล้ว เข้าสู่ระบบด้วยชื่อผู้ใช้และรหัสผ่านที่สมัครไว้',
          style: TextStyle(
            fontSize: 14.5,
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // back to login or dashboard
            },
            child: const Text('เข้าสู่ระบบ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('สมัครสมาชิกร้านค้า')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppContentWidth.form),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  const SafeVegeLogo(
                    size: 40,
                    subtitle: 'ลงทะเบียนร้านค้าใหม่',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'กรอกข้อมูลเพื่อเริ่มต้นใช้งาน SafeVege',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SECTION 1: ข้อมูลเจ้าของร้าน
                  _buildSectionTitle(
                    'ส่วนที่ 1: ข้อมูลเจ้าของร้าน',
                    Icons.person_outline,
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'ชื่อจริง *',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'กรุณากรอกชื่อจริง'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'นามสกุล *',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'กรุณากรอกนามสกุล'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'เบอร์โทรศัพท์ *',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'กรุณากรอกเบอร์โทรศัพท์'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SECTION 2: ข้อมูลร้านค้า
                  _buildSectionTitle(
                    'ส่วนที่ 2: ข้อมูลร้านค้า',
                    Icons.storefront_outlined,
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _shopNameController,
                            decoration: const InputDecoration(
                              labelText: 'ชื่อร้านค้า *',
                              prefixIcon: Icon(Icons.store_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'กรุณากรอกชื่อร้านค้า'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _houseNoController,
                                  decoration: const InputDecoration(
                                    labelText: 'บ้านเลขที่ *',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'กรุณากรอกบ้านเลขที่'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _mooController,
                                  decoration: const InputDecoration(
                                    labelText: 'หมู่',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _roadController,
                            decoration: const InputDecoration(labelText: 'ถนน'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _subDistrictController,
                                  decoration: const InputDecoration(
                                    labelText: 'ตำบล *',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'กรุณากรอกตำบล'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _districtController,
                                  decoration: const InputDecoration(
                                    labelText: 'อำเภอ *',
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'กรุณากรอกอำเภอ'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _provinceController,
                            decoration: const InputDecoration(
                              labelText: 'จังหวัด *',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'กรุณากรอกจังหวัด'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SECTION 3: ตำแหน่งร้าน
                  _buildSectionTitle(
                    'ส่วนที่ 3: ตำแหน่งร้านค้าบนแผนที่',
                    Icons.pin_drop_outlined,
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundOf(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.borderOf(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _hasLocation
                                      ? Icons.check_circle
                                      : Icons.warning_amber_rounded,
                                  color: _hasLocation
                                      ? AppColors.success
                                      : AppColors.warning,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _hasLocation
                                        ? 'พิกัดที่เลือก: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}'
                                        : 'ยังไม่ได้เลือกตำแหน่งพิกัดร้านค้า *',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: _hasLocation
                                          ? AppColors.textPrimaryOf(context)
                                          : AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickLocation,
                                  icon: const Icon(Icons.map_rounded, size: 16),
                                  label: const Text('เลือกตำแหน่งบนแผนที่'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _useCurrentLocation,
                                  icon: const Icon(Icons.my_location, size: 16),
                                  label: const Text('ใช้ตำแหน่งปัจจุบัน'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // SECTION 4: ข้อมูลบัญชี
                  _buildSectionTitle(
                    'ส่วนที่ 4: ข้อมูลบัญชีผู้ใช้',
                    Icons.lock_outline,
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'ชื่อผู้ใช้ (Username) *',
                              prefixIcon: Icon(Icons.account_circle_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'กรุณากรอกชื่อผู้ใช้'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'รหัสผ่าน *',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 12)
                                ? 'รหัสผ่านต้องมีอย่างน้อย 12 ตัวอักษร'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscurePassword,
                            decoration: const InputDecoration(
                              labelText: 'ยืนยันรหัสผ่าน *',
                              prefixIcon: Icon(Icons.lock_reset),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'กรุณายืนยันรหัสผ่าน'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '* หมายถึงข้อมูลที่จำเป็นต้องกรอก\nกรุณาตรวจสอบข้อมูลให้ถูกต้องก่อนกดสมัครสมาชิก',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submitRegistration,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('สมัครสมาชิก'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('มีบัญชีอยู่แล้ว? เข้าสู่ระบบ'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
              color: AppColors.primaryOf(context),
            ),
          ),
        ],
      ),
    );
  }
}
