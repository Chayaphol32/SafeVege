import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_map.dart';
import 'inspection_scheduling_screen.dart';
import 'record_result_screen.dart';
import 'result_management_screen.dart';

class AdminRequestDetailsScreen extends StatefulWidget {
  const AdminRequestDetailsScreen({
    super.key,
    required this.request,
    required this.appState,
  });

  final InspectionRequestModel request;
  final AppState appState;

  @override
  State<AdminRequestDetailsScreen> createState() =>
      _AdminRequestDetailsScreenState();
}

class _AdminRequestDetailsScreenState extends State<AdminRequestDetailsScreen> {
  late InspectionRequestModel _request;
  bool _isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    _reloadRequest();
  }

  Future<void> _reloadRequest() async {
    setState(() => _isLoadingDetails = true);
    try {
      final request = await widget.appState.loadRequestDetails(_request.id);
      if (mounted) setState(() => _request = request);
    } catch (error) {
      if (mounted) AppFeedback.showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDetails) {
      return Scaffold(
        appBar: AppBar(title: const Text('รายละเอียดคำขอ')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final matchingShops = widget.appState.shops
        .where((shop) => shop.id == _request.shopId)
        .toList();
    if (matchingShops.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('รายละเอียดคำขอ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(widget.appState.errorMessage ?? 'ไม่พบข้อมูลร้านค้า'),
          ),
        ),
      );
    }
    final shop = matchingShops.first;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('รายละเอียดคำขอตรวจ')),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: AppContentWidth.form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status bar
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _request.id,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primaryOf(context),
                            ),
                          ),
                          Text(
                            'ส่งเมื่อ: ${_request.submissionDate.day}/${_request.submissionDate.month}/${_request.submissionDate.year + 543}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(status: _request.status, large: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // SECTION 1: Shop Information
              const SectionHeader(
                title: 'ข้อมูลร้านค้าและสถานที่ตรวจ',
                icon: Icons.storefront,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _request.shopName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'เจ้าของร้าน: ${shop.ownerFullName} • โทร: ${shop.phone}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ที่อยู่แปลง: ${_request.shopAddress}',
                        style: TextStyle(
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.primaryOf(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'พิกัด: ${_request.latitude.toStringAsFixed(4)}, ${_request.longitude.toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 120,
                          child: SafeVegeInteractiveMap(
                            height: 120,
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
              const SizedBox(height: 14),

              // SECTION 2: Request vegetables
              const SectionHeader(
                title: 'รายการผักที่ขอรับการตรวจ',
                icon: Icons.eco,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'จำนวนทั้งหมด ${_request.vegetables.length} ชนิด',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _request.vegetables.map((v) {
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
                            child: Text(
                              v,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // SECTION 3: Appointment info
              const SectionHeader(
                title: 'ข้อมูลการนัดหมายตรวจสอบ',
                icon: Icons.event,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_request.appointmentDate != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: AppColors.primaryOf(context),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'วันนัดตรวจ: ${_request.appointmentDate!.day}/${_request.appointmentDate!.month}/${_request.appointmentDate!.year + 543}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (_request.appointmentNotes != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'หมายเหตุ: ${_request.appointmentNotes}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          'ยังไม่ได้กำหนดวันนัดหมายตรวจสอบ',
                          style: TextStyle(
                            color: AppColors.textMutedOf(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons by Status
              if (_request.isPending) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InspectionSchedulingScreen(
                          request: _request,
                          appState: widget.appState,
                        ),
                      ),
                    );
                    if (res == true) _reloadRequest();
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('กำหนดวันนัดตรวจ'),
                ),
              ] else if (_request.isScheduled) ...[
                FilledButton.icon(
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordResultScreen(
                          request: _request,
                          appState: widget.appState,
                        ),
                      ),
                    );
                    if (res == true) _reloadRequest();
                  },
                  icon: const Icon(Icons.biotech_outlined),
                  label: const Text('บันทึกผลตรวจ'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InspectionSchedulingScreen(
                          request: _request,
                          appState: widget.appState,
                        ),
                      ),
                    );
                    if (res == true) _reloadRequest();
                  },
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('แก้ไขวันนัดหมาย'),
                ),
              ] else if (_request.isInProgress) ...[
                FilledButton.icon(
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordResultScreen(
                          request: _request,
                          appState: widget.appState,
                        ),
                      ),
                    );
                    if (res == true) _reloadRequest();
                  },
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('บันทึกผลการตรวจสอบ'),
                ),
              ] else if (_request.isCompleted) ...[
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultManagementScreen(
                          request: _request,
                          appState: widget.appState,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: const Text('ดูรายละเอียดผลตรวจและใบรับรอง'),
                ),
              ],

              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('กลับไปรายการคำขอ'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
