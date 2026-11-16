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
import '../../../data/repositories/admin_verification_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';

/// Profilni tasdiqlash navbati (mobil 0051).
///
/// Foydalanuvchi hujjat suratini yuboradi. Admin hujjatni ko'rib
/// tasdiqlaydi — bozorda "Tasdiqlangan" belgisi chiqadi — yoki sabab bilan
/// rad etadi; sabab foydalanuvchiga push bilan boradi.
class VerificationReviewPage extends StatefulWidget {
  const VerificationReviewPage({super.key});

  @override
  State<VerificationReviewPage> createState() => _VerificationReviewPageState();
}

class _VerificationReviewPageState extends State<VerificationReviewPage> {
  final _repo = getIt<AdminVerificationRepository>();

  List<VerificationRow> _rows = const [];
  String? _status = 'pending';
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

  Future<void> _approve(VerificationRow row) async {
    final ok = await showReasonDialog(
      context,
      title: 'admin.verification.approve_title'.tr(),
      message: 'admin.verification.approve_message'.tr(
        namedArgs: {'name': row.fullName},
      ),
      confirmLabel: 'admin.verification.approve'.tr(),
      reasonRequired: false,
      danger: false,
    );
    if (!ok.confirmed || !mounted) return;

    final res = await _repo.review(row.id, approve: true, reason: ok.reason);
    if (!mounted) return;
    if (res case Fail(:final failure)) return _showError(failure);
    await _load();
  }

  Future<void> _reject(VerificationRow row) async {
    final ok = await showReasonDialog(
      context,
      title: 'admin.verification.reject_title'.tr(),
      message: 'admin.verification.reject_message'.tr(),
      confirmLabel: 'admin.verification.reject'.tr(),
    );
    if (!ok.confirmed || !mounted) return;

    final res = await _repo.review(row.id, approve: false, reason: ok.reason);
    if (!mounted) return;
    if (res case Fail(:final failure)) return _showError(failure);
    await _load();
  }

  Future<void> _revoke(VerificationRow row) async {
    final ok = await showReasonDialog(
      context,
      title: 'admin.verification.revoke_title'.tr(),
      message: 'admin.verification.revoke_message'.tr(
        namedArgs: {'name': row.fullName},
      ),
      confirmLabel: 'admin.verification.revoke'.tr(),
    );
    if (!ok.confirmed || !mounted) return;

    final res = await _repo.revoke(row.userId, ok.reason!);
    if (!mounted) return;
    if (res case Fail(:final failure)) return _showError(failure);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return PermissionGuard(
      permission: AdminPermission.usersRead,
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.x7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'admin.nav.verification'.tr(),
              subtitle: 'admin.verification.subtitle'.tr(),
            ),
            const SizedBox(height: AgSpace.x4),
            AdminNote(
              text: 'admin.verification.note'.tr(),
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: AgSpace.x4),
            Wrap(
              spacing: AgSpace.x2,
              children: [
                for (final s in const ['pending', 'approved', 'rejected', null])
                  ChoiceChip(
                    label: Text('admin.verification_status.${s ?? 'all'}'.tr()),
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
          'admin.verification.empty'.tr(),
          style: AppTypography.body.copyWith(color: c.textTertiary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: AgSpace.x3),
        itemBuilder: (context, i) => _RequestCard(
          key: ValueKey(_rows[i].id),
          row: _rows[i],
          repo: _repo,
          onApprove: () => _approve(_rows[i]),
          onReject: () => _reject(_rows[i]),
          onRevoke: () => _revoke(_rows[i]),
        ),
      ),
    );
  }
}

class _RequestCard extends StatefulWidget {
  const _RequestCard({
    super.key,
    required this.row,
    required this.repo,
    required this.onApprove,
    required this.onReject,
    required this.onRevoke,
  });

  final VerificationRow row;
  final AdminVerificationRepository repo;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRevoke;

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  List<String>? _urls;

  @override
  void initState() {
    super.initState();
    _loadUrls();
  }

  Future<void> _loadUrls() async {
    final res = await widget.repo.docUrls(widget.row.docPaths);
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

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final row = widget.row;

    final role = row.accountType == 'buyer'
        ? [
            'admin.verification.role_buyer'.tr(),
            if (row.buyerKind != null)
              'admin.verification.buyer_kind.${row.buyerKind}'.tr(),
          ].join(' · ')
        : 'admin.verification.role_farmer'.tr();

    return Container(
      padding: const EdgeInsets.all(AgSpace.x5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AgRadius.rMd,
        border: Border.all(color: row.isPending ? c.warningText : c.border),
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
                label: 'admin.verification_status.${row.status}'.tr(),
                tone: switch (row.status) {
                  'approved' => BadgeTone.success,
                  'rejected' => BadgeTone.danger,
                  _ => BadgeTone.warning,
                },
              ),
              StatusBadge(label: 'admin.verification.doc.${row.docType}'.tr()),
              Text(
                Fmt.dateTime(row.createdAt),
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AgSpace.x3),
          Text(
            row.fullName.isEmpty ? '—' : row.fullName,
            style: AppTypography.body.copyWith(
              color: c.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AgSpace.x1),
          Text(
            [
              role,
              if (row.contact != null) row.contact!,
              if (row.joinedAt != null)
                'admin.verification.joined'.tr(
                  namedArgs: {'date': Fmt.date(row.joinedAt)},
                ),
              if (row.ratingCount > 0)
                '★ ${Fmt.decimal(row.rating)} (${row.ratingCount})',
            ].join(' · '),
            style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
          ),
          if (row.note != null) ...[
            const SizedBox(height: AgSpace.x2),
            Text(
              '“${row.note}”',
              style: AppTypography.bodySmall.copyWith(color: c.text),
            ),
          ],
          if (row.rejectReason != null) ...[
            const SizedBox(height: AgSpace.x2),
            Text(
              'admin.verification.reject_reason'.tr(
                namedArgs: {'reason': row.rejectReason!},
              ),
              style: AppTypography.bodySmall.copyWith(color: c.errorText),
            ),
          ],
          const SizedBox(height: AgSpace.x3),
          _docs(c),
          PermissionGuard(
            permission: AdminPermission.usersWrite,
            fallback: const SizedBox.shrink(),
            child: Padding(
              padding: const EdgeInsets.only(top: AgSpace.x4),
              child: Wrap(
                spacing: AgSpace.x2,
                children: [
                  if (row.isPending) ...[
                    AdminButton(
                      label: 'admin.verification.approve'.tr(),
                      onPressed: widget.onApprove,
                    ),
                    AdminButton(
                      label: 'admin.verification.reject'.tr(),
                      kind: AdminButtonKind.danger,
                      onPressed: widget.onReject,
                    ),
                  ] else if (row.status == 'approved' && row.isVerified)
                    AdminButton(
                      label: 'admin.verification.revoke'.tr(),
                      kind: AdminButtonKind.danger,
                      onPressed: widget.onRevoke,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docs(AppColors c) {
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
        'admin.verification.no_docs'.tr(),
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
          message: 'admin.verification.zoom'.tr(),
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
