import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/rbac/permission.dart';
import '../../../core/rbac/permission_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/admin_staff.dart';
import '../../../data/repositories/admin_staff_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_table.dart';
import '../cubit/staff_cubit.dart';

/// Xodimlar (TTZ §6.13).
class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.adminRead,
      child: BlocProvider(
        create: (_) => StaffCubit(
          getIt<AdminStaffRepository>(),
          context.locale.languageCode,
        )..load(),
        child: const _StaffView(),
      ),
    );
  }
}

class _StaffView extends StatelessWidget {
  const _StaffView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocConsumer<StaffCubit, StaffState>(
      listenWhen: (prev, next) =>
          next.actionFailure != null &&
          prev.actionFailure != next.actionFailure,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: c.errorBg,
            content: Text(
              state.actionFailure!.messageKey.tr(),
              style: AppTypography.bodySmall.copyWith(color: c.errorText),
            ),
          ),
        );
      },
      builder: (context, state) {
        final cubit = context.read<StaffCubit>();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AgSpace.x7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminPageHeader(
                title: 'admin.nav.staff'.tr(),
                subtitle: 'admin.staff.subtitle'.tr(),
              ),
              const SizedBox(height: AgSpace.x5),

              SizedBox(
                height: 320,
                child: AdminTable<StaffRow>(
                  rows: state.staff,
                  loading: state.loading,
                  failure: state.failure,
                  onRetry: cubit.load,
                  emptyTitle: 'admin.staff.empty'.tr(),
                  columns: _columns(c, context),
                ),
              ),

              const SizedBox(height: AgSpace.x7),
              Text(
                'admin.staff.matrix'.tr(),
                style: AppTypography.h3.copyWith(color: c.text),
              ),
              const SizedBox(height: AgSpace.x2),
              Text(
                'admin.staff.matrix_note'.tr(),
                style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AgSpace.x4),
              _Matrix(roles: state.roles, colors: c),

              const SizedBox(height: AgSpace.x7),
              Text(
                'admin.staff.logins'.tr(),
                style: AppTypography.h3.copyWith(color: c.text),
              ),
              const SizedBox(height: AgSpace.x4),
              _Logins(events: state.events, colors: c),
            ],
          ),
        );
      },
    );
  }

  List<AdminColumn<StaffRow>> _columns(AppColors c, BuildContext pageContext) =>
      [
        AdminColumn(
          labelKey: 'admin.users.col_name',
          flex: 3,
          build: (row) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                row.fullName ?? '—',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(color: c.text),
              ),
              Text(
                row.email ?? '—',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
            ],
          ),
        ),
        AdminColumn(
          labelKey: 'admin.staff.col_role',
          width: 190,
          build: (row) => Wrap(
            spacing: AgSpace.x1,
            children: [
              StatusBadge(
                label: 'admin.roles.${row.roleCode}'.tr(),
                tone: BadgeTone.brand,
              ),
              if (!row.isActive)
                StatusBadge(
                  label: 'admin.staff.inactive'.tr(),
                  tone: BadgeTone.neutral,
                ),
            ],
          ),
        ),
        AdminColumn(
          labelKey: 'admin.staff.col_last_login',
          width: 150,
          build: (row) => Text(
            Fmt.dateTime(row.lastLoginAt),
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ),
        AdminColumn(
          labelKey: 'admin.staff.col_actions',
          width: 130,
          build: (row) => PermissionGuard(
            permission: AdminPermission.adminWrite,
            fallback: const SizedBox.shrink(),
            child: AdminButton(
              label: 'admin.staff.change'.tr(),
              kind: AdminButtonKind.secondary,
              onPressed: () => _changeRole(pageContext, row),
            ),
          ),
        ),
      ];

  Future<void> _changeRole(BuildContext context, StaffRow row) async {
    final cubit = context.read<StaffCubit>();

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
                  style: AppTypography.body.copyWith(
                    color: code == row.roleCode ? c.textBrand : c.text,
                  ),
                ),
              ),
            const Divider(height: 1),
            // Bo'sh qiymat = xodimlikdan chiqarish (`admin_set_role` null
            // qabul qiladi va `admin_users` dan o'chiradi).
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('__remove__'),
              child: Text(
                'admin.staff.remove'.tr(),
                style: AppTypography.body.copyWith(color: c.errorText),
              ),
            ),
          ],
        );
      },
    );

    if (roleCode == null || !context.mounted) return;
    final isRemove = roleCode == '__remove__';

    final result = await showReasonDialog(
      context,
      title: isRemove
          ? 'admin.staff.remove'.tr()
          : 'admin.users.make_staff'.tr(),
      message: isRemove
          ? 'admin.staff.remove_confirm'.tr(
              args: [row.fullName ?? row.email ?? ''],
            )
          : 'admin.users.role_confirm'.tr(
              args: [
                row.fullName ?? row.email ?? '',
                'admin.roles.$roleCode'.tr(),
              ],
            ),
      confirmLabel: 'admin.common.confirm'.tr(),
      danger: isRemove,
    );
    if (!result.confirmed || result.reason == null) return;

    await cubit.setRole(row.id, isRemove ? null : roleCode, result.reason!);
  }
}

/// Rol × ruxsat matritsasi (TTZ §7).
///
/// Bazadan o'qiladi, kodda qat'iy yozilmagan: `admin_role_permissions` qo'lda
/// o'zgartirilsa matritsa shuni ko'rsatishi kerak, aks holda admin
/// hujjatga qarab noto'g'ri xulosa chiqarardi.
class _Matrix extends StatelessWidget {
  const _Matrix({required this.roles, required this.colors});

  final List<RoleWithPermissions> roles;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) {
      return Text(
        'admin.common.empty'.tr(),
        style: AppTypography.bodySmall.copyWith(color: colors.textTertiary),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AgRadius.rLg,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Sarlavha qatori
            Container(
              height: 40,
              color: colors.surfaceSunken,
              child: Row(
                children: [
                  _cell('', 220, colors, header: true),
                  for (final r in roles)
                    _cell(r.name, 130, colors, header: true),
                ],
              ),
            ),
            for (final permission in AdminPermission.all)
              Container(
                height: 34,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: [
                    _cell(permission, 220, colors),
                    for (final r in roles)
                      SizedBox(
                        width: 130,
                        child: Center(
                          child: r.permissions.contains(permission)
                              ? Icon(
                                  Icons.check,
                                  size: 15,
                                  color: colors.successText,
                                )
                              : Text(
                                  '—',
                                  style: AppTypography.caption.copyWith(
                                    color: colors.textDisabled,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, double width, AppColors c, {bool header = false}) =>
      SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AgSpace.x3),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: header ? c.textSecondary : c.text,
              ),
            ),
          ),
        ),
      );
}

class _Logins extends StatelessWidget {
  const _Logins({required this.events, required this.colors});

  final List<LoginEvent> events;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return AdminNote(text: 'admin.staff.logins_empty'.tr());
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AgRadius.rLg,
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final e in events)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AgSpace.x4,
                vertical: AgSpace.x3,
              ),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  Icon(
                    e.success
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: 15,
                    color: e.success ? colors.successText : colors.errorText,
                  ),
                  const SizedBox(width: AgSpace.x3),
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.email ?? '—',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.text,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      e.failureCode ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: colors.errorText,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      e.ipAddress ?? '—',
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                  Text(
                    Fmt.dateTime(e.createdAt),
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
