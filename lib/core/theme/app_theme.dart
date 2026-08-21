import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// Ilova mavzusi. Ranglar `AppColors` kengaytmasidan olinadi — Material
/// `ColorScheme` faqat framework komponentlari (dialog, snackbar, ripple)
/// to'g'ri ko'rinishi uchun to'ldiriladi.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.actionPrimary,
      onPrimary: c.actionPrimaryText,
      primaryContainer: c.surfaceBrand,
      onPrimaryContainer: c.textBrand,
      secondary: c.accent,
      onSecondary: isLight ? Colors.white : const Color(0xFF1A1405),
      secondaryContainer: c.accentBg,
      onSecondaryContainer: c.accentText,
      error: c.error,
      onError: Colors.white,
      errorContainer: c.errorBg,
      onErrorContainer: c.errorText,
      surface: c.surface,
      onSurface: c.text,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.bg,
      surfaceContainer: c.surfaceSunken,
      surfaceContainerHigh: c.surfaceSunken,
      surfaceContainerHighest: c.surfaceSunken,
      onSurfaceVariant: c.textSecondary,
      outline: c.border,
      outlineVariant: c.borderStrong,
      inverseSurface: c.surfaceInverse,
      onInverseSurface: c.textInverse,
      scrim: c.scrim,
    );

    final textTheme = AppTypography.textTheme(c.text, c.textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[c],

      // Ripple ataylab yumshoq — prototipda bosish holati rang bilan beriladi.
      splashFactory: InkSparkle.splashFactory,
      highlightColor: c.actionPrimary.withValues(alpha: 0.06),

      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: AgLayout.navbarHeight,
        centerTitle: false,
        titleTextStyle: AppTypography.h3.copyWith(color: c.text),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
              )
            : SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
      ),

      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),

      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AgRadius.rLg,
          side: BorderSide(color: c.border),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AgRadius.rXl),
        titleTextStyle: AppTypography.h3.copyWith(color: c.text),
        contentTextStyle: AppTypography.body.copyWith(color: c.textSecondary),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AgRadius.sheet),
        showDragHandle: false,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.text,
        contentTextStyle: AppTypography.body.copyWith(color: c.surface),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AgRadius.rMd),
        elevation: 0,
      ),

      // Sof Material inputlar deyarli ishlatilmaydi (AgInput bor), lekin
      // qidiruv va dialog ichidagi maydonlar uchun asos kerak.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AgSpace.x4,
          vertical: AgSpace.x4,
        ),
        hintStyle: AppTypography.body.copyWith(color: c.textTertiary),
        border: OutlineInputBorder(
          borderRadius: AgRadius.rMd,
          borderSide: BorderSide(color: c.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AgRadius.rMd,
          borderSide: BorderSide(color: c.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AgRadius.rMd,
          borderSide: BorderSide(color: c.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AgRadius.rMd,
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AgRadius.rMd,
          borderSide: BorderSide(color: c.error, width: 1.5),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.actionPrimary,
        linearTrackColor: c.surfaceSunken,
        circularTrackColor: c.surfaceSunken,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : c.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? c.actionPrimary
              : c.borderStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      // Sahifa o'tishlari prototipdagi spetsifikatsiyaga mos: chapdan surilish.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SlidePageTransitionBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// "Move in → Left, 250ms, Ease out" — prototipdagi push animatsiyasi.
class _SlidePageTransitionBuilder extends PageTransitionsBuilder {
  const _SlidePageTransitionBuilder();

  @override
  Duration get transitionDuration => AgMotion.push;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AgMotion.reduced(context)) return child;

    final slide = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: AgMotion.easeOut));

    return SlideTransition(position: slide, child: child);
  }
}
