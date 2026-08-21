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
import '../../../data/models/admin_farm.dart';
import '../../../data/repositories/admin_farm_repository.dart';
import '../../../data/repositories/admin_user_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_table.dart';
import '../cubit/farms_cubit.dart';
import '../widgets/farm_detail_panel.dart';

/// Xo'jaliklar (TTZ §6.3).
class FarmsPage extends StatelessWidget {
  const FarmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.farmsRead,
      child: BlocProvider(
        create: (_) => FarmsCubit(
          getIt<AdminFarmRepository>(),
          getIt<AdminUserRepository>(),
          context.locale.languageCode,
        )..init(),
        child: const _FarmsView(),
      ),
    );
  }
}

class _FarmsView extends StatelessWidget {
  const _FarmsView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocBuilder<FarmsCubit, FarmsState>(
      builder: (context, state) {
        final cubit = context.read<FarmsCubit>();

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AgSpace.x7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPageHeader(
                    title: 'admin.nav.farms'.tr(),
                    subtitle: 'admin.farms.subtitle'.tr(),
                  ),
                  const SizedBox(height: AgSpace.x5),
                  _Filters(state: state, cubit: cubit),
                  const SizedBox(height: AgSpace.x4),

                  Expanded(
                    child: AdminTable<AdminFarmRow>(
                      rows: state.rows,
                      loading: state.loading,
                      failure: state.failure,
                      onRetry: cubit.load,
                      emptyTitle: state.filter.isEmpty
                          ? 'admin.farms.empty'.tr()
                          : 'admin.common.no_results'.tr(),
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
              FarmDetailPanel(
                farm: state.selected!,
                fields: state.fields,
                loading: state.fieldsLoading,
                onClose: cubit.closeDetail,
              ),
          ],
        );
      },
    );
  }

  List<AdminColumn<AdminFarmRow>> _columns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.farms.col_name',
      flex: 3,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.name,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            row.ownerName ?? '—',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.farms.col_region',
      flex: 2,
      build: (row) => Text(
        [row.regionName, row.districtName].where((e) => e != null).join(' · '),
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.farms.col_area',
      width: 110,
      align: Alignment.centerRight,
      build: (row) => Text(
        '${Fmt.hectares(row.areaHectares)} ga',
        style: AppTypography.bodySmall.copyWith(color: c.text),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.farms.col_fields',
      width: 90,
      align: Alignment.centerRight,
      build: (row) => Text(
        '${row.fieldCount}',
        style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.farms.col_irrigation',
      width: 130,
      build: (row) =>
          StatusBadge(label: 'admin.irrigation.${row.irrigation}'.tr()),
    ),
    AdminColumn(
      labelKey: 'admin.farms.col_created',
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

  final FarmsState state;
  final FarmsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final f = state.filter;

    return Wrap(
      spacing: AgSpace.x3,
      runSpacing: AgSpace.x3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AdminSearchField(
          hintKey: 'admin.farms.search_hint',
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
          value: f.irrigation,
          hintKey: 'admin.farms.filter_irrigation',
          width: 190,
          items: [
            for (final i in const ['furrow', 'drip', 'sprinkler', 'other'])
              (i, 'admin.irrigation.$i'.tr()),
          ],
          onChanged: (v) => cubit.applyFilter(
            v == null
                ? f.copyWith(clearIrrigation: true)
                : f.copyWith(irrigation: v),
          ),
        ),
      ],
    );
  }
}
