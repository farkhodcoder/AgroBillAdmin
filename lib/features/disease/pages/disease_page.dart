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
import '../cubit/disease_cubit.dart';

BadgeTone contentTone(String status) => switch (status) {
  ContentStatus.published => BadgeTone.success,
  ContentStatus.review => BadgeTone.warning,
  ContentStatus.draft => BadgeTone.neutral,
  ContentStatus.archived => BadgeTone.neutral,
  _ => BadgeTone.neutral,
};

/// Kasallik ma'lumotnomasi (TTZ §6.7).
class DiseasePage extends StatelessWidget {
  const DiseasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.diseaseRead,
      child: BlocProvider(
        create: (_) => DiseaseCubit(
          getIt<AdminAiRepository>(),
          context.locale.languageCode,
        )..load(),
        child: const _DiseaseView(),
      ),
    );
  }
}

class _DiseaseView extends StatelessWidget {
  const _DiseaseView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocConsumer<DiseaseCubit, DiseaseState>(
      listenWhen: (prev, next) =>
          next.actionFailure != null &&
          prev.actionFailure != next.actionFailure,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: c.errorBg,
            content: Text(
              state.actionFailure!.messageKey.tr(),
              style: AppTypography.bodySmall.copyWith(color: c.errorText),
            ),
          ),
        );
      },
      builder: (context, state) {
        final cubit = context.read<DiseaseCubit>();

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AgSpace.x7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPageHeader(
                    title: 'admin.nav.disease'.tr(),
                    subtitle: 'admin.disease.subtitle'.tr(),
                  ),
                  const SizedBox(height: AgSpace.x5),

                  if (state.untranslatedCount > 0) ...[
                    AdminNote(
                      text: 'admin.disease.untranslated'.tr(
                        args: ['${state.untranslatedCount}'],
                      ),
                      icon: Icons.translate_outlined,
                    ),
                    const SizedBox(height: AgSpace.x4),
                  ],

                  Wrap(
                    spacing: AgSpace.x3,
                    runSpacing: AgSpace.x3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AdminSearchField(
                        hintKey: 'admin.disease.search_hint',
                        onChanged: cubit.setSearch,
                      ),
                      AdminSelect<String>(
                        value: state.status,
                        hintKey: 'admin.disease.filter_status',
                        width: 190,
                        items: [
                          for (final s in ContentStatus.all)
                            (s, 'admin.content_status.$s'.tr()),
                        ],
                        onChanged: cubit.setStatus,
                      ),
                    ],
                  ),
                  const SizedBox(height: AgSpace.x4),

                  Expanded(
                    child: AdminTable<DiseaseRow>(
                      rows: state.rows,
                      loading: state.loading,
                      failure: state.failure,
                      onRetry: cubit.load,
                      emptyTitle: 'admin.disease.empty'.tr(),
                      onRowTap: (row) => cubit.select(row.id),
                      columns: _columns(c),
                    ),
                  ),
                ],
              ),
            ),

            if (state.selected != null)
              _DetailPanel(
                disease: state.selected!,
                onClose: cubit.closeDetail,
              ),
          ],
        );
      },
    );
  }

  List<AdminColumn<DiseaseRow>> _columns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.disease.col_name',
      flex: 3,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.nameUz,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            row.latinName ?? row.code,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: c.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.disease.col_crop',
      flex: 2,
      build: (row) => Text(
        row.cropName ?? '—',
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.disease.col_content',
      width: 150,
      build: (row) => Text(
        'admin.disease.counts'.tr(
          args: ['${row.symptomCount}', '${row.treatmentCount}'],
        ),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.disease.col_status',
      width: 170,
      build: (row) => Wrap(
        spacing: AgSpace.x1,
        children: [
          StatusBadge(
            label: 'admin.content_status.${row.status}'.tr(),
            tone: contentTone(row.status),
          ),
          if (!row.isTranslated)
            StatusBadge(
              label: 'admin.disease.partial'.tr(),
              tone: BadgeTone.warning,
            ),
        ],
      ),
    ),
  ];
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.disease, required this.onClose});

  final DiseaseRow disease;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Positioned.fill(
      child: Stack(
        children: [
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
                    Container(
                      padding: const EdgeInsets.all(AgSpace.x6),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: c.border)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  disease.nameUz,
                                  style: AppTypography.h3.copyWith(
                                    color: c.text,
                                  ),
                                ),
                                const SizedBox(height: AgSpace.x1),
                                Text(
                                  disease.latinName ?? disease.code,
                                  style: AppTypography.caption.copyWith(
                                    color: c.textTertiary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: onClose,
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: c.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AgSpace.x6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _names(c),
                            const SizedBox(height: AgSpace.x5),
                            _text(
                              c,
                              'admin.disease.description',
                              disease.description,
                            ),
                            _text(c, 'admin.disease.causes', disease.causes),
                            _text(
                              c,
                              'admin.disease.prevention',
                              disease.prevention,
                            ),
                            const SizedBox(height: AgSpace.x5),
                            _StatusActions(disease: disease),
                          ],
                        ),
                      ),
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

  Widget _names(AppColors c) => Column(
    children: [
      for (final (label, value) in [
        ('UZ', disease.nameUz),
        ('RU', disease.nameRu),
        ('EN', disease.nameEn),
        ('ID', '${disease.id} · ${disease.code}'),
        if (disease.updatedAt != null)
          ('admin.disease.updated', Fmt.dateTime(disease.updatedAt)),
      ])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AgSpace.x1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  label.startsWith('admin.') ? label.tr() : label,
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
              ),
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: AppTypography.bodySmall.copyWith(
                    color: value.isEmpty ? c.warningText : c.text,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _text(AppColors c, String labelKey, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AgSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelKey.tr(),
            style: AppTypography.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AgSpace.x1),
          Text(value, style: AppTypography.bodySmall.copyWith(color: c.text)),
        ],
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({required this.disease});

  final DiseaseRow disease;

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.diseaseWrite,
      fallback: const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'admin.disease.change_status'.tr(),
            style: AppTypography.label.copyWith(
              color: Theme.of(context).extension<AppColors>()!.textSecondary,
            ),
          ),
          const SizedBox(height: AgSpace.x3),
          Wrap(
            spacing: AgSpace.x2,
            runSpacing: AgSpace.x2,
            children: [
              for (final status in ContentStatus.all)
                AdminButton(
                  label: 'admin.content_status.$status'.tr(),
                  kind: disease.status == status
                      ? AdminButtonKind.primary
                      : AdminButtonKind.secondary,
                  // Joriy holatga qayta o'tkazish ma'nosiz — tugma o'chiq.
                  onPressed: disease.status == status
                      ? null
                      : () => context.read<DiseaseCubit>().setStatusOf(
                          disease.id,
                          status,
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
