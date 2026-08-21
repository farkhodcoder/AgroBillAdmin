import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ui/admin_button.dart';
import '../../../ui/auth_scaffold.dart';
import '../cubit/admin_auth_cubit.dart';

/// Sessiya bor, lekin `admin_users` da faol yozuv yo'q.
///
/// Bu oddiy fermer admin panel manzilini ochgan holat. Ekran ataylab
/// quruq: nima yetishmayotgani ham aytilmaydi.
class NotAdminPage extends StatelessWidget {
  const NotAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'admin.auth.not_admin_title'.tr(),
      subtitle: 'admin.auth.not_admin_subtitle'.tr(),
      child: AdminButton(
        label: 'admin.auth.sign_out'.tr(),
        kind: AdminButtonKind.secondary,
        size: AdminButtonSize.large,
        expand: true,
        onPressed: () => context.read<AdminAuthCubit>().signOut(),
      ),
    );
  }
}
