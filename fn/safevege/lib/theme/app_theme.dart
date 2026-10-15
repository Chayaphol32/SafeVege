import 'package:flutter/material.dart';

import 'design_tokens.dart';
import '../widgets/interactive_animations.dart';

class AppColors {
  // Evergreen brand colors over a quiet, warm-neutral canvas.
  static const Color primary = Color(0xFF0F5A3C);
  static const Color secondary = Color(0xFF2A8A58);
  static const Color accent = Color(0xFFA6C85A);
  static const Color background = Color(0xFFF5F6F2);
  static const Color surface = Color(0xFFFFFEFC);
  static const Color surfaceGlass = Color(0xEBFFFFFF); // 92% Frosted Glass

  // Functional & Semantic
  static const Color textPrimary = Color(0xFF17241C);
  static const Color textSecondary = Color(0xFF56635A);
  static const Color textMuted = Color(0xFF758279);
  static const Color border = Color(0xFFE1E7E0);
  static const Color borderLight = Color(0xFFEDF1EC);

  // Status Colors (iOS Refined HSL)
  static const Color success = Color(0xFF208850);
  static const Color successBg = Color(0xFFE8F4EA);
  static const Color warning = Color(0xFFB9770E);
  static const Color warningBg = Color(0xFFFEF4DB);
  static const Color danger = Color(0xFFC13B3B);
  static const Color dangerBg = Color(0xFFFCECEC);
  static const Color info = Color(0xFF227FAD);
  static const Color infoBg = Color(0xFFEAF4FA);

  // Dynamic Theme Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color backgroundOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.background : background;

  static Color surfaceOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.surface : surface;

  static Color surfaceElevatedOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.surfaceElevated : surface;

  static Color textPrimaryOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.textPrimary : textPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.textSecondary : textSecondary;

  static Color textMutedOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.textMuted : textMuted;

  static Color borderOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.border : border;

  static Color borderLightOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.borderLight : borderLight;

  static Color primaryOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.primary : primary;

  static Color successBgOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.successBg : successBg;

  static Color warningBgOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.warningBg : warningBg;

  static Color dangerBgOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.dangerBg : dangerBg;

  static Color infoBgOf(BuildContext context) =>
      isDark(context) ? AppDarkColors.infoBg : infoBg;
}

class AppDarkColors {
  // OLED / Botanical Night Palette
  static const Color primary = Color(0xFF2FD66A); // Vibrant emerald highlight
  static const Color primaryAccent = primary;
  static const Color primaryGlow = Color(0x282FD66A);
  static const Color secondary = Color(0xFF4ADE80);
  static const Color accent = Color(0xFFA3E635);
  static const Color background = Color(0xFF0F1411); // Deep OLED canvas
  static const Color surface = Color(0xFF18201B); // Elevated card container
  static const Color surfaceElevated = Color(0xFF212B24); // Floating card
  static const Color surfaceSubtle = Color(0xFF1E2820);
  static const Color surfaceGlass = Color(0xEB18201B);

  // Functional & Semantic
  static const Color textPrimary = Color(0xFFF3F7F4); // Crisp warm white
  static const Color textSecondary = Color(0xFFA4B3A8); // Readable slate
  static const Color textMuted = Color(0xFF6B7A70);
  static const Color border = Color(0xFF263329); // Subtle dark hairline
  static const Color borderLight = Color(0xFF1E2820);

  // Status Colors (Vibrant on Dark)
  static const Color success = Color(0xFF34D399);
  static const Color successBg = Color(0xFF13361E);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningBg = Color(0xFF38260A);
  static const Color danger = Color(0xFFF87171);
  static const Color dangerBg = Color(0xFF381515);
  static const Color info = Color(0xFF38BDF8);
  static const Color infoBg = Color(0xFF0C2B42);
}

