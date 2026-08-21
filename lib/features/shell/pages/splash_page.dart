import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/supabase/admin_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../ui/admin_feedback.dart';

/// Sessiya tekshirilayotgan paytdagi ekran.
///
/// `404` uchun ham shu ekran ishlatiladi — router baribir bir zumda to'g'ri
/// sahifaga yo'naltiradi, shuning uchun alohida ekran ortiqcha.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key, this.notFound = false});

  final bool notFound;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.brandDeep,
                borderRadius: AgRadius.rMd,
              ),
              child: Center(
                child: Text(
                  'A',
                  style: AppTypography.h2.copyWith(color: c.textInverse),
                ),
              ),
            ),
            const SizedBox(height: AgSpace.x5),
            Text(
              'app.title'.tr(),
              style: AppTypography.h3.copyWith(color: c.text),
            ),
            const SizedBox(height: AgSpace.x6),

            if (notFound)
              Text(
                'app.not_found'.tr(),
                style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
              )
            else if (!AdminConfig.isConfigured)
              // Kalitsiz ishga tushirilgan — bu holat aks holda cheksiz
              // spinner bo'lib ko'rinardi.
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AdminNote(text: 'app.status.not_configured'.tr()),
              )
            else
              const AdminLoading(),
          ],
        ),
      ),
    );
  }
}
