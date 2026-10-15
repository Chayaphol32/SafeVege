import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../models/app_models.dart';
import '../../widgets/common_widgets.dart';
import 'shop_results_screen.dart';

class RequestTrackingScreen extends StatelessWidget {
  const RequestTrackingScreen({super.key, required this.request});

  final InspectionRequestModel request;

  int _getCurrentStepIndex() {
    switch (request.status) {
      case RequestStatus.pending:
        return 0; // ส่งคำขอแล้ว
      case RequestStatus.scheduled:
        return 2; // นัดหมายวันตรวจ
      case RequestStatus.inProgress:
        return 3; // อยู่ระหว่างตรวจสอบ
      case RequestStatus.completed:
        return 4; // ตรวจสอบเสร็จสิ้น
      case RequestStatus.cancelled:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _getCurrentStepIndex();

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('รายละเอียดคำขอ')),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: AppContentWidth.form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Request Header Card
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
                            request.id,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primaryOf(context),
                            ),
                          ),
                          StatusBadge(status: request.status, large: true),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ร้านค้า: ${request.shopName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'วันที่ส่งคำขอ: ${request.submissionDate.day}/${request.submissionDate.month}/${request.submissionDate.year + 543} เวลา ${request.submissionDate.hour.toString().padLeft(2, '0')}:${request.submissionDate.minute.toString().padLeft(2, '0')} น.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Timeline Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'สถานะการดำเนินงาน (Status Timeline)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTimelineStep(
                        context,
                        stepNumber: 1,
                        title: 'ส่งคำขอแล้ว',
                        subtitle: 'ระบบได้รับข้อมูลคำขอตรวจผักเรียบร้อย',
                        dateStr:
                            '${request.submissionDate.day}/${request.submissionDate.month}/${request.submissionDate.year + 543}',
                        isDone: currentStep >= 0,
                        isCurrent: currentStep == 0,
                        isLast: false,
                      ),
                      _buildTimelineStep(
                        context,
                        stepNumber: 2,
                        title: 'รับคำขอแล้ว',
                        subtitle: 'เจ้าหน้าที่ตรวจสอบเอกสารและรับเรื่อง',
                        dateStr: currentStep >= 1
                            ? 'ผ่านการอนุมัติรับเรื่อง'
                            : null,
                        isDone: currentStep >= 1,
                        isCurrent: currentStep == 1,
                        isLast: false,
                      ),
                      _buildTimelineStep(
                        context,
                        stepNumber: 3,
                        title: 'นัดหมายวันตรวจ',
                        subtitle: request.appointmentDate != null
                            ? 'กำหนดนัดตรวจ: ${request.appointmentDate!.day}/${request.appointmentDate!.month}/${request.appointmentDate!.year + 543}'
                            : 'รอนัดหมายวันเข้าตรวจสอบแปลง',
                        dateStr: request.appointmentDate != null
                            ? 'กำหนดแล้ว'
                            : null,
                        isDone: currentStep >= 2,
                        isCurrent: currentStep == 2,
                        isLast: false,
                      ),
                      _buildTimelineStep(
                        context,
                        stepNumber: 4,
                        title: 'อยู่ระหว่างตรวจสอบ',
                        subtitle: 'เก็บตัวอย่างผักและวิเคราะห์สารตกค้างในห้องปฏิบัติการ',
                        dateStr: currentStep >= 3 ? 'เข้าตรวจแล้ว' : null,
                        isDone: currentStep >= 3,
                        isCurrent: currentStep == 3,
                        isLast: false,
                      ),
                      _buildTimelineStep(
                        context,
                        stepNumber: 5,
                        title: 'ตรวจสอบเสร็จสิ้น',
                        subtitle: request.isCompleted
                            ? 'ออกเอกสารรับรองผลตรวจเรียบร้อยแล้ว'
                            : 'รอสรุปผลการวิเคราะห์สารพิษ',
                        dateStr: request.isCompleted ? 'เสร็จสิ้น' : null,
                        isDone: currentStep >= 4,
                        isCurrent: currentStep == 4,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Vegetables in this request
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'รายการผักที่ขอรับการตรวจ (${request.vegetables.length} ชนิด)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: request.vegetables.map((v) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundOf(context),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.borderOf(context),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.eco_rounded,
                                  size: 14,
                                  color: AppColors.primaryOf(context),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  v,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      Text(
                        'ที่อยู่สำหรับเข้าตรวจ:',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.shopAddress,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Buttons
              if (request.isCompleted) ...[
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShopResultsScreen(request: request),
                      ),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium_rounded),
                  label: const Text('ดูผลการตรวจและใบรับรอง'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('กลับไปยังรายการคำขอ'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String subtitle,
    String? dateStr,
    required bool isDone,
    required bool isCurrent,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step circle & line
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primaryOf(context)
                      : AppColors.borderOf(context),
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: AppColors.accent, width: 3)
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$stepNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMutedOf(context),
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? AppColors.primary : Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Step text info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDone
                              ? AppColors.textPrimaryOf(context)
                              : AppColors.textMutedOf(context),
                        ),
                      ),
                      if (dateStr != null)
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? AppColors.primary
                                : AppColors.textMutedOf(context),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDone
                          ? AppColors.textSecondaryOf(context)
                          : AppColors.textMutedOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
