import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/rbac/permission.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../ui/agro_mark.dart';
import '../../auth/cubit/admin_auth_cubit.dart';
import '../nav_items.dart';

/// Chapdagi navigatsiya paneli.
///
/// Yig'iladi (`collapsed`) — jadval ekranlari uchun kenglik qimmatli.
class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.collapsed,
    required this.onToggle,
    required this.currentRoute,
  });

  final bool collapsed;
  final VoidCallback onToggle;
  final String currentRoute;

  static const expandedWidth = 240.0;
  static const collapsedWidth = 64.0;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final perms = context.select<AdminAuthCubit, AdminPermissions>(
      (cubit) => cubit.state.permissions,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: collapsed ? collapsedWidth : expandedWidth,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(right: BorderSide(color: c.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(collapsed: collapsed, onToggle: onToggle, colors: c),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AgSpace.x3),
              children: [
                for (final group in adminNavigation) ...[
                  if (!collapsed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AgSpace.x4,
                        AgSpace.x3,
                        AgSpace.x4,
                        AgSpace.x2,
                      ),
                      child: Text(
                        group.titleKey.tr().toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: c.textTertiary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  for (final item in group.items)
                    if (item.visibleFor(perms))
                      _NavTile(
                        icon: item.icon,
                        label: item.labelKey.tr(),
                        selected: currentRoute.startsWith(item.route),
                        collapsed: collapsed,
                        colors: c,
                        onTap: () => context.go(item.route),
                      ),
                ],

                // Rejadagi modullar — ish hajmi ko'rinib tursin. Ular
                // bosilmaydi, chunki hali ekran yo'q; "ishlamayapti" degan
                // taassurot qolmasligi uchun alohida ajratilgan.
                if (!collapsed) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AgSpace.x4,
                      AgSpace.x6,
                      AgSpace.x4,
                      AgSpace.x2,
                    ),
                    child: Text(
                      'admin.nav.coming_soon'.tr().toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: c.textTertiary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  for (final (labelKey, icon, permission) in plannedModules)
                    if (perms.has(permission))
                      _NavTile(
                        icon: icon,
                        label: labelKey.tr(),
                        selected: false,
                        collapsed: collapsed,
                        colors: c,
                        disabled: true,
                        onTap: null,
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.collapsed,
    required this.onToggle,
    required this.colors,
  });

  final bool collapsed;
  final VoidCallback onToggle;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AgSpace.x4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          const AgroMark(size: 28),
          if (!collapsed) ...[
            const SizedBox(width: AgSpace.x3),
            Expanded(
              child: Text(
                'AgroBill',
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h3.copyWith(color: colors.text),
              ),
            ),
          ],
          IconButton(
            onPressed: onToggle,
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              collapsed ? Icons.chevron_right : Icons.chevron_left,
              color: colors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.collapsed,
    required this.colors,
    required this.onTap,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool collapsed;
  final AppColors colors;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final fg = widget.disabled
        ? c.textDisabled
        : widget.selected
        ? c.textBrand
        : c.textSecondary;

    final tile = Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: AgSpace.x2, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: AgSpace.x3),
      decoration: BoxDecoration(
        color: widget.selected
            ? c.surfaceBrand
            : (_hovered && !widget.disabled)
            ? c.surfaceSunken
            : Colors.transparent,
        borderRadius: AgRadius.rSm,
      ),
      child: Row(
        children: [
          Icon(widget.icon, size: 18, color: fg),
          if (!widget.collapsed) ...[
            const SizedBox(width: AgSpace.x3),
            Expanded(
              child: Text(
                widget.label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(color: fg),
              ),
            ),
          ],
        ],
      ),
    );

    return MouseRegion(
      cursor: widget.disabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: widget.collapsed
            ? Tooltip(message: widget.label, child: tile)
            : tile,
      ),
    );
  }
}
