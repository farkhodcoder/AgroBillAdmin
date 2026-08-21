import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/theme_controller.dart';

/// Kunduzgi/tungi rejim tugmasi.
///
/// `lib/ui/` da turadi, chunki ikki joyda ishlatiladi: kirish ekranida
/// (`AuthScaffold` footer) va panel ichida (`TopBar`). Modul papkasiga
/// qo'yilsa ulardan biri ikkinchisiga bog'lanib qolardi.
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, mode, _) {
        final (icon, labelKey) = switch (mode) {
          ThemeMode.system => (Icons.brightness_auto, 'admin.theme.system'),
          ThemeMode.light => (Icons.light_mode, 'admin.theme.light'),
          ThemeMode.dark => (Icons.dark_mode, 'admin.theme.dark'),
        };

        // Tooltip joriy rejimni emas, BOSILGANDA nima bo'lishini aytadi —
        // ikonka joriy holatni allaqachon ko'rsatib turibdi, takrorlash
        // foydalanuvchiga hech narsa qo'shmasdi.
        final nextKey = switch (mode) {
          ThemeMode.system => 'admin.theme.light',
          ThemeMode.light => 'admin.theme.dark',
          ThemeMode.dark => 'admin.theme.system',
        };

        return Tooltip(
          message: 'admin.theme.switch_to'.tr(args: [nextKey.tr()]),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: controller.cycle,
              child: Semantics(
                button: true,
                label: labelKey.tr(),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: AgSpace.x3),
                  decoration: BoxDecoration(
                    color: c.surfaceSunken,
                    borderRadius: AgRadius.rMd,
                  ),
                  child: Center(
                    child: Icon(icon, size: 17, color: c.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
