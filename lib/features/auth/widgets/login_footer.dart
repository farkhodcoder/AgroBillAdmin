import 'package:flutter/material.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../ui/theme_switch.dart';
import 'language_switch.dart';

/// Kirish ekrani ostidagi til va tema tanlagichlari.
///
/// `Row` EMAS, `Wrap`. Til nomlari to'liq yoziladi («O'zbekcha», «Русский»,
/// «English») va tema tugmasi bilan birga ular tor oynada 420px ga
/// sig'masligi mumkin. `Row` sig'masa istisno ko'taradi va bolalarni
/// QIRQADI — tugma ekranda umuman ko'rinmay qolardi. `Wrap` esa ortiqchasini
/// keyingi qatorga tushiradi.
///
/// Alohida vidjet, chunki shu holda uni test qilib bo'ladi: `login_page.dart`
/// ichida bo'lganda tekshirish uchun butun sahifani, u bilan birga Supabase
/// mijozini ham ko'tarish kerak bo'lardi.
class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AgSpace.x3,
      runSpacing: AgSpace.x3,
      children: [
        const LanguageSwitch(),
        ThemeSwitch(controller: controller),
      ],
    );
  }
}
