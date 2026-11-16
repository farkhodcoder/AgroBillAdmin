import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/result.dart';
import '../../../data/repositories/admin_auth_repository.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_field.dart';

/// Authenticator kodi uchun maydon sozlamalari — ikkala 2FA ekranida bir xil.
final mfaCodeFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(6),
];

/// Kod to'liqmi (6 ta raqam).
bool isMfaCode(String value) => RegExp(r'^\d{6}$').hasMatch(value.trim());

/// 2FA ni ulash: QR -> authenticator ilovasi -> 6 xonali kod.
///
/// Ikki joyda ishlatiladi: majburiy ulash ekranida (kirish oqimi) va profil
/// menyusidagi ixtiyoriy ulash oynasida. Mantiq bitta — ikki nusxa
/// bir-biridan ajralib ketmasin.
class MfaSetupPanel extends StatefulWidget {
  const MfaSetupPanel({super.key, required this.onDone});

  /// Omil tasdiqlandi, sessiya `aal2` ga ko'tarildi.
  final VoidCallback onDone;

  @override
  State<MfaSetupPanel> createState() => _MfaSetupPanelState();
}

class _MfaSetupPanelState extends State<MfaSetupPanel> {
  final _repo = getIt<AdminAuthRepository>();
  final _code = TextEditingController();

  MfaEnrollment? _enrollment;
  AppFailure? _failure;
  String? _codeError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _failure = null;
      _enrollment = null;
    });
    final res = await _repo.startMfaEnrollment();
    if (!mounted) return;
    setState(() {
      switch (res) {
        case Ok(:final value):
          _enrollment = value;
        case Fail(:final failure):
          _failure = failure;
      }
    });
  }

  Future<void> _confirm() async {
    final enrollment = _enrollment;
    if (enrollment == null || _busy) return;

    if (!isMfaCode(_code.text)) {
      setState(() => _codeError = 'admin.mfa.code_required'.tr());
      return;
    }

    setState(() {
      _busy = true;
      _codeError = null;
      _failure = null;
    });

    final res = await _repo.confirmMfaEnrollment(
      factorId: enrollment.factorId,
      code: _code.text.trim(),
    );
    if (!mounted) return;

    if (res case Fail(:final failure)) {
      setState(() {
        _busy = false;
        _failure = failure;
      });
      return;
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final enrollment = _enrollment;

    if (enrollment == null) {
      // Boshlab bo'lmadi (tarmoq, Supabase'da MFA o'chiq) yoki hali yuklanmoqda.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_failure != null) ...[
            AdminErrorBanner(failure: _failure!),
            const SizedBox(height: AgSpace.x4),
            AdminButton(
              label: 'admin.common.retry'.tr(),
              kind: AdminButtonKind.secondary,
              onPressed: _start,
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AgSpace.x7),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'admin.mfa.step_scan'.tr(),
          style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AgSpace.x4),
        Center(
          // QR har doim oq fonda: qorong'i temada qora-oq kontrast
          // yo'qolsa telefon kamerasi uni o'qiy olmaydi.
          child: Container(
            padding: const EdgeInsets.all(AgSpace.x3),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: AgRadius.rMd,
            ),
            child: SvgPicture.string(
              enrollment.qrSvg,
              width: 176,
              height: 176,
              placeholderBuilder: (_) =>
                  const SizedBox(width: 176, height: 176),
            ),
          ),
        ),
        const SizedBox(height: AgSpace.x4),
        Text(
          'admin.mfa.manual_key'.tr(),
          style: AppTypography.caption.copyWith(color: c.textTertiary),
        ),
        const SizedBox(height: AgSpace.x1),
        SelectableText(
          enrollment.secret,
          style: AppTypography.bodySmall.copyWith(
            color: c.text,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: AgSpace.x5),
        if (_failure != null) ...[
          AdminErrorBanner(failure: _failure!),
          const SizedBox(height: AgSpace.x4),
        ],
        AdminField(
          controller: _code,
          label: 'admin.mfa.code'.tr(),
          hint: '000000',
          enabled: !_busy,
          errorText: _codeError,
          keyboardType: TextInputType.number,
          inputFormatters: mfaCodeFormatters,
          onSubmitted: (_) => _confirm(),
        ),
        const SizedBox(height: AgSpace.x3),
        AdminButton(
          label: 'admin.mfa.enable'.tr(),
          size: AdminButtonSize.large,
          expand: true,
          busy: _busy,
          onPressed: _busy ? null : _confirm,
        ),
      ],
    );
  }
}
