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
import '../../../data/models/admin_ai.dart' show ContentStatus;
import '../../../data/models/admin_staff.dart';
import '../../../data/repositories/admin_staff_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_table.dart';

/// Kontent (CMS) — TTZ §6.10.
///
/// Bu bosqichda FAQAT RO'YXAT VA NASHR HOLATI. To'liq muharrir (maqola
/// yozish, rasm yuklash, uch tilda tahrirlash) alohida ish: u boy matn
/// muharriri va `content-images` buketini talab qiladi, ikkalasi ham
/// hozircha yo'q. Ro'yxat esa mavjud kontentni boshqarish uchun yetarli.
class ContentPage extends StatefulWidget {
  const ContentPage({super.key});

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  final _repo = getIt<AdminStaffRepository>();

  List<ContentRow> _rows = const [];
  String? _kind;
  String? _status;
  bool _loading = true;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });

    final res = await _repo.content(
      kind: _kind,
      status: _status,
      locale: context.locale.languageCode,
    );
    if (!mounted) return;

    setState(() {
      _loading = false;
      switch (res) {
        case Ok(:final value):
          _rows = value;
        case Fail(:final failure):
          _failure = failure;
      }
    });
  }

  Future<void> _setStatus(ContentRow row, String status) async {
    final res = await _repo.setContentStatus(
      row.id,
      status,
      alreadyPublished: row.publishedAt != null,
    );
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
              title: 'admin.nav.content'.tr(),
              subtitle: 'admin.content.subtitle'.tr(),
            ),
            const SizedBox(height: AgSpace.x4),
            AdminNote(
              text: 'admin.content.editor_note'.tr(),
              icon: Icons.edit_note_outlined,
            ),
            const SizedBox(height: AgSpace.x4),

            Wrap(
              spacing: AgSpace.x3,
              runSpacing: AgSpace.x3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AdminSelect<String>(
                  value: _kind,
                  hintKey: 'admin.content.filter_kind',
                  width: 190,
                  items: [
                    for (final k in ContentKind.all)
                      (k, 'admin.content_kind.$k'.tr()),
                  ],
                  onChanged: (v) {
                    setState(() => _kind = v);
                    _load();
                  },
                ),
                AdminSelect<String>(
                  value: _status,
                  hintKey: 'admin.disease.filter_status',
                  width: 190,
                  items: [
                    for (final s in ContentStatus.all)
                      (s, 'admin.content_status.$s'.tr()),
                  ],
                  onChanged: (v) {
                    setState(() => _status = v);
                    _load();
                  },
                ),
              ],
            ),
            const SizedBox(height: AgSpace.x4),

            Expanded(
              child: AdminTable<ContentRow>(
                rows: _rows,
                loading: _loading,
                failure: _failure,
                onRetry: _load,
                emptyTitle: 'admin.content.empty'.tr(),
                emptyHint: 'admin.content.empty_hint'.tr(),
                columns: _columns(c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AdminColumn<ContentRow>> _columns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.content.col_title',
      flex: 3,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.titleUz,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            row.slug,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.content.col_kind',
      width: 140,
      build: (row) => StatusBadge(label: 'admin.content_kind.${row.kind}'.tr()),
    ),
    AdminColumn(
      labelKey: 'admin.content.col_translation',
      width: 140,
      build: (row) => StatusBadge(
        label: 'admin.translation.${row.translationState}'.tr(),
        tone: switch (row.translationState) {
          'complete' => BadgeTone.success,
          'partial' => BadgeTone.warning,
          _ => BadgeTone.danger,
        },
      ),
    ),
    AdminColumn(
      labelKey: 'admin.disease.col_status',
      width: 140,
      build: (row) => StatusBadge(
        label: 'admin.content_status.${row.status}'.tr(),
        tone: switch (row.status) {
          ContentStatus.published => BadgeTone.success,
          ContentStatus.review => BadgeTone.warning,
          _ => BadgeTone.neutral,
        },
      ),
    ),
    AdminColumn(
      labelKey: 'admin.content.col_published',
      width: 110,
      build: (row) => Text(
        Fmt.date(row.publishedAt),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.staff.col_actions',
      width: 200,
      build: (row) => PermissionGuard(
        permission: AdminPermission.contentWrite,
        fallback: const SizedBox.shrink(),
        child: Wrap(
          spacing: AgSpace.x1,
          children: [
            if (row.status != ContentStatus.published)
              AdminButton(
                label: 'admin.content.publish'.tr(),
                onPressed: () => _setStatus(row, ContentStatus.published),
              ),
            if (row.status == ContentStatus.published)
              AdminButton(
                label: 'admin.content.archive'.tr(),
                kind: AdminButtonKind.secondary,
                onPressed: () => _setStatus(row, ContentStatus.archived),
              ),
          ],
        ),
      ),
    ),
  ];
}
