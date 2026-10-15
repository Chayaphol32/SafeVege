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

/// Curated high quality vegetable, farm, and organic market photos matching SafeVege demo
String getShopImageUrl(ShopModel shop) {
  final name = shop.name.toLowerCase();
  if (name.contains('ริมกก')) {
    return 'https://images.unsplash.com/photo-1488459716781-31db52582fe9?auto=format&fit=crop&w=600&q=80'; // Fresh vegetable market stall
  }
  if (name.contains('บ้านดอย')) {
    return 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80'; // Crisp green salad lettuce farm
  }
  if (name.contains('สุขใจ')) {
    return 'https://images.unsplash.com/photo-1573246123716-6b1782bfc499?auto=format&fit=crop&w=600&q=80'; // Fresh greens, tomatoes and market produce
  }
  final fallbackImages = [
    'https://images.unsplash.com/photo-1488459716781-31db52582fe9?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1573246123716-6b1782bfc499?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?auto=format&fit=crop&w=600&q=80',
  ];
  return fallbackImages[shop.id.hashCode.abs() % fallbackImages.length];
}

Widget _buildFallbackImage(bool isDark) {
  return Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1B3D2A) : const Color(0xFFE2EFE5),
    ),
    child: Center(
      child: Icon(
        Icons.eco_rounded,
        color: isDark ? AppDarkColors.primary : const Color(0xFF10B981),
        size: 28,
      ),
    ),
  );
}

Widget _buildPillAction({
  required String label,
  required IconData icon,
  required bool isDark,
  required VoidCallback onTap,
}) {
  return PressableScale(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceElevated : const Color(0xFFF1F5F2),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark ? AppDarkColors.border : const Color(0xFFE2EBE4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12.5,
            color: isDark ? AppDarkColors.textSecondary : const Color(0xFF475569),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppDarkColors.textPrimary : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    ),
  );
}

List<Widget> _buildShopTagList(ShopModel shop, bool isDark, {int maxTags = 3}) {
  final tags = <Widget>[
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF143820) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '🌱 ตรวจรับรองความปลอดภัย',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
        ),
      ),
    ),
  ];

  if (shop.verifiedVegetables.isNotEmpty) {
    for (final veg in shop.verifiedVegetables.take(maxTags - 1)) {
      tags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            '${_safeVegeEmoji(veg)} $veg',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ),
      );
    }
  } else {
    tags.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          'ผักหลากหลาย',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
      ),
    );
    if (maxTags >= 3) {
      tags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            'ราคายุติธรรม',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ),
      );
    }
  }

  return tags;
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

    final isRealDistance =
        distanceText != null &&
        distanceText != '—' &&
        distanceText!.trim().isNotEmpty;
    final imageUrl = getShopImageUrl(shop);
    final displayDistance = isRealDistance ? distanceText! : 'ใกล้ฉัน';

    final isWide = MediaQuery.sizeOf(context).width >= 650;

    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(12),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Photo on left
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 120,
                      height: 96,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, _) => _buildFallbackImage(isDark),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // 2. Middle column: Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shop.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              shop.shortArea,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '|',
                              style: TextStyle(fontSize: 11, color: borderColor),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              CupertinoIcons.location_fill,
                              size: 11,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              displayDistance,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _buildShopTagList(shop, isDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 3. Right column: Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onFavorite != null)
                            IconButton(
                              onPressed: onFavorite,
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                isFavorite
                                    ? CupertinoIcons.heart_fill
                                    : CupertinoIcons.heart,
                                color: isFavorite
                                    ? const Color(0xFFEF4444)
                                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                size: 20,
                              ),
                            ),
                          const SizedBox(width: 6),
                          FilledButton(
                            onPressed: onTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ดูร้านค้า',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(CupertinoIcons.chevron_right, size: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onCall != null)
                            _buildPillAction(
                              label: 'โทร',
                              icon: Icons.phone_rounded,
                              isDark: isDark,
                              onTap: onCall!,
                            ),
                          const SizedBox(width: 8),
                          if (onRoute != null)
                            _buildPillAction(
                              label: 'นำทาง',
                              icon: CupertinoIcons.arrow_turn_up_right,
                              isDark: isDark,
                              onTap: onRoute!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              )
            // Compact / Mobile Layout (< 650px)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: SizedBox(
                        width: 105,
                        height: 90,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, _) => _buildFallbackImage(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  shop.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (onFavorite != null)
                                GestureDetector(
                                  onTap: onFavorite,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Icon(
                                      isFavorite
                                          ? CupertinoIcons.heart_fill
                                          : CupertinoIcons.heart,
                                      color: isFavorite
                                          ? const Color(0xFFEF4444)
                                          : (isDark ? Colors.white60 : const Color(0xFF94A3B8)),
                                      size: 19,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 2),
                              Flexible(
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
                              const SizedBox(width: 4),
                              Text('|', style: TextStyle(fontSize: 10, color: borderColor)),
                              const SizedBox(width: 4),
                              Text(
                                displayDistance,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: _buildShopTagList(shop, isDark, maxTags: 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: isDark ? AppDarkColors.borderLight : const Color(0xFFF1F5F2),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    if (onCall != null)
                      _buildPillAction(
                        label: 'โทร',
                        icon: Icons.phone_rounded,
                        isDark: isDark,
                        onTap: onCall!,
                      ),
                    const SizedBox(width: 8),
                    if (onRoute != null)
                      _buildPillAction(
                        label: 'นำทาง',
                        icon: CupertinoIcons.arrow_turn_up_right,
                        isDark: isDark,
                        onTap: onRoute!,
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ดูร้านค้า',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(CupertinoIcons.chevron_right, size: 11),
                        ],
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

    final imageUrl = getShopImageUrl(shop);

    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 275,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
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
            // Top Farm/Vegetable Photo with Badges
            SizedBox(
              height: 115,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, _) => _buildFallbackImage(isDark),
                  ),
                  // Dark gradient scrim at the top for badge contrast
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Left Badge: ร้านแนะนำ
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.star_fill,
                            size: 10,
                            color: Color(0xFFF59E0B),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'ร้านแนะนำ',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right Badge: รับรองแล้ว
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F5A3C).withOpacity(0.94),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 10,
                            color: Color(0xFF86EFAC),
                          ),
                          SizedBox(width: 3),
                          Text(
                            'รับรองแล้ว',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12.5,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                shop.shortArea,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: _buildShopTagList(shop, isDark, maxTags: 2),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ดูรายละเอียด',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_right,
                          size: 11,
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
                  colors: [Color(0xFF13281C), Color(0xFF0F1E15)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFEFFBF3), Color(0xFFE4F7EC)],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF285037) : const Color(0xFFCFEBD6),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(isDark ? 0.08 : 0.06),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF0F5A3C), Color(0xFF08412B)],
                        ),
                  borderRadius: BorderRadius.circular(14),
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
                      CupertinoIcons.checkmark_shield_fill,
                      color: Colors.white,
                      size: 22,
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
                        fontSize: 14,
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
                        fontSize: 11.5,
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
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F3D2B) : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2E5E41) : const Color(0xFFD6EDE0),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ดูผลตรวจ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF0F5A3C),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF0F5A3C),
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
