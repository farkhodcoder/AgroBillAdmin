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
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_table.dart';

/// Hisobni o'chirish so'rovlari.
///
/// Foydalanuvchi ilovada hisobini o'chirishni so'raydi; o'chirish kechiktirib
/// bajariladi (shu muddatda u fikridan qaytishi mumkin). Admin bu yerda
/// HECH NARSA O'ZGARTIRMAYDI — kim ketayotganini va qachon o'chishini ko'radi.
class DeletionRequestsPage extends StatefulWidget {
  const DeletionRequestsPage({super.key});

  @override
  State<DeletionRequestsPage> createState() => _DeletionRequestsPageState();
}

class _DeletionRequestsPageState extends State<DeletionRequestsPage> {
  final _repo = getIt<AdminRequestRepository>();

  List<DeletionRequest> _rows = const [];
  String? _status = 'pending';
  bool _loading = true;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _repo.deletionRequests(status: _status);
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
    final now = DateTime.now();

    return PermissionGuard(
      permission: AdminPermission.usersRead,
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.x7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'admin.nav.deletions'.tr(),
              subtitle: 'admin.deletions.subtitle'.tr(),
            ),
            const SizedBox(height: AgSpace.x4),
            AdminNote(
              text: 'admin.deletions.note'.tr(),
              icon: Icons.person_remove_outlined,
            ),
            const SizedBox(height: AgSpace.x4),
            Wrap(
              spacing: AgSpace.x2,
              children: [
                for (final s in const [
                  'pending',
                  'completed',
                  'cancelled',
                  null,
                ])
                  ChoiceChip(
                    label: Text('admin.deletion_status.${s ?? 'all'}'.tr()),
                    selected: _status == s,
                    onSelected: (_) {
                      _status = s;
                      _load();
                    },
                  ),
              ],
            ),
            const SizedBox(height: AgSpace.x4),
            Expanded(
              child: AdminTable<DeletionRequest>(
                rows: _rows,
                loading: _loading,
                failure: _failure,
                onRetry: _load,
                emptyTitle: 'admin.deletions.empty'.tr(),
                columns: [
                  AdminColumn(
                    labelKey: 'admin.deletions.col_user',
                    flex: 3,
                    build: (r) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.fullName ?? '—',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: c.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SelectableText(
                          r.userId,
                          maxLines: 1,
                          style: AppTypography.caption.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AdminColumn(
                    labelKey: 'admin.deletions.col_contact',
                    flex: 2,
                    build: (r) => SelectableText(
                      r.contact ?? '—',
                      maxLines: 1,
                      style: AppTypography.bodySmall.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  AdminColumn(
                    labelKey: 'admin.deletions.col_requested',
                    flex: 2,
                    build: (r) => Text(
                      Fmt.dateTime(r.requestedAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  AdminColumn(
                    labelKey: 'admin.deletions.col_scheduled',
                    flex: 2,
                    build: (r) => Text(
                      r.isPending
                          ? 'admin.deletions.days_left'.tr(
                              namedArgs: {
                                'date': Fmt.date(r.scheduledAt),
                                'days': '${r.daysLeft(now)}',
                              },
                            )
                          : Fmt.date(r.scheduledAt),
                      style: AppTypography.bodySmall.copyWith(
                        color: r.isPending && r.daysLeft(now) <= 3
                            ? c.warningText
                            : c.textSecondary,
                      ),
                    ),
                  ),
                  AdminColumn(
                    labelKey: 'admin.deletions.col_status',
                    width: 140,
                    build: (r) => StatusBadge(
                      label: 'admin.deletion_status.${r.status}'.tr(),
                      tone: switch (r.status) {
                        'completed' => BadgeTone.danger,
                        'cancelled' => BadgeTone.neutral,
                        _ => BadgeTone.warning,
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
