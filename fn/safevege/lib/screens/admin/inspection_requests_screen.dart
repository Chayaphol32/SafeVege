import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import 'admin_request_details_screen.dart';
import 'inspection_scheduling_screen.dart';
import 'record_result_screen.dart';

class InspectionRequestsScreen extends StatefulWidget {
  const InspectionRequestsScreen({
    super.key,
    required this.appState,
    this.initialTab = 0,
  });

  final AppState appState;
  final int initialTab;

  @override
  State<InspectionRequestsScreen> createState() =>
      _InspectionRequestsScreenState();
}

class _InspectionRequestsScreenState extends State<InspectionRequestsScreen> {
  late int _selectedTab;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InspectionRequestModel> _filterRequests(
    List<InspectionRequestModel> all,
  ) {
    return all.where((r) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchId = r.id.toLowerCase().contains(q);
        final matchShop = r.shopName.toLowerCase().contains(q);
        if (!matchId && !matchShop) return false;
      }

      switch (_selectedTab) {
        case 1:
          return r.status == RequestStatus.pending;
        case 2:
          return r.status == RequestStatus.scheduled;
        case 3:
          return r.status == RequestStatus.inProgress;
        case 4:
          return r.status == RequestStatus.completed;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final all = widget.appState.requests;
        final filtered = _filterRequests(all);

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(title: const Text('จัดการคำขอตรวจสอบ')),
          body: ResponsiveContent(
            maxWidth: 1120,
            padding: EdgeInsets.zero,
            child: SafeArea(
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อร้านค้าหรือหมายเลขคำขอ...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.primaryOf(context),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),

                  // Filter Tabs Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        _buildTab(0, 'ทั้งหมด (${all.length})'),
                        const SizedBox(width: 6),
                        _buildTab(
                          1,
                          'รอรับคำขอ (${all.where((r) => r.status == RequestStatus.pending).length})',
                        ),
                        const SizedBox(width: 6),
                        _buildTab(
                          2,
                          'นัดหมายแล้ว (${all.where((r) => r.status == RequestStatus.scheduled).length})',
                        ),
                        const SizedBox(width: 6),
                        _buildTab(
                          3,
                          'กำลังตรวจ (${all.where((r) => r.status == RequestStatus.inProgress).length})',
                        ),
                        const SizedBox(width: 6),
                        _buildTab(
                          4,
                          'เสร็จสิ้น (${all.where((r) => r.status == RequestStatus.completed).length})',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Requests list
                  Expanded(
                    child: filtered.isEmpty
                        ? EmptyStateView(
                            title: 'ไม่มีคำขอในรายการนี้',
                            message: 'ไม่พบคำขอตรวจสอบในสถานะที่เลือก',
                            actionLabel: 'ล้างตัวกรอง',
                            onAction: () {
                              setState(() {
                                _selectedTab = 0;
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
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
        );
      },
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedTab = index),
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
            const SizedBox(height: 6),
            Text(
              req.shopName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'รายการผัก (${req.vegetables.length} ชนิด): ${req.vegetables.join(", ")}',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            if (req.appointmentDate != null)
              Text(
                'วันนัดตรวจ: ${req.appointmentDate!.day}/${req.appointmentDate!.month}/${req.appointmentDate!.year + 543}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryOf(context),
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                'ส่งเมื่อ: ${req.submissionDate.day}/${req.submissionDate.month}/${req.submissionDate.year + 543}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMutedOf(context),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminRequestDetailsScreen(
                            request: req,
                            appState: widget.appState,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text(
                      'ดูรายละเอียด',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                if (req.isPending || req.isScheduled) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InspectionSchedulingScreen(
                              request: req,
                              appState: widget.appState,
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.event_outlined, size: 14),
                      label: Text(
                        req.isScheduled ? 'แก้ไขวันนัด' : 'นัดวันตรวจ',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ] else if (req.isInProgress) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecordResultScreen(
                              request: req,
                              appState: widget.appState,
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.verified_outlined, size: 14),
                      label: const Text(
                        'บันทึกผลตรวจ',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
