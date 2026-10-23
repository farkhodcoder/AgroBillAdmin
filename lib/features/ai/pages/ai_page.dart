import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_table.dart';
import '../../dashboard/widgets/kpi_card.dart';
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

BadgeTone _severityTone(String severity) => switch (severity) {
  'high' => BadgeTone.danger,
  'medium' => BadgeTone.warning,
  'low' => BadgeTone.success,
  _ => BadgeTone.neutral,
};

class _AiView extends StatelessWidget {
  const _AiView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocBuilder<AiCubit, AiState>(
      builder: (context, state) {
        final cubit = context.read<AiCubit>();

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AgSpace.x7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPageHeader(
                    title: 'admin.nav.ai'.tr(),
                    subtitle: 'admin.ai.subtitle'.tr(),
                    actions: [
                      for (final (tab, key) in const [
                        (AiTab.usage, 'admin.ai.tab_usage'),
                        (AiTab.questions, 'admin.ai.tab_questions'),
                        (AiTab.scans, 'admin.ai.tab_scans'),
                      ]) ...[
                        const SizedBox(width: AgSpace.x2),
                        AdminButton(
                          label: key.tr(),
                          kind: state.tab == tab
                              ? AdminButtonKind.primary
                              : AdminButtonKind.secondary,
                          onPressed: () => cubit.switchTab(tab),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AgSpace.x5),

                  _Overview(state: state, colors: c),
                  const SizedBox(height: AgSpace.x5),

                  _Filters(state: state, cubit: cubit),
                  const SizedBox(height: AgSpace.x4),

                  Expanded(child: _table(context, state, cubit, c)),
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
            ),

            if (state.selectedScan != null)
              _ScanPanel(
                scan: state.selectedScan!,
                imageUrl: state.imageUrls[state.selectedScan!.imagePath],
                onClose: cubit.closeDetail,
              ),
            if (state.selectedQuestion != null)
              _ConversationPanel(state: state, onClose: cubit.closeDetail),
          ],
        );
      },
    );
  }

  Widget _table(
    BuildContext context,
    AiState state,
    AiCubit cubit,
    AppColors c,
  ) => switch (state.tab) {
    AiTab.usage => AdminTable<AiUsageRow>(
      rows: state.usage,
      loading: state.loading,
      failure: state.failure,
      onRetry: cubit.load,
      emptyTitle: 'admin.ai.usage_empty'.tr(),
      columns: _usageColumns(c),
    ),
    // Suhbat matni shaxsiy yozishma — alohida ruxsat (0009). Ruxsatsiz
    // so'rov xato emas, bo'sh ro'yxat qaytarardi va admin "hech kim hech
    // narsa so'ramagan" deb o'ylardi.
    AiTab.questions => PermissionGuard(
      permission: AdminPermission.aiModerate,
      child: AdminTable<AiQuestion>(
        rows: state.questions,
        loading: state.loading,
        failure: state.failure,
        onRetry: cubit.load,
        emptyTitle: 'admin.ai.questions_empty'.tr(),
        onRowTap: cubit.openQuestion,
        columns: _questionColumns(c),
      ),
    ),
    AiTab.scans => AdminTable<ScanRow>(
      rows: state.scans,
      loading: state.loading,
      failure: state.failure,
      onRetry: cubit.load,
      emptyTitle: 'admin.ai.scans_empty'.tr(),
      onRowTap: (row) => cubit.selectScan(row.id),
      columns: _scanColumns(c, state.imageUrls),
    ),
  };

  List<AdminColumn<AiUsageRow>> _usageColumns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.users.col_name',
      flex: 3,
      build: (row) =>
          _UserCell(name: row.userName, email: row.userEmail, colors: c),
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

  List<AdminColumn<AiQuestion>> _questionColumns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.ai.col_question',
      flex: 5,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.content.replaceAll('\n', ' '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          if (row.conversationTitle != null)
            Text(
              row.conversationTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: c.textTertiary),
            ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.users.col_name',
      flex: 2,
      build: (row) =>
          _UserCell(name: row.userName, email: row.userEmail, colors: c),
    ),
    AdminColumn(
      labelKey: 'admin.ai.col_date',
      width: 140,
      build: (row) => Text(
        Fmt.dateTime(row.createdAt),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
  ];

  List<AdminColumn<ScanRow>> _scanColumns(
    AppColors c,
    Map<String, String> urls,
  ) => [
    AdminColumn(
      labelKey: 'admin.ai.col_image',
      width: 72,
      build: (row) => _Thumb(
        url: urls[row.imagePath],
        hasImage: row.imagePath != null,
        size: 44,
        colors: c,
      ),
    ),
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
            [row.cropName, row.userName].whereType<String>().join(' · '),
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
            tone: _severityTone(row.severity),
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

class _UserCell extends StatelessWidget {
  const _UserCell({
    required this.name,
    required this.email,
    required this.colors,
  });

  final String? name;
  final String? email;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        name ?? '—',
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(color: colors.text),
      ),
      Text(
        email ?? '—',
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(color: colors.textTertiary),
      ),
    ],
  );
}

