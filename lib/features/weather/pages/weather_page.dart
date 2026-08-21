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

/// Ob-havo ogohlantirishlari (TTZ §6.8).
class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _repo = getIt<AdminOpsRepository>();
  final _userRepo = getIt<AdminUserRepository>();

  List<WeatherAlert> _alerts = const [];
  List<RefItem> _regions = const [];
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

    final locale = context.locale.languageCode;
    final results = await Future.wait([
      _repo.alerts(locale: locale),
      _userRepo.regions(locale: locale),
    ]);
    if (!mounted) return;

    final alertsRes = results[0] as Result<List<WeatherAlert>>;
    setState(() {
      _loading = false;
      switch (alertsRes) {
        case Ok(:final value):
          _alerts = value;
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
      permission: AdminPermission.contentRead,
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.x7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'admin.nav.weather'.tr(),
              subtitle: 'admin.weather.subtitle'.tr(),
              actions: [
                PermissionGuard(
                  permission: AdminPermission.contentWrite,
                  fallback: const SizedBox.shrink(),
                  child: AdminButton(
                    label: 'admin.weather.create'.tr(),
                    icon: Icons.add,
                    onPressed: _regions.isEmpty ? null : _create,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AgSpace.x4),
            AdminNote(
              text: 'admin.weather.scope_note'.tr(),
              icon: Icons.public_outlined,
            ),
            const SizedBox(height: AgSpace.x4),

            Expanded(
              child: AdminTable<WeatherAlert>(
                rows: _alerts,
                loading: _loading,
                failure: _failure,
                onRetry: _load,
                emptyTitle: 'admin.weather.empty'.tr(),
                columns: _columns(c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<AdminColumn<WeatherAlert>> _columns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.weather.col_title',
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
            row.message,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.weather.col_scope',
      width: 200,
      build: (row) => StatusBadge(
        label: row.isRegional
            ? (row.regionName ?? 'admin.weather.region'.tr())
            : 'admin.weather.farm_level'.tr(),
        tone: row.isRegional ? BadgeTone.brand : BadgeTone.neutral,
      ),
    ),
    AdminColumn(
      labelKey: 'admin.weather.col_severity',
      width: 160,
      build: (row) => Wrap(
        spacing: AgSpace.x1,
        children: [
          StatusBadge(
            label: 'admin.notification_type.${row.severity}'.tr(),
            tone: switch (row.severity) {
              'critical' => BadgeTone.danger,
              'important' => BadgeTone.warning,
              _ => BadgeTone.info,
            },
          ),
          if (row.isExpired)
            StatusBadge(
              label: 'admin.weather.expired'.tr(),
              tone: BadgeTone.neutral,
            ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.weather.col_expires',
      width: 110,
      build: (row) => Text(
        Fmt.date(row.expiresAt),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.staff.col_actions',
      width: 120,
      build: (row) => PermissionGuard(
        permission: AdminPermission.contentWrite,
        fallback: const SizedBox.shrink(),
        // Xo'jalik darajasidagi ogohlantirishlarni admin o'chirmaydi —
        // ular mobil ilova tomonidan yaratilgan va fermerning ishi.
        child: row.isRegional
            ? AdminButton(
                label: 'admin.market.delete'.tr(),
                kind: AdminButtonKind.ghost,
                onPressed: () => _delete(row),
              )
            : const SizedBox.shrink(),
      ),
    ),
  ];

  Future<void> _delete(WeatherAlert alert) async {
    final result = await showReasonDialog(
      context,
      title: 'admin.market.delete'.tr(),
      message: 'admin.weather.delete_confirm'.tr(args: [alert.title]),
      confirmLabel: 'admin.market.delete'.tr(),
      reasonRequired: false,
    );
    if (!result.confirmed) return;

    final res = await _repo.deleteAlert(alert.id);
    if (!mounted) return;

    if (res case Fail(:final failure)) {
      _snack(failure);
      return;
    }
    await _load();
  }

  Future<void> _create() async {
    final draft = await showDialog<_AlertDraft>(
      context: context,
      builder: (context) => _CreateDialog(regions: _regions),
    );
    if (draft == null) return;

    final res = await _repo.createAlert(
      regionId: draft.regionId,
      alertType: draft.alertType,
      severity: draft.severity,
      title: draft.title,
      message: draft.message,
      expiresAt: draft.expiresAt,
    );
    if (!mounted) return;

    if (res case Fail(:final failure)) {
      _snack(failure);
      return;
    }
    await _load();
  }

  void _snack(AppFailure failure) {
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
}

class _AlertDraft {
  const _AlertDraft({
    required this.regionId,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    this.expiresAt,
  });

  final int regionId;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final DateTime? expiresAt;
}

class _CreateDialog extends StatefulWidget {
  const _CreateDialog({required this.regions});

  final List<RefItem> regions;

  @override
  State<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<_CreateDialog> {
  final _title = TextEditingController();
  final _message = TextEditingController();

  int? _regionId;
  String _alertType = 'frost';
  String _severity = 'important';
  int _days = 3;

  String? _titleError;
  String? _messageError;
  String? _regionError;

  static const _types = ['frost', 'heat', 'rain', 'wind', 'hail', 'drought'];

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _regionError = _regionId == null
          ? 'admin.errors.invalid_value'.tr()
          : null;
      _titleError = _title.text.trim().isEmpty
          ? 'admin.errors.invalid_value'.tr()
          : null;
      _messageError = _message.text.trim().isEmpty
          ? 'admin.errors.invalid_value'.tr()
          : null;
    });
    if (_regionError != null || _titleError != null || _messageError != null) {
      return;
    }

    Navigator.of(context).pop(
      _AlertDraft(
        regionId: _regionId!,
        alertType: _alertType,
        severity: _severity,
        title: _title.text.trim(),
        message: _message.text.trim(),
        expiresAt: DateTime.now().add(Duration(days: _days)),
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
                'admin.weather.create'.tr(),
                style: AppTypography.h3.copyWith(color: c.text),
              ),
              const SizedBox(height: AgSpace.x5),

              AdminSelect<int>(
                value: _regionId,
                hintKey: 'admin.users.filter_region',
                width: double.infinity,
                items: [for (final r in widget.regions) (r.id, r.name)],
                onChanged: (v) => setState(() => _regionId = v),
              ),
              if (_regionError != null)
                Padding(
                  padding: const EdgeInsets.only(top: AgSpace.x1),
                  child: Text(
                    _regionError!,
                    style: AppTypography.caption.copyWith(color: c.errorText),
                  ),
                ),
              const SizedBox(height: AgSpace.x3),

              Row(
                children: [
                  Expanded(
                    child: AdminSelect<String>(
                      value: _alertType,
                      hintKey: 'admin.weather.col_type',
                      width: double.infinity,
                      items: [
                        for (final t in _types) (t, 'admin.alert_type.$t'.tr()),
                      ],
                      onChanged: (v) =>
                          setState(() => _alertType = v ?? _alertType),
                    ),
                  ),
                  const SizedBox(width: AgSpace.x3),
                  Expanded(
                    child: AdminSelect<String>(
                      value: _severity,
                      hintKey: 'admin.weather.col_severity',
                      width: double.infinity,
                      items: [
                        for (final s in const [
                          'informational',
                          'important',
                          'critical',
                        ])
                          (s, 'admin.notification_type.$s'.tr()),
                      ],
                      onChanged: (v) =>
                          setState(() => _severity = v ?? _severity),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AgSpace.x3),

              AdminField(
                controller: _title,
                label: 'admin.weather.col_title'.tr(),
                errorText: _titleError,
                maxLength: 150,
              ),
              AdminField(
                controller: _message,
                label: 'admin.weather.message'.tr(),
                errorText: _messageError,
                maxLength: 300,
              ),

              const SizedBox(height: AgSpace.x2),
              Text(
                'admin.weather.expires_in'.tr(),
                style: AppTypography.label.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AgSpace.x2),
              Wrap(
                spacing: AgSpace.x2,
                children: [
                  for (final d in [1, 3, 7])
                    AdminButton(
                      label: 'admin.dashboard.days'.tr(args: ['$d']),
                      kind: _days == d
                          ? AdminButtonKind.primary
                          : AdminButtonKind.secondary,
                      onPressed: () => setState(() => _days = d),
                    ),
                ],
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