class AppGradients {
  static const LinearGradient primaryHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A452E), Color(0xFF105A3B), Color(0xFF167046)],
  );

  static const LinearGradient heroCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A4B32), Color(0xFF176C46)],
  );

  static const LinearGradient heroCardDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF13361E), Color(0xFF1B4E2B)],
  );

  static const LinearGradient accentLime = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF21894F), Color(0xFF95C950)],
  );

  static const LinearGradient softCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFEFC), Color(0xFFF8FAF6)],
  );

  static const LinearGradient softCardDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B241E), Color(0xFF18201B)],
  );

  static const LinearGradient verifiedRibbon = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B6338), Color(0xFF1B944F)],
  );
}

class AppShadows {
  // Quiet depth for clean, elevated surfaces.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A14251A), blurRadius: 22, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x040E2417), blurRadius: 5, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> cardDark = [
    BoxShadow(color: Color(0x28000000), blurRadius: 20, offset: Offset(0, 4)),
  ];

  static List<BoxShadow> cardOf(BuildContext context) =>
      AppColors.isDark(context) ? cardDark : card;

  static const List<BoxShadow> cardHover = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x140D5D35), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> searchBar = [
    BoxShadow(color: Color(0x06000000), blurRadius: 14, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> badge = [
    BoxShadow(color: Color(0x140D5D35), blurRadius: 10, offset: Offset(0, 2)),
  ];
}

class AppTheme {
  static const String thaiFontFamily = 'NotoSansThai';
  static const List<String> thaiFontFamilyFallback = [
    'Sarabun',
    'Noto Sans Thai',
    'Leelawadee UI',
    'Tahoma',
    'sans-serif',
  ];

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: SafeVegePageTransitionsBuilder(),
      TargetPlatform.iOS: SafeVegePageTransitionsBuilder(),
      TargetPlatform.linux: SafeVegePageTransitionsBuilder(),
      TargetPlatform.macOS: SafeVegePageTransitionsBuilder(),
      TargetPlatform.windows: SafeVegePageTransitionsBuilder(),
      TargetPlatform.fuchsia: SafeVegePageTransitionsBuilder(),
    },
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        brightness: Brightness.light,
      ),
      fontFamily: thaiFontFamily,
      fontFamilyFallback: thaiFontFamilyFallback,
      pageTransitionsTheme: _pageTransitions,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 30,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          height: 1.35,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: thaiFontFamily,
          fontFamilyFallback: thaiFontFamilyFallback,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(color: AppColors.primary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: thaiFontFamily,
            fontFamilyFallback: thaiFontFamilyFallback,
            letterSpacing: 0,
          ),
          elevation: 0,
        ).copyWith(animationDuration: MotionTokens.micro),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border, width: 1.0),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: thaiFontFamily,
            fontFamilyFallback: thaiFontFamilyFallback,
            letterSpacing: 0,
          ),
        ).copyWith(animationDuration: MotionTokens.micro),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: thaiFontFamily,
            fontFamilyFallback: thaiFontFamilyFallback,
            letterSpacing: 0,
          ),
        ).copyWith(animationDuration: MotionTokens.micro),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.successBg,
        side: const BorderSide(color: AppColors.border, width: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        labelStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontFamilyFallback: thaiFontFamilyFallback,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontFamilyFallback: thaiFontFamilyFallback,
        ),
        helperStyle: const TextStyle(fontSize: 13, height: 1.45),
        errorStyle: const TextStyle(fontSize: 13, height: 1.45),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.successBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontFamily: thaiFontFamily,
              fontFamilyFallback: thaiFontFamilyFallback,
              letterSpacing: 0,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            fontFamily: thaiFontFamily,
            fontFamilyFallback: thaiFontFamilyFallback,
            letterSpacing: 0,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.successBg,
        selectedIconTheme: const IconThemeData(color: AppColors.primary),
        unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1B2B21),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontFamilyFallback: thaiFontFamilyFallback,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 0.8,
        space: 20,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppDarkColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppDarkColors.primary,
        secondary: AppDarkColors.secondary,
        tertiary: AppDarkColors.accent,
        surface: AppDarkColors.surface,
        onPrimary: const Color(0xFF032610),
        onSurface: AppDarkColors.textPrimary,
        brightness: Brightness.dark,
      ),
      fontFamily: thaiFontFamily,
      fontFamilyFallback: thaiFontFamilyFallback,
      pageTransitionsTheme: _pageTransitions,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppDarkColors.textPrimary,
          fontSize: 32,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          color: AppDarkColors.textPrimary,
          fontSize: 30,
          height: 1.3,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          color: AppDarkColors.textPrimary,
          fontSize: 24,
          height: 1.35,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: AppDarkColors.textPrimary,
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: AppDarkColors.textPrimary,
          fontSize: 18,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppDarkColors.textPrimary,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: AppDarkColors.textSecondary,
          fontSize: 15,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: AppDarkColors.textMuted,
          fontSize: 13,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: AppDarkColors.textPrimary,
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppDarkColors.background,
        foregroundColor: AppDarkColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppDarkColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: thaiFontFamily,
          fontFamilyFallback: thaiFontFamilyFallback,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(color: AppDarkColors.primary),
      ),
      cardTheme: CardThemeData(
        color: AppDarkColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppDarkColors.border, width: 0.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppDarkColors.primary,
          foregroundColor: const Color(0xFF04200E),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: thaiFontFamily,
            fontFamilyFallback: thaiFontFamilyFallback,
            letterSpacing: 0,
          ),
          elevation: 0,
        ).copyWith(animationDuration: MotionTokens.micro),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppDarkColors.primary,
          side: const BorderSide(color: AppDarkColors.border, width: 1.0),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: thaiFontFamily,
            fontFamilyFallback: thaiFontFamilyFallback,
            letterSpacing: 0,
          ),
        ).copyWith(animationDuration: MotionTokens.micro),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppDarkColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: thaiFontFamily,
            fontFamilyFallback: thaiFontFamilyFallback,
            letterSpacing: 0,
          ),
        ).copyWith(animationDuration: MotionTokens.micro),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppDarkColors.surface,
        selectedColor: AppDarkColors.successBg,
        side: const BorderSide(color: AppDarkColors.border, width: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        labelStyle: const TextStyle(
          color: AppDarkColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppDarkColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppDarkColors.border, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppDarkColors.border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(
            color: AppDarkColors.primary,
            width: 1.8,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppDarkColors.danger, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: const BorderSide(color: AppDarkColors.danger, width: 1),
        ),
        labelStyle: const TextStyle(
          color: AppDarkColors.textSecondary,
          fontFamilyFallback: thaiFontFamilyFallback,
        ),
        hintStyle: const TextStyle(
          color: AppDarkColors.textMuted,
          fontFamilyFallback: thaiFontFamilyFallback,
        ),
        helperStyle: const TextStyle(fontSize: 13, height: 1.45),
        errorStyle: const TextStyle(fontSize: 13, height: 1.45),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppDarkColors.surface,
        indicatorColor: const Color(0xFF204631),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppDarkColors.primary,
              fontFamily: thaiFontFamily,
              fontFamilyFallback: thaiFontFamilyFallback,
              letterSpacing: 0,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppDarkColors.textMuted,
            fontFamily: thaiFontFamily,
            fontFamilyFallback: thaiFontFamilyFallback,
            letterSpacing: 0,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppDarkColors.primary, size: 24);
          }
          return const IconThemeData(color: AppDarkColors.textMuted, size: 24);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppDarkColors.surface,
        indicatorColor: const Color(0xFF204631),
        selectedIconTheme: const IconThemeData(color: AppDarkColors.primary),
        unselectedIconTheme: const IconThemeData(
          color: AppDarkColors.textMuted,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: AppDarkColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppDarkColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppDarkColors.borderLight,
        thickness: 0.8,
        space: 20,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppDarkColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppDarkColors.border, width: 0.8),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppDarkColors.surface,
        modalBackgroundColor: AppDarkColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