/// Skan rasmi kichik ko'rinishda.
///
/// Uch holat: rasm bor va URL olindi · rasm bor, lekin URL yo'q (ruxsat
/// yo'q yoki fayl o'chirilgan) · skan rasmsiz saqlangan (yuklash
/// muvaffaqiyatsiz bo'lgan).
class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.url,
    required this.hasImage,
    required this.size,
    required this.colors,
  });

  final String? url;
  final bool hasImage;
  final double size;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    Widget placeholder(IconData icon) => Container(
      width: size,
      height: size,
      color: colors.surfaceSunken,
      child: Icon(icon, size: size * 0.4, color: colors.textTertiary),
    );

    return ClipRRect(
      borderRadius: AgRadius.rSm,
      child: url == null
          ? placeholder(
              hasImage
                  ? Icons.lock_outline
                  : Icons.image_not_supported_outlined,
            )
          : CachedNetworkImage(
              imageUrl: url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                width: size,
                height: size,
                color: colors.skeletonBase,
              ),
              errorWidget: (_, _, _) =>
                  placeholder(Icons.broken_image_outlined),
            ),
    );
  }
}

/// Davr bo'yicha jami ko'rsatkichlar va model taqsimoti.
///
/// Model taqsimoti — zanjirdagi qaysi model qancha ishlatilgani. Kvota
/// tugaganda ilova keyingi modelga tushadi, shuning uchun bu taqsimotning
/// o'zgarishi kvota muammosining birinchi belgisi (TTZ §6.6).
class _Overview extends StatelessWidget {
  const _Overview({required this.state, required this.colors});

  final AiState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final period = 'admin.dashboard.days'.tr(args: ['${state.days}']);

    return Wrap(
      spacing: AgSpace.x3,
      runSpacing: AgSpace.x3,
      children: [
        KpiCard(
          label: 'admin.ai.total_questions'.tr(),
          value: Fmt.count(state.totals.questions),
          hint: period,
          icon: Icons.chat_bubble_outline,
        ),
        KpiCard(
          label: 'admin.ai.total_scans'.tr(),
          value: Fmt.count(state.totals.scans),
          hint: period,
          icon: Icons.document_scanner_outlined,
        ),
        KpiCard(
          label: 'admin.ai.active_users'.tr(),
          value: Fmt.count(state.totals.activeUsers),
          hint: period,
          icon: Icons.people_outline,
        ),
        for (final m in state.models)
          Container(
            width: 210,
            padding: const EdgeInsets.all(AgSpace.x5),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AgRadius.rLg,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.memory_outlined,
                      size: 15,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: AgSpace.x2),
                    Expanded(
                      child: Text(
                        m.model,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AgSpace.x3),
                Text(
                  Fmt.count(m.count),
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
    final periods = [
      for (final days in [7, 30, 90])
        AdminButton(
          label: 'admin.dashboard.days'.tr(args: ['$days']),
          kind: state.days == days
              ? AdminButtonKind.primary
              : AdminButtonKind.secondary,
          onPressed: () => cubit.setDays(days),
        ),
    ];

    return switch (state.tab) {
      AiTab.usage => Wrap(spacing: AgSpace.x2, children: periods),
      AiTab.questions => Wrap(
        spacing: AgSpace.x3,
        runSpacing: AgSpace.x3,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AdminSearchField(
            hintKey: 'admin.ai.search_questions',
            width: 360,
            onChanged: cubit.setSearch,
          ),
          Text(
            'admin.ai.private_note'.tr(),
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).extension<AppColors>()!.textTertiary,
            ),
          ),
        ],
      ),
      AiTab.scans => Wrap(
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
      ),
    };
  }
}

/// Skan tafsiloti: rasm, natija, alomatlar, tavsiya qilingan davolash.
///
/// Admin AI nima ko'rganini va nima maslahat berganini yonma-yon tekshira
/// olishi kerak — noto'g'ri tashxis shu yerda ko'rinadi.
class _ScanPanel extends StatelessWidget {
  const _ScanPanel({
    required this.scan,
    required this.imageUrl,
    required this.onClose,
  });

