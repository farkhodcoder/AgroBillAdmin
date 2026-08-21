import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';

/// Tugma turlari.
///
/// `danger` alohida: bloklash, o'chirish, bekor qilish kabi qaytarib
/// bo'lmaydigan amallar ko'rinishidan ham ajralib turishi kerak.
enum AdminButtonKind { primary, secondary, ghost, danger }

enum AdminButtonSize { medium, large }

/// Admin panelining asosiy tugmasi.
///
/// Mobil ilovadagi `AgButton` ko'chirilmadi — u sensorli ekran uchun
/// (52 px balandlik, keng padding). Desktop jadval interfeysida tugmalar
/// zichroq va hover holati bo'lishi kerak.
class AdminButton extends StatefulWidget {
  const AdminButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = AdminButtonKind.primary,
    this.size = AdminButtonSize.medium,
    this.icon,
    this.busy = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AdminButtonKind kind;
  final AdminButtonSize size;
  final IconData? icon;

  /// Yuklanmoqda — tugma bloklanadi va spinner ko'rsatiladi.
  final bool busy;

  /// Mavjud kenglikni to'liq egallaydi (forma tugmalari).
  final bool expand;

  @override
  State<AdminButton> createState() => _AdminButtonState();
}

class _AdminButtonState extends State<AdminButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final enabled = widget.onPressed != null && !widget.busy;
    final height = widget.size == AdminButtonSize.large ? 44.0 : 36.0;
    final padding = widget.size == AdminButtonSize.large
        ? AgSpace.x5
        : AgSpace.x4;

    final (bg, fg, border) = _colors(c, enabled);

    final child = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.busy)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: 16, color: fg),
        if (widget.busy || widget.icon != null)
          const SizedBox(width: AgSpace.x2),
        Text(widget.label, style: AppTypography.button.copyWith(color: fg)),
      ],
    );

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: height,
          padding: EdgeInsets.symmetric(horizontal: padding),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AgRadius.rMd,
            border: border == null ? null : Border.all(color: border),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  /// (fon, matn, chegara) — holatga qarab.
  (Color, Color, Color?) _colors(AppColors c, bool enabled) {
    if (!enabled) {
      return switch (widget.kind) {
        AdminButtonKind.ghost => (
          Colors.transparent,
          c.textDisabled,
          Colors.transparent,
        ),
        _ => (c.actionDisabled, c.actionDisabledText, null),
      };
    }

    return switch (widget.kind) {
      AdminButtonKind.primary => (
        _hovered ? c.actionPrimaryHover : c.actionPrimary,
        c.actionPrimaryText,
        null,
      ),
      AdminButtonKind.secondary => (
        _hovered ? c.surfaceSunken : c.surface,
        c.actionSecondaryText,
        c.border,
      ),
      AdminButtonKind.ghost => (
        _hovered ? c.surfaceSunken : Colors.transparent,
        c.textSecondary,
        Colors.transparent,
      ),
      AdminButtonKind.danger => (
        _hovered ? c.errorText : c.error,
        Colors.white,
        null,
      ),
    };
  }
}
