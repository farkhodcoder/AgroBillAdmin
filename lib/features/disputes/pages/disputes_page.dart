import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../data/repositories/admin_dispute_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';

/// Buyurtma nizolari navbati (mobil 0058).
///
/// Xaridor yoki sotuvchi ilovada nizo ochadi: sabab, tafsilot va 5 tagacha
/// surat. Admin ikkala tomon bilan bog'lanib qaror yozadi — qaror matni
/// ikkala tomonga bildirishnoma bo'lib boradi va auditga tushadi.
class DisputesPage extends StatefulWidget {
  const DisputesPage({super.key});

  @override
  State<DisputesPage> createState() => _DisputesPageState();
}

class _DisputesPageState extends State<DisputesPage> {
  final _repo = getIt<AdminDisputeRepository>();

  List<DisputeRow> _rows = const [];
  String? _status = 'open';
  bool _loading = true;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _repo.list(status: _status);
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

  void _showError(AppFailure failure) {
    final c = Theme.of(context).extension<AppColors>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: c.errorBg,
        content: Text(
          failure.messageKey.tr(),
          style: AppTypography.bodySmall.copyWith(color: c.errorText),
        ),
      ),
    );
  }

  Future<void> _resolve(DisputeRow row) async {
    final ok = await showReasonDialog(
      context,
      title: 'admin.disputes.resolve_title'.tr(),
      message: 'admin.disputes.resolve_message'.tr(),
      confirmLabel: 'admin.disputes.resolve'.tr(),
      danger: false,
    );
    if (!ok.confirmed || !mounted) return;

    final res = await _repo.resolve(row.id, ok.reason!);
    if (!mounted) return;
    if (res case Fail(:final failure)) return _showError(failure);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return PermissionGuard(
      permission: AdminPermission.ordersRead,
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.x7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'admin.nav.disputes'.tr(),
              subtitle: 'admin.disputes.subtitle'.tr(),
            ),
            const SizedBox(height: AgSpace.x4),
            AdminNote(
              text: 'admin.disputes.note'.tr(),
              icon: Icons.gavel_outlined,
            ),
            const SizedBox(height: AgSpace.x4),
            Wrap(
              spacing: AgSpace.x2,
              children: [
                for (final s in const ['open', 'resolved', 'closed', null])
                  ChoiceChip(
                    label: Text('admin.dispute_status.${s ?? 'all'}'.tr()),
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
          'admin.disputes.empty'.tr(),
          style: AppTypography.body.copyWith(color: c.textTertiary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: AgSpace.x3),
        itemBuilder: (context, i) => _DisputeCard(
          key: ValueKey(_rows[i].id),
          row: _rows[i],
          repo: _repo,
          onResolve: () => _resolve(_rows[i]),
        ),
      ),
    );
  }
}

class _DisputeCard extends StatefulWidget {
  const _DisputeCard({
    super.key,
    required this.row,
    required this.repo,
    required this.onResolve,
  });

  final DisputeRow row;
  final AdminDisputeRepository repo;
  final VoidCallback onResolve;

  @override
  State<_DisputeCard> createState() => _DisputeCardState();
}

class _DisputeCardState extends State<_DisputeCard> {
  List<String>? _urls;

  @override
  void initState() {
    super.initState();
    _loadUrls();
  }

  Future<void> _loadUrls() async {
    final res = await widget.repo.photoUrls(widget.row.photos);
    if (!mounted) return;
    setState(() => _urls = res is Ok<List<String>> ? res.value : const []);
  }

  void _openImage(String url) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: InteractiveViewer(
        maxScale: 5,
        child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
      ),
    ),
  );

  /// «Ism · telefon» — telefon bo'lmasa faqat ism.
  String _party(String? name, String? phone) =>
      [name ?? '—', ?phone].join(' · ');

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final row = widget.row;

    return Container(
      padding: const EdgeInsets.all(AgSpace.x5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AgRadius.rMd,
        border: Border.all(color: row.isOpen ? c.warningText : c.border),
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
                label: 'admin.dispute_status.${row.status}'.tr(),
                tone: switch (row.status) {
                  'resolved' => BadgeTone.success,
                  'closed' => BadgeTone.neutral,
                  _ => BadgeTone.warning,
                },
              ),
              StatusBadge(label: 'admin.dispute_reason.${row.reason}'.tr()),
              Text(
                Fmt.dateTime(row.createdAt),
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
              if (row.isOpen)
                Text(
                  Fmt.ago(row.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: c.warningText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AgSpace.x3),
          Text(
            row.listingTitle ?? '—',
            style: AppTypography.body.copyWith(
              color: c.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AgSpace.x1),
          SelectableText(
            [
              'admin.disputes.order'.tr(namedArgs: {'id': row.orderShortId}),
              if (row.orderStatus != null)
                'admin.order_status.${row.orderStatus}'.tr(),
              if (row.totalPrice != null) Fmt.sum(row.totalPrice!),
            ].join(' · '),
            style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AgSpace.x3),
          _line(
            c,
            'admin.disputes.opened_by'.tr(),
            _party(
              row.openerName.isEmpty ? null : row.openerName,
              row.openerContact,
            ),
          ),
          _line(
            c,
            'admin.orders.buyer'.tr(),
            _party(row.buyerName, row.buyerPhone),
          ),
          _line(
            c,
            'admin.orders.seller'.tr(),
            _party(row.sellerName, row.sellerPhone),
          ),
          const SizedBox(height: AgSpace.x3),
          SelectableText(
            row.details,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          if (row.photos.isNotEmpty) ...[
            const SizedBox(height: AgSpace.x3),
            _photos(c),
          ],
          if (row.resolution != null) ...[
            const SizedBox(height: AgSpace.x3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AgSpace.x3),
              decoration: BoxDecoration(
                color: c.surfaceSunken,
                borderRadius: AgRadius.rMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      'admin.disputes.resolution'.tr(),
                      ?row.resolverName,
                      if (row.resolvedAt != null) Fmt.dateTime(row.resolvedAt),
                    ].join(' · '),
                    style: AppTypography.caption.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AgSpace.x1),
                  SelectableText(
                    row.resolution!,
                    style: AppTypography.bodySmall.copyWith(color: c.text),
                  ),
                ],
              ),
            ),
          ],
          if (row.isOpen)
            PermissionGuard(
              permission: AdminPermission.ordersWrite,
              fallback: const SizedBox.shrink(),
              child: Padding(
                padding: const EdgeInsets.only(top: AgSpace.x4),
                child: AdminButton(
                  label: 'admin.disputes.resolve'.tr(),
                  onPressed: widget.onResolve,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(AppColors c, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AgSpace.x1),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
          ),
        ),
      ],
    ),
  );

  Widget _photos(AppColors c) {
    final urls = _urls;
    if (urls == null) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: c.skeletonBase,
          borderRadius: AgRadius.rMd,
        ),
      );
    }
    if (urls.isEmpty) {
      return Text(
        'admin.disputes.no_photos'.tr(),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: AgSpace.x2),
        itemBuilder: (context, i) => Tooltip(
          message: 'admin.disputes.zoom'.tr(),
          child: InkWell(
            borderRadius: AgRadius.rMd,
            onTap: () => _openImage(urls[i]),
            child: ClipRRect(
              borderRadius: AgRadius.rMd,
              child: CachedNetworkImage(
                imageUrl: urls[i],
                width: 220,
                height: 160,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: c.skeletonBase),
                errorWidget: (_, _, _) => Container(
                  width: 220,
                  color: c.surfaceSunken,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: c.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
