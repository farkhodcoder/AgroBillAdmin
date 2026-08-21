import 'package:flutter/material.dart';

/// AgroBill brend palitrasi.
///
/// Ikki qatlamli model, `AgroBill-Prototype.html` dagi `:root` bilan bir xil:
/// primitivlar (ranglar shkalasi) hech qachon to'g'ridan-to'g'ri ishlatilmaydi —
/// komponentlar faqat semantik nomlarni oladi. Yashil brendni olib yuradi,
/// interfeys esa tinch qoladi, chunki to'yingan rang faqat holat va harakat
/// uchun ajratilgan.
abstract final class AgPalette {
  // --- Yashil shkala (brend) ---
  static const green900 = Color(0xFF173B22); // chuqur agrar yashil
  static const green800 = Color(0xFF1E5128);
  static const green700 = Color(0xFF26682C);
  static const green600 = Color(0xFF2E7D32); // asosiy yashil
  static const green500 = Color(0xFF4C8A24);
  static const green450 = Color(0xFF5F8F19); // ikkilamchi yashil
  static const green400 = Color(0xFF7CB342); // yangi o'sim yashili
  static const green300 = Color(0xFFA5CF7B);
  static const green200 = Color(0xFFCDE6B4);
  static const green100 = Color(0xFFE6F2DA);
  static const green050 = Color(0xFFF1F7EA);

  // --- Neytral shkala ---
  static const n900 = Color(0xFF172018);
  static const n800 = Color(0xFF2A342C);
  static const n700 = Color(0xFF3E4A40);
  static const n600 = Color(0xFF667066);
  static const n500 = Color(0xFF8A938B);
  static const n400 = Color(0xFFAFB6B0);
  static const n300 = Color(0xFFD2D7D2);
  static const n200 = Color(0xFFE4E8E2);
  static const n150 = Color(0xFFEDF0EA);
  static const n100 = Color(0xFFF7F8F4);
  static const n000 = Color(0xFFFFFFFF);

  // --- Urg'u va holat ranglari ---
  static const gold600 = Color(0xFF9C7C10);
  static const gold500 = Color(0xFFC9A227); // iliq tabiiy urg'u
  static const gold300 = Color(0xFFE8D08A);
  static const gold100 = Color(0xFFFBF3DC);

  static const red600 = Color(0xFFB23333);
  static const red500 = Color(0xFFD64545);
  static const red100 = Color(0xFFFBE9E9);

  static const amber600 = Color(0xFFB87407);
  static const amber500 = Color(0xFFE08B0B);
  static const amber100 = Color(0xFFFDF1DE);

  static const blue600 = Color(0xFF1D6FA5);
  static const blue500 = Color(0xFF2C8FD1);
  static const blue100 = Color(0xFFE4F1FA);

  // --- Tungi rejim uchun qo'shimcha tuslar ---
  // Prototip faqat kunduzgi rejimda chizilgan; tungi variant shu shkaladan
  // kelib chiqib qurilgan — brend yashili yorqinroq, fon esa yashil tusli qora.
  static const dark900 = Color(0xFF0B120D);
  static const dark800 = Color(0xFF121A14);
  static const dark700 = Color(0xFF18221B);
  static const dark600 = Color(0xFF1F2C23);
  static const dark500 = Color(0xFF2A3A2E);
  static const dark400 = Color(0xFF3A4D3F);
}

