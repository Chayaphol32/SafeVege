import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import 'location_picker_screen.dart';
import 'request_tracking_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final List<TextEditingController> _vegControllers = [TextEditingController()];
  bool _isSubmitting = false;

  late double _latitude;
  late double _longitude;
  late String _address;

  @override
  void initState() {
    super.initState();
    final shop = widget.appState.currentShop;
    _latitude = shop.latitude;
    _longitude = shop.longitude;
    _address = shop.fullAddress;
  }

  @override
  void dispose() {
    for (final c in _vegControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addVegetableItem() {
    setState(() {
      _vegControllers.add(TextEditingController());
    });
  }

  void _removeVegetableItem(int index) {
    if (_vegControllers.length > 1) {
      setState(() {
        _vegControllers[index].dispose();
        _vegControllers.removeAt(index);
      });
    } else {
      AppFeedback.showError(context, 'ต้องมีรายการผักอย่างน้อย 1 รายการ');
    }
  }

  Future<void> _pickLocationOnMap() async {
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
        _address = result.formattedAddress;
      });
      AppFeedback.showSuccess(context, 'อัปเดตตำแหน่งจุดตรวจสอบแล้ว');
    }
  }

  void _submitRequest() {
    final vegNames = _vegControllers.map((c) => c.text.trim()).toList();

    if (vegNames.any((name) => name.isEmpty)) {
      AppFeedback.showError(
        context,
        'กรุณากรอกชื่อผักทุกรายการ หรือลบแถวที่ไม่ใช้',
      );
      return;
    }
    if (vegNames.toSet().length != vegNames.length) {
      AppFeedback.showError(context, 'มีชื่อผักซ้ำกัน กรุณาตรวจสอบรายการ');
      return;
    }

    // Confirmation dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'ยืนยันการส่งคำขอตรวจสอบ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Text(
          'คุณต้องการส่งรายการผักทั้งหมด ${vegNames.length} รายการ เพื่อขอรับการตรวจสอบจาก SafeVege ใช่หรือไม่?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('กลับไปแก้ไข'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeSend(vegNames);
            },
            child: const Text('ยืนยันการส่ง'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSend(List<String> vegNames) async {
    setState(() => _isSubmitting = true);
    late final InspectionRequestModel newReq;
    try {
      newReq = await widget.appState.addInspectionRequest(
        vegetables: vegNames,
        latitude: _latitude,
        longitude: _longitude,
        address: _address,
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

    // Success dialog
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
            SizedBox(width: 8),
            Text(
              'ส่งคำขอตรวจสอบสำเร็จ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'ส่งคำขอไปยัง SafeVege แล้ว คุณติดตามสถานะและวันนัดได้จากหน้าคำขอ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Back to dashboard
            },
            child: const Text('กลับหน้าหลัก'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestTrackingScreen(request: newReq),
                ),
              );
            },
            child: const Text('ดูรายละเอียดคำขอ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.appState.currentShop;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('ส่งคำขอตรวจสอบ')),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: AppContentWidth.form,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              const SafeVegeLogo(
                size: 36,
                subtitle: 'กรอกข้อมูลผักที่ต้องการส่งตรวจ',
              ),
              const SizedBox(height: 16),

              // SECTION 1: Shop Info (Auto)
              _buildSectionHeader(
                'ส่วนที่ 1: ข้อมูลร้านค้า',
                Icons.storefront_outlined,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.primaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'เจ้าของร้าน: ${shop.ownerFullName} • โทร: ${shop.phone}',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ที่อยู่: ${shop.fullAddress}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // SECTION 2: Vegetable items
              _buildSectionHeader(
                'ส่วนที่ 2: รายการผักที่ต้องการตรวจ',
                Icons.eco_outlined,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (int i = 0; i < _vegControllers.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundOf(context),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryOf(context),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _vegControllers[i],
                                  decoration: InputDecoration(
                                    hintText: 'ชื่อผัก เช่น คะน้า, กวางตุ้ง...',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    suffixIcon: _vegControllers.length > 1
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: AppColors.danger,
                                              size: 20,
                                            ),
                                            onPressed: () =>
                                                _removeVegetableItem(i),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: _addVegetableItem,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('+ เพิ่มรายการผัก'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // SECTION 3: Location of inspection
              _buildSectionHeader(
                'ส่วนที่ 3: ตำแหน่งร้านและแปลงผัก',
                Icons.pin_drop_outlined,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'พิกัดตรวจสอบ: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _address,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickLocationOnMap,
                              icon: const Icon(Icons.map_outlined, size: 16),
                              label: const Text('เลือกตำแหน่งบนแผนที่'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _latitude = shop.latitude;
                                  _longitude = shop.longitude;
                                  _address = shop.fullAddress;
                                });
                                AppFeedback.showSuccess(
                                  context,
                                  'ใช้ตำแหน่งร้านที่บันทึกไว้แล้ว',
                                );
                              },
                              icon: const Icon(Icons.restore_rounded, size: 16),
                              label: const Text('ใช้ตำแหน่งที่บันทึกไว้'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Buttons
              FilledButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ส่งคำขอตรวจสอบ'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
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
