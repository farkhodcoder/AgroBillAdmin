import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/auth_scaffold.dart';
import '../cubit/admin_auth_cubit.dart';
import '../widgets/mfa_setup_panel.dart';

/// 2FA majburiy (`admin.mfa_required`), lekin xodim hali ulamagan.
///
/// Bu ekrandan o'tmaguncha panel ochilmaydi — va bu faqat interfeys emas:
/// `admin_has()` `aal2` siz `false` qaytaradi (0067), ya'ni manzilni qo'lda
/// yozish ham foyda bermaydi.
class MfaEnrollPage extends StatelessWidget {
  const MfaEnrollPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'admin.mfa.enroll_title'.tr(),
      subtitle: 'admin.mfa.enroll_subtitle'.tr(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MfaSetupPanel(
            // Kirish shu yerda yakunlanadi — muvaffaqiyat endi yoziladi.
            onDone: () =>
                context.read<AdminAuthCubit>().refresh(recordSuccess: true),
          ),
          const SizedBox(height: AgSpace.x3),
          AdminButton(
            label: 'admin.auth.sign_out'.tr(),
            kind: AdminButtonKind.ghost,
            expand: true,
            onPressed: () => context.read<AdminAuthCubit>().signOut(),
          ),
        ],
      ),
    );
  }
}
