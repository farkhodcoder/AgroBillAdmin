import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_field.dart';
import '../../../ui/auth_scaffold.dart';
import '../../../ui/theme_switch.dart';
import '../cubit/admin_auth_cubit.dart';
import '../widgets/language_switch.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    // Mahalliy validatsiya — bo'sh forma uchun serverga borish shart emas.
    setState(() {
      _emailError = _email.text.trim().isEmpty
          ? 'admin.auth.email_required'.tr()
          : null;
      _passwordError = _password.text.isEmpty
          ? 'admin.auth.password_required'.tr()
          : null;
    });
    if (_emailError != null || _passwordError != null) return;

    context.read<AdminAuthCubit>().signIn(
      email: _email.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminAuthCubit, AdminAuthState>(
      builder: (context, state) {
        return AuthScaffold(
          title: 'admin.auth.sign_in_title'.tr(),
          subtitle: 'admin.auth.sign_in_subtitle'.tr(),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LanguageSwitch(),
              const SizedBox(width: AgSpace.x3),
              ThemeSwitch(controller: getIt<ThemeController>()),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.failure != null) ...[
                AdminErrorBanner(failure: state.failure!),
                const SizedBox(height: AgSpace.x5),
              ],
              AdminField(
                controller: _email,
                label: 'admin.auth.email'.tr(),
                hint: 'admin@agrobill.uz',
                autofocus: true,
                enabled: !state.busy,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AgSpace.x3),
              AdminField(
                controller: _password,
                label: 'admin.auth.password'.tr(),
                obscure: true,
                enabled: !state.busy,
                errorText: _passwordError,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AgSpace.x4),
              AdminButton(
                label: 'admin.auth.sign_in'.tr(),
                size: AdminButtonSize.large,
                expand: true,
                busy: state.busy,
                onPressed: state.busy ? null : _submit,
              ),
            ],
          ),
        );
      },
    );
  }
}
