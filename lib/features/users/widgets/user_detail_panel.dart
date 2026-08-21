import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/rbac/permission.dart';
import '../../../core/rbac/permission_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/admin_user.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../cubit/users_cubit.dart';

/// Foydalanuvchi tafsiloti — o'ngdan chiqadigan panel.
///
/// Alohida sahifa emas: admin ro'yxatni yo'qotmasdan bir necha
/// foydalanuvchini ketma-ket ko'rib chiqadi. Sahifaga o'tish har safar
/// ro'yxatni qayta yuklashni talab qilardi.
Future<void> showUserDetail(
  BuildContext context,
  UsersCubit cubit,
  AdminUserRow row,
) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'close',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) => const SizedBox.shrink(),
    transitionBuilder: (dialogContext, anim, _, _) {
      return SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: Align(
          alignment: Alignment.centerRight,
          // Cubit dialog daraxtidan tashqarida qoladi, shuning uchun
          // `.value` bilan qayta beriladi.
          child: BlocProvider.value(
            value: cubit,
            child: _DetailPanel(userId: row.id),
          ),
        ),
      );
    },
  );
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        // Ro'yxatdagi eng so'nggi holat — bloklashdan keyin panel o'zi
        // yangilanadi, chunki cubit ro'yxatni qayta yuklaydi.
        final row = state.rows.where((r) => r.id == userId).firstOrNull;
        if (row == null) return const SizedBox.shrink();

        return Material(
          color: c.surface,
          child: SizedBox(
            width: 460,
            height: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(row: row, colors: c),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AgSpace.x6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Fields(row: row, colors: c),
                        const SizedBox(height: AgSpace.x6),
                        _Actions(row: row),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.row, required this.colors});

  final AdminUserRow row;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AgSpace.x6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.fullName.isEmpty ? '—' : row.fullName,
                  style: AppTypography.h3.copyWith(color: colors.text),
                ),
                const SizedBox(height: AgSpace.x1),
                SelectableText(
                  row.email ?? '—',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, size: 18, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _Fields extends StatelessWidget {
  const _Fields({required this.row, required this.colors});

  final AdminUserRow row;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('admin.users.col_status', _statusLabel()),
      ('admin.user_roles.label', 'admin.user_roles.${row.role}'.tr()),
      ('admin.users.col_activity', 'admin.activity.${row.activity}'.tr()),
      ('admin.users.col_region', row.regionName ?? '—'),
      ('admin.users.district', row.districtName ?? '—'),
      ('admin.users.rating', '${row.rating} (${row.ratingCount})'),
      ('admin.users.col_joined', Fmt.dateTime(row.createdAt)),
      ('admin.users.id', row.id),
      if (row.isBlocked) ('admin.users.block_reason', row.blockReason ?? '—'),
    ];

    return Column(
      children: [
        for (final (labelKey, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AgSpace.x2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    labelKey.tr(),
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText(
                    value,
                    style: AppTypography.bodySmall.copyWith(color: colors.text),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _statusLabel() {
    if (row.isDeleted) return 'admin.users.deleted'.tr();
    if (row.isBlocked) return 'admin.users.blocked'.tr();
    return 'admin.users.active'.tr();
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.row});

  final AdminUserRow row;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<UsersCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bloklash `users.block` talab qiladi. Ruxsat yo'q bo'lsa tugma
        // umuman ko'rinmaydi — bosib "PERMISSION_DENIED" olishdan yaxshi.
        PermissionGuard(
          permission: AdminPermission.usersBlock,
          fallback: const SizedBox.shrink(),
          child: row.isBlocked
              ? AdminButton(
                  label: 'admin.users.unblock'.tr(),
                  kind: AdminButtonKind.secondary,
                  size: AdminButtonSize.large,
                  expand: true,
                  icon: Icons.lock_open_outlined,
                  onPressed: () async {
                    final result = await showReasonDialog(
                      context,
                      title: 'admin.users.unblock'.tr(),
                      message: 'admin.users.unblock_confirm'.tr(
                        args: [row.fullName],
                      ),
                      confirmLabel: 'admin.users.unblock'.tr(),
                      reasonRequired: false,
                      danger: false,
                    );
                    if (!result.confirmed) return;
                    await cubit.unblock(row.id, result.reason);
                  },
                )
              : AdminButton(
                  label: 'admin.users.block'.tr(),
                  kind: AdminButtonKind.danger,
                  size: AdminButtonSize.large,
                  expand: true,
                  icon: Icons.block,
                  onPressed: () async {
                    final result = await showReasonDialog(
                      context,
                      title: 'admin.users.block'.tr(),
                      message: 'admin.users.block_confirm'.tr(
                        args: [row.fullName],
                      ),
                      confirmLabel: 'admin.users.block'.tr(),
                    );
                    if (!result.confirmed || result.reason == null) return;
                    await cubit.block(row.id, result.reason!);
                  },
                ),
        ),

        const SizedBox(height: AgSpace.x3),

        // Xodim roli — faqat `admin.write` (ya'ni super_admin).
        PermissionGuard(
          permission: AdminPermission.adminWrite,
          fallback: const SizedBox.shrink(),
          child: AdminButton(
            label: 'admin.users.make_staff'.tr(),
            kind: AdminButtonKind.secondary,
            size: AdminButtonSize.large,
            expand: true,
            icon: Icons.badge_outlined,
            onPressed: () => _pickRole(context, cubit),
          ),
        ),
      ],
    );
  }

  Future<void> _pickRole(BuildContext context, UsersCubit cubit) async {
    final roleCode = await showDialog<String>(
      context: context,
      builder: (context) {
        final c = Theme.of(context).extension<AppColors>()!;
        return SimpleDialog(
          backgroundColor: c.surface,
          shape: const RoundedRectangleBorder(borderRadius: AgRadius.rLg),
          title: Text(
            'admin.users.pick_role'.tr(),
            style: AppTypography.h3.copyWith(color: c.text),
          ),
          children: [
            for (final code in AdminRole.all)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(code),
                child: Text(
                  'admin.roles.$code'.tr(),
                  style: AppTypography.body.copyWith(color: c.text),
                ),
              ),
          ],
        );
      },
    );

    if (roleCode == null || !context.mounted) return;

    final result = await showReasonDialog(
      context,
      title: 'admin.users.make_staff'.tr(),
      message: 'admin.users.role_confirm'.tr(
        args: [row.fullName, 'admin.roles.$roleCode'.tr()],
      ),
      confirmLabel: 'admin.common.confirm'.tr(),
      danger: false,
    );
    if (!result.confirmed || result.reason == null) return;

    await cubit.setRole(row.id, roleCode, result.reason!);
  }
}
