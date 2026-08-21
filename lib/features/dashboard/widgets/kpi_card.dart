import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

/// KPI kartasi.
///
/// `tone` — e'tibor talab qiladigan ko'rsatkichlar uchun (kutayotgan e'lon,
/// ochiq murojaat). Ular nol bo'lsa neytral, aks holda ogohlantirish rangi:
/// admin ekranga qarab darhol nima kutayotganini ko'rsin.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.icon,
    this.tone,
  });

  final String label;
  final String value;
  final String? hint;
  final IconData? icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Container(
      width: 210,
      padding: const EdgeInsets.all(AgSpace.x5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AgRadius.rLg,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: tone ?? c.textTertiary),
                const SizedBox(width: AgSpace.x2),
              ],
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AgSpace.x3),
          Text(
            value,
            style: AppTypography.metric.copyWith(color: tone ?? c.text),
          ),
          if (hint != null) ...[
            const SizedBox(height: AgSpace.x1),
            Text(
              hint!,
              style: AppTypography.caption.copyWith(color: c.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
