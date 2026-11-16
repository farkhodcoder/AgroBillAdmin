import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../app/di.dart';
import '../../../core/rbac/permission.dart';
import '../../../core/rbac/permission_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/result.dart';
import '../../../data/repositories/admin_request_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';

/// Xaridor so'rovlari ("menga 2 tonna pomidor kerak") va ularga fermerlar
/// bergan takliflar (mobil 0052).
///
/// Faqat kuzatuv: so'rovni xaridorning o'zi yopadi, muddati o'tgani
/// avtomatik `expired` bo'ladi. Bozorning "talab" tomoni shu yerda ko'rinadi —
/// e'lonlar esa "taklif" tomoni.
class MarketRequestsPage extends StatefulWidget {
  const MarketRequestsPage({super.key});

  @override
  State<MarketRequestsPage> createState() => _MarketRequestsPageState();
}

class _MarketRequestsPageState extends State<MarketRequestsPage> {
  final _repo = getIt<AdminRequestRepository>();

  List<MarketRequest> _rows = const [];
  String? _status = 'open';
  bool _loading = true;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _repo.marketRequests(
      status: _status,
      locale: context.locale.languageCode,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (res) {
        case Ok(:final value):
          _rows = value;
          _failure = null;
        case Fail(:final failure):
          _failure = failure;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return PermissionGuard(
      permission: AdminPermission.listingsRead,
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.x7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'admin.nav.requests'.tr(),
              subtitle: 'admin.requests.subtitle'.tr(),
            ),
            const SizedBox(height: AgSpace.x4),
            Wrap(
              spacing: AgSpace.x2,
              children: [
                for (final s in const [
                  'open',
                  'fulfilled',
                  'expired',
                  'cancelled',
                  null,
                ])
                  ChoiceChip(
                    label: Text('admin.request_status.${s ?? 'all'}'.tr()),
                    selected: _status == s,
                    onSelected: (_) {
                      setState(() {
                        _status = s;
                        _loading = true;
                      });
                      _load();
                    },
                  ),
              ],
            ),
            const SizedBox(height: AgSpace.x4),
            Expanded(child: _body(c)),
          ],
        ),
      ),
    );
  }

  Widget _body(AppColors c) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failure != null && _rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _failure!.messageKey.tr(),
              style: AppTypography.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AgSpace.x3),
            AdminButton(label: 'admin.common.retry'.tr(), onPressed: _load),
          ],
        ),
      );
    }
    if (_rows.isEmpty) {
      return Center(
        child: Text(
          'admin.requests.empty'.tr(),
          style: AppTypography.body.copyWith(color: c.textTertiary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: AgSpace.x3),
        itemBuilder: (context, i) =>
            _RequestCard(key: ValueKey(_rows[i].id), row: _rows[i]),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({super.key, required this.row});

  final MarketRequest row;

  String _amount(double quantity) =>
      '${Fmt.decimal(quantity)} ${'admin.unit.${row.unit}'.tr()}';

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(AgSpace.x5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AgRadius.rMd,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AgSpace.x2,
            runSpacing: AgSpace.x1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(
                label: 'admin.request_status.${row.status}'.tr(),
                tone: switch (row.status) {
                  'open' => BadgeTone.info,
                  'fulfilled' => BadgeTone.success,
                  _ => BadgeTone.neutral,
                },
              ),
              StatusBadge(label: 'admin.request_category.${row.category}'.tr()),
              Text(
                Fmt.dateTime(row.createdAt),
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AgSpace.x3),
          Text(
            row.title,
            style: AppTypography.body.copyWith(
              color: c.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AgSpace.x1),
          Text(
            [
              _amount(row.quantity),
              if (row.targetPrice != null)
                'admin.requests.target_price'.tr(
                  namedArgs: {'price': Fmt.count(row.targetPrice!)},
                ),
              ?row.regionName,
              if (row.neededBy != null)
                'admin.requests.needed_by'.tr(
                  namedArgs: {'date': Fmt.date(row.neededBy)},
                ),
            ].join(' · '),
            style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AgSpace.x1),
          SelectableText(
            [
              'admin.orders.buyer'.tr(),
              row.buyerName ?? '—',
              ?row.buyerPhone,
            ].join(' · '),
            style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
          ),
          if (row.note != null && row.note!.trim().isNotEmpty) ...[
            const SizedBox(height: AgSpace.x2),
            Text(
              '“${row.note}”',
              style: AppTypography.bodySmall.copyWith(color: c.text),
            ),
          ],
          const SizedBox(height: AgSpace.x3),
          Text(
            'admin.requests.offers'.tr(
              namedArgs: {'count': '${row.offers.length}'},
            ),
            style: AppTypography.caption.copyWith(
              color: c.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (final o in row.offers)
            Padding(
              padding: const EdgeInsets.only(top: AgSpace.x2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: StatusBadge(
                      label: 'admin.offer_status.${o.status}'.tr(),
                      tone: switch (o.status) {
                        'accepted' => BadgeTone.success,
                        'pending' => BadgeTone.warning,
                        _ => BadgeTone.neutral,
                      },
                    ),
                  ),
                  const SizedBox(width: AgSpace.x3),
                  Expanded(
                    child: SelectableText(
                      [
                        o.farmerName ?? '—',
                        ?o.farmerPhone,
                        '${Fmt.count(o.price)} × ${_amount(o.quantity)}',
                        if (o.note != null && o.note!.trim().isNotEmpty)
                          o.note!,
                      ].join(' · '),
                      style: AppTypography.bodySmall.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
