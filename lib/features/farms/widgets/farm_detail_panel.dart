import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/admin_farm.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_feedback.dart';

/// Xo'jalik tafsiloti — dalalar ro'yxati bilan.
///
/// Xarita bu bosqichda YO'Q. `fields.boundary_geojson` da GeoJSON Polygon
/// bor va uni `flutter_map` bilan chizish mumkin, lekin bu alohida ish:
/// paket qo'shish, plitka manbasi, offline holat. Hozircha chegara
/// chizilgan-chizilmagani belgisi ko'rsatiladi.
class FarmDetailPanel extends StatelessWidget {
  const FarmDetailPanel({
    super.key,
    required this.farm,
    required this.fields,
    required this.loading,
    required this.onClose,
  });

  final AdminFarmRow farm;
  final List<AdminFieldRow> fields;
  final bool loading;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Positioned.fill(
      child: Stack(
        children: [
          // Tashqariga bosilsa yopiladi.
          GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: c.surface,
              child: SizedBox(
                width: 520,
                height: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(farm: farm, colors: c, onClose: onClose),
                    Expanded(
                      child: loading
                          ? const AdminLoading()
                          : _Body(farm: farm, fields: fields, colors: c),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.farm,
    required this.colors,
    required this.onClose,
  });

  final AdminFarmRow farm;
  final AppColors colors;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AgSpace.x6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm.name,
                  style: AppTypography.h3.copyWith(color: colors.text),
                ),
                const SizedBox(height: AgSpace.x1),
                Text(
                  '${farm.ownerName ?? '—'} · ${farm.ownerEmail ?? '—'}',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, size: 18, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.farm, required this.fields, required this.colors});

  final AdminFarmRow farm;
  final List<AdminFieldRow> fields;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    // Dalalarning yig'indisi xo'jalik maydonidan farq qilishi mumkin —
    // fermer xo'jalik maydonini qo'lda kiritadi. Farq katta bo'lsa bu
    // tekshirishga arziydi, shuning uchun ikkalasi yonma-yon ko'rsatiladi.
    final fieldsArea = fields.fold<double>(0, (s, f) => s + f.areaHectares);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AgSpace.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Stat(
                label: 'admin.farms.col_area'.tr(),
                value: '${Fmt.hectares(farm.areaHectares)} ga',
                colors: colors,
              ),
              _Stat(
                label: 'admin.farms.fields_area'.tr(),
                value: '${Fmt.hectares(fieldsArea)} ga',
                colors: colors,
              ),
              _Stat(
                label: 'admin.farms.col_fields'.tr(),
                value: '${fields.length}',
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: AgSpace.x6),

          Text(
            'admin.farms.fields'.tr(),
            style: AppTypography.label.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AgSpace.x3),

          if (fields.isEmpty)
            Text(
              'admin.farms.no_fields'.tr(),
              style: AppTypography.bodySmall.copyWith(
                color: colors.textTertiary,
              ),
            )
          else
            for (final field in fields)
              _FieldTile(field: field, colors: colors),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.colors});

  final String label;
  final String value;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AgSpace.x1),
          Text(
            value,
            style: AppTypography.metricSmall.copyWith(color: colors.text),
          ),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({required this.field, required this.colors});

  final AdminFieldRow field;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final tone = switch (field.health) {
      'healthy' => BadgeTone.success,
      'watch' => BadgeTone.warning,
      'diseased' => BadgeTone.danger,
      _ => BadgeTone.neutral,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AgSpace.x2),
      padding: const EdgeInsets.all(AgSpace.x4),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: AgRadius.rMd,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        field.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.text,
                        ),
                      ),
                    ),
                    if (field.hasBoundary) ...[
                      const SizedBox(width: AgSpace.x2),
                      Tooltip(
                        message: 'admin.farms.has_boundary'.tr(),
                        child: Icon(
                          Icons.map_outlined,
                          size: 13,
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    '${Fmt.hectares(field.areaHectares)} ga',
                    if (field.cropName != null) field.cropName!,
                    if (field.growthPercent != null) '${field.growthPercent}%',
                  ].join(' · '),
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: 'admin.health.${field.health}'.tr(), tone: tone),
        ],
      ),
    );
  }
}
