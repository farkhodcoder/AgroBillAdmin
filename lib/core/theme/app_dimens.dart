import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Masofa, radius, soya va layout o'lchamlari — prototipdagi 8pt tizim.
///
/// 4pt yarim qadamlar faqat ikonka bilan yorliq orasidagi bo'shliq uchun;
/// tuzilmaviy hamma narsa 8 ga tushadi.
abstract final class AgSpace {
  static const x0 = 0.0;
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x7 = 32.0;
  static const x8 = 40.0;
  static const x9 = 48.0;
  static const x10 = 56.0;
  static const x11 = 64.0;
  static const x12 = 80.0;
}

/// Burchak radiuslari. Har biri aniq bir komponentga biriktirilgan, shuning
/// uchun ilova bo'ylab shakl tili bir xil qoladi.
abstract final class AgRadius {
  static const xs = 4.0; // badge
  static const sm = 8.0; // chip, segment
  static const md = 12.0; // input, tugma
  static const lg = 16.0; // karta
  static const xl = 20.0; // dialog
  static const xxl = 28.0; // bottom sheet
  static const full = 999.0; // pill, FAB

  static const rXs = BorderRadius.all(Radius.circular(xs));
  static const rSm = BorderRadius.all(Radius.circular(sm));
  static const rMd = BorderRadius.all(Radius.circular(md));
  static const rLg = BorderRadius.all(Radius.circular(lg));
  static const rXl = BorderRadius.all(Radius.circular(xl));
  static const rFull = BorderRadius.all(Radius.circular(full));

  /// Bottom sheet — faqat yuqori burchaklar.
  static const sheet = BorderRadius.vertical(top: Radius.circular(xxl));
}

/// Soyalar. Ataylab sayoz va yashil tusli — kulrang emas — hamda hech qachon
/// ustma-ust qo'yilmaydi.
abstract final class AgShadow {
  static const _tint = Color(0xFF173B22);

  static const none = <BoxShadow>[];

  /// Karta tinch holati.
  static const s1 = <BoxShadow>[
    BoxShadow(color: Color(0x0F173B22), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Hover / bosilgan karta.
  static const s2 = <BoxShadow>[
    BoxShadow(color: Color(0x12173B22), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// FAB, dialog.
  static const s3 = <BoxShadow>[
    BoxShadow(color: Color(0x1A173B22), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Bottom sheet va tab bar ko'tarilishi (yuqoriga tushadigan soya).
  static const s4 = <BoxShadow>[
    BoxShadow(color: Color(0x1F173B22), blurRadius: 28, offset: Offset(0, -6)),
  ];

  /// Fokus halqasi — 3px, green-600, 14% shaffoflik.
  static List<BoxShadow> focusRing(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.14),
      blurRadius: 0,
      spreadRadius: 3,
    ),
  ];

  static Color get tint => _tint;
}

/// Layout konstantalari. Prototip iPhone 15/16 Pro (393×852) uchun chizilgan.
abstract final class AgLayout {
  /// Ekranning yon tomonlaridagi bo'shliq. Kichik qurilmalarda 16 ga tushadi.
  static const gutter = 20.0;
  static const gutterCompact = 16.0;
  static const gutterWide = 24.0;

  /// Yuqori navigatsiya balandligi.
  static const navbarHeight = 56.0;

  /// Pastki tab bar kontent balandligi (safe area qo'shiladi).
  static const tabbarHeight = 64.0;

  /// Minimal teginish maydoni — WCAG va Material talabi.
  static const touchMin = 44.0;

  /// Tugma balandliklari.
  static const buttonLg = 52.0;
  static const buttonMd = 44.0;
  static const buttonSm = 36.0;

  /// Kichik tugmaning teginish balandligi. 36dp WCAG minimumidan (44) past —
  /// matn o'lchami o'sha-o'sha qoladi, lekin bosish maydoni kattalashadi.
  static const buttonSmTouch = 40.0;

  /// Input balandligi.
  static const inputHeight = 56.0;
  static const searchHeight = 48.0;

  /// Ikonka tugmasi (44px teginish maydoni ichida 40px ko'rinish).
  static const iconButton = 40.0;

  /// Prototipdagi asosiy ekran kengligi — vizual taqqoslash uchun.
  static const designWidth = 393.0;

  /// Ekran kengligiga qarab gutter tanlaydi (prototipdagi responsive jadval).
  static double gutterFor(double width) {
    if (width < 380) return gutterCompact;
    if (width >= 430) return gutterWide;
    return gutter;
  }

  /// Tezkor xizmatlar gridi 360dp dan past bo'lsa 2 ustunga tushadi.
  static int serviceColumnsFor(double width) => width < 360 ? 2 : 3;

  /// Tab sahifalaridagi ro'yxat oxiridagi bo'shliq.
  ///
  /// `AppShell` `extendBody: true` bilan quriladi, shuning uchun Flutter tab
  /// sahifalari ichida `MediaQuery.padding.bottom` ni **navbar balandligiga**
  /// tenglashtiradi (`Scaffold._BodyBuilder`). Ya'ni bu qiymat allaqachon
  /// "navbar + tizim paneli" ni o'z ichiga oladi va uni qo'lda hisoblash
  /// shart emas.
  ///
  /// Ilgari sahifalar qattiq raqam yozardi (24-80dp) va navbar (110-122dp)
  /// oxirgi kartani bosib qolardi.
  static double navBottomPad(
    BuildContext context, {
    double extra = AgSpace.x6,
  }) => MediaQuery.paddingOf(context).bottom + extra;
}

/// Animatsiya davomiyliklari — prototipdagi "Interaction specification".
abstract final class AgMotion {
  static const push = Duration(milliseconds: 250);
  static const pop = Duration(milliseconds: 220);
  static const sheetIn = Duration(milliseconds: 280);
  static const sheetOut = Duration(milliseconds: 220);
  static const dialog = Duration(milliseconds: 180);
  static const toast = Duration(milliseconds: 200);
  static const toastVisible = Duration(seconds: 4);
  static const pager = Duration(milliseconds: 300);
  static const skeleton = Duration(milliseconds: 900);

  static const easeOut = Curves.easeOut;
  static const easeInOut = Curves.easeInOut;

  /// "Harakatni kamaytirish" yoqilgan bo'lsa animatsiya o'chiriladi —
  /// scanline va shimmer statik holatga o'tadi (prototip accessibility bandi).
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

/// Ranglarga bog'liq umumiy dekoratsiyalar — takrorlanishni kamaytiradi.
extension AgDecorations on AppColors {
  /// Standart karta: yuza + 1px chegara + sayoz soya.
  BoxDecoration get cardDecoration => BoxDecoration(
    color: surface,
    borderRadius: AgRadius.rLg,
    border: Border.all(color: border),
    boxShadow: AgShadow.s1,
  );

  /// Brend tusli karta (AI tavsiyasi, maslahat bloklari).
  BoxDecoration get brandCardDecoration => BoxDecoration(
    color: surfaceBrand,
    borderRadius: AgRadius.rLg,
    border: Border.all(color: borderBrand.withValues(alpha: 0.45)),
  );

  /// Ob-havo va header uchun chuqur yashil gradient.
  BoxDecoration get brandGradient => BoxDecoration(
    borderRadius: AgRadius.rLg,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [brandDeep, brandMid],
    ),
  );
}
