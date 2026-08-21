import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';

/// Matn maydoni.
///
/// Xato matni maydonning OSTIDA turadi va joyni doim egallaydi (`errorText`
/// null bo'lsa ham balandlik saqlanadi) — aks holda xato chiqqanda forma
/// sakrab ketardi va foydalanuvchi bosayotgan tugma joyidan siljirdi.
class AdminField extends StatelessWidget {
  const AdminField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.errorText,
    this.autofocus = false,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.style,
    this.onSubmitted,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final String? errorText;
  final bool autofocus;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextStyle? style;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AgSpace.x2),
        TextField(
          controller: controller,
          obscureText: obscure,
          autofocus: autofocus,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textAlign: textAlign,
          maxLength: maxLength,
          onSubmitted: onSubmitted,
          style: (style ?? AppTypography.body).copyWith(color: c.text),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: AppTypography.body.copyWith(color: c.textTertiary),
            filled: true,
            fillColor: enabled ? c.surface : c.surfaceSunken,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AgSpace.x4,
              vertical: AgSpace.x3,
            ),
            border: OutlineInputBorder(
              borderRadius: AgRadius.rMd,
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AgRadius.rMd,
              borderSide: BorderSide(color: hasError ? c.error : c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AgRadius.rMd,
              borderSide: BorderSide(
                color: hasError ? c.error : c.borderFocus,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: AgRadius.rMd,
              borderSide: BorderSide(color: c.border),
            ),
          ),
        ),
        // Balandlik doim band — xato chiqqanda forma sakramaydi.
        SizedBox(
          height: 20,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: AgSpace.x1),
                  child: Text(
                    errorText!,
                    style: AppTypography.caption.copyWith(color: c.errorText),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
