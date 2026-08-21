import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/supabase/db.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/cubit/admin_auth_cubit.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../ui/theme_switch.dart';
import '../../auth/widgets/language_switch.dart';

/// Yuqori panel — sahifa sarlavhasi, til va profil.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final state = context.watch<AdminAuthCubit>().state;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AgSpace.x6),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Text(title, style: AppTypography.h3.copyWith(color: c.text)),
          const Spacer(),
          ThemeSwitch(controller: getIt<ThemeController>()),
          const SizedBox(width: AgSpace.x3),
          const LanguageSwitch(compact: true),
          const SizedBox(width: AgSpace.x4),
          _ProfileMenu(
            email: Db.currentUser?.email ?? '',
            roleCode: state.permissions.roleCode,
            colors: c,
          ),
        ],
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({
    required this.email,
    required this.roleCode,
    required this.colors,
  });

  final String email;
  final String? roleCode;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 48),
      color: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AgRadius.rMd),
      onSelected: (value) {
        if (value == 'sign_out') {
          context.read<AdminAuthCubit>().signOut();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          height: 56,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                email,
                style: AppTypography.bodySmall.copyWith(color: colors.text),
              ),
              if (roleCode != null)
                Text(
                  'admin.roles.$roleCode'.tr(),
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'sign_out',
          child: Row(
            children: [
              Icon(Icons.logout, size: 16, color: colors.textSecondary),
              const SizedBox(width: AgSpace.x3),
              Text(
                'admin.auth.sign_out'.tr(),
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.surfaceBrand,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                email.isEmpty ? '?' : email.characters.first.toUpperCase(),
                style: AppTypography.label.copyWith(color: colors.textBrand),
              ),
            ),
          ),
          const SizedBox(width: AgSpace.x2),
          Icon(Icons.expand_more, size: 16, color: colors.textTertiary),
        ],
      ),
    );
  }
}
