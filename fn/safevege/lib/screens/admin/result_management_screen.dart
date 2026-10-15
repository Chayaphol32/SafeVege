import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../guest/certificate_viewer_screen.dart';

class ResultManagementScreen extends StatefulWidget {
  const ResultManagementScreen({
    super.key,
    required this.request,
    required this.appState,
  });

  final InspectionRequestModel request;
  final AppState appState;

  @override
  State<ResultManagementScreen> createState() => _ResultManagementScreenState();
}

class _ResultManagementScreenState extends State<ResultManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('รายละเอียดผลตรวจและใบรับรอง')),
      body: ResponsiveContent(
        maxWidth: 720,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Overview card
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
                            req.id,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primaryOf(context),
                            ),
                          ),
                          StatusBadge(status: req.allPassed),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ร้านค้า: ${req.shopName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'วันที่ตรวจจริง: ${req.inspectionDate != null ? "${req.inspectionDate!.day}/${req.inspectionDate!.month}/${req.inspectionDate!.year + 543}" : "-"}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                      Text(
                        'ผู้ตรวจสอบ: ${req.inspectorName ?? widget.appState.adminName}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Vegetable breakdown
              const SectionHeader(title: 'ผลการตรวจผักรายชนิด'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: req.results.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              item.passed == true
                                  ? Icons.verified
                                  : Icons.cancel,
                              color: item.passed == true
                                  ? AppColors.success
                                  : AppColors.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (item.details != null)
                                    Text(
                                      item.details!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondaryOf(
                                          context,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            StatusBadge(status: item.passed),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Document card
              const SectionHeader(title: 'ใบรับรองตัวอย่าง'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.insert_drive_file_outlined,
                            color: AppColors.primaryOf(context),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req.hasCertificate
                                      ? req.certificateFileName!
                                      : 'ยังไม่มีไฟล์ใบรับรอง',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                Text(
                                  req.hasCertificate
                                      ? 'เลขที่ใบรับรอง: ${req.certificateNumber!}'
                                      : 'ต้องมีผลผ่านครบทุกชนิดและมีเอกสารแนบ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: req.hasCertificate
                                  ? () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CertificateViewerScreen(
                                                shopName: req.shopName,
                                                certNumber:
                                                    req.certificateNumber!,
                                                certificateId:
                                                    req.certificateId,
                                                certificateFileName:
                                                    req.certificateFileName,
                                                vegetables: req.results
                                                    .where(
                                                      (result) =>
                                                          result.passed == true,
                                                    )
                                                    .map(
                                                      (result) => result.name,
                                                    )
                                                    .toList(),
                                                issueDate: req.inspectionDate,
                                                expiryDate:
                                                    req.certificateExpiryDate,
                                                inspectorName:
                                                    req.inspectorName,
                                              ),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: const Icon(
                                Icons.remove_red_eye_outlined,
                                size: 16,
                              ),
                              label: const Text('เปิดใบรับรองจริง'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('กลับไปประวัติการตรวจ'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
