import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_animations.dart';
import 'inspection_requests_screen.dart';
import 'admin_request_details_screen.dart';
import 'shop_management_screen.dart';
import 'admin_history_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _navIndex = 0;

  Future<void> _logout() async {
    final confirmed = await ConfirmActionDialog.show(
      context,
      title: 'ต้องการออกจากระบบผู้ดูแล?',
      message: 'คุณต้องการออกจากระบบบริหารจัดการ SafeVege ใช่หรือไม่?',
      confirmLabel: 'ออกจากระบบ',
      isDestructive: true,
    );

    if (confirmed && mounted) {
      widget.appState.logoutAdmin();
      Navigator.popUntil(context, (r) => r.isFirst);
      AppFeedback.showSuccess(context, 'ออกจากระบบผู้ดูแลเรียบร้อยแล้ว');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset('assets/safevege_logo.png', width: 34, height: 34),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ภาพรวมระบบผู้ดูแล',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        widget.appState.adminName,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryOf(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'ออกจากระบบ',
                onPressed: _logout,
              ),
            ],
          ),
          body: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppContentWidth.page,
                      ),
                      child: MotionSwitcher(
                        child: KeyedSubtree(
                          key: ValueKey(_navIndex),
                          child: _navIndex == 0
                              ? _buildDashboardHome()
                              : _navIndex == 1
                              ? InspectionRequestsScreen(
                                  appState: widget.appState,
                                )
                              : _navIndex == 2
                              ? ShopManagementScreen(appState: widget.appState)
                              : AdminHistoryScreen(appState: widget.appState),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _navIndex,
            onDestinationSelected: (idx) => setState(() => _navIndex = idx),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'ภาพรวม',
              ),
              NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment_rounded),
                label: 'คำขอตรวจ',
              ),
              NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront_rounded),
                label: 'ร้านค้า',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_rounded),
                selectedIcon: Icon(Icons.history),
                label: 'ประวัติ',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardHome() {
    final shops = widget.appState.shops;
    final requests = widget.appState.requests;

    final pending = requests
        .where((r) => r.status == RequestStatus.pending)
        .length;
    final scheduled = requests
        .where((r) => r.status == RequestStatus.scheduled)
        .length;
    final inProgress = requests
        .where((r) => r.status == RequestStatus.inProgress)
        .length;
    final completed = requests
        .where((r) => r.status == RequestStatus.completed)
        .length;

    final actionableRequests = requests
        .where((r) => r.status != RequestStatus.completed)
        .toList();
    final metricCards = <Widget>[
      _buildMetricCard(
        'ร้านค้าทั้งหมด',
        '${shops.length}',
        Icons.storefront,
        AppColors.primary,
      ),
      _buildMetricCard(
        'คำขอทั้งหมด',
        '${requests.length}',
        Icons.assignment,
        AppColors.secondary,
      ),
      _buildMetricCard(
        'รอดำเนินการ',
        '$pending',
        Icons.hourglass_top,
        AppColors.warning,
      ),
      _buildMetricCard(
        'นัดหมายแล้ว',
        '$scheduled',
        Icons.event_available,
        AppColors.info,
      ),
      _buildMetricCard(
        'กำลังตรวจ',
        '$inProgress',
        Icons.biotech,
        const Color(0xFF7C3AED),
      ),
      _buildMetricCard(
        'ตรวจเสร็จสิ้น',
        '$completed',
        Icons.verified,
        AppColors.success,
      ),
    ];
    final quickActions = <Widget>[
      _buildActionTile(
        icon: Icons.assignment_turned_in_outlined,
        title: 'จัดการคำขอ',
        color: AppColors.primaryOf(context),
        onTap: () => setState(() => _navIndex = 1),
      ),
      _buildActionTile(
        icon: Icons.event_note_outlined,
        title: 'นัดหมายตรวจ',
        color: AppColors.info,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InspectionRequestsScreen(
                appState: widget.appState,
                initialTab: 1,
              ),
            ),
          );
        },
      ),
      _buildActionTile(
        icon: Icons.verified_outlined,
        title: 'บันทึกผลตรวจ',
        color: const Color(0xFF7C3AED),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InspectionRequestsScreen(
                appState: widget.appState,
                initialTab: 3,
              ),
            ),
          );
        },
      ),
      _buildActionTile(
        icon: Icons.store_mall_directory_outlined,
        title: 'จัดการร้านค้า',
        color: AppColors.secondary,
        onTap: () => setState(() => _navIndex = 2),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Card(
          color: AppColors.surfaceOf(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundOf(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_turned_in_outlined,
                    color: AppColors.primaryOf(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'คิวงานที่ต้องทำ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${actionableRequests.length} คำขอยังไม่เสร็จ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'เปิดคิวคำขอ',
                  onPressed: () => setState(() => _navIndex = 1),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
          ),
        ),
        // Summary Cards Grid (2 rows)
        const SectionHeader(title: 'สถิติภาพรวมระบบ (System Metrics)'),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final columns = constraints.maxWidth < 560 ? 2 : 3;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final card in metricCards)
                  SizedBox(width: itemWidth, child: card),
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Quick Actions
        const SectionHeader(title: 'การดำเนินการด่วน (Quick Actions)'),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 8.0;
            final columns = constraints.maxWidth < 560 ? 2 : 4;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final action in quickActions)
                  SizedBox(width: itemWidth, child: action),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Actionable requests
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'คำขอที่ต้องดำเนินการ (${actionableRequests.length})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryOf(context),
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _navIndex = 1),
              child: const Text('ดูทั้งหมด'),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (actionableRequests.isEmpty)
          const EmptyStateView(
            title: 'ไม่มีคำขอที่ค้างดำเนินการ',
            message: 'คำขอตรวจสอบทั้งหมดได้รับการตรวจและบันทึกผลเสร็จสิ้นแล้ว',
            icon: Icons.check_circle_outline,
          )
        else
          ...actionableRequests.map((req) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
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
                            fontSize: 15,
                            color: AppColors.primaryOf(context),
                          ),
                        ),
                        StatusBadge(status: req.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      req.shopName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'ผักที่ขอตรวจ: ${req.vegetables.join(", ")}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton(
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
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            minimumSize: const Size(90, 34),
                          ),
                          child: const Text(
                            'ดูคำขอ',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondaryOf(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderOf(context)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
