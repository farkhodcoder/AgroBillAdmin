import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/rbac/permission.dart';
import '../../../core/rbac/permission_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/admin_order.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../cubit/orders_cubit.dart';
import '../pages/orders_page.dart' show orderTone;

/// Buyurtma tafsiloti: tomonlar, holat tarixi, baholar.
class OrderDetailPanel extends StatelessWidget {
  const OrderDetailPanel({
    super.key,
    required this.order,
    required this.history,
    required this.reviews,
    required this.loading,
    required this.onClose,
  });

  final AdminOrderRow order;
  final List<OrderHistoryEntry> history;
  final List<Map<String, dynamic>> reviews;
  final bool loading;
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
                    _Header(order: order, colors: c, onClose: onClose),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AgSpace.x6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Facts(order: order, colors: c),
                            const SizedBox(height: AgSpace.x6),
                            _Actions(order: order),
                            const SizedBox(height: AgSpace.x6),
                            if (loading)
                              const AdminLoading()
                            else ...[
                              _History(entries: history, colors: c),
                              if (reviews.isNotEmpty) ...[
                                const SizedBox(height: AgSpace.x6),
                                _Reviews(reviews: reviews, colors: c),
                              ],
                            ],
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
}

class _Header extends StatelessWidget {
  const _Header({
    required this.order,
    required this.colors,
    required this.onClose,
  });

  final AdminOrderRow order;
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
                  order.listingTitle ?? '—',
                  style: AppTypography.h3.copyWith(color: colors.text),
                ),
                const SizedBox(height: AgSpace.x2),
                Row(
                  children: [
                    StatusBadge(
                      label: 'admin.order_status.${order.status}'.tr(),
                      tone: orderTone(order.status),
                    ),
                    if (order.isOverdue) ...[
                      const SizedBox(width: AgSpace.x2),
                      StatusBadge(
                        label: 'admin.orders.overdue'.tr(),
                        tone: BadgeTone.danger,
                      ),
                    ],
                  ],
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

class _Facts extends StatelessWidget {
  const _Facts({required this.order, required this.colors});

  final AdminOrderRow order;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      (
        'admin.orders.buyer',
        '${order.buyerName ?? '—'} · ${order.buyerEmail ?? '—'}',
      ),
      (
        'admin.orders.seller',
        '${order.sellerName ?? '—'} · ${order.sellerEmail ?? '—'}',
      ),
      ('admin.market.quantity', Fmt.decimal(order.quantity)),
      ('admin.orders.unit_price', Fmt.sum(order.unitPrice)),
      ('admin.orders.col_total', Fmt.sum(order.totalPrice)),
      ('admin.orders.delivery', order.deliveryMethod),
      ('admin.orders.col_created', Fmt.dateTime(order.createdAt)),
      ('admin.orders.respond_by', Fmt.dateTime(order.respondBy)),
      if (order.confirmedAt != null)
        ('admin.orders.confirmed_at', Fmt.dateTime(order.confirmedAt)),
      if (order.completedAt != null)
        ('admin.orders.completed_at', Fmt.dateTime(order.completedAt)),
      if (order.cancelledReason != null)
        ('admin.orders.cancel_reason', order.cancelledReason!),
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
                  width: 130,
                  child: Text(
                    labelKey.tr(),
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
}

class _Actions extends StatelessWidget {
  const _Actions({required this.order});

  final AdminOrderRow order;

  @override
  Widget build(BuildContext context) {
    final closed = OrderStatus.isClosed(order.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PermissionGuard(
          permission: AdminPermission.ordersWrite,
          fallback: const SizedBox.shrink(),
          child: AdminButton(
            label: 'admin.orders.cancel_order'.tr(),
            kind: AdminButtonKind.danger,
            size: AdminButtonSize.large,
            expand: true,
            icon: Icons.cancel_outlined,
            // Yopilgan buyurtmani baza ham rad etadi
            // (`ORDER_ALREADY_CLOSED`, 0010) — tugma oldindan o'chiriladi.
            onPressed: closed
                ? null
                : () async {
                    final cubit = context.read<OrdersCubit>();
                    final result = await showReasonDialog(
                      context,
                      title: 'admin.orders.cancel_order'.tr(),
                      message: 'admin.orders.cancel_confirm'.tr(),
                      confirmLabel: 'admin.orders.cancel_order'.tr(),
                    );
                    if (!result.confirmed || result.reason == null) return;
                    await cubit.cancel(order.id, result.reason!);
                  },
          ),
        ),
        if (closed)
          Padding(
            padding: const EdgeInsets.only(top: AgSpace.x2),
            child: Text(
              'admin.orders.already_closed'.tr(),
              style: AppTypography.caption.copyWith(
                color: Theme.of(context).extension<AppColors>()!.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.entries, required this.colors});

  final List<OrderHistoryEntry> entries;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.orders.history'.tr(),
          style: AppTypography.label.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AgSpace.x3),
        if (entries.isEmpty)
          Text(
            'admin.common.empty'.tr(),
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          )
        else
          for (final e in entries)
            Container(
              margin: const EdgeInsets.only(bottom: AgSpace.x2),
              padding: const EdgeInsets.all(AgSpace.x3),
              decoration: BoxDecoration(
                color: colors.surfaceSunken,
                borderRadius: AgRadius.rSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (e.oldStatus != null) ...[
                        Text(
                          'admin.order_status.${e.oldStatus}'.tr(),
                          style: AppTypography.caption.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                        Icon(
                          Icons.arrow_right_alt,
                          size: 14,
                          color: colors.textTertiary,
                        ),
                      ],
                      Text(
                        'admin.order_status.${e.newStatus}'.tr(),
                        style: AppTypography.caption.copyWith(
                          color: colors.text,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Fmt.dateTime(e.changedAt),
                        style: AppTypography.caption.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  if (e.reason != null) ...[
                    const SizedBox(height: AgSpace.x1),
                    Text(
                      e.reason!,
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
      ],
    );
  }
}

class _Reviews extends StatelessWidget {
  const _Reviews({required this.reviews, required this.colors});

  final List<Map<String, dynamic>> reviews;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.orders.reviews'.tr(),
          style: AppTypography.label.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AgSpace.x3),
        for (final r in reviews)
          Container(
            margin: const EdgeInsets.only(bottom: AgSpace.x2),
            padding: const EdgeInsets.all(AgSpace.x3),
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              borderRadius: AgRadius.rSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Icon(
                        i < ((r['rating'] as num?)?.toInt() ?? 0)
                            ? Icons.star
                            : Icons.star_border,
                        size: 13,
                        color: colors.accent,
                      ),
                  ],
                ),
                if (r['comment'] != null) ...[
                  const SizedBox(height: AgSpace.x1),
                  Text(
                    r['comment'] as String,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
