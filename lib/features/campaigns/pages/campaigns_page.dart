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
import '../../../data/models/admin_user.dart';
import '../../../data/repositories/admin_ops_repository.dart';
import '../../../data/repositories/admin_user_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_field.dart';
import '../../../ui/admin_table.dart';

/// Bildirishnoma kampaniyalari (TTZ §6.9).
class CampaignsPage extends StatefulWidget {
  const CampaignsPage({super.key});

  @override
  State<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends State<CampaignsPage> {
  final _repo = getIt<AdminOpsRepository>();
  final _userRepo = getIt<AdminUserRepository>();

  List<Map<String, dynamic>> _rows = const [];
  List<RefItem> _regions = const [];
  bool _loading = true;
  bool _sending = false;
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

    final results = await Future.wait([
      _repo.campaigns(),
      _userRepo.regions(locale: context.locale.languageCode),
    ]);
    if (!mounted) return;

    final res = results[0] as Result<List<Map<String, dynamic>>>;
    setState(() {
      _loading = false;
      switch (res) {
        case Ok(:final value):
          _rows = value;
        case Fail(:final failure):
          _failure = failure;
      }
      _regions = (results[1] as Result<List<RefItem>>).valueOrNull ?? const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return PermissionGuard(
      permission: AdminPermission.notificationsSend,
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.x7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'admin.nav.notifications'.tr(),
              subtitle: 'admin.campaigns.subtitle'.tr(),
              actions: [
                AdminButton(
                  label: 'admin.campaigns.create'.tr(),
                  icon: Icons.add,
                  onPressed: _regions.isEmpty ? null : _create,
                ),
              ],
            ),
            const SizedBox(height: AgSpace.x4),

            // Bu izoh MUHIM: admin "push yubordim" deb o'ylab, telefonda
            // hech narsa chiqmasa sababini tushunmasdi.
            AdminNote(
              text: 'admin.campaigns.no_push_note'.tr(),
              icon: Icons.notifications_off_outlined,
            ),
            const SizedBox(height: AgSpace.x4),

            Expanded(
              child: AdminTable<Map<String, dynamic>>(
                rows: _rows,
                loading: _loading,
                failure: _failure,
                onRetry: _load,
                emptyTitle: 'admin.campaigns.empty'.tr(),
                columns: _columns(c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AdminColumn<Map<String, dynamic>>> _columns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.campaigns.col_title',
      flex: 3,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row['title'] as String? ?? '',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            row['body'] as String? ?? '',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.campaigns.col_status',
      width: 150,
      build: (row) {
        final status = row['status'] as String? ?? 'draft';
        return StatusBadge(
          label: 'admin.campaign_status.$status'.tr(),
          tone: switch (status) {
            'sent' => BadgeTone.success,
            'sending' => BadgeTone.info,
            'failed' => BadgeTone.danger,
            'cancelled' => BadgeTone.neutral,
            _ => BadgeTone.warning,
          },
        );
      },
    ),
    AdminColumn(
      labelKey: 'admin.campaigns.col_delivered',
      width: 140,
      align: Alignment.centerRight,
      build: (row) => Text(
        '${row['delivered_count'] ?? 0} / ${row['recipient_count'] ?? 0}',
        style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.campaigns.col_sent',
      width: 140,
      build: (row) => Text(
        row['sent_at'] == null
            ? '—'
            : Fmt.dateTime(DateTime.parse(row['sent_at'] as String)),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.staff.col_actions',
      width: 130,
      build: (row) {
        final status = row['status'] as String? ?? 'draft';
        // Yuborilgan kampaniyani qayta yuborib bo'lmaydi — Edge Function
        // ham `CAMPAIGN_ALREADY_SENT` bilan rad etadi.
        if (status != 'draft' && status != 'scheduled') {
          return const SizedBox.shrink();
        }
        return AdminButton(
          label: 'admin.campaigns.send'.tr(),
          busy: _sending,
          onPressed: _sending ? null : () => _send(row),
        );
      },
    ),
  ];

  Future<void> _send(Map<String, dynamic> row) async {
    final audience = Map<String, dynamic>.from(
      (row['audience'] as Map?) ?? const {},
    );

    // Yuborishdan OLDIN qancha odamga ketishini ko'rsatamiz — 12 ming
    // kishiga tasodifan yuborib qo'yishning oldini oladi (TTZ §6.9).
    final countRes = await _repo.audienceCount(audience);
    if (!mounted) return;

    final count = countRes.valueOrNull;
    if (count == null) {
      _snack(countRes.failureOrNull!);
      return;
    }

    final result = await showReasonDialog(
      context,
      title: 'admin.campaigns.send'.tr(),
      message: 'admin.campaigns.send_confirm'.tr(
        args: ['$count', row['title'] as String? ?? ''],
      ),
      confirmLabel: 'admin.campaigns.send'.tr(),
      reasonRequired: false,
      danger: false,
    );
    if (!result.confirmed) return;

    setState(() => _sending = true);
    final res = await _repo.sendCampaign(row['id'] as String);
    if (!mounted) return;
    setState(() => _sending = false);

    if (res case Fail(:final failure)) {
      _snack(failure, isExportHint: true);
      return;
    }
    await _load();
  }

  Future<void> _create() async {
    final draft = await showDialog<_CampaignDraft>(
      context: context,
      builder: (context) => _CreateDialog(regions: _regions, repo: _repo),
    );
    if (draft == null) return;

    final res = await _repo.createCampaign(
      title: draft.title,
      body: draft.body,
      type: draft.type,
      audience: draft.audience,
    );
    if (!mounted) return;

    if (res case Fail(:final failure)) {
      _snack(failure);
      return;
    }
    await _load();
  }

  void _snack(AppFailure failure, {bool isExportHint = false}) {
    final c = Theme.of(context).extension<AppColors>()!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: c.errorBg,
        duration: Duration(seconds: isExportHint ? 6 : 4),
        content: Text(
          isExportHint
              ? 'admin.campaigns.send_failed'.tr(
                  args: [failure.messageKey.tr()],
                )
              : failure.messageKey.tr(),
          style: AppTypography.bodySmall.copyWith(color: c.errorText),
        ),
      ),
    );
  }
}

class _CampaignDraft {
  const _CampaignDraft({
    required this.title,
    required this.body,
    required this.type,
    required this.audience,
  });

  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> audience;
}

class _CreateDialog extends StatefulWidget {
  const _CreateDialog({required this.regions, required this.repo});

  final List<RefItem> regions;
  final AdminOpsRepository repo;

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _title = TextEditingController();
  final _body = TextEditingController();

  String _type = 'informational';
  int? _regionId;
  String? _activity;

  int? _count;
  bool _counting = false;
  String? _titleError;
  String? _bodyError;

  @override
  void initState() {
    super.initState();
    _recount();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _audience => {
    if (_regionId != null) 'region_ids': [_regionId],
    if (_activity != null) 'activity': _activity,
  };

  Future<void> _recount() async {
    setState(() => _counting = true);
    final res = await widget.repo.audienceCount(_audience);
    if (!mounted) return;
    setState(() {
      _counting = false;
      _count = res.valueOrNull;
    });
  }

  void _submit() {
    setState(() {
      // `notifications` da ikkalasiga ham 150 belgi cheklovi bor (0001) —
      // kampaniya yaratilib, yoyish paytida check constraint bilan
      // qulamasligi uchun bu yerda ham tekshiriladi.
      final title = _title.text.trim();
      final body = _body.text.trim();
      _titleError = title.isEmpty || title.length > 150
          ? 'admin.errors.invalid_value'.tr()
          : null;
      _bodyError = body.isEmpty || body.length > 150
          ? 'admin.errors.invalid_value'.tr()
          : null;
    });
    if (_titleError != null || _bodyError != null) return;

    Navigator.of(context).pop(
      _CampaignDraft(
        title: _title.text.trim(),
        body: _body.text.trim(),
        type: _type,
        audience: _audience,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: AgRadius.rLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AgSpace.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'admin.campaigns.create'.tr(),
                style: AppTypography.h3.copyWith(color: c.text),
              ),
              const SizedBox(height: AgSpace.x5),

              AdminField(
                controller: _title,
                label: 'admin.campaigns.col_title'.tr(),
                errorText: _titleError,
                maxLength: 150,
                autofocus: true,
              ),
              AdminField(
                controller: _body,
                label: 'admin.campaigns.body'.tr(),
                errorText: _bodyError,
                maxLength: 150,
              ),

              const SizedBox(height: AgSpace.x2),
              Text(
                'admin.campaigns.audience'.tr(),
                style: AppTypography.label.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AgSpace.x2),
              Row(
                children: [
                  Expanded(
                    child: AdminSelect<int>(
                      value: _regionId,
                      hintKey: 'admin.users.filter_region',
                      width: double.infinity,
                      items: [for (final r in widget.regions) (r.id, r.name)],
                      onChanged: (v) {
                        setState(() => _regionId = v);
                        _recount();
                      },
                    ),
                  ),
                  const SizedBox(width: AgSpace.x3),
                  Expanded(
                    child: AdminSelect<String>(
                      value: _activity,
                      hintKey: 'admin.users.filter_activity',
                      width: double.infinity,
                      items: [
                        for (final a in const [
                          'farm_owner',
                          'agronomist',
                          'entrepreneur',
                          'other',
                        ])
                          (a, 'admin.activity.$a'.tr()),
                      ],
                      onChanged: (v) {
                        setState(() => _activity = v);
                        _recount();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AgSpace.x3),
              AdminSelect<String>(
                value: _type,
                hintKey: 'admin.weather.col_severity',
                width: double.infinity,
                items: [
                  for (final t in const [
                    'informational',
                    'important',
                    'critical',
                  ])
                    (t, 'admin.notification_type.$t'.tr()),
                ],
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),

              const SizedBox(height: AgSpace.x4),
              Container(
                padding: const EdgeInsets.all(AgSpace.x3),
                decoration: BoxDecoration(
                  color: c.surfaceBrand,
                  borderRadius: AgRadius.rSm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_outline, size: 15, color: c.textBrand),
                    const SizedBox(width: AgSpace.x2),
                    Text(
                      _counting
                          ? '…'
                          : 'admin.campaigns.recipients'.tr(
                              args: ['${_count ?? 0}'],
                            ),
                      style: AppTypography.bodySmall.copyWith(
                        color: c.textBrand,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AgSpace.x5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminButton(
                    label: 'admin.common.cancel'.tr(),
                    kind: AdminButtonKind.ghost,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AgSpace.x2),
                  AdminButton(
                    label: 'admin.common.confirm'.tr(),
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
