import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../guest/certificate_viewer_screen.dart';
import 'result_management_screen.dart';

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String _statusFilter = 'ทั้งหมด'; // 'ทั้งหมด', 'ผ่าน', 'ไม่ผ่าน'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InspectionRequestModel> _getHistoryRequests() {
    return widget.appState.requests.where((r) {
      if (!r.isCompleted) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchId = r.id.toLowerCase().contains(q);
        final matchShop = r.shopName.toLowerCase().contains(q);
        if (!matchId && !matchShop) return false;
      }
      if (_statusFilter == 'ผ่าน' && !r.allPassed) return false;
      if (_statusFilter == 'ไม่ผ่าน' && r.allPassed) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final historyList = _getHistoryRequests();

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(title: const Text('ประวัติการตรวจสอบ')),
      body: ResponsiveContent(
        maxWidth: 1120,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: Column(
            children: [
              // Search & Filter
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    TextField(
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
                    const SizedBox(height: 8),
                    Row(
                      children: ['ทั้งหมด', 'ผ่าน', 'ไม่ผ่าน'].map((st) {
                        final isSel = _statusFilter == st;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(st),
                            selected: isSel,
                            onSelected: (_) =>
                                setState(() => _statusFilter = st),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // History list
              Expanded(
                child: historyList.isEmpty
                    ? EmptyStateView(
                        title: 'ไม่พบประวัติการตรวจสอบ',
                        message: 'ยังไม่มีคำขอที่ผ่านกระบวนการตรวจเสร็จสิ้นตรงกับตัวกรองนี้',
                        actionLabel: 'ล้างตัวกรอง',
                        onAction: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                            _statusFilter = 'ทั้งหมด';
                          });
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: historyList.length,
                        itemBuilder: (ctx, idx) {
                          final req = historyList[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        req.id,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.primaryOf(context),
                                        ),
                                      ),
                                      StatusBadge(status: req.allPassed),
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
                                  Text(
                                    'วันที่ตรวจ: ${req.inspectionDate != null ? "${req.inspectionDate!.day}/${req.inspectionDate!.month}/${req.inspectionDate!.year + 543}" : "-"}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondaryOf(context),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ผักที่ผ่าน: ${req.results.where((result) => result.passed == true).map((result) => result.name).join(", ")}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
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
                                                builder: (_) =>
                                                    ResultManagementScreen(
                                                      request: req,
                                                      appState: widget.appState,
                                                    ),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            minimumSize: const Size(0, 36),
                                          ),
                                          child: const Text(
                                            'ดูรายละเอียดผลตรวจ',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: req.hasCertificate
                                            ? FilledButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => CertificateViewerScreen(
                                                        shopName: req.shopName,
                                                        certNumber: req
                                                            .certificateNumber!,
                                                        certificateId:
                                                            req.certificateId,
                                                        certificateFileName: req
                                                            .certificateFileName,
                                                        vegetables: req.results
                                                            .where(
                                                              (result) =>
                                                                  result
                                                                      .passed ==
                                                                  true,
                                                            )
                                                            .map(
                                                              (result) =>
                                                                  result.name,
                                                            )
                                                            .toList(),
                                                        issueDate:
                                                            req.inspectionDate,
                                                        expiryDate: req
                                                            .certificateExpiryDate,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: FilledButton.styleFrom(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  minimumSize: const Size(
                                                    0,
                                                    36,
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons
                                                      .workspace_premium_rounded,
                                                  size: 14,
                                                ),
                                                label: const Text(
                                                  'ดูตัวอย่างใบรับรอง',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              )
                                            : OutlinedButton.icon(
                                                onPressed: null,
                                                icon: const Icon(
                                                  Icons
                                                      .workspace_premium_outlined,
                                                  size: 14,
                                                ),
                                                label: const Text(
                                                  'ไม่มีใบรับรอง',
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
