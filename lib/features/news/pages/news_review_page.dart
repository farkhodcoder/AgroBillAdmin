import 'dart:async';

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
import '../../../data/repositories/admin_news_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';

/// AI yangiliklar navbati.
///
/// Server kuniga 3 marta (08:00, 13:00, 19:00) yangilik tayyorlaydi. Har biri
/// 30 daqiqa shu yerda kutadi: admin tasdiqlasa darhol, rad etsa hech qachon,
/// hech kim qaramasa — muddat tugagach avtomatik e'lon qilinadi.
class NewsReviewPage extends StatefulWidget {
  const NewsReviewPage({super.key});

  @override
  State<NewsReviewPage> createState() => _NewsReviewPageState();
}

class _NewsReviewPageState extends State<NewsReviewPage> {
  final _repo = getIt<AdminNewsRepository>();

  List<NewsRow> _rows = const [];
  String? _status = 'pending';
  bool _loading = true;
  AppFailure? _failure;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    // Qolgan vaqt sanog'i va yangi partiya o'zi yangilansin.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
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

  Future<void> _review(NewsRow row, bool approve) async {
    final res = await _repo.review(row.id, approve: approve);
    if (!mounted) return;
    if (res case Fail(:final failure)) {
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
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return PermissionGuard(
      permission: AdminPermission.contentRead,
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.x7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'admin.nav.news'.tr(),
              subtitle: 'admin.news.subtitle'.tr(),
            ),
            const SizedBox(height: AgSpace.x4),
            AdminNote(
              text: 'admin.news.note'.tr(),
              icon: Icons.auto_awesome_outlined,
            ),
            const SizedBox(height: AgSpace.x4),
            Wrap(
              spacing: AgSpace.x2,
              children: [
                for (final s in const [
                  null,
                  'pending',
                  'published',
                  'rejected',
                ])
                  ChoiceChip(
                    label: Text('admin.news_status.${s ?? 'all'}'.tr()),
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
          'admin.news.empty'.tr(),
          style: AppTypography.body.copyWith(color: c.textTertiary),
        ),
      );
    }

    return ListView.separated(
      itemCount: _rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: AgSpace.x3),
      itemBuilder: (context, i) => _NewsCard(
        row: _rows[i],
        onApprove: () => _review(_rows[i], true),
        onReject: () => _review(_rows[i], false),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.row,
    required this.onApprove,
    required this.onReject,
  });

  final NewsRow row;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

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
                label: 'admin.news_status.${row.status}'.tr(),
                tone: switch (row.status) {
                  'published' => BadgeTone.success,
                  'rejected' => BadgeTone.danger,
                  _ => BadgeTone.warning,
                },
              ),
              StatusBadge(label: row.source),
              if (row.topic != null) StatusBadge(label: row.topic!),
              Text(
                Fmt.dateTime(row.createdAt),
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
              if (row.isPending)
                Text(
                  'admin.news.auto_in'.tr(
                    namedArgs: {'min': '${row.remaining.inMinutes}'},
                  ),
                  style: AppTypography.caption.copyWith(
                    color: c.warningText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AgSpace.x3),
          Text(
            row.titleUz,
            style: AppTypography.body.copyWith(
              color: c.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AgSpace.x2),
          Text(
            row.bodyUz,
            style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AgSpace.x2),
          Text(
            row.titleCyrl,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
          const SizedBox(height: AgSpace.x2),
          SelectableText(
            row.sourceUrl,
            style: AppTypography.caption.copyWith(color: c.textBrand),
          ),
          if (row.isPending) ...[
            const SizedBox(height: AgSpace.x4),
            PermissionGuard(
              permission: AdminPermission.contentWrite,
              fallback: const SizedBox.shrink(),
              child: Wrap(
                spacing: AgSpace.x2,
                children: [
                  AdminButton(
                    label: 'admin.news.approve'.tr(),
                    onPressed: onApprove,
                  ),
                  AdminButton(
                    label: 'admin.news.reject'.tr(),
                    kind: AdminButtonKind.danger,
                    onPressed: onReject,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
