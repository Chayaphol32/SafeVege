import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';

class InspectionSchedulingScreen extends StatefulWidget {
  const InspectionSchedulingScreen({
    super.key,
    required this.request,
    required this.appState,
  });

  final InspectionRequestModel request;
  final AppState appState;

  @override
  State<InspectionSchedulingScreen> createState() =>
      _InspectionSchedulingScreenState();
}

class _InspectionSchedulingScreenState
    extends State<InspectionSchedulingScreen> {
  DateTime? _selectedDate;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate =
        widget.request.appointmentDate ??
        DateTime.now().add(const Duration(days: 3));
    _notesController.text = widget.request.appointmentNotes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null && _selectedDate!.isAfter(now)
          ? _selectedDate!
          : now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      helpText: 'เลือกวันนัดหมายตรวจสอบ',
      confirmText: 'ตกลง',
      cancelText: 'ยกเลิก',
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _confirmScheduling() async {
    if (_selectedDate == null) {
      AppFeedback.showError(context, 'กรุณาเลือกวันที่นัดตรวจ');
      return;
    }
    if (_selectedDate!.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    )) {
      AppFeedback.showError(context, 'ไม่สามารถเลือกวันที่ผ่านมาแล้ว');
      return;
    }

    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'ยืนยันวันนัดตรวจสอบ?',
      message:
          'ร้าน ${widget.request.shopName}\nวันที่นัดหมาย: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year + 543}',
      confirmLabel: 'ยืนยันวันนัด',
    );

    if (confirmed && mounted) {
      setState(() => _isSubmitting = true);
      try {
        await widget.appState.scheduleInspection(
          widget.request.id,
          _selectedDate!,
          _notesController.text.trim(),
        );
        if (!mounted) return;
        AppFeedback.showSuccess(context, 'กำหนดวันนัดหมายเรียบร้อยแล้ว');
        Navigator.pop(context, true);
      } catch (error) {
        if (mounted) AppFeedback.showError(context, error.toString());
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('กำหนดวันตรวจสอบ')),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: AppContentWidth.form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Request overview card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.request.id,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primaryOf(context),
                            ),
                          ),
                          StatusBadge(status: widget.request.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ร้านค้า: ${widget.request.shopName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ที่ตั้ง: ${widget.request.shopAddress}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'รายการผักที่ขอตรวจ: ${widget.request.vegetables.join(", ")}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.primaryOf(context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date picker card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'วันที่ต้องการนัดตรวจ *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.borderOf(context),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event,
                                    color: AppColors.primaryOf(context),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedDate != null
                                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year + 543}'
                                        : 'แตะเพื่อเลือกวันที่นัดตรวจ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: _selectedDate != null
                                          ? AppColors.textPrimaryOf(context)
                                          : AppColors.textMutedOf(context),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'เปลี่ยนวันที่',
                                style: TextStyle(
                                  color: AppColors.primaryOf(context),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'หมายเหตุการนัดหมาย (ข้อความถึงร้านค้า)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'เช่น แจ้งเวลาเข้าตรวจ, สิ่งที่ต้องเตรียมความพร้อม...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _isSubmitting ? null : _confirmScheduling,
                icon: const Icon(Icons.check_circle_outline),
                label: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ยืนยันวันนัดตรวจ'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ยกเลิก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
