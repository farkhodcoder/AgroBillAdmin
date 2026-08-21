import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';
import 'agro_mark.dart';

/// Kirish oqimidagi barcha ekranlar uchun umumiy karkas.
///
/// Hozircha bitta ekran (login) ishlatadi, lekin karkas alohida turadi:
/// kirish oqimiga yangi ekran qo'shilganda (masalan parol tiklash) u ham
/// ayni markazlashtirilgan kartani oladi va layout ajralib ketmaydi.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AgSpace.x9),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Brand(colors: c),
                const SizedBox(height: AgSpace.x7),
                Container(
                  padding: const EdgeInsets.all(AgSpace.x7),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: AgRadius.rLg,
                    border: Border.all(color: c.border),
                    boxShadow: AgShadow.s2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        style: AppTypography.h2.copyWith(color: c.text),
                      ),
                      const SizedBox(height: AgSpace.x2),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AgSpace.x6),
                      child,
                    ],
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: AgSpace.x5),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const AgroMark(size: 32),
        const SizedBox(width: AgSpace.x3),
        Text(
          'app.title'.tr(),
          style: AppTypography.h3.copyWith(color: colors.text),
        ),
      ],
    );
  }
}
