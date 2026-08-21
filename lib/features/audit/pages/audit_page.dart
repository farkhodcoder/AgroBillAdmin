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
import '../../../data/repositories/admin_audit_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_table.dart';
import '../cubit/audit_cubit.dart';

/// Audit jurnali (TTZ §6.14).
class AuditPage extends StatelessWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.auditRead,
      child: BlocProvider(
        create: (_) => AuditCubit(getIt<AdminAuditRepository>())..init(),
        child: const _AuditView(),
      ),
    );
  }
}

class _AuditView extends StatelessWidget {
  const _AuditView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocBuilder<AuditCubit, AuditState>(
      builder: (context, state) {
        final cubit = context.read<AuditCubit>();
        final f = state.filter;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AgSpace.x7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPageHeader(
                    title: 'admin.nav.audit'.tr(),
                    subtitle: 'admin.audit.subtitle'.tr(),
                  ),
                  const SizedBox(height: AgSpace.x5),

                  Wrap(
                    spacing: AgSpace.x3,
                    runSpacing: AgSpace.x3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AdminSelect<String>(
                        value: f.action,
                        hintKey: 'admin.audit.filter_action',
                        width: 220,
                        // Amallar jurnalning O'ZIDAN olinadi: qat'iy ro'yxat
                        // yozilsa yangi RPC qo'shilganda filtr eskirib
                        // qolardi va admin uni ko'rmay qolardi.
                        items: [for (final a in state.actions) (a, a)],
                        onChanged: (v) => cubit.applyFilter(
                          v == null
                              ? f.copyWith(clearAction: true)
                              : f.copyWith(action: v),
                        ),
                      ),
                      AdminSelect<String>(
                        value: f.targetType,
                        hintKey: 'admin.audit.filter_target',
                        width: 190,
                        items: const [
                          ('profile', 'profile'),
                          ('listing', 'listing'),
                          ('order', 'order'),
                          ('admin_user', 'admin_user'),
                          ('conversation', 'conversation'),
                          ('disease_reference', 'disease_reference'),
                          ('app_setting', 'app_setting'),
                        ],
                        onChanged: (v) => cubit.applyFilter(
                          v == null
                              ? f.copyWith(clearTargetType: true)
                              : f.copyWith(targetType: v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AgSpace.x4),

                  Expanded(
                    child: AdminTable<AuditRow>(
                      rows: state.rows,
                      loading: state.loading,
                      failure: state.failure,
                      onRetry: cubit.load,
                      emptyTitle: f.isEmpty
                          ? 'admin.audit.empty'.tr()
                          : 'admin.common.no_results'.tr(),
                      emptyHint: f.isEmpty
                          ? 'admin.audit.empty_hint'.tr()
                          : null,
                      onRowTap: (row) => cubit.select(row.id),
                      columns: _columns(c),
                    ),
                  ),
                  const SizedBox(height: AgSpace.x4),
                  AdminPagination(
                    page: state.page,
                    hasMore: state.hasMore,
                    loading: state.loading,
                    onChanged: cubit.goToPage,
                  ),
                ],
              ),
            ),

            if (state.selected != null)
              _DetailPanel(entry: state.selected!, onClose: cubit.closeDetail),
          ],
        );
      },
    );
  }

  List<AdminColumn<AuditRow>> _columns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.audit.col_action',
      flex: 2,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.action,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            row.targetType ?? '—',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.audit.col_actor',
      flex: 2,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.actorName ?? '—',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          if (row.actorRole != null)
            Text(
              'admin.roles.${row.actorRole}'.tr(),
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(color: c.textTertiary),
            ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.audit.col_reason',
      flex: 3,
      build: (row) => Text(
        row.reason ?? '—',
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.audit.col_time',
      width: 140,
      build: (row) => Text(
        Fmt.dateTime(row.createdAt),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
  ];
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.entry, required this.onClose});

  final AuditRow entry;
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
                width: 540,
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
                        children: [
                          Expanded(
                            child: Text(
                              entry.action,
                              style: AppTypography.h3.copyWith(color: c.text),
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
                            _facts(c),
                            const SizedBox(height: AgSpace.x6),
                            _changes(c),
                            const SizedBox(height: AgSpace.x6),
                            AdminNote(
                              text: 'admin.audit.immutable_note'.tr(),
                              icon: Icons.lock_outline,
                            ),
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

  Widget _facts(AppColors c) {
    final rows = <(String, String)>[
      ('admin.audit.col_actor', entry.actorEmail ?? entry.actorName ?? '—'),
      if (entry.actorRole != null)
        ('admin.user_roles.label', 'admin.roles.${entry.actorRole}'.tr()),
      ('admin.audit.col_target', entry.targetType ?? '—'),
      if (entry.targetId != null) ('admin.users.id', entry.targetId!),
      if (entry.reason != null) ('admin.audit.col_reason', entry.reason!),
      ('admin.audit.col_time', Fmt.dateTime(entry.createdAt)),
      if (entry.ipAddress != null) ('admin.audit.ip', entry.ipAddress!),
      if (entry.userAgent != null) ('admin.audit.user_agent', entry.userAgent!),
    ];

    return Column(
      children: [
        for (final (labelKey, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AgSpace.x1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    labelKey.tr(),
                    style: AppTypography.caption.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    value,
                    style: AppTypography.caption.copyWith(color: c.text),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// O'zgargan maydonlar.
  ///
  /// `old_value` odatda butun qatorni saqlaydi (`to_jsonb(p)`), shuning
  /// uchun `new_value` dagi kalitlar bo'yicha yuriladi — aks holda o'nlab
  /// tegilmagan maydon ham chiqib, haqiqiy o'zgarish yo'qolib ketardi.
  Widget _changes(AppColors c) {
    final changes = entry.changes;
    if (changes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.audit.changes'.tr(),
          style: AppTypography.label.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AgSpace.x3),
        for (final (field, before, after) in changes)
          Container(
            margin: const EdgeInsets.only(bottom: AgSpace.x2),
            padding: const EdgeInsets.all(AgSpace.x3),
            decoration: BoxDecoration(
              color: c.surfaceSunken,
              borderRadius: AgRadius.rSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field,
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: AgSpace.x1),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        before ?? '—',
                        style: AppTypography.caption.copyWith(
                          color: c.textTertiary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_right_alt,
                      size: 14,
                      color: c.textTertiary,
                    ),
                    Expanded(
                      child: Text(
                        after ?? '—',
                        style: AppTypography.caption.copyWith(color: c.text),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
