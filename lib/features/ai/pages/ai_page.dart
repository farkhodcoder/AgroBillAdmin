import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/rbac/permission.dart';
import '../../../core/rbac/permission_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/admin_ai.dart';
import '../../../data/repositories/admin_ai_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_table.dart';
import '../cubit/ai_cubit.dart';

/// AI monitoringi (TTZ §6.6).
class AiPage extends StatelessWidget {
  const AiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.aiRead,
      child: BlocProvider(
        create: (_) =>
            AiCubit(getIt<AdminAiRepository>(), context.locale.languageCode)
              ..init(),
        child: const _AiView(),
      ),
    );
  }
}

class _AiView extends StatelessWidget {
  const _AiView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocBuilder<AiCubit, AiState>(
      builder: (context, state) {
        final cubit = context.read<AiCubit>();

        return Padding(
          padding: const EdgeInsets.all(AgSpace.x7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminPageHeader(
                title: 'admin.nav.ai'.tr(),
                subtitle: 'admin.ai.subtitle'.tr(),
                actions: [
                  AdminButton(
                    label: 'admin.ai.tab_usage'.tr(),
                    kind: state.tab == AiTab.usage
                        ? AdminButtonKind.primary
                        : AdminButtonKind.secondary,
                    onPressed: () => cubit.switchTab(AiTab.usage),
                  ),
                  const SizedBox(width: AgSpace.x2),
                  AdminButton(
                    label: 'admin.ai.tab_scans'.tr(),
                    kind: state.tab == AiTab.scans
                        ? AdminButtonKind.primary
                        : AdminButtonKind.secondary,
                    onPressed: () => cubit.switchTab(AiTab.scans),
                  ),
                ],
              ),
              const SizedBox(height: AgSpace.x5),

              if (state.models.isNotEmpty) ...[
                _Models(models: state.models, colors: c),
                const SizedBox(height: AgSpace.x5),
              ],

              _Filters(state: state, cubit: cubit),
              const SizedBox(height: AgSpace.x4),

              Expanded(
                child: state.tab == AiTab.usage
                    ? AdminTable<AiUsageRow>(
                        rows: state.usage,
                        loading: state.loading,
                        failure: state.failure,
                        onRetry: cubit.load,
                        emptyTitle: 'admin.ai.usage_empty'.tr(),
                        columns: _usageColumns(c),
                      )
                    : AdminTable<ScanRow>(
                        rows: state.scans,
                        loading: state.loading,
                        failure: state.failure,
                        onRetry: cubit.load,
                        emptyTitle: 'admin.ai.scans_empty'.tr(),
                        columns: _scanColumns(c),
                      ),
              ),
              const SizedBox(height: AgSpace.x4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'admin.ai.tokens_note'.tr(),
                      style: AppTypography.caption.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  ),
                  AdminPagination(
                    page: state.page,
                    hasMore: state.hasMore,
                    loading: state.loading,
                    onChanged: cubit.goToPage,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<AdminColumn<AiUsageRow>> _usageColumns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.users.col_name',
      flex: 3,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.userName ?? '—',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            row.userEmail ?? '—',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.ai.col_date',
      width: 120,
      build: (row) => Text(
        Fmt.date(row.usageDate),
        style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.ai.col_questions',
      width: 110,
      align: Alignment.centerRight,
      build: (row) => Text(
        '${row.questionsCount}',
        style: AppTypography.bodySmall.copyWith(color: c.text),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.ai.col_scans',
      width: 110,
      align: Alignment.centerRight,
      build: (row) => Text(
        '${row.scansCount}',
        style: AppTypography.bodySmall.copyWith(color: c.text),
      ),
    ),
  ];

  List<AdminColumn<ScanRow>> _scanColumns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.ai.col_disease',
      flex: 3,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.diseaseName,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            [row.cropName, row.userName].where((e) => e != null).join(' · '),
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.ai.col_severity',
      width: 190,
      build: (row) => Wrap(
        spacing: AgSpace.x1,
        children: [
          StatusBadge(
            label: 'admin.severity.${row.severity}'.tr(),
            tone: switch (row.severity) {
              'high' => BadgeTone.danger,
              'medium' => BadgeTone.warning,
              'low' => BadgeTone.success,
              _ => BadgeTone.neutral,
            },
          ),
          // AI rasmda o'simlik topmagan — odatda noto'g'ri rasm yuborilgan.
          if (!row.isPlant)
            StatusBadge(
              label: 'admin.ai.not_plant'.tr(),
              tone: BadgeTone.danger,
            ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.ai.col_confidence',
      width: 100,
      align: Alignment.centerRight,
      build: (row) => Text(
        '${row.confidence}%',
        style: AppTypography.bodySmall.copyWith(
          color: row.confidence < 60 ? c.warningText : c.text,
        ),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.ai.col_model',
      width: 190,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.modelVersion ?? '—',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textSecondary),
          ),
          if (row.latencyMs != null)
            Text(
              '${row.latencyMs} ms',
              style: AppTypography.caption.copyWith(color: c.textTertiary),
            ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.ai.col_date',
      width: 130,
      build: (row) => Text(
        Fmt.dateTime(row.createdAt),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
  ];
}

/// Model taqsimoti — zanjirdagi qaysi model qancha ishlatilgani.
///
/// Kvota tugaganda ilova keyingi modelga tushadi, shuning uchun bu
/// taqsimotning o'zgarishi kvota muammosining birinchi belgisi (TTZ §6.6).
class _Models extends StatelessWidget {
  const _Models({required this.models, required this.colors});

  final List<ModelUsage> models;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AgSpace.x3,
      runSpacing: AgSpace.x3,
      children: [
        for (final m in models)
          Container(
            padding: const EdgeInsets.all(AgSpace.x4),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AgRadius.rMd,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.model,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AgSpace.x1),
                Text(
                  '${m.count}',
                  style: AppTypography.metricSmall.copyWith(color: colors.text),
                ),
                Text(
                  '${m.avgLatencyMs} ms · ${m.avgConfidence}%',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.cubit});

  final AiState state;
  final AiCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (state.tab == AiTab.usage) {
      return Wrap(
        spacing: AgSpace.x2,
        children: [
          for (final days in [7, 30, 90])
            AdminButton(
              label: 'admin.dashboard.days'.tr(args: ['$days']),
              kind: state.days == days
                  ? AdminButtonKind.primary
                  : AdminButtonKind.secondary,
              onPressed: () => cubit.setDays(days),
            ),
        ],
      );
    }

    return Wrap(
      spacing: AgSpace.x3,
      runSpacing: AgSpace.x3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AdminSelect<String>(
          value: state.severity,
          hintKey: 'admin.ai.filter_severity',
          width: 190,
          items: [
            for (final s in const ['low', 'medium', 'high', 'unknown'])
              (s, 'admin.severity.$s'.tr()),
          ],
          onChanged: cubit.setSeverity,
        ),
        AdminButton(
          label: 'admin.ai.problems_only'.tr(),
          icon: Icons.report_gmailerrorred_outlined,
          kind: state.problemsOnly
              ? AdminButtonKind.primary
              : AdminButtonKind.secondary,
          onPressed: cubit.toggleProblems,
        ),
      ],
    );
  }
}
