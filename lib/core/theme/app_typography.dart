import 'package:flutter/material.dart';

/// Tipografika — `AgroBill-Prototype.html` dagi shkalaning aynan o'zi.
///
/// Inter tanlangan, chunki u o'zbek lotin alifbosini to'liq qoplaydi: `oʻ`,
/// `gʻ`, `sh`, `ch` va U+02BB modifikator belgisi. Barcha son ko'rsatkichlari
/// `tabularFigures` bilan beriladi — dashboard raqamlari yangilanganda
/// "sakramaydi".
abstract final class AppTypography {
  /// Matn shrifti — 13-15px da eng yaxshi o'qiladigan interfeys shrifti.
  static const fontFamily = 'Inter';

  /// Sarlavha shrifti — Manrope geometrik va kengroq, shuning uchun
  /// sarlavha matndan aniq ajralib turadi va ilova "standart Material"
  /// ko'rinishidan chiqadi. Kirill va o'zbek lotini (U+02BB) qoplangan.
  static const displayFamily = 'Manrope';

  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  /// Prototipdagi nomlangan uslublar. Material `TextTheme` ga moslanadi,
  /// lekin ilova ichida shu nomlar bilan ishlatiladi (`context.type.h2`).
  static const display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 34,
    height: 40 / 34,
    letterSpacing: -0.8,
    fontWeight: FontWeight.w800,
  );

  static const h1 = TextStyle(
    fontFamily: displayFamily,
    fontSize: 28,
    height: 34 / 28,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w700,
  );

  static const h2 = TextStyle(
    fontFamily: displayFamily,
    fontSize: 22,
    height: 28 / 22,
    letterSpacing: -0.3,
    fontWeight: FontWeight.w700,
  );

  static const h3 = TextStyle(
    fontFamily: displayFamily,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w600,
  );

  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 26 / 17,
    letterSpacing: -0.1,
    fontWeight: FontWeight.w400,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
  );

  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w400,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w500,
  );

  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 22 / 16,
    letterSpacing: -0.1,
    fontWeight: FontWeight.w600,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 18 / 13,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w600,
  );

  /// Katta son ko'rsatkichi — "28,4 ga", "18 420 000 so'm".
  static const metric = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 36 / 32,
    letterSpacing: -1,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  /// Ro'yxat ichidagi kichikroq son.
  static const metricSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    height: 30 / 26,
    letterSpacing: -0.6,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  /// Ob-havodagi ulkan harorat ("27°").
  static const temperature = TextStyle(
    fontFamily: fontFamily,
    fontSize: 66,
    height: 70 / 66,
    letterSpacing: -2.5,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  /// Material komponentlari (dialog, snackbar va h.k.) uchun asos.
  static TextTheme textTheme(Color primary, Color secondary) {
    TextStyle p(TextStyle s) => s.copyWith(color: primary);
    TextStyle sec(TextStyle s) => s.copyWith(color: secondary);

    return TextTheme(
      displayLarge: p(display),
      displayMedium: p(h1),
      displaySmall: p(h2),
      headlineLarge: p(h1),
      headlineMedium: p(h2),
      headlineSmall: p(h3),
      titleLarge: p(h3),
      titleMedium: p(body.copyWith(fontWeight: FontWeight.w600)),
      titleSmall: p(label),
      bodyLarge: p(bodyLarge),
      bodyMedium: p(body),
      bodySmall: sec(bodySmall),
      labelLarge: p(button),
      labelMedium: sec(label),
      labelSmall: sec(caption),
    );
  }
}

extension AppTypographyX on BuildContext {
  /// Matn uslublariga qisqa yo'l: `context.type.h2`.
  AppTypeStyles get type => const AppTypeStyles();
}

/// `context.type.*` orqali chaqiriladigan uslublar to'plami.
class AppTypeStyles {
  const AppTypeStyles();

  TextStyle get display => AppTypography.display;
  TextStyle get h1 => AppTypography.h1;
  TextStyle get h2 => AppTypography.h2;
  TextStyle get h3 => AppTypography.h3;
  TextStyle get bodyLarge => AppTypography.bodyLarge;
  TextStyle get body => AppTypography.body;
  TextStyle get bodySmall => AppTypography.bodySmall;
  TextStyle get caption => AppTypography.caption;
  TextStyle get button => AppTypography.button;
  TextStyle get label => AppTypography.label;
  TextStyle get metric => AppTypography.metric;
  TextStyle get metricSmall => AppTypography.metricSmall;
  TextStyle get temperature => AppTypography.temperature;
}
