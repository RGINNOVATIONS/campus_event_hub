import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFFB01E28);
  static const primaryDark = Color(0xFF8C161E);
  static const primaryLight = Color(0xFFFCE9EA);
  static const primaryLighter = Color(0xFFFDF3F3);

  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF6F6F5);
  static const border = Color(0xFFE5E4E2);
  static const borderStrong = Color(0xFFD6D5D2);

  static const textPrimary = Color(0xFF1F1F1F);
  static const textSecondary = Color(0xFF5B5B5B);
  static const textMuted = Color(0xFF8A8A8A);
  static const textOnPrimary = Color(0xFFFFFFFF);

  static const success = Color(0xFF1E7A3D);
  static const successBg = Color(0xFFE9F6EE);
  static const warning = Color(0xFFB4680B);
  static const warningBg = Color(0xFFFBF0DF);
  static const danger = Color(0xFFB01E28);
  static const dangerBg = Color(0xFFFCE9EA);

  // Backwards-compatible aliases for screens that will be migrated later.
  static const bgPrimary = background;
  static const bgSecondary = surface;
  static const cardBg = surface;
  static const surfaceElevated = surfaceSubtle;
  static const divider = border;
  static const error = danger;
  static const goldPrimary = primary;
  static const goldBright = primaryDark;
  static const goldMuted = primaryLight;
}

class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const section = 40.0;

  static const sidebarWidth = 264.0;
  static const headerHeight = 76.0;
  static const mobileHeaderHeight = 60.0;
  static const bottomNavigationHeight = 64.0;
  static const maxContentWidth = 1180.0;
}

class AppRadius {
  AppRadius._();

  static const small = 6.0;
  static const medium = 10.0;
  static const large = 14.0;
  static const pill = 999.0;

  static BorderRadius get sm => BorderRadius.circular(small);
  static BorderRadius get md => BorderRadius.circular(medium);
  static BorderRadius get lg => BorderRadius.circular(large);
  static BorderRadius get full => BorderRadius.circular(pill);
}

class AppBreakpoints {
  AppBreakpoints._();

  static const compact = 480.0;
  static const mobile = 640.0;
  static const tablet = 900.0;
  static const desktop = 1024.0;
  static const wide = 1280.0;
}

class AppShadows {
  AppShadows._();

  static const sm = [
    BoxShadow(
      color: Color(0x0A141414),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static const md = [
    BoxShadow(
      color: Color(0x0F141414),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const lg = [
    BoxShadow(
      color: Color(0x1A141414),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];
}

class AppTextStyles {
  AppTextStyles._();

  static const fontFamily = 'Inter';
  static const fontFallback = ['Segoe UI', 'Roboto', 'Arial', 'sans-serif'];

  static const display = TextStyle(
    fontSize: 32,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const headline = TextStyle(
    fontSize: 24,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const bodySecondary = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const label = TextStyle(
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const caption = TextStyle(
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark => light;

  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      secondary: AppColors.primaryDark,
      onSecondary: AppColors.textOnPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
      onError: AppColors.textOnPrimary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderStrong,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.border,
      fontFamily: AppTextStyles.fontFamily,
      fontFamilyFallback: AppTextStyles.fontFallback,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lg,
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.surfaceSubtle,
        labelStyle:
            AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        secondaryLabelStyle:
            AppTextStyles.label.copyWith(color: AppColors.textOnPrimary),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.full),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        titleTextStyle: AppTextStyles.title,
        contentTextStyle: AppTextStyles.bodySecondary,
      ),
      textTheme: const TextTheme(
        headlineMedium: AppTextStyles.display,
        headlineSmall: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        titleMedium: AppTextStyles.title,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.bodySecondary,
        labelLarge: AppTextStyles.label,
        labelMedium: AppTextStyles.label,
        labelSmall: AppTextStyles.caption,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          textStyle: AppTextStyles.label,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.primaryLight,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          textStyle: AppTextStyles.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.textMuted,
          side: const BorderSide(color: AppColors.borderStrong),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          textStyle: AppTextStyles.label,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        labelStyle: AppTextStyles.bodySecondary,
        hintStyle:
            AppTextStyles.bodySecondary.copyWith(color: AppColors.textMuted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.bottomNavigationHeight,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryLight,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : AppColors.textMuted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTextStyles.caption.copyWith(
            color: selected ? AppColors.primary : AppColors.textMuted,
          );
        }),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryLight,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.textMuted),
        selectedLabelTextStyle: TextStyle(color: AppColors.primary),
        unselectedLabelTextStyle: TextStyle(color: AppColors.textMuted),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle:
            AppTextStyles.body.copyWith(color: AppColors.textOnPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.primaryLight,
      ),
    );
  }
}
