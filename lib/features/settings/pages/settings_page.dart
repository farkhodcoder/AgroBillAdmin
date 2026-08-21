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
import '../../../data/models/admin_staff.dart';
import '../../../data/repositories/admin_staff_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_field.dart';

/// Tizim sozlamalari (TTZ §6.15).
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _repo = getIt<AdminStaffRepository>();

  List<AppSetting> _settings = const [];
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

    final res = await _repo.settings();
    if (!mounted) return;

    setState(() {
      _loading = false;
      switch (res) {
        case Ok(:final value):
          _settings = value;
        case Fail(:final failure):
          _failure = failure;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    // Sozlamalar `settings.write` bilan ochiladi — TTZ §7 bo'yicha faqat
    // `super_admin` da bor.
    return PermissionGuard(
      permission: AdminPermission.settingsWrite,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AgSpace.x7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'admin.nav.settings'.tr(),
              subtitle: 'admin.settings.subtitle'.tr(),
            ),
            const SizedBox(height: AgSpace.x5),

            AdminNote(
              text: 'admin.settings.mobile_note'.tr(),
              icon: Icons.phonelink_off_outlined,
            ),
            const SizedBox(height: AgSpace.x5),

            if (_failure != null)
              AdminErrorBanner(failure: _failure!, onRetry: _load)
            else if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AgSpace.x9),
                child: AdminLoading(),
              )
            else
              for (final setting in _settings)
                _SettingTile(
                  setting: setting,
                  colors: c,
                  onSave: (value, reason) => _save(setting, value, reason),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(AppSetting setting, Object value, String reason) async {
    final res = await _repo.updateSetting(setting.key, value, reason);
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
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.setting,
    required this.colors,
    required this.onSave,
  });

  final AppSetting setting;
  final AppColors colors;
  final Future<void> Function(Object value, String reason) onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AgSpace.x3),
      padding: const EdgeInsets.all(AgSpace.x5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AgRadius.rLg,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  setting.key,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.text,
                    fontFamily: 'monospace',
                  ),
                ),
                if (setting.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    setting.description!,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                if (setting.updatedAt != null)
                  Text(
                    'admin.settings.updated'.tr(
                      args: [
                        Fmt.dateTime(setting.updatedAt),
                        setting.updatedByName ?? '—',
                      ],
                    ),
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AgSpace.x4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AgSpace.x3,
              vertical: AgSpace.x2,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              borderRadius: AgRadius.rSm,
            ),
            child: Text(
              setting.display,
              style: AppTypography.bodySmall.copyWith(
                color: colors.text,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: AgSpace.x3),
          AdminButton(
            label: 'admin.settings.change'.tr(),
            kind: AdminButtonKind.secondary,
            onPressed: () => _edit(context),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final result = await showDialog<(Object, String)>(
      context: context,
      builder: (context) => _EditDialog(setting: setting),
    );
    if (result == null) return;

    await onSave(result.$1, result.$2);
  }
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.setting});

  final AppSetting setting;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _value = TextEditingController(text: widget.setting.display);
  final _reason = TextEditingController();
  String? _valueError;
  String? _reasonError;

  @override
  void dispose() {
    _value.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _value.text.trim();
    final reason = _reason.text.trim();

    setState(() {
      _valueError = raw.isEmpty ? 'admin.errors.invalid_value'.tr() : null;
      _reasonError = reason.length < 5
          ? 'admin.errors.reason_required'.tr()
          : null;
    });
    if (_valueError != null || _reasonError != null) return;

    // `app_settings.value` — `jsonb`. Son kiritilsa son bo'lib saqlanadi,
    // aks holda matn: mobil ilova `15` va `"15"` ni bir xil o'qimaydi.
    final Object parsed = switch (raw) {
      'true' => true,
      'false' => false,
      _ => num.tryParse(raw) ?? raw,
    };

    Navigator.of(context).pop((parsed, reason));
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: AgRadius.rLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AgSpace.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.setting.key,
                style: AppTypography.h3.copyWith(color: c.text),
              ),
              if (widget.setting.description != null) ...[
                const SizedBox(height: AgSpace.x2),
                Text(
                  widget.setting.description!,
                  style: AppTypography.bodySmall.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AgSpace.x5),
              AdminField(
                controller: _value,
                label: 'admin.settings.value'.tr(),
                autofocus: true,
                errorText: _valueError,
              ),
              const SizedBox(height: AgSpace.x2),
              AdminField(
                controller: _reason,
                label: 'admin.common.reason_required'.tr(),
                errorText: _reasonError,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AgSpace.x4),
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
