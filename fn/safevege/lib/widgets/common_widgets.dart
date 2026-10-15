import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../models/app_models.dart';
import 'interactive_animations.dart';
export 'responsive_content.dart';

class SafeVegeLogo extends StatelessWidget {
  const SafeVegeLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.subtitle,
  });

  final double size;
  final bool showText;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/safevege_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SafeVege',
                style: TextStyle(
                  color: AppColors.primaryOf(context),
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.large = false});

  final dynamic status; // Can be RequestStatus or String or bool
  final bool large;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData? icon;

    if (status == null) {
      bg = AppColors.warningBgOf(context);
      fg = AppColors.warning;
      label = 'ยังไม่บันทึก';
      icon = Icons.pending_outlined;
    } else if (status is RequestStatus) {
      final reqStatus = status as RequestStatus;
      switch (reqStatus) {
        case RequestStatus.pending:
          bg = AppColors.warningBgOf(context);
          fg = AppColors.warning;
          label = 'รอดำเนินการ';
          icon = Icons.hourglass_top_rounded;
          break;
        case RequestStatus.scheduled:
          bg = AppColors.infoBgOf(context);
          fg = AppColors.info;
          label = 'นัดหมายแล้ว';
          icon = Icons.event_available_rounded;
          break;
        case RequestStatus.inProgress:
          bg = const Color(0xFFEDE9FE);
          fg = const Color(0xFF7C3AED);
          label = 'กำลังตรวจสอบ';
          icon = Icons.biotech_rounded;
          break;
        case RequestStatus.completed:
          bg = AppColors.successBgOf(context);
          fg = AppColors.success;
          label = 'เสร็จสิ้น';
          icon = Icons.check_circle_rounded;
          break;
        case RequestStatus.cancelled:
          bg = AppColors.dangerBgOf(context);
          fg = AppColors.danger;
          label = 'ยกเลิกแล้ว';
          icon = Icons.cancel_rounded;
          break;
      }
    } else if (status is bool) {
      final passed = status as bool;
      if (passed) {
        bg = AppColors.successBgOf(context);
        fg = AppColors.success;
        label = 'ผ่านการตรวจ';
        icon = Icons.verified_rounded;
      } else {
        bg = AppColors.dangerBgOf(context);
        fg = AppColors.danger;
        label = 'ไม่ผ่านการตรวจ';
        icon = Icons.cancel_rounded;
      }
    } else {
      final str = status.toString();
      if (str.contains('ผ่าน') && !str.contains('ไม่ผ่าน')) {
        bg = AppColors.successBgOf(context);
        fg = AppColors.success;
        label = str;
        icon = Icons.verified_rounded;
      } else if (str.contains('ไม่ผ่าน')) {
        bg = AppColors.dangerBgOf(context);
        fg = AppColors.danger;
        label = str;
        icon = Icons.cancel_rounded;
      } else if (str.contains('นัด') || str.contains('รอ')) {
        bg = AppColors.warningBgOf(context);
        fg = AppColors.warning;
        label = str;
        icon = Icons.schedule_rounded;
      } else {
        bg = AppColors.infoBgOf(context);
        fg = AppColors.info;
        label = str;
        icon = Icons.info_outline_rounded;
      }
    }

    return AnimatedContainer(
      duration: MotionTokens.stateChange,
      curve: MotionTokens.curve,
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 8,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: fg.withOpacity(0.2), width: 1),
      ),
      child: AnimatedSwitcher(
        duration: MotionTokens.micro,
        switchInCurve: MotionTokens.curve,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final scale = Tween<double>(begin: 0.96, end: 1).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        child: Row(
          key: ValueKey('$label-$large'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: large ? 16 : 13, color: fg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: large ? 13 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.message = 'กำลังโหลดข้อมูล...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedEntrance(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  color: AppColors.primaryOf(context),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    this.title = 'เกิดข้อผิดพลาด',
    this.message = 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
    this.onRetry,
    this.isNetworkError = false,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool isNetworkError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedEntrance(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.dangerBgOf(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNetworkError
                      ? Icons.wifi_off_rounded
                      : Icons.error_outline_rounded,
                  size: 42,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isNetworkError ? 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้' : title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textSecondaryOf(context),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('ลองอีกครั้ง'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.search_off_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedEntrance(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingElement(
                distance: 5.0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundOf(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.borderOf(context),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 40, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimaryOf(context),
                ),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  style: TextStyle(
                    color: AppColors.textSecondaryOf(context),
                    fontSize: 13.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(140, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ConfirmActionDialog extends StatelessWidget {
  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'ยืนยัน',
    this.cancelLabel = 'ยกเลิก',
    this.isDestructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'ยืนยัน',
    String cancelLabel = 'ยกเลิก',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmActionDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDestructive
              ? AppColors.danger
              : AppColors.textPrimaryOf(context),
        ),
      ),
      content: Text(
        message,
        style: TextStyle(
          fontSize: 14.5,
          color: AppColors.textSecondaryOf(context),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelLabel,
            style: TextStyle(color: AppColors.textMutedOf(context)),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: isDestructive
                ? AppColors.danger
                : AppColors.primary,
            minimumSize: const Size(100, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class AppFeedback {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 20, color: primaryColor),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? AppDarkColors.textSecondary
                          : AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

String _safeVegeEmoji(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('สลัด') ||
      lower.contains('กาด') ||
      lower.contains('ผักกาด')) {
    return '🥬';
  }
  if (lower.contains('คะน้า') ||
      lower.contains('บร็อค') ||
      lower.contains('บล็อค')) {
    return '🥦';
  }
  if (lower.contains('เขือ')) return '🍅';
  if (lower.contains('กะหล่ำ')) return '🥗';
  if (lower.contains('แตง')) return '🥒';
  if (lower.contains('พริก')) return '🌶️';
  if (lower.contains('ข้าวโพด')) return '🌽';
  if (lower.contains('แครอท')) return '🥕';
  if (lower.contains('หอม') || lower.contains('กระเทียม')) return '🧅';
  if (lower.contains('เห็ด')) return '🍄';
  if (lower.contains('ถั่ว')) return '🫛';
  return '🌱';
}

String _safeVegeLocationText(ShopModel shop, String? distanceText) {
  if (distanceText != null &&
      distanceText != '—' &&
      distanceText.trim().isNotEmpty) {
    return distanceText;
  }
  if (shop.district.isNotEmpty) {
    return 'อ.${shop.district}';
  }
  return 'เชียงราย';
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: isDark
            ? AppDarkColors.surfaceElevated
            : const Color(0xFFF1F5F2),
        foregroundColor: isDark
            ? AppDarkColors.textPrimary
            : const Color(0xFF1C2E22),
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE4),
            width: 0.6,
          ),
        ),
      ),
      icon: Icon(icon, size: 12),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// การ์ดร้านค้าสไตล์ Marketplace Feed สำหรับ SafeVege
class MarketplaceShopCard extends StatelessWidget {
  const MarketplaceShopCard({
    super.key,
    required this.shop,
    required this.onTap,
    this.distanceText,
    this.onCall,
    this.onRoute,
    this.isFavorite = false,
    this.onFavorite,
  });

  final ShopModel shop;
  final String? distanceText;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onRoute;
  final bool isFavorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final surfaceColor = isDark ? AppDarkColors.surface : Colors.white;
    final borderColor = isDark
        ? AppDarkColors.border
        : AppColors.borderOf(context);
    final textPrimary = isDark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimaryOf(context);
    final textSecondary = isDark
        ? AppDarkColors.textSecondary
        : AppColors.textSecondaryOf(context);

    final locationOrDistance = _safeVegeLocationText(shop, distanceText);
    final isRealDistance =
        distanceText != null &&
        distanceText != '—' &&
        distanceText!.trim().isNotEmpty;

    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? borderColor : const Color(0xFFE2EBE4),
            width: 0.9,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0x0A0F3820),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lush botanical header banner with integrated info & badges
            Container(
              height: 76,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF132B1D),
                          Color(0xFF1B3D2A),
                          Color(0xFF153322),
                        ],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0C4D33),
                          Color(0xFF156E47),
                          Color(0xFF208A56),
                        ],
                      ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Stack(
                children: [
                  Positioned(
                    right: -6,
                    bottom: -18,
                    child: FloatingElement(
                      distance: 3.0,
                      child: Icon(
                        CupertinoIcons.leaf_arrow_circlepath,
                        size: 80,
                        color: Colors.white.withOpacity(isDark ? 0.07 : 0.12),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Farm / Shop Emblem squircle
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppDarkColors.surfaceElevated
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(
                              isDark ? 0.2 : 0.85,
                            ),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.35 : 0.1,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.eco_rounded,
                            color: isDark
                                ? AppDarkColors.primary
                                : const Color(0xFF167B4C),
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Verified SafeVege trust pill
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      isDark ? 0.14 : 0.22,
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.35),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PulseBadge(
                                        minScale: 0.9,
                                        maxScale: 1.15,
                                        duration: const Duration(milliseconds: 2000),
                                        child: const Icon(
                                          CupertinoIcons.checkmark_seal_fill,
                                          size: 11,
                                          color: Color(0xFF86EFAC),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        shop.isVerified
                                            ? 'ตรวจผ่านการรับรอง'
                                            : 'รอการตรวจรับรอง',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Distance / Location indicator pill
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(
                                        isDark ? 0.32 : 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isRealDistance
                                              ? CupertinoIcons.location_fill
                                              : CupertinoIcons.placemark,
                                          size: 10.5,
                                          color: const Color(0xFFD1FAE5),
                                        ),
                                        const SizedBox(width: 3.5),
                                        Flexible(
                                          child: Text(
                                            locationOrDistance,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (onFavorite != null) ...[
                        const SizedBox(width: 8),
                        AnimatedFavoriteHeart(
                          isFavorite: isFavorite,
                          onToggle: onFavorite!,
                          size: 19,
                          backgroundColor: Colors.black.withOpacity(
                            isDark ? 0.35 : 0.24,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Card Body Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop name
                  Text(
                    shop.name,
                    style: TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Area and owner info
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: isDark
                            ? AppDarkColors.secondary
                            : const Color(0xFF267D4F),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shop.ownerFullName.isNotEmpty
                              ? '${shop.shortArea} • เจ้าของ: ${shop.ownerFullName}'
                              : shop.shortArea,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Certified vegetables tags or safety guarantee
                  if (shop.verifiedVegetables.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...shop.verifiedVegetables.map((veg) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1B2E21)
                                  : const Color(0xFFEBF6EE),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2D4D36)
                                    : const Color(0xFFCFE8D5),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _safeVegeEmoji(veg),
                                  style: const TextStyle(fontSize: 11.5),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  veg,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF6EE7B7)
                                        : const Color(0xFF0F5A3C),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (shop.publicResults.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2E2413)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF523D18)
                                    : const Color(0xFFFDE68A),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.verified_outlined,
                                  size: 12,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ตรวจผ่าน ${shop.publicResults.length} ชนิด',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B2E21)
                            : const Color(0xFFEBF6EE),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2D4D36)
                              : const Color(0xFFCFE8D5),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🌱', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(
                            'ผักปลอดภัยผ่านเกณฑ์มาตรฐาน สสจ.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF0F5A3C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppDarkColors.borderLight
                        : const Color(0xFFEDF2EE),
                  ),
                  const SizedBox(height: 12),

                  // Actions row: Call, Directions, View Shop Details
                  Row(
                    children: [
                      if (onCall != null) ...[
                        _CardActionButton(
                          icon: CupertinoIcons.phone_fill,
                          label: 'โทร',
                          isDark: isDark,
                          onPressed: onCall!,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (onRoute != null) ...[
                        _CardActionButton(
                          icon: CupertinoIcons.arrow_turn_up_right,
                          label: 'นำทาง',
                          isDark: isDark,
                          onPressed: onRoute!,
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      PressableScale(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF22C55E),
                                      Color(0xFF16A34A),
                                    ],
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF0F5A3C),
                                      Color(0xFF167B4C),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark
                                        ? const Color(0xFF22C55E)
                                        : const Color(0xFF0F5A3C))
                                    .withOpacity(0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ดูร้านค้า',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFF04200E)
                                      : Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 12,
                                color: isDark
                                    ? const Color(0xFF04200E)
                                    : Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// การ์ดร้านค้าแนะนำในแนวนอน (Featured Horizontal Card)
class FeaturedFarmCard extends StatelessWidget {
  const FeaturedFarmCard({
    super.key,
    required this.shop,
    required this.onTap,
    this.distanceText,
  });

  final ShopModel shop;
  final VoidCallback onTap;
  final String? distanceText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final surfaceColor = isDark ? AppDarkColors.surface : Colors.white;
    final borderColor = isDark
        ? AppDarkColors.border
        : AppColors.borderOf(context);
    final textPrimary = isDark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimaryOf(context);
    final textSecondary = isDark
        ? AppDarkColors.textSecondary
        : AppColors.textSecondaryOf(context);

    final locationOrDistance = _safeVegeLocationText(shop, distanceText);
    final isRealDistance =
        distanceText != null &&
        distanceText != '—' &&
        distanceText!.trim().isNotEmpty;

    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 236,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isDark ? borderColor : const Color(0xFFE2ECE4),
            width: 0.9,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0x0A0F3820),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Soft Tint Cover with badges
            Container(
              height: 104,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF132A1C),
                          Color(0xFF1B3D2A),
                          Color(0xFF153322),
                        ],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0C4D33),
                          Color(0xFF17734B),
                          Color(0xFF26915B),
                        ],
                      ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -20,
                    child: Icon(
                      CupertinoIcons.leaf_arrow_circlepath,
                      size: 78,
                      color: Colors.white.withOpacity(isDark ? 0.08 : 0.12),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Row: Featured Badge + Verified Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xE01C261F)
                                  : Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.star_fill,
                                  size: 10,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ร้านแนะนำ',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppDarkColors.textPrimary
                                        : const Color(0xFF1C2E22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  size: 10,
                                  color: Color(0xFF86EFAC),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'รับรองแล้ว',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Bottom Row: Location / Distance Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.24),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isRealDistance
                                  ? CupertinoIcons.location_fill
                                  : CupertinoIcons.placemark,
                              size: 10,
                              color: const Color(0xFFD1FAE5),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              locationOrDistance,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Info Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: isDark
                                  ? AppDarkColors.secondary
                                  : const Color(0xFF267D4F),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                shop.shortArea,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Vegetable pills
                        if (shop.verifiedVegetables.isNotEmpty) ...[
                          SizedBox(
                            height: 24,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: shop.verifiedVegetables.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 5),
                              itemBuilder: (ctx, vIdx) {
                                final veg = shop.verifiedVegetables[vIdx];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1B2E21)
                                        : const Color(0xFFEBF6EE),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF2D4D36)
                                          : const Color(0xFFCFE8D5),
                                      width: 0.6,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _safeVegeEmoji(veg),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        veg,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isDark
                                              ? const Color(0xFF6EE7B7)
                                              : const Color(0xFF0F5A3C),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1B2E21)
                                  : const Color(0xFFEBF6EE),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '🌱 ตรวจรับรองความปลอดภัย',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark
                                    ? const Color(0xFF6EE7B7)
                                    : const Color(0xFF0F5A3C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Action cue
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ดูรายละเอียด',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 12,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// แบนเนอร์เพิ่มความมั่นใจ SafeVege Trust Banner
class TrustHighlightBanner extends StatelessWidget {
  const TrustHighlightBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppDarkColors.primary : AppColors.primary;
    final textPrimary = isDark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimaryOf(context);
    final textSecondary = isDark
        ? AppDarkColors.textSecondary
        : AppColors.textSecondaryOf(context);

    return PressableScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF142B1E), Color(0xFF0F1E15)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFF2FBF5), Color(0xFFE5F5EB)],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF285037) : const Color(0xFFC7E5CF),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(isDark ? 0.08 : 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF15764D), Color(0xFF0C4D32)],
                        ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(isDark ? 0.35 : 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: PulseBadge(
                    duration: const Duration(milliseconds: 2200),
                    minScale: 0.92,
                    maxScale: 1.1,
                    child: const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ตรวจสอบสถานะการรับรองก่อนเลือกซื้อ',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ดูผลตรวจและวันที่รับรองได้จากข้อมูลของแต่ละร้าน',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ดูผลตรวจ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: primaryColor,
                      size: 11,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({
    super.key,
    this.message = 'ข้อมูลตัวอย่าง • การเปลี่ยนแปลงไม่ถูกบันทึกขึ้นระบบ',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0D795)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF8C6413),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF72510E),
                fontSize: 11.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
