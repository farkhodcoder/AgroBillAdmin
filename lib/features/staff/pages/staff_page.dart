import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/rbac/permission.dart';
import '../../../core/rbac/permission_guard.dart';
import '../../../core/supabase/db.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/admin_staff.dart';
import '../../../data/repositories/admin_staff_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_field.dart';
import '../../../ui/admin_table.dart';
import '../../dashboard/widgets/kpi_card.dart';
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
        final visible = state.visible;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AgSpace.x7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminPageHeader(
                title: 'admin.nav.staff'.tr(),
                subtitle: 'admin.staff.subtitle'.tr(),
                actions: [
                  PermissionGuard(
                    permission: AdminPermission.adminWrite,
                    fallback: const SizedBox.shrink(),
                    child: AdminButton(
                      label: 'admin.staff.add'.tr(),
                      icon: Icons.person_add_alt_1_outlined,
                      busy: state.busy,
                      onPressed: () => _create(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AgSpace.x5),

              Wrap(
                spacing: AgSpace.x4,
                runSpacing: AgSpace.x4,
                children: [
                  KpiCard(
                    label: 'admin.staff.stat_total'.tr(),
                    value: Fmt.count(state.staff.length),
                    icon: Icons.badge_outlined,
                  ),
                  KpiCard(
                    label: 'admin.staff.stat_active'.tr(),
                    value: Fmt.count(state.activeCount),
                    icon: Icons.verified_user_outlined,
                  ),
                  KpiCard(
                    label: 'admin.staff.stat_inactive'.tr(),
                    value: Fmt.count(state.staff.length - state.activeCount),
                    icon: Icons.pause_circle_outline,
                    tone: state.staff.length > state.activeCount
                        ? c.warningText
                        : null,
                  ),
                  KpiCard(
                    label: 'admin.staff.stat_roles'.tr(),
                    value: Fmt.count(state.roles.length),
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AgSpace.x5),

              Wrap(
                spacing: AgSpace.x3,
                runSpacing: AgSpace.x3,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AdminSearchField(
                    hintKey: 'admin.staff.search_hint',
                    onChanged: cubit.setSearch,
                  ),
                  AdminSelect<String>(
                    value: state.roleFilter,
                    hintKey: 'admin.staff.col_role',
                    width: 200,
                    items: [
                      for (final code in AdminRole.all)
                        (code, 'admin.roles.$code'.tr()),
                    ],
                    onChanged: cubit.setRoleFilter,
                  ),
                  AdminSelect<bool>(
                    value: state.activeFilter,
                    hintKey: 'admin.staff.col_status',
                    width: 170,
                    items: [
                      (true, 'admin.staff.active'.tr()),
                      (false, 'admin.staff.inactive'.tr()),
                    ],
                    onChanged: cubit.setActiveFilter,
                  ),
                ],
              ),
              const SizedBox(height: AgSpace.x4),

              SizedBox(
                height: 440,
                child: AdminTable<StaffRow>(
                  rows: visible,
                  loading: state.loading,
                  failure: state.failure,
                  onRetry: cubit.load,
                  emptyTitle: state.staff.isEmpty
                      ? 'admin.staff.empty'.tr()
                      : 'admin.common.no_results'.tr(),
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

  List<AdminColumn<StaffRow>> _columns(
    AppColors c,
    BuildContext pageContext,
  ) => [
    AdminColumn(
      labelKey: 'admin.users.col_name',
      flex: 3,
      build: (row) => Row(
        children: [
          _Avatar(name: row.fullName ?? row.email ?? '?', colors: c),
          const SizedBox(width: AgSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  row.id == Db.userId
                      ? '${row.fullName ?? '—'} · ${'admin.staff.you'.tr()}'
                      : row.fullName ?? '—',
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
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.staff.col_role',
      width: 190,
      build: (row) => StatusBadge(
        label: 'admin.roles.${row.roleCode}'.tr(),
        tone: row.roleCode == AdminRole.founder
            ? BadgeTone.info
            : BadgeTone.brand,
      ),
    ),
    AdminColumn(
      labelKey: 'admin.staff.col_status',
      width: 120,
      build: (row) => StatusBadge(
        label: row.isActive
            ? 'admin.staff.active'.tr()
            : 'admin.staff.inactive'.tr(),
        tone: row.isActive ? BadgeTone.success : BadgeTone.warning,
      ),
    ),
    AdminColumn(
      labelKey: 'admin.staff.col_last_login',
      width: 150,
      build: (row) => Text(
        row.lastLoginAt == null
            ? 'admin.staff.never'.tr()
            : Fmt.dateTime(row.lastLoginAt),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.staff.col_created',
      width: 110,
      build: (row) => Text(
        Fmt.date(row.createdAt),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.staff.col_actions',
      width: 80,
      align: Alignment.center,
      build: (row) => PermissionGuard(
        permission: AdminPermission.adminWrite,
        fallback: const SizedBox.shrink(),
        child: _RowMenu(row: row, pageContext: pageContext),
      ),
    ),
  ];

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<StaffCubit>();

    final input = await showDialog<_NewStaff>(
      context: context,
      builder: (_) => const _CreateStaffDialog(),
    );
    if (input == null || !context.mounted) return;

    final ok = await cubit.createStaff(
      email: input.email,
      password: input.password,
      fullName: input.fullName,
      roleCode: input.roleCode,
      reason: input.reason,
    );
    if (!ok || !context.mounted) return;

    // Parol faqat shu yerda ko'rinadi — keyin hech qayerdan olib bo'lmaydi.
    await showDialog<void>(
      context: context,
      builder: (_) =>
          _CredentialsDialog(email: input.email, password: input.password),
    );
  }
}

enum _StaffAction { role, password, deactivate, activate, remove }

/// Qator amallari. Asoschi qatori va o'z qatori uchun xavfli amallar
/// ko'rsatilmaydi — baza ularni baribir rad etadi (`CANNOT_CHANGE_FOUNDER`,
/// `CANNOT_CHANGE_OWN_ROLE`), lekin bosiladigan tugma "ishlaydi" degan
/// taassurot qoldirardi.
class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.row, required this.pageContext});

  final StaffRow row;
  final BuildContext pageContext;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final isSelf = row.id == Db.userId;
    final isFounder = row.roleCode == AdminRole.founder;
    final iAmFounder = context.perms.isFounder;

    final items = <(_StaffAction, IconData, String, bool)>[
      if (!isSelf && !isFounder)
        (
          _StaffAction.role,
          Icons.manage_accounts_outlined,
          'admin.staff.change_role',
          false,
        ),
      if (!isFounder || iAmFounder)
        (
          _StaffAction.password,
          Icons.key_outlined,
          'admin.staff.set_password',
          false,
        ),
      if (!isSelf && !isFounder && row.isActive)
        (
          _StaffAction.deactivate,
          Icons.pause_circle_outline,
          'admin.staff.deactivate',
          true,
        ),
      if (!isSelf && !isFounder && !row.isActive)
        (
          _StaffAction.activate,
          Icons.play_circle_outline,
          'admin.staff.activate',
          false,
        ),
      if (!isSelf && !isFounder)
        (
          _StaffAction.remove,
          Icons.person_remove_outlined,
          'admin.staff.remove',
          true,
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<_StaffAction>(
      tooltip: 'admin.staff.col_actions'.tr(),
      color: c.surface,
      icon: Icon(Icons.more_horiz, size: 18, color: c.textSecondary),
      onSelected: (action) => _run(pageContext, action),
      itemBuilder: (_) => [
        for (final (action, icon, key, danger) in items)
          PopupMenuItem(
            value: action,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: danger ? c.errorText : c.textSecondary,
                ),
                const SizedBox(width: AgSpace.x3),
                Text(
                  key.tr(),
                  style: AppTypography.bodySmall.copyWith(
                    color: danger ? c.errorText : c.text,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _run(BuildContext context, _StaffAction action) async {
    final cubit = context.read<StaffCubit>();
    final name = row.fullName ?? row.email ?? '';

    switch (action) {
      case _StaffAction.role:
        await _changeRole(context, cubit, name);

      case _StaffAction.password:
        final input = await showDialog<({String password, String reason})>(
          context: context,
          builder: (_) => _PasswordDialog(name: name),
        );
        if (input == null) return;
        final ok = await cubit.setPassword(
          row.id,
          input.password,
          input.reason,
        );
        if (ok && context.mounted) {
          _toast(context, 'admin.staff.password_changed'.tr(args: [name]));
        }

      case _StaffAction.deactivate || _StaffAction.activate:
        final activate = action == _StaffAction.activate;
        final result = await showReasonDialog(
          context,
          title: activate
              ? 'admin.staff.activate'.tr()
              : 'admin.staff.deactivate'.tr(),
          message: activate
              ? 'admin.staff.activate_confirm'.tr(args: [name])
              : 'admin.staff.deactivate_confirm'.tr(args: [name]),
          confirmLabel: 'admin.common.confirm'.tr(),
          danger: !activate,
        );
        if (!result.confirmed || result.reason == null) return;
        await cubit.setActive(row.id, activate, result.reason!);

      case _StaffAction.remove:
        final result = await showReasonDialog(
          context,
          title: 'admin.staff.remove'.tr(),
          message: 'admin.staff.remove_confirm'.tr(args: [name]),
          confirmLabel: 'admin.common.confirm'.tr(),
        );
        if (!result.confirmed || result.reason == null) return;
        await cubit.setRole(row.id, null, result.reason!);
    }
  }

  Future<void> _changeRole(
    BuildContext context,
    StaffCubit cubit,
    String name,
  ) async {
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
            // Asoschi yagona — uni hech kimga berib bo'lmaydi (0043).
            for (final code in AdminRole.assignable)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(code),
                child: Text(
                  'admin.roles.$code'.tr(),
                  style: AppTypography.body.copyWith(
                    color: code == row.roleCode ? c.textBrand : c.text,
                  ),
                ),
              ),
          ],
        );
      },
    );

    if (roleCode == null || roleCode == row.roleCode || !context.mounted) {
      return;
    }

    final result = await showReasonDialog(
      context,
      title: 'admin.users.make_staff'.tr(),
      message: 'admin.users.role_confirm'.tr(
        args: [name, 'admin.roles.$roleCode'.tr()],
      ),
      confirmLabel: 'admin.common.confirm'.tr(),
      danger: false,
    );
    if (!result.confirmed || result.reason == null) return;

    await cubit.setRole(row.id, roleCode, result.reason!);
  }
}

void _toast(BuildContext context, String text) {
  final c = Theme.of(context).extension<AppColors>()!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: c.successBg,
      content: Text(
        text,
        style: AppTypography.bodySmall.copyWith(color: c.successText),
      ),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.colors});

  final String name;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p.characters.first.toUpperCase())
        .join();

    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceBrand,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: AppTypography.caption.copyWith(color: colors.textBrand),
      ),
    );
  }
}

/// Xavfsiz tasodifiy parol — admin o'ylab topishi shart emas.
///
/// O'xshash belgilar (`0/O`, `1/l/I`) ataylab olib tashlangan: parol odatda
/// og'zaki yoki xabarda uzatiladi.
String _generatePassword([int length = 14]) {
  const alphabet =
      'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#%*?';
  final rnd = Random.secure();
  return List.generate(
    length,
    (_) => alphabet[rnd.nextInt(alphabet.length)],
  ).join();
}

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

typedef _NewStaff = ({
  String email,
  String password,
  String fullName,
  String roleCode,
  String reason,
});

class _CreateStaffDialog extends StatefulWidget {
  const _CreateStaffDialog();

  @override
  State<_CreateStaffDialog> createState() => _CreateStaffDialogState();
}

class _CreateStaffDialogState extends State<_CreateStaffDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController(text: _generatePassword());
  final _reason = TextEditingController();
  String _role = AdminRole.moderator;
  bool _showPassword = true;
  final _errors = <String, String>{};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _email.text.trim().toLowerCase();
    final password = _password.text;
    final reason = _reason.text.trim();

    setState(() {
      _errors.clear();
      if (_name.text.trim().length < 2) {
        _errors['name'] = 'admin.staff.name_required'.tr();
      }
      if (!_emailRe.hasMatch(email)) {
        _errors['email'] = 'admin.errors.invalid_email'.tr();
      }
      if (password.length < 8) {
        _errors['password'] = 'admin.errors.weak_password'.tr();
      }
      if (reason.length < 5) {
        _errors['reason'] = 'admin.errors.reason_required'.tr();
      }
    });
    if (_errors.isNotEmpty) return;

    Navigator.of(context).pop<_NewStaff>((
      email: email,
      password: password,
      fullName: _name.text.trim(),
      roleCode: _role,
      reason: reason,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return AdminFormDialog(
      title: 'admin.staff.add'.tr(),
      subtitle: 'admin.staff.add_hint'.tr(),
      confirmLabel: 'admin.staff.create'.tr(),
      onConfirm: _submit,
      children: [
        AdminField(
          controller: _name,
          label: 'admin.staff.full_name'.tr(),
          autofocus: true,
          errorText: _errors['name'],
        ),
        AdminField(
          controller: _email,
          label: 'admin.staff.email'.tr(),
          keyboardType: TextInputType.emailAddress,
          errorText: _errors['email'],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AdminField(
                controller: _password,
                label: 'admin.staff.password'.tr(),
                obscure: !_showPassword,
                errorText: _errors['password'],
              ),
            ),
            const SizedBox(width: AgSpace.x2),
            Padding(
              padding: const EdgeInsets.only(top: 26),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'admin.staff.show_password'.tr(),
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: c.textSecondary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'admin.staff.generate'.tr(),
                    onPressed: () =>
                        setState(() => _password.text = _generatePassword()),
                    icon: Icon(Icons.refresh, size: 18, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        Text(
          'admin.staff.col_role'.tr(),
          style: AppTypography.label.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AgSpace.x2),
        Wrap(
          spacing: AgSpace.x2,
          runSpacing: AgSpace.x2,
          children: [
            for (final code in AdminRole.assignable)
              ChoiceChip(
                label: Text('admin.roles.$code'.tr()),
                selected: _role == code,
                onSelected: (_) => setState(() => _role = code),
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: _role == code ? c.textBrand : c.text,
                ),
                selectedColor: c.surfaceBrand,
                backgroundColor: c.surface,
                side: BorderSide(
                  color: _role == code ? c.borderFocus : c.border,
                ),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: AgSpace.x4),
        AdminField(
          controller: _reason,
          label: 'admin.common.reason_required'.tr(),
          errorText: _errors['reason'],
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.name});

  final String name;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController(text: _generatePassword());
  final _reason = TextEditingController();
  String? _passwordError;
  String? _reasonError;

  @override
  void dispose() {
    _password.dispose();
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _passwordError = _password.text.length < 8
          ? 'admin.errors.weak_password'.tr()
          : null;
      _reasonError = _reason.text.trim().length < 5
          ? 'admin.errors.reason_required'.tr()
          : null;
    });
    if (_passwordError != null || _reasonError != null) return;

    Navigator.of(
      context,
    ).pop((password: _password.text, reason: _reason.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return AdminFormDialog(
      title: 'admin.staff.set_password'.tr(),
      subtitle: 'admin.staff.password_hint'.tr(args: [widget.name]),
      confirmLabel: 'admin.common.confirm'.tr(),
      onConfirm: _submit,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AdminField(
                controller: _password,
                label: 'admin.staff.new_password'.tr(),
                errorText: _passwordError,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 26, left: AgSpace.x2),
              child: IconButton(
                tooltip: 'admin.staff.generate'.tr(),
                onPressed: () =>
                    setState(() => _password.text = _generatePassword()),
                icon: Icon(Icons.refresh, size: 18, color: c.textSecondary),
              ),
            ),
          ],
        ),
        AdminField(
          controller: _reason,
          label: 'admin.common.reason_required'.tr(),
          errorText: _reasonError,
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}

/// Yaratilgan akkaunt ma'lumotlari — bir marta ko'rsatiladi.
class _CredentialsDialog extends StatelessWidget {
  const _CredentialsDialog({required this.email, required this.password});

  final String email;
  final String password;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final text = '$email\n$password';

    return AdminFormDialog(
      title: 'admin.staff.created_title'.tr(),
      subtitle: 'admin.staff.created_hint'.tr(),
      confirmLabel: 'admin.staff.copy'.tr(),
      showCancel: false,
      onConfirm: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) Navigator.of(context).pop();
      },
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AgSpace.x4),
          decoration: BoxDecoration(
            color: c.surfaceSunken,
            borderRadius: AgRadius.rMd,
          ),
          child: SelectableText(
            text,
            style: AppTypography.body.copyWith(color: c.text),
          ),
        ),
      ],
    );
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
