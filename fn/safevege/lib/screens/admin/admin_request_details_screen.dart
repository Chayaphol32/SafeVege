import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../models/app_models.dart';
import '../../state/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/interactive_map.dart';
import '../guest/certificate_viewer_screen.dart';
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
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reloadRequest();
    });
  }

  Future<void> _reloadRequest() async {
    setState(() => _isLoadingDetails = true);
    try {
      final request = await widget.appState.loadRequestDetails(_request.id);
      if (mounted) setState(() => _request = request);

      // Make sure admin shops are loaded so shop details (owner, phone) are populated
      if (!widget.appState.shops.any((s) => s.id == request.shopId)) {
        await widget.appState.loadAdminShops().catchError((Object _) {});
        if (mounted) setState(() {});
      }
    } catch (error) {
      if (mounted) AppFeedback.showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  ShopModel _resolveShop() {
    final matchingShops = widget.appState.shops
        .where((shop) => shop.id == _request.shopId)
        .toList();
    if (matchingShops.isNotEmpty) {
      return matchingShops.first;
    }
    // Fallback ShopModel synthesized from the request's snapshots
    return ShopModel(
      id: _request.shopId,
      name: _request.shopName,
      ownerFirstName: _request.shopName,
      ownerLastName: '',
      phone: '-',
      houseNo: _request.shopAddress,
      subDistrict: '',
      district: '',
      province: '',
      latitude: _request.latitude,
      longitude: _request.longitude,
      hasCoordinates: _request.latitude != 0 || _request.longitude != 0,
      createdAt: _request.submissionDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shop = _resolveShop();
    final hasCoords = _request.latitude != 0 || _request.longitude != 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('รายละเอียดคำขอตรวจ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'รีเฟรชข้อมูล',
            onPressed: _isLoadingDetails ? null : _reloadRequest,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: AppContentWidth.form,
          child: Column(
            children: [
              if (_isLoadingDetails)
                const LinearProgressIndicator(
                  minHeight: 2.5,
                  backgroundColor: Colors.transparent,
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  children: [
                    // Header Status Card
                    _buildHeaderStatusCard(isDark),
                    const SizedBox(height: 14),

                    // SECTION 1: Shop & Farm Location
                    _buildShopInfoCard(shop, hasCoords, isDark),
                    const SizedBox(height: 14),

                    // SECTION 2: Request Vegetables
                    _buildVegetablesCard(isDark),
                    const SizedBox(height: 14),

                    // SECTION 3: Appointment Information
                    _buildAppointmentCard(isDark),
                    const SizedBox(height: 14),

                    // SECTION 4: Inspection Results (if any)
                    if (_request.results.isNotEmpty || _request.isCompleted) ...[
                      _buildResultsCard(isDark),
                      const SizedBox(height: 14),
                    ],

                    // SECTION 5: Action Buttons
                    _buildActionButtons(isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStatusCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE5),
          width: 1,
        ),
        boxShadow: isDark ? null : AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF14281B)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment_rounded,
              size: 26,
              color: isDark ? AppDarkColors.primaryAccent : AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'คำขอ #${_request.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: isDark ? AppDarkColors.primaryAccent : AppColors.primary,
                      ),
                    ),
                    if (_request.requestNumber != null &&
                        _request.requestNumber!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _request.requestNumber!,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ส่งเมื่อ: ${_request.submissionDate.day}/${_request.submissionDate.month}/${_request.submissionDate.year + 543} เวลา ${_request.submissionDate.hour.toString().padLeft(2, '0')}:${_request.submissionDate.minute.toString().padLeft(2, '0')} น.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: _request.status, large: true),
        ],
      ),
    );
  }

  Widget _buildShopInfoCard(ShopModel shop, bool hasCoords, bool isDark) {
    final hasOwnerName = shop.ownerLastName.isNotEmpty;
    final hasPhone = shop.phone.isNotEmpty && shop.phone != '-';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE5),
          width: 1,
        ),
        boxShadow: isDark ? null : AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 20,
                color: isDark ? AppDarkColors.primaryAccent : AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'ข้อมูลร้านค้าและสถานที่ตรวจ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _request.shopName,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          if (hasOwnerName || hasPhone) ...[
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: AppColors.textSecondaryOf(context),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    hasOwnerName
                        ? 'เจ้าของร้าน: ${shop.ownerFullName}${hasPhone ? " • โทร: ${shop.phone}" : ""}'
                        : 'โทร: ${shop.phone}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.place_outlined,
                  size: 15,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _request.shopAddress.isNotEmpty
                      ? _request.shopAddress
                      : (shop.fullAddress.isNotEmpty
                          ? shop.fullAddress
                          : 'ไม่ระบุที่อยู่แปลง'),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(context),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (hasCoords) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.my_location_rounded,
                  size: 14,
                  color: isDark ? AppDarkColors.primaryAccent : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'พิกัด: ${_request.latitude.toStringAsFixed(5)}, ${_request.longitude.toStringAsFixed(5)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.primaryAccent : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 140,
                child: SafeVegeInteractiveMap(
                  height: 140,
                  compact: true,
                  shops: [shop],
                  selectedShop: shop,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVegetablesCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE5),
          width: 1,
        ),
        boxShadow: isDark ? null : AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.eco_rounded,
                    size: 20,
                    color: isDark ? AppDarkColors.primaryAccent : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'รายการผักที่ขอรับการตรวจ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF14281B)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${_request.vegetables.length} ชนิด',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppDarkColors.primaryAccent : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_request.vegetables.isEmpty)
            Text(
              'ไม่มีรายการผักระบุไว้',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMutedOf(context),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _request.vegetables.map((v) {
                final emoji = safeVegeEmoji(v);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF192E21)
                        : const Color(0xFFF1F8F4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF234430)
                          : const Color(0xFFD3E7DC),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        v,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF1B4332),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(bool isDark) {
    final hasAppDate = _request.appointmentDate != null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE5),
          width: 1,
        ),
        boxShadow: isDark ? null : AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 20,
                color: isDark ? AppDarkColors.primaryAccent : AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'ข้อมูลการนัดหมายตรวจสอบ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasAppDate) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14281B) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF234430) : const Color(0xFFC8E6C9),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_rounded,
                    color: isDark ? AppDarkColors.primaryAccent : AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'วันนัดหมายเข้าตรวจสอบแปลง:',
                          style: TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_request.appointmentDate!.day}/${_request.appointmentDate!.month}/${_request.appointmentDate!.year + 543}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isDark ? AppDarkColors.primaryAccent : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_request.appointmentNotes != null &&
                _request.appointmentNotes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'หมายเหตุ: ${_request.appointmentNotes}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2B2412) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF524419) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pending_actions_rounded,
                    color: const Color(0xFFD97706),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ยังไม่ได้กำหนดวันนัดหมายเข้าตรวจสอบ\nท่านสามารถกดปุ่ม "กำหนดวันนัดตรวจ" ด้านล่างได้ทันที',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFB45309),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE5),
          width: 1,
        ),
        boxShadow: isDark ? null : AppShadows.cardOf(context),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.biotech_rounded,
                size: 20,
                color: isDark ? AppDarkColors.primaryAccent : AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'ผลการตรวจวิเคราะห์ทางห้องแล็บ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_request.results.isEmpty)
            Text(
              'ยังไม่มีการบันทึกผลการตรวจในระบบ',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMutedOf(context),
              ),
            )
          else ...[
            ..._request.results.map((res) {
              final isPassed = res.passed == true || res.outcome == 'passed';
              final isFailed = res.passed == false || res.outcome == 'failed';
              final outcomeColor = isPassed
                  ? const Color(0xFF16A34A)
                  : isFailed
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFD97706);
              final outcomeText = isPassed
                  ? 'ปลอดภัย (ผ่าน)'
                  : isFailed
                      ? 'พบสารตกค้าง (ไม่ผ่าน)'
                      : 'รอวิเคราะห์';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16231A) : const Color(0xFFF9FBFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppDarkColors.border : const Color(0xFFE9EFEA),
                  ),
                ),
                child: Row(
                  children: [
                    Text(safeVegeEmoji(res.name), style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            res.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          if (res.details != null && res.details!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              res.details!,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: outcomeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        outcomeText,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: outcomeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (_request.hasCertificate) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF122C1A) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF225B36) : const Color(0xFFA5D6A7),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: isDark ? AppDarkColors.primaryAccent : AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'มีใบรับรองความปลอดภัย SafeVege',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'เลขที่: ${_request.certificateNumber ?? "-"}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CertificateViewerScreen(
                            shopName: _request.shopName,
                            certNumber: _request.certificateNumber ?? '',
                            certificateId: _request.certificateId,
                            certificateFileName: _request.certificateFileName,
                            expiryDate: _request.certificateExpiryDate,
                            vegetables: _request.vegetables,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('ดูใบรับรอง', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(
      children: [
        if (_request.isPending) ...[
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
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
              icon: const Icon(Icons.event_available_rounded, size: 18),
              label: const Text(
                'กำหนดวันนัดตรวจแปลง',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ] else if (_request.isScheduled) ...[
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
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
              icon: const Icon(Icons.biotech_rounded, size: 18),
              label: const Text(
                'บันทึกผลการตรวจแล็บ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
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
              icon: const Icon(Icons.edit_calendar_outlined, size: 18),
              label: const Text('แก้ไขวันนัดหมาย'),
            ),
          ),
        ] else if (_request.isInProgress) ...[
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
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
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: const Text(
                'บันทึกผลการตรวจสอบ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ] else if (_request.isCompleted) ...[
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
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
              icon: const Icon(Icons.workspace_premium_outlined, size: 18),
              label: const Text(
                'ดูรายละเอียดผลตรวจและใบรับรอง',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('กลับไปรายการคำขอ'),
          ),
        ),
      ],
    );
  }
}
