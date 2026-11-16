import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/result.dart';
import '../../../data/repositories/admin_auth_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_field.dart';
import '../cubit/admin_auth_cubit.dart';
import 'mfa_setup_panel.dart';

/// Supabase'ning eng kichik chegarasi va `admin-staff` dagi tekshiruv bilan
/// bir xil.
const _minPasswordLength = 8;

/// Xodim O'Z parolini almashtiradi.
///
/// Boshqa xodimning parolini almashtirish — «Xodimlar» bo'limida
/// (`admin-staff`, `set_password`); bu oyna faqat joriy hisob uchun.
Future<void> showChangePasswordDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const _ChangePasswordDialog(),
);

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _repo = getIt<AdminAuthRepository>();
  final _proof = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();

  String? _proofError;
  String? _nextError;
  String? _repeatError;
  AppFailure? _failure;
  bool _busy = false;

  /// 2FA ulangan bo'lsa shaxs kod bilan, aks holda joriy parol bilan
  /// tasdiqlanadi — sababi `AdminAuthRepository.changePassword` izohida.
  late final bool _useCode = _repo.hasTotp;

  @override
  void dispose() {
    _proof.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _failure = null;
      _proofError = _useCode
          ? (isMfaCode(_proof.text) ? null : 'admin.mfa.code_required'.tr())
          : (_proof.text.isEmpty ? 'admin.auth.password_required'.tr() : null);
      _nextError = _next.text.length < _minPasswordLength
          ? 'admin.errors.weak_password'.tr()
          : null;
      _repeatError = _repeat.text == _next.text
          ? null
          : 'admin.account.password_mismatch'.tr();
    });
    if (_proofError != null || _nextError != null || _repeatError != null) {
      return;
    }

    setState(() => _busy = true);
    final res = await _repo.changePassword(
      newPassword: _next.text,
      currentPassword: _useCode ? null : _proof.text,
      totpCode: _useCode ? _proof.text.trim() : null,
    );
    if (!mounted) return;

    if (res case Fail(:final failure)) {
      setState(() {
        _busy = false;
        _failure = failure;
      });
      return;
    }

    final c = Theme.of(context).extension<AppColors>()!;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: c.successBg,
        content: Text(
          'admin.account.password_changed'.tr(),
          style: AppTypography.bodySmall.copyWith(color: c.successText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormDialog(
      title: 'admin.account.change_password'.tr(),
      subtitle: _useCode
          ? 'admin.account.change_password_hint_code'.tr()
          : 'admin.account.change_password_hint'.tr(),
      confirmLabel: 'admin.account.change_password'.tr(),
      busy: _busy,
      onConfirm: _busy ? null : _submit,
      children: [
        if (_failure != null) ...[
          AdminErrorBanner(failure: _failure!),
          const SizedBox(height: AgSpace.x4),
        ],
        if (_useCode)
          AdminField(
            controller: _proof,
            label: 'admin.mfa.code'.tr(),
            hint: '000000',
            autofocus: true,
            enabled: !_busy,
            errorText: _proofError,
            keyboardType: TextInputType.number,
            inputFormatters: mfaCodeFormatters,
          )
        else
          AdminField(
            controller: _proof,
            label: 'admin.account.current_password'.tr(),
            obscure: true,
            autofocus: true,
            enabled: !_busy,
            errorText: _proofError,
          ),
        const SizedBox(height: AgSpace.x3),
        AdminField(
          controller: _next,
          label: 'admin.account.new_password'.tr(),
          obscure: true,
          enabled: !_busy,
          errorText: _nextError,
        ),
        const SizedBox(height: AgSpace.x3),
        AdminField(
          controller: _repeat,
          label: 'admin.account.repeat_password'.tr(),
          obscure: true,
          enabled: !_busy,
          errorText: _repeatError,
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}

/// 2FA ni ixtiyoriy ulash — `admin.mfa_required` hali yoqilmagan bo'lsa ham.
///
/// Asoschi bayroqni yoqishdan OLDIN shu yerda o'zi ulab oladi (0067 dagi
/// tartib).
Future<void> showMfaSetupDialog(BuildContext context) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (dialogContext) {
    final c = Theme.of(dialogContext).extension<AppColors>()!;
    final cubit = context.read<AdminAuthCubit>();

    return Dialog(
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: AgRadius.rLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AgSpace.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'admin.mfa.enroll_title'.tr(),
                style: AppTypography.h3.copyWith(color: c.text),
              ),
              const SizedBox(height: AgSpace.x5),
              MfaSetupPanel(
                onDone: () {
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  Navigator.of(dialogContext).pop();
                  // Sessiya `aal2` ga ko'tarildi — bosqich va menyu yangilansin.
                  cubit.refresh();
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: c.successBg,
                      content: Text(
                        'admin.mfa.enabled'.tr(),
                        style: AppTypography.bodySmall.copyWith(
                          color: c.successText,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AgSpace.x2),
              AdminButton(
                label: 'admin.common.cancel'.tr(),
                kind: AdminButtonKind.ghost,
                expand: true,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
