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
import '../../../data/models/admin_listing.dart';
import '../../../data/repositories/admin_listing_repository.dart';
import '../../../data/repositories/admin_user_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_table.dart';
import '../cubit/listings_cubit.dart';
import '../widgets/listing_detail_panel.dart';

/// E'lon holatining rangi — jadval va panelda bir xil boʻlishi uchun
/// bitta joyda.
BadgeTone listingTone(String status) => switch (status) {
  ListingStatus.active => BadgeTone.success,
  ListingStatus.pending => BadgeTone.warning,
  ListingStatus.rejected => BadgeTone.danger,
  ListingStatus.suspended => BadgeTone.danger,
  ListingStatus.changesRequested => BadgeTone.info,
  ListingStatus.sold => BadgeTone.brand,
  _ => BadgeTone.neutral,
};

/// Bozor moderatsiyasi (TTZ §6.4).
class MarketplacePage extends StatelessWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.listingsRead,
      child: BlocProvider(
        create: (_) => ListingsCubit(
          getIt<AdminListingRepository>(),
          getIt<AdminUserRepository>(),
          context.locale.languageCode,
        )..init(),
        child: const _MarketplaceView(),
      ),
    );
  }
}

class _MarketplaceView extends StatelessWidget {
  const _MarketplaceView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocConsumer<ListingsCubit, ListingsState>(
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
        final cubit = context.read<ListingsCubit>();

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AgSpace.x7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPageHeader(
                    title: 'admin.nav.marketplace'.tr(),
                    subtitle: state.pendingCount > 0
                        ? 'admin.market.pending_count'.tr(
                            args: ['${state.pendingCount}'],
                          )
                        : 'admin.market.subtitle'.tr(),
                  ),
                  const SizedBox(height: AgSpace.x5),
                  _Filters(state: state, cubit: cubit),
                  const SizedBox(height: AgSpace.x4),

                  Expanded(
                    child: AdminTable<AdminListingRow>(
                      rows: state.rows,
                      loading: state.loading,
                      failure: state.failure,
                      onRetry: cubit.load,
                      emptyTitle: state.filter.status == ListingStatus.pending
                          ? 'admin.market.queue_empty'.tr()
                          : 'admin.common.no_results'.tr(),
                      emptyHint: state.filter.status == ListingStatus.pending
                          ? 'admin.market.queue_empty_hint'.tr()
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
              ListingDetailPanel(
                listing: state.selected!,
                imageUrls: state.imageUrls,
                history: state.history,
                loading: state.detailLoading,
                onClose: cubit.closeDetail,
              ),
          ],
        );
      },
    );
  }

  List<AdminColumn<AdminListingRow>> _columns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.market.col_listing',
      flex: 3,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.title,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            row.sellerName ?? '—',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.market.col_crop',
      flex: 2,
      build: (row) => Text(
        row.cropName ?? row.category,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.market.col_price',
      width: 140,
      align: Alignment.centerRight,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Fmt.sum(row.price),
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            '${Fmt.decimal(row.quantity)} ${row.unit}',
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.market.col_status',
      width: 150,
      build: (row) => StatusBadge(
        label: 'admin.listing_status.${row.status}'.tr(),
        tone: listingTone(row.status),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.market.col_created',
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

  final ListingsState state;
  final ListingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final f = state.filter;

    return Wrap(
      spacing: AgSpace.x3,
      runSpacing: AgSpace.x3,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AdminSearchField(
          hintKey: 'admin.market.search_hint',
          onChanged: (v) => cubit.applyFilter(f.copyWith(search: v)),
        ),
        AdminSelect<String>(
          value: f.status,
          hintKey: 'admin.market.filter_status',
          width: 200,
          items: [
            for (final s in ListingStatus.all)
              (s, 'admin.listing_status.$s'.tr()),
          ],
          onChanged: (v) => cubit.applyFilter(
            v == null ? f.copyWith(clearStatus: true) : f.copyWith(status: v),
          ),
        ),
        AdminSelect<int>(
          value: f.regionId,
          hintKey: 'admin.users.filter_region',
          items: [for (final r in state.regions) (r.id, r.name)],
          onChanged: (v) => cubit.applyFilter(
            v == null ? f.copyWith(clearRegion: true) : f.copyWith(regionId: v),
          ),
        ),
      ],
    );
  }
}