  final ScanRow scan;
  final String? imageUrl;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return AdminSidePanel(
      title: scan.diseaseName,
      subtitle: scan.diseaseLatin,
      onClose: onClose,
      badges: [
        StatusBadge(
          label: 'admin.severity.${scan.severity}'.tr(),
          tone: _severityTone(scan.severity),
        ),
        StatusBadge(
          label: '${'admin.ai.col_confidence'.tr()}: ${scan.confidence}%',
          tone: scan.confidence < 60 ? BadgeTone.warning : BadgeTone.info,
        ),
        if (!scan.isPlant)
          StatusBadge(label: 'admin.ai.not_plant'.tr(), tone: BadgeTone.danger),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AgSpace.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: AgRadius.rMd,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: imageUrl == null
                    ? Container(
                        color: c.surfaceSunken,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(AgSpace.x6),
                        child: Text(
                          scan.imagePath == null
                              ? 'admin.ai.no_image'.tr()
                              : 'admin.ai.image_denied'.tr(),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                      )
                    : InteractiveViewer(
                        maxScale: 4,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (_, _) =>
                              Container(color: c.skeletonBase),
                          errorWidget: (_, _, _) => Icon(
                            Icons.broken_image_outlined,
                            color: c.textTertiary,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AgSpace.x5),
            _Facts(
              colors: c,
              rows: [
                ('admin.ai.user', scan.userName ?? scan.userEmail ?? '—'),
                ('admin.disease.col_crop', scan.cropName ?? '—'),
                ('admin.ai.col_model', scan.modelVersion ?? '—'),
                (
                  'admin.ai.latency',
                  scan.latencyMs == null ? '—' : '${scan.latencyMs} ms',
                ),
                ('admin.ai.col_date', Fmt.dateTime(scan.createdAt)),
              ],
            ),
            const SizedBox(height: AgSpace.x5),
            if (scan.symptoms.isNotEmpty)
              AdminFactBlock(
                label: 'admin.disease.symptoms'.tr(),
                child: _Bullets(items: scan.symptoms, colors: c),
              ),
            if (scan.treatments.isNotEmpty)
              AdminFactBlock(
                label: 'admin.disease.treatments'.tr(),
                child: _Steps(steps: scan.treatments, colors: c),
              ),
            if ((scan.prevention ?? '').isNotEmpty)
              AdminFactBlock(
                label: 'admin.disease.prevention'.tr(),
                child: Text(
                  scan.prevention!,
                  style: AppTypography.bodySmall.copyWith(color: c.text),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Suhbat to'liq ko'rinishda — savol va AI javoblari navbatma-navbat.
class _ConversationPanel extends StatelessWidget {
  const _ConversationPanel({required this.state, required this.onClose});

  final AiState state;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final q = state.selectedQuestion!;

    final Widget body;
    if (state.conversationLoading) {
      body = const AdminLoading();
    } else if (state.conversationFailure != null) {
      body = Padding(
        padding: const EdgeInsets.all(AgSpace.x6),
        child: AdminErrorBanner(
          failure: state.conversationFailure!,
          onRetry: () => context.read<AiCubit>().openQuestion(q),
        ),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.all(AgSpace.x6),
        itemCount: state.conversation.length,
        separatorBuilder: (_, _) => const SizedBox(height: AgSpace.x3),
        itemBuilder: (_, i) {
          final m = state.conversation[i];
          return AdminChatBubble(
            text: m.content,
            time: m.createdAt,
            mine: m.isUser,
            highlighted: m.id == q.id,
            label: m.isUser
                ? (q.userName ?? 'admin.ai.user'.tr())
                : 'admin.ai.assistant'.tr(),
            colors: c,
          );
        },
      );
    }

    return AdminSidePanel(
      title: q.conversationTitle ?? 'admin.ai.conversation'.tr(),
      subtitle: [q.userName, q.userEmail].whereType<String>().join(' · '),
      onClose: onClose,
      width: 600,
      body: body,
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.rows, required this.colors});

  final List<(String, String)> rows;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (key, value) in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AgSpace.x1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  key.tr(),
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(color: colors.text),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.items, required this.colors});

  final List<String> items;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final s in items)
        Padding(
          padding: const EdgeInsets.only(bottom: AgSpace.x1),
          child: Text(
            '•  $s',
            style: AppTypography.bodySmall.copyWith(color: colors.text),
          ),
        ),
    ],
  );
}

class _Steps extends StatelessWidget {
  const _Steps({required this.steps, required this.colors});

  final List<TreatmentStep> steps;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < steps.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: AgSpace.x2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${i + 1}. ${steps[i].title}',
                style: AppTypography.bodySmall.copyWith(color: colors.text),
              ),
              if (steps[i].detail.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: AgSpace.x4),
                  child: Text(
                    steps[i].detail,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}