/// Semantik ranglar. Light va dark rejimda bir xil nom ishlatiladi, shuning
/// uchun `context.colors.success` har ikkalasida ham to'g'ri qiymat qaytaradi.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.surfaceSunken,
    required this.surfaceBrand,
    required this.surfaceInverse,
    required this.scrim,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.textInverse,
    required this.textBrand,
    required this.textLink,
    required this.border,
    required this.borderStrong,
    required this.borderBrand,
    required this.borderFocus,
    required this.actionPrimary,
    required this.actionPrimaryHover,
    required this.actionPrimaryPress,
    required this.actionPrimaryText,
    required this.actionSecondary,
    required this.actionSecondaryText,
    required this.actionDisabled,
    required this.actionDisabledText,
    required this.success,
    required this.successBg,
    required this.successText,
    required this.warning,
    required this.warningBg,
    required this.warningText,
    required this.error,
    required this.errorBg,
    required this.errorText,
    required this.info,
    required this.infoBg,
    required this.infoText,
    required this.accent,
    required this.accentBg,
    required this.accentText,
    required this.brandDeep,
    required this.brandMid,
    required this.brandFresh,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  /// Sahifa foni (ekranning eng pastki qatlami).
  final Color bg;

  /// Karta, ro'yxat, forma foni.
  final Color surface;

  /// Botiq yuza — segment, sunken search maydoni.
  final Color surfaceSunken;

  /// Brend tusli yumshoq yuza — AI kartasi, tanlangan qator.
  final Color surfaceBrand;

  /// To'q brend yuza — header, splash, chuqur yashil bloklar.
  final Color surfaceInverse;

  /// Modal ortidagi qorayish.
  final Color scrim;

  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  /// To'q fon ustidagi matn.
  final Color textInverse;
  final Color textBrand;
  final Color textLink;

  final Color border;
  final Color borderStrong;
  final Color borderBrand;
  final Color borderFocus;

  final Color actionPrimary;
  final Color actionPrimaryHover;
  final Color actionPrimaryPress;
  final Color actionPrimaryText;
  final Color actionSecondary;
  final Color actionSecondaryText;
  final Color actionDisabled;
  final Color actionDisabledText;

  /// Sog'lom, muvaffaqiyat, o'sish.
  final Color success;
  final Color successBg;
  final Color successText;

  /// Kuzatuv talab, ogohlantirish.
  final Color warning;
  final Color warningBg;
  final Color warningText;

  /// Kasallik, xato, o'chirish.
  final Color error;
  final Color errorBg;
  final Color errorText;

  final Color info;
  final Color infoBg;
  final Color infoText;

  /// AI va premium urg'usi (oltin).
  final Color accent;
  final Color accentBg;
  final Color accentText;

  /// Gradientlar uchun brend tuslari (ob-havo kartasi, header).
  final Color brandDeep;
  final Color brandMid;
  final Color brandFresh;

  /// Skeleton shimmer.
  final Color skeletonBase;
  final Color skeletonHighlight;

  static const light = AppColors(
    bg: AgPalette.n100,
    surface: AgPalette.n000,
    surfaceSunken: AgPalette.n150,
    surfaceBrand: AgPalette.green050,
    surfaceInverse: AgPalette.green900,
    scrim: Color(0x70172018),
    text: AgPalette.n900,
    textSecondary: AgPalette.n600,
    textTertiary: AgPalette.n500,
    textDisabled: AgPalette.n400,
    textInverse: AgPalette.n000,
    textBrand: AgPalette.green700,
    textLink: AgPalette.green600,
    border: AgPalette.n200,
    borderStrong: AgPalette.n300,
    borderBrand: AgPalette.green400,
    borderFocus: AgPalette.green600,
    actionPrimary: AgPalette.green600,
    actionPrimaryHover: AgPalette.green700,
    actionPrimaryPress: AgPalette.green800,
    actionPrimaryText: AgPalette.n000,
    actionSecondary: AgPalette.green050,
    actionSecondaryText: AgPalette.green700,
    actionDisabled: AgPalette.n200,
    actionDisabledText: AgPalette.n400,
    success: AgPalette.green600,
    successBg: AgPalette.green100,
    successText: AgPalette.green800,
    warning: AgPalette.amber500,
    warningBg: AgPalette.amber100,
    warningText: AgPalette.amber600,
    error: AgPalette.red500,
    errorBg: AgPalette.red100,
    errorText: AgPalette.red600,
    info: AgPalette.blue500,
    infoBg: AgPalette.blue100,
    infoText: AgPalette.blue600,
    accent: AgPalette.gold500,
    accentBg: AgPalette.gold100,
    accentText: AgPalette.gold600,
    brandDeep: AgPalette.green900,
    brandMid: AgPalette.green600,
    brandFresh: AgPalette.green400,
    skeletonBase: AgPalette.n150,
    skeletonHighlight: AgPalette.n200,
  );

  static const dark = AppColors(
    bg: AgPalette.dark900,
    surface: AgPalette.dark800,
    surfaceSunken: AgPalette.dark700,
    surfaceBrand: Color(0xFF16281B),
    surfaceInverse: Color(0xFF0E1811),
    scrim: Color(0xAA000000),
    text: Color(0xFFEDF2EC),
    textSecondary: Color(0xFFA3B0A6),
    textTertiary: Color(0xFF7A867D),
    textDisabled: Color(0xFF57635A),
    textInverse: AgPalette.n000,
    textBrand: AgPalette.green300,
    textLink: AgPalette.green400,
    border: AgPalette.dark500,
    borderStrong: AgPalette.dark400,
    borderBrand: AgPalette.green500,
    borderFocus: AgPalette.green400,
    actionPrimary: AgPalette.green500,
    actionPrimaryHover: AgPalette.green400,
    actionPrimaryPress: AgPalette.green600,
    actionPrimaryText: Color(0xFF08130B),
    actionSecondary: Color(0xFF1B2E20),
    actionSecondaryText: AgPalette.green300,
    actionDisabled: AgPalette.dark600,
    actionDisabledText: Color(0xFF5C685F),
    success: AgPalette.green400,
    successBg: Color(0xFF132A18),
    successText: AgPalette.green300,
    warning: Color(0xFFF0A93A),
    warningBg: Color(0xFF2E2211),
    warningText: Color(0xFFF0C07A),
    error: Color(0xFFF06A6A),
    errorBg: Color(0xFF2E1616),
    errorText: Color(0xFFF3A0A0),
    info: Color(0xFF5CAEE4),
    infoBg: Color(0xFF11212D),
    infoText: Color(0xFF9BCEEE),
    accent: AgPalette.gold300,
    accentBg: Color(0xFF2C2413),
    accentText: Color(0xFFE8D08A),
    brandDeep: Color(0xFF0E1811),
    brandMid: AgPalette.green700,
    brandFresh: AgPalette.green400,
    skeletonBase: AgPalette.dark700,
    skeletonHighlight: AgPalette.dark600,
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceSunken,
    Color? surfaceBrand,
    Color? surfaceInverse,
    Color? scrim,
    Color? text,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? textInverse,
    Color? textBrand,
    Color? textLink,
    Color? border,
    Color? borderStrong,
    Color? borderBrand,
    Color? borderFocus,
    Color? actionPrimary,
    Color? actionPrimaryHover,
    Color? actionPrimaryPress,
    Color? actionPrimaryText,
    Color? actionSecondary,
    Color? actionSecondaryText,
    Color? actionDisabled,
    Color? actionDisabledText,
    Color? success,
    Color? successBg,
    Color? successText,
    Color? warning,
    Color? warningBg,
    Color? warningText,
    Color? error,
    Color? errorBg,
    Color? errorText,
    Color? info,
    Color? infoBg,
    Color? infoText,
    Color? accent,
    Color? accentBg,
    Color? accentText,
    Color? brandDeep,
    Color? brandMid,
    Color? brandFresh,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surfaceBrand: surfaceBrand ?? this.surfaceBrand,
      surfaceInverse: surfaceInverse ?? this.surfaceInverse,
      scrim: scrim ?? this.scrim,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      textInverse: textInverse ?? this.textInverse,
      textBrand: textBrand ?? this.textBrand,
      textLink: textLink ?? this.textLink,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      borderBrand: borderBrand ?? this.borderBrand,
      borderFocus: borderFocus ?? this.borderFocus,
      actionPrimary: actionPrimary ?? this.actionPrimary,
      actionPrimaryHover: actionPrimaryHover ?? this.actionPrimaryHover,
      actionPrimaryPress: actionPrimaryPress ?? this.actionPrimaryPress,
      actionPrimaryText: actionPrimaryText ?? this.actionPrimaryText,
      actionSecondary: actionSecondary ?? this.actionSecondary,
      actionSecondaryText: actionSecondaryText ?? this.actionSecondaryText,
      actionDisabled: actionDisabled ?? this.actionDisabled,
      actionDisabledText: actionDisabledText ?? this.actionDisabledText,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      successText: successText ?? this.successText,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      warningText: warningText ?? this.warningText,
      error: error ?? this.error,
      errorBg: errorBg ?? this.errorBg,
      errorText: errorText ?? this.errorText,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
      infoText: infoText ?? this.infoText,
      accent: accent ?? this.accent,
      accentBg: accentBg ?? this.accentBg,
      accentText: accentText ?? this.accentText,
      brandDeep: brandDeep ?? this.brandDeep,
      brandMid: brandMid ?? this.brandMid,
      brandFresh: brandFresh ?? this.brandFresh,
      skeletonBase: skeletonBase ?? this.skeletonBase,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      surfaceBrand: c(surfaceBrand, other.surfaceBrand),
      surfaceInverse: c(surfaceInverse, other.surfaceInverse),
      scrim: c(scrim, other.scrim),
      text: c(text, other.text),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      textDisabled: c(textDisabled, other.textDisabled),
      textInverse: c(textInverse, other.textInverse),
      textBrand: c(textBrand, other.textBrand),
      textLink: c(textLink, other.textLink),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      borderBrand: c(borderBrand, other.borderBrand),
      borderFocus: c(borderFocus, other.borderFocus),
      actionPrimary: c(actionPrimary, other.actionPrimary),
      actionPrimaryHover: c(actionPrimaryHover, other.actionPrimaryHover),
      actionPrimaryPress: c(actionPrimaryPress, other.actionPrimaryPress),
      actionPrimaryText: c(actionPrimaryText, other.actionPrimaryText),
      actionSecondary: c(actionSecondary, other.actionSecondary),
      actionSecondaryText: c(actionSecondaryText, other.actionSecondaryText),
      actionDisabled: c(actionDisabled, other.actionDisabled),
      actionDisabledText: c(actionDisabledText, other.actionDisabledText),
      success: c(success, other.success),
      successBg: c(successBg, other.successBg),
      successText: c(successText, other.successText),
      warning: c(warning, other.warning),
      warningBg: c(warningBg, other.warningBg),
      warningText: c(warningText, other.warningText),
      error: c(error, other.error),
      errorBg: c(errorBg, other.errorBg),
      errorText: c(errorText, other.errorText),
      info: c(info, other.info),
      infoBg: c(infoBg, other.infoBg),
      infoText: c(infoText, other.infoText),
      accent: c(accent, other.accent),
      accentBg: c(accentBg, other.accentBg),
      accentText: c(accentText, other.accentText),
      brandDeep: c(brandDeep, other.brandDeep),
      brandMid: c(brandMid, other.brandMid),
      brandFresh: c(brandFresh, other.brandFresh),
      skeletonBase: c(skeletonBase, other.skeletonBase),
      skeletonHighlight: c(skeletonHighlight, other.skeletonHighlight),
    );
  }
}

extension AppColorsX on BuildContext {
  /// `context.colors.success` — mavzuga bog'liq semantik rang.
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
