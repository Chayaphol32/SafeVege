import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/common_widgets.dart';

class CertificateViewerScreen extends StatefulWidget {
  const CertificateViewerScreen({
    super.key,
    required this.shopName,
    required this.certNumber,
    this.vegetables = const [],
    this.certificateId,
    this.certificateFileName,
    this.issueDate,
    this.expiryDate,
    this.inspectorName,
  });

  final String shopName;
  final String certNumber;
  final String? certificateId;
  final List<String> vegetables;
  final String? certificateFileName;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? inspectorName;

  @override
  State<CertificateViewerScreen> createState() =>
      _CertificateViewerScreenState();
}

class _CertificateViewerScreenState extends State<CertificateViewerScreen> {
  bool _isOpening = false;

  void _shareCertificate() {
    final vegList = widget.vegetables.isNotEmpty
        ? widget.vegetables.join(', ')
        : 'ผักปลอดภัยทั้งหมด';
    final shareText =
        'ใบรับรองผักปลอดภัย SafeVege\n'
        'ร้านค้า: ${widget.shopName}\n'
        'เลขที่ใบรับรอง: ${widget.certNumber}\n'
        'รายการผักที่ผ่านการตรวจ: $vegList\n'
        'วันที่ออก: ${_date(widget.issueDate)} - หมดอายุ: ${_date(widget.expiryDate)}\n'
        'ตรวจสอบความปลอดภัยได้ที่ SafeVege เชียงราย';

    Clipboard.setData(ClipboardData(text: shareText));
    AppFeedback.showSuccess(
      context,
      'คัดลอกข้อมูลใบรับรองสำหรับแชร์เรียบร้อยแล้ว',
    );
  }

  Future<void> _openOriginalFile() async {
    final id = widget.certificateId;
    if (id == null || id.isEmpty) {
      AppFeedback.showInfo(
        context,
        'เอกสารใบรับรองฉบับดิจิทัลถูกรับรองบนระบบ SafeVege แล้ว',
      );
      return;
    }

    setState(() => _isOpening = true);
    try {
      final base = AppConfig.apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
      final uri = Uri.parse('$base/certificates/$id/file');
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (error) {
      if (mounted) AppFeedback.showError(context, error.toString());
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  String _date(DateTime? value) {
    if (value == null) return 'ไม่ระบุ';
    return '${value.day}/${value.month}/${value.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: const Text('ใบรับรองผักปลอดภัย'),
        actions: [
          IconButton(
            tooltip: 'แชร์ใบรับรอง',
            icon: const Icon(CupertinoIcons.share),
            onPressed: _shareCertificate,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: AppContentWidth.form,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Official Certificate Card Container with Luxury Border
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppDarkColors.surface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2A5038)
                        : const Color(0xFFC5E1CF),
                    width: 1.5,
                  ),
                  boxShadow: AppShadows.cardOf(context),
                ),
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Certificate Header with Crest
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF143820)
                                : const Color(0xFFE8F7EC),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified_rounded,
                            color: isDark
                                ? AppDarkColors.primary
                                : AppColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ใบรับรองมาตรฐานผักปลอดภัย',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppDarkColors.textPrimary
                                      : AppColors.textPrimaryOf(context),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'SAFEVEGE OFFICIAL CERTIFICATION',
                                style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppDarkColors.primary
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppDarkColors.borderLight
                          : AppColors.borderLightOf(context),
                    ),
                    const SizedBox(height: 16),

                    // Shop Name & Certificate No
                    Text(
                      widget.shopName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppDarkColors.textPrimary
                            : AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'เลขที่รับรอง: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppDarkColors.textSecondary
                                : AppColors.textSecondaryOf(context),
                          ),
                        ),
                        Text(
                          widget.certNumber,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppDarkColors.primary
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Detailed Grid
                    _CertificateDetail(
                      label: 'วันที่ออกใบรับรอง',
                      value: _date(widget.issueDate),
                    ),
                    _CertificateDetail(
                      label: 'วันหมดอายุการรับรอง',
                      value: _date(widget.expiryDate),
                    ),
                    if (widget.inspectorName?.isNotEmpty == true)
                      _CertificateDetail(
                        label: 'ผู้ตรวจสอบและอนุมัติ',
                        value: widget.inspectorName!,
                      ),
                    if (widget.certificateFileName?.isNotEmpty == true)
                      _CertificateDetail(
                        label: 'เอกสารอ้างอิง',
                        value: widget.certificateFileName!,
                      ),

                    // Vegetables List
                    if (widget.vegetables.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'รายการผักที่ผ่านการตรวจสารตกค้าง (100% ปลอดภัย):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppDarkColors.textPrimary
                              : AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.vegetables
                            .map(
                              (name) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF143820)
                                      : const Color(0xFFE8F7EC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? AppDarkColors.primary.withOpacity(0.3)
                                        : AppColors.primary.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 13,
                                      color: isDark
                                          ? AppDarkColors.primary
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppDarkColors.primary
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 20),
                    Divider(
                      height: 1,
                      color: isDark
                          ? AppDarkColors.borderLight
                          : AppColors.borderLightOf(context),
                    ),
                    const SizedBox(height: 16),

                    // QR Verification Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppDarkColors.surfaceSubtle
                            : const Color(0xFFF7FAF7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppDarkColors.borderLight
                              : AppColors.borderLightOf(context),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              size: 44,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'QR CODE ตรวจสอบความถูกต้อง',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'สแกนเพื่อตรวจสอบสถานะผลแล็บจริงผ่านฐานข้อมูล SafeVege เชียงราย',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppDarkColors.textSecondary
                                        : AppColors.textSecondaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareCertificate,
                      icon: const Icon(CupertinoIcons.share, size: 18),
                      label: const Text('แชร์ข้อมูล'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isOpening ? null : _openOriginalFile,
                      icon: _isOpening
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        _isOpening ? 'กำลังเปิดไฟล์…' : 'เปิดไฟล์ใบรับรองจริง',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CertificateDetail extends StatelessWidget {
  const _CertificateDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondaryOf(context)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
