import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/result.dart';
import 'admin_button.dart';

/// Xato banneri.
///
/// `AppFailure.messageKey` tarjima kalitini olib keladi — server matni
/// foydalanuvchiga hech qachon ko'rsatilmaydi (TTZ §9).
class AdminErrorBanner extends StatelessWidget {
  const AdminErrorBanner({super.key, required this.failure, this.onRetry});

  final AppFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AgSpace.x4),
      decoration: BoxDecoration(
        color: c.errorBg,
        borderRadius: AgRadius.rMd,
        border: Border.all(color: c.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: c.errorText),
          const SizedBox(width: AgSpace.x3),
          Expanded(
            child: Text(
              failure.messageKey.tr(),
              style: AppTypography.bodySmall.copyWith(color: c.errorText),
            ),
          ),
          // Qayta urinish faqat mantiqan to'g'ri xatolarda (tarmoq, timeout).
          // Ruxsat yo'q xatosida qayta urinish hech narsani o'zgartirmaydi.
          if (onRetry != null && failure.isRetryable) ...[
            const SizedBox(width: AgSpace.x3),
            AdminButton(
              label: 'admin.common.retry'.tr(),
              kind: AdminButtonKind.ghost,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// Ma'lumot/ogohlantirish qutisi.
class AdminNote extends StatelessWidget {
  const AdminNote({super.key, required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AgSpace.x4),
      decoration: BoxDecoration(color: c.infoBg, borderRadius: AgRadius.rMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? Icons.info_outline, size: 18, color: c.infoText),
          const SizedBox(width: AgSpace.x3),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(color: c.infoText),
            ),
          ),
        ],
      ),
    );
  }
}

/// Butun sahifani egallaydigan yuklanish holati.
class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: c.actionPrimary,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: AgSpace.x4),
            Text(
              label!,
              style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ruxsat yo'q holati.
///
/// TTZ §10: har bir ekranda olti holat bo'lishi kerak, shulardan biri —
/// "ruxsat yo'q". Bo'sh sahifa o'rniga sabab ko'rsatiladi.
class AdminNoAccess extends StatelessWidget {
  const AdminNoAccess({super.key, this.permission});

  /// Qaysi ruxsat yetishmayotgani — xodim adminga aniq ayta olsin.
  final String? permission;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 32, color: c.textTertiary),
            const SizedBox(height: AgSpace.x4),
            Text(
              'admin.errors.permission_denied'.tr(),
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(color: c.text),
            ),
            const SizedBox(height: AgSpace.x2),
            Text(
              'admin.common.ask_super_admin'.tr(),
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
            ),
            if (permission != null) ...[
              const SizedBox(height: AgSpace.x4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AgSpace.x3,
                  vertical: AgSpace.x1,
                ),
                decoration: BoxDecoration(
                  color: c.surfaceSunken,
                  borderRadius: AgRadius.rSm,
                ),
                child: Text(
                  permission!,
                  style: AppTypography.caption.copyWith(color: c.textTertiary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
