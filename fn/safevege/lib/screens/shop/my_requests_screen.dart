import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import 'create_request_screen.dart';
import 'request_tracking_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({
    super.key,
    required this.appState,
    this.initialFilterIndex = 0,
  });

  final AppState appState;
  final int initialFilterIndex;

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  late int _selectedFilterTab;

  @override
  void initState() {
    super.initState();
    _selectedFilterTab = widget.initialFilterIndex;
    widget.appState.loadMyRequests().catchError((Object _) {});
  }

  Future<void> _openRequest(InspectionRequestModel request) async {
    try {
      final details = await widget.appState.loadRequestDetails(request.id);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RequestTrackingScreen(request: details),
        ),
      );
    } catch (error) {
      if (mounted) AppFeedback.showError(context, error.toString());
    }
  }

  @override
  void didUpdateWidget(covariant MyRequestsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilterIndex != widget.initialFilterIndex) {
      _selectedFilterTab = widget.initialFilterIndex;
    }
  }

  List<InspectionRequestModel> _filterRequests(
    List<InspectionRequestModel> all,
  ) {
    switch (_selectedFilterTab) {
      case 1:
        return all.where((r) => r.status == RequestStatus.pending).toList();
      case 2:
        return all.where((r) => r.status == RequestStatus.scheduled).toList();
      case 3:
        return all.where((r) => r.status == RequestStatus.inProgress).toList();
      case 4:
        return all.where((r) => r.status == RequestStatus.completed).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final allRequests = widget.appState.currentShopRequests;
        final filtered = _filterRequests(allRequests);

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            title: const Text('คำขอตรวจสอบทั้งหมด'),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primaryOf(context),
                ),
                tooltip: 'ส่งคำขอใหม่',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CreateRequestScreen(appState: widget.appState),
                  ),
                ),
              ),
            ],
          ),
          body: ResponsiveContent(
            maxWidth: 1120,
            padding: EdgeInsets.zero,
            child: SafeArea(
              child: Column(
                children: [
                  // Filter Tabs Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        _buildFilterChip(0, 'ทั้งหมด (${allRequests.length})'),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          1,
                          'รอดำเนินการ (${allRequests.where((r) => r.status == RequestStatus.pending).length})',
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          2,
                          'นัดหมายแล้ว (${allRequests.where((r) => r.status == RequestStatus.scheduled).length})',
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          3,
                          'กำลังตรวจ (${allRequests.where((r) => r.status == RequestStatus.inProgress).length})',
                        ),
                        const SizedBox(width: 6),
                        _buildFilterChip(
                          4,
                          'เสร็จสิ้น (${allRequests.where((r) => r.status == RequestStatus.completed).length})',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Requests List
                  Expanded(
                    child: filtered.isEmpty && widget.appState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filtered.isEmpty &&
                              widget.appState.errorMessage != null
                        ? EmptyStateView(
                            title: 'โหลดคำขอไม่สำเร็จ',
                            message: widget.appState.errorMessage!,
                            actionLabel: 'ลองอีกครั้ง',
                            onAction: () => widget.appState
                                .loadMyRequests()
                                .catchError((Object _) {}),
                          )
                        : filtered.isEmpty
                        ? EmptyStateView(
                            title: 'ไม่พบคำขอในสถานะนี้',
                            message: 'ยังไม่มีรายการคำขอในหมวดหมู่นี้ คุณสามารถสร้างคำขอใหม่ได้ตลอดเวลา',
                            actionLabel: 'ส่งคำขอใหม่',
                            onAction: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CreateRequestScreen(
                                  appState: widget.appState,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, idx) {
                              final req = filtered[idx];
                              return _buildRequestCard(req);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateRequestScreen(appState: widget.appState),
              ),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('ส่งคำขอใหม่'),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterTab == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilterTab = index),
    );
  }

  Widget _buildRequestCard(InspectionRequestModel req) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    fontSize: 16,
                    color: AppColors.primaryOf(context),
                  ),
                ),
                StatusBadge(status: req.status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: AppColors.textMutedOf(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ส่งเมื่อ: ${req.submissionDate.day}/${req.submissionDate.month}/${req.submissionDate.year + 543}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
                if (req.appointmentDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 14,
                        color: AppColors.primaryOf(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'นัดตรวจ: ${req.appointmentDate!.day}/${req.appointmentDate!.month}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOf(context),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'รายการผัก (${req.vegetables.length} ชนิด): ${req.vegetables.join(', ')}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openRequest(req),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(0, 36),
                  ),
                  icon: const Icon(Icons.timeline, size: 16),
                  label: const Text(
                    'ติดตามสถานะ & ดูรายละเอียด',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
