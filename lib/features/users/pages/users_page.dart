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
import '../../../data/models/admin_user.dart';
import '../../../data/repositories/admin_user_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_table.dart';
import '../cubit/users_cubit.dart';
import '../widgets/user_detail_panel.dart';

/// Foydalanuvchilar ro'yxati (TTZ §6.2).
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.usersRead,
      child: BlocProvider(
        create: (_) => UsersCubit(
          getIt<AdminUserRepository>(),
          context.locale.languageCode,
        )..init(),
        child: const _UsersView(),
      ),
    );
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocConsumer<UsersCubit, UsersState>(
      // Amal xatosi — ro'yxat joyida qoladi, xabar tepada chiqadi.
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
        final cubit = context.read<UsersCubit>();

        return Padding(
          padding: const EdgeInsets.all(AgSpace.x7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminPageHeader(
                title: 'admin.nav.users'.tr(),
                subtitle: 'admin.users.subtitle'.tr(),
              ),
              const SizedBox(height: AgSpace.x5),
              _Filters(state: state, cubit: cubit),
              const SizedBox(height: AgSpace.x4),

              Expanded(
                child: AdminTable<AdminUserRow>(
                  rows: state.rows,
                  loading: state.loading,
                  failure: state.failure,
                  onRetry: cubit.load,
                  emptyTitle: state.filter.isEmpty
                      ? 'admin.users.empty'.tr()
                      : 'admin.common.no_results'.tr(),
                  emptyHint: state.filter.isEmpty
                      ? null
                      : 'admin.common.no_results_hint'.tr(),
                  onRowTap: (row) => showUserDetail(context, cubit, row),
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
        );
      },
    );
  }

  List<AdminColumn<AdminUserRow>> _columns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.users.col_name',
      flex: 3,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.fullName.isEmpty ? '—' : row.fullName,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            row.email ?? '—',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.users.col_region',
      flex: 2,
      build: (row) => Text(
        row.regionName ?? '—',
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.users.col_activity',
      flex: 2,
      build: (row) => Text(
        'admin.activity.${row.activity}'.tr(),
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.users.col_status',
      width: 190,
      build: (row) => Wrap(
        spacing: AgSpace.x1,
        runSpacing: 2,
        children: [
          if (row.isDeleted)
            StatusBadge(
              label: 'admin.users.deleted'.tr(),
              tone: BadgeTone.neutral,
            )
          else if (row.isBlocked)
            StatusBadge(
              label: 'admin.users.blocked'.tr(),
              tone: BadgeTone.danger,
            )
          else
            StatusBadge(
              label: 'admin.users.active'.tr(),
              tone: BadgeTone.success,
            ),
          if (row.role != 'farmer')
            StatusBadge(
              label: 'admin.user_roles.${row.role}'.tr(),
              tone: BadgeTone.brand,
            ),
          if (row.isPremium)
            StatusBadge(
              label: 'admin.users.premium'.tr(),
              tone: BadgeTone.warning,
            ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.users.col_joined',
      width: 110,
      build: (row) => Text(
        Fmt.date(row.createdAt),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
  ];
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state, required this.cubit});

  final UsersState state;
  final UsersCubit cubit;

  @override
  Widget build(BuildContext context) {
    final f = state.filter;

    return Wrap(
      spacing: AgSpace.x3,
      runSpacing: AgSpace.x3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AdminSearchField(
          hintKey: 'admin.users.search_hint',
          onChanged: (v) => cubit.applyFilter(f.copyWith(search: v)),
        ),
        AdminSelect<int>(
          value: f.regionId,
          hintKey: 'admin.users.filter_region',
          items: [for (final r in state.regions) (r.id, r.name)],
          onChanged: (v) => cubit.applyFilter(
            v == null ? f.copyWith(clearRegion: true) : f.copyWith(regionId: v),
          ),
        ),
        AdminSelect<String>(
          value: f.activity,
          hintKey: 'admin.users.filter_activity',
          width: 200,
          items: [
            for (final a in const [
              'farm_owner',
              'agronomist',
              'entrepreneur',
              'other',
            ])
              (a, 'admin.activity.$a'.tr()),
          ],
          onChanged: (v) => cubit.applyFilter(
            v == null
                ? f.copyWith(clearActivity: true)
                : f.copyWith(activity: v),
          ),
        ),
        AdminSelect<String>(
          value: f.role,
          hintKey: 'admin.users.filter_role',
          width: 170,
          items: [
            for (final r in const [
              'farmer',
              'agronomist',
              'moderator',
              'admin',
            ])
              (r, 'admin.user_roles.$r'.tr()),
          ],
          onChanged: (v) => cubit.applyFilter(
            v == null ? f.copyWith(clearRole: true) : f.copyWith(role: v),
          ),
        ),
        AdminSelect<bool>(
          value: f.blocked,
          hintKey: 'admin.users.filter_status',
          width: 160,
          items: [
            (true, 'admin.users.blocked'.tr()),
            (false, 'admin.users.active'.tr()),
          ],
          onChanged: (v) => cubit.applyFilter(
            v == null ? f.copyWith(clearBlocked: true) : f.copyWith(blocked: v),
          ),
        ),
      ],
    );
  }
}
