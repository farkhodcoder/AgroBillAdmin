import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_field.dart';
import '../../../ui/auth_scaffold.dart';
import '../cubit/admin_auth_cubit.dart';
import '../widgets/mfa_setup_panel.dart';

/// Kirishdagi ikkinchi bosqich: authenticator ilovasidagi 6 xonali kod.
class MfaVerifyPage extends StatefulWidget {
  const MfaVerifyPage({super.key});

  @override
  State<MfaVerifyPage> createState() => _MfaVerifyPageState();
}

class _MfaVerifyPageState extends State<MfaVerifyPage> {
  final _code = TextEditingController();
  String? _codeError;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (!isMfaCode(_code.text)) {
      setState(() => _codeError = 'admin.mfa.code_required'.tr());
      return;
    }
    setState(() => _codeError = null);
    context.read<AdminAuthCubit>().verifyMfa(_code.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminAuthCubit, AdminAuthState>(
      // Kod xato bo'lsa maydon tozalanadi: authenticator kodi 30 soniyada
      // almashadi, eskisini tuzatib bo'lmaydi.
      listenWhen: (prev, next) => prev.busy && !next.busy,
      listener: (context, state) {
        if (state.failure != null) _code.clear();
      },
      builder: (context, state) {
        return AuthScaffold(
          title: 'admin.mfa.verify_title'.tr(),
          subtitle: 'admin.mfa.verify_subtitle'.tr(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.failure != null) ...[
                AdminErrorBanner(failure: state.failure!),
                const SizedBox(height: AgSpace.x5),
              ],
              AdminField(
                controller: _code,
                label: 'admin.mfa.code'.tr(),
                hint: '000000',
                autofocus: true,
                enabled: !state.busy,
                errorText: _codeError,
                keyboardType: TextInputType.number,
                inputFormatters: mfaCodeFormatters,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AgSpace.x3),
              AdminButton(
                label: 'admin.mfa.verify'.tr(),
                size: AdminButtonSize.large,
                expand: true,
                busy: state.busy,
                onPressed: state.busy ? null : _submit,
              ),
              const SizedBox(height: AgSpace.x3),
              AdminButton(
                label: 'admin.auth.sign_out'.tr(),
                kind: AdminButtonKind.ghost,
                expand: true,
                onPressed: state.busy
                    ? null
                    : () => context.read<AdminAuthCubit>().signOut(),
              ),
            ],
          ),
        );
      },
    );
  }
}
