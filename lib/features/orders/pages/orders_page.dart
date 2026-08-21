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
import '../../../data/models/admin_order.dart';
import '../../../data/repositories/admin_order_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_table.dart';
import '../cubit/orders_cubit.dart';
import '../widgets/order_detail_panel.dart';

BadgeTone orderTone(String status) => switch (status) {
  OrderStatus.completed => BadgeTone.success,
  OrderStatus.pending => BadgeTone.warning,
  OrderStatus.cancelled => BadgeTone.danger,
  OrderStatus.confirmed => BadgeTone.info,
  OrderStatus.inProgress => BadgeTone.brand,
  _ => BadgeTone.neutral,
};

/// Buyurtmalar (TTZ §6.5).
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.ordersRead,
      child: BlocProvider(
        create: (_) => OrdersCubit(getIt<AdminOrderRepository>())..load(),
        child: const _OrdersView(),
      ),
    );
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocConsumer<OrdersCubit, OrdersState>(
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
        final cubit = context.read<OrdersCubit>();
        final f = state.filter;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AgSpace.x7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPageHeader(
                    title: 'admin.nav.orders'.tr(),
                    subtitle: 'admin.orders.subtitle'.tr(),
                  ),
                  const SizedBox(height: AgSpace.x5),
                  Wrap(
                    spacing: AgSpace.x3,
                    runSpacing: AgSpace.x3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AdminSelect<String>(
                        value: f.status,
                        hintKey: 'admin.orders.filter_status',
                        width: 200,
                        items: [
                          for (final s in OrderStatus.all)
                            (s, 'admin.order_status.$s'.tr()),
                        ],
                        onChanged: (v) => cubit.applyFilter(
                          v == null
                              ? f.copyWith(clearStatus: true)
                              : f.copyWith(status: v, overdueOnly: false),
                        ),
                      ),
                      // Nizolar shu yerdan boshlanadi: sotuvchi 24 soat
                      // ichida javob bermagan buyurtmalar.
                      AdminButton(
                        label: 'admin.orders.overdue_only'.tr(),
                        icon: Icons.timer_outlined,
                        kind: f.overdueOnly
                            ? AdminButtonKind.primary
                            : AdminButtonKind.secondary,
                        onPressed: () => cubit.applyFilter(
                          f.overdueOnly
                              ? const OrderFilter()
                              : const OrderFilter(overdueOnly: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AgSpace.x4),

                  Expanded(
                    child: AdminTable<AdminOrderRow>(
                      rows: state.rows,
                      loading: state.loading,
                      failure: state.failure,
                      onRetry: cubit.load,
                      emptyTitle: f.isEmpty
                          ? 'admin.orders.empty'.tr()
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
              OrderDetailPanel(
                order: state.selected!,
                history: state.history,
                reviews: state.reviews,
                loading: state.detailLoading,
                onClose: cubit.closeDetail,
              ),
          ],
        );
      },
    );
  }

  List<AdminColumn<AdminOrderRow>> _columns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.orders.col_listing',
      flex: 3,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.listingTitle ?? '—',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            '${row.buyerName ?? '—'} → ${row.sellerName ?? '—'}',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.orders.col_total',
      width: 140,
      align: Alignment.centerRight,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Fmt.sum(row.totalPrice),
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            Fmt.decimal(row.quantity),
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.orders.col_status',
      width: 160,
      build: (row) => Wrap(
        spacing: AgSpace.x1,
        children: [
          StatusBadge(
            label: 'admin.order_status.${row.status}'.tr(),
            tone: orderTone(row.status),
          ),
          if (row.isOverdue)
            StatusBadge(
              label: 'admin.orders.overdue'.tr(),
              tone: BadgeTone.danger,
            ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.orders.col_created',
      width: 130,
      build: (row) => Text(
        Fmt.dateTime(row.createdAt),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
  ];
}
