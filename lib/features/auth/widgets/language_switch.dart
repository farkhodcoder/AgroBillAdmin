import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../cubit/admin_auth_cubit.dart';

/// Til tanlagich — segment ko'rinishida.
///
/// Kirish ekranida ham kerak: admin panelga kirolmasa ham xato matnini
/// o'z tilida o'qiy olsin.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key, this.compact = false});

  final bool compact;

  static const _languages = [
    ('uz', "O'zbekcha"),
    ('ru', 'Русский'),
    ('en', 'English'),
  ];

  /// To'liq nomlar bilan tanlagich shuncha joy oladi (o'lchangan).
  ///
  /// Bundan tor joyda `Row` sig'may istisno ko'taradi va tugmalarni
  /// QIRQADI — foydalanuvchi til tanlagichni topolmay qoladi. Shuning
  /// uchun sig'masa qisqa kodlarga o'tamiz: "UZ RU EN" qirqilgan
  /// "O'zbekch..." dan ancha yaxshi.
  static const _fullLabelsWidth = 412.0;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final current = context.locale.languageCode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useCodes = compact || constraints.maxWidth < _fullLabelsWidth;

        return Container(
          padding: const EdgeInsets.all(AgSpace.x1),
          decoration: BoxDecoration(
            color: c.surfaceSunken,
            borderRadius: AgRadius.rMd,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (code, label) in _languages)
                _Option(
                  code: code,
                  label: useCodes ? code.toUpperCase() : label,
                  selected: code == current,
                  colors: c,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.code,
    required this.label,
    required this.selected,
    required this.colors,
  });

  final String code;
  final String label;
  final bool selected;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // Til `admin_users.language_code` ga ham yoziladi — admin boshqa
        // kompyuterdan kirsa ham o'z tili qoladi (TTZ §9).
        onTap: () =>
            context.read<AdminAuthCubit>().changeLanguage(context, code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(
            horizontal: AgSpace.x4,
            vertical: AgSpace.x2,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.surface : Colors.transparent,
            borderRadius: AgRadius.rSm,
          ),
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              color: selected ? colors.text : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
