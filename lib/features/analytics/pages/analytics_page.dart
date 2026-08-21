import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/di.dart';
import '../../../core/rbac/permission.dart';
import '../../../core/rbac/permission_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/result.dart';
import '../../../data/models/admin_metrics.dart';
import '../../../data/repositories/admin_dashboard_repository.dart';
import '../../../data/repositories/admin_ops_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_table.dart';

/// Tahlil (TTZ §6.11).
///
/// Dashboard grafiklarni ko'rsatadi, bu yerda esa XOM QATOR: kunlik
/// metrikalar jadvali va eksport. Ikkitasi bir sahifada bo'lsa, kundalik
/// nazorat (dashboard) va chuqur tahlil (bu yer) bir-biriga xalaqit
/// berardi.
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _repo = getIt<AdminDashboardRepository>();
  final _ops = getIt<AdminOpsRepository>();

  List<DailyMetric> _metrics = const [];
  int _days = 30;
  bool _loading = true;
  bool _exporting = false;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });

    final res = await _repo.loadMetrics(days: _days);
    if (!mounted) return;

    setState(() {
      _loading = false;
      switch (res) {
        case Ok(:final value):
          // Jadvalda yangisi tepada — grafikda esa vaqt bo'yicha chapdan
          // o'ngga, shuning uchun tartib bu yerda teskari.
          _metrics = value.reversed.toList();
        case Fail(:final failure):
          _failure = failure;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return PermissionGuard(
      permission: AdminPermission.analyticsRead,
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.x7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'admin.nav.analytics'.tr(),
              subtitle: 'admin.analytics.subtitle'.tr(),
              actions: [
                for (final days in [30, 90, 365])
                  Padding(
                    padding: const EdgeInsets.only(left: AgSpace.x2),
                    child: AdminButton(
                      label: 'admin.dashboard.days'.tr(args: ['$days']),
                      kind: _days == days
                          ? AdminButtonKind.primary
                          : AdminButtonKind.secondary,
                      onPressed: () {
                        setState(() => _days = days);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AgSpace.x5),

            _ExportBar(busy: _exporting, onExport: _export, colors: c),
            const SizedBox(height: AgSpace.x4),

            Expanded(
              child: AdminTable<DailyMetric>(
                rows: _metrics,
                loading: _loading,
                failure: _failure,
                onRetry: _load,
                emptyTitle: 'admin.analytics.empty'.tr(),
                emptyHint: 'admin.analytics.empty_hint'.tr(),
                columns: _columns(c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AdminColumn<DailyMetric>> _columns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.ai.col_date',
      width: 110,
      build: (row) => Text(
        Fmt.date(row.day),
        style: AppTypography.bodySmall.copyWith(color: c.text),
      ),
    ),
    _num(c, 'admin.analytics.col_new_users', (r) => '${r.newUsers}'),
    _num(c, 'admin.dashboard.total_users', (r) => Fmt.count(r.totalUsers)),
    _num(c, 'admin.dashboard.total_farms', (r) => Fmt.count(r.totalFarms)),
    _num(c, 'admin.farms.col_area', (r) => Fmt.hectares(r.totalHectares)),
    _num(c, 'admin.analytics.col_orders', (r) => '${r.ordersCreated}'),
    _num(c, 'admin.dashboard.chart_gmv', (r) => Fmt.sum(r.gmv)),
    _num(c, 'admin.ai.col_scans', (r) => '${r.scans}'),
    _num(c, 'admin.ai.col_questions', (r) => '${r.aiQuestions}'),
  ];

  AdminColumn<DailyMetric> _num(
    AppColors c,
    String labelKey,
    String Function(DailyMetric) value,
  ) => AdminColumn(
    labelKey: labelKey,
    width: 120,
    align: Alignment.centerRight,
    build: (row) => Text(
      value(row),
      style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
    ),
  );

  Future<void> _export(String table) async {
    setState(() => _exporting = true);
    final res = await _ops.exportCsv(table);
    if (!mounted) return;
    setState(() => _exporting = false);

    switch (res) {
      case Ok(:final value):
        // Faylni yuklab olish o'rniga buferga nusxalanadi.
        //
        // Flutter Web'da faylni saqlash uchun `dart:js_interop` bilan
        // `<a download>` yaratish kerak — bu qo'shimcha bog'liqlik va
        // brauzer siyosatlariga tayanadi. CSV odatda darhol jadvalga
        // qo'yiladi, shuning uchun bufer yetarli va ishonchliroq.
        await Clipboard.setData(ClipboardData(text: value));
        if (!mounted) return;

        final c = Theme.of(context).extension<AppColors>()!;
        final lines = '\n'.allMatches(value).length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: c.successBg,
            content: Text(
              'admin.analytics.copied'.tr(args: ['$lines']),
              style: AppTypography.bodySmall.copyWith(color: c.successText),
            ),
          ),
        );

      case Fail(:final failure):
        if (!mounted) return;
        final c = Theme.of(context).extension<AppColors>()!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: c.errorBg,
            duration: const Duration(seconds: 6),
            content: Text(
              // Eng ehtimolli sabab — funksiya hali deploy qilinmagan.
              'admin.analytics.export_failed'.tr(
                args: [failure.messageKey.tr()],
              ),
              style: AppTypography.bodySmall.copyWith(color: c.errorText),
            ),
          ),
        );
    }
  }
}

class _ExportBar extends StatelessWidget {
  const _ExportBar({
    required this.busy,
    required this.onExport,
    required this.colors,
  });

  final bool busy;
  final Future<void> Function(String table) onExport;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AgSpace.x4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AgRadius.rMd,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.download_outlined, size: 16, color: colors.textSecondary),
          const SizedBox(width: AgSpace.x3),
          Text(
            'admin.analytics.export'.tr(),
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: AgSpace.x4),
          for (final table in const [
            'metrics',
            'users',
            'farms',
            'listings',
            'orders',
          ])
            Padding(
              padding: const EdgeInsets.only(right: AgSpace.x2),
              child: AdminButton(
                label: table,
                kind: AdminButtonKind.secondary,
                busy: busy,
                onPressed: busy ? null : () => onExport(table),
              ),
            ),
        ],
      ),
    );
  }
}
