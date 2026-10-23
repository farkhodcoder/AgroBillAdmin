import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/formatters.dart';
import 'admin_button.dart';
import 'admin_field.dart';

/// Holat belgisi (e'lon holati, buyurtma holati, bloklangan va h.k.).
enum BadgeTone { neutral, success, warning, danger, info, brand }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.neutral,
  });

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final (bg, fg) = switch (tone) {
      BadgeTone.success => (c.successBg, c.successText),
      BadgeTone.warning => (c.warningBg, c.warningText),
      BadgeTone.danger => (c.errorBg, c.errorText),
      BadgeTone.info => (c.infoBg, c.infoText),
      BadgeTone.brand => (c.surfaceBrand, c.textBrand),
      BadgeTone.neutral => (c.surfaceSunken, c.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AgSpace.x2, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: AgRadius.rXs),
      child: Text(label, style: AppTypography.caption.copyWith(color: fg)),
    );
  }
}

/// Sahifa sarlavhasi va o'ngdagi amallar.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.h2.copyWith(color: c.text)),
              if (subtitle != null) ...[
                const SizedBox(height: AgSpace.x1),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

/// Qidiruv maydoni — yozishni to'xtatgach ishga tushadi.
///
/// Har bosilgan harfda so'rov yuborish sekundiga bir necha marta bazaga
/// murojaat qilardi va natijalar tartibsiz kelib, ekran sakrardi.
class AdminSearchField extends StatefulWidget {
  const AdminSearchField({
    super.key,
    required this.onChanged,
    this.hintKey = 'admin.common.search',
    this.width = 280,
  });

  final ValueChanged<String> onChanged;
  final String hintKey;
  final double width;

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  final _controller = TextEditingController();
  String _last = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_schedule);
  }

  void _schedule() {
    final value = _controller.text.trim();
    if (value == _last) return;
    _last = value;

    // 350 ms — odam yozishni to'xtatganini bildiradigan eng qisqa oraliq.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (_controller.text.trim() == value) widget.onChanged(value);
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_schedule)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: AdminField(
        controller: _controller,
        label: '',
        hint: widget.hintKey.tr(),
        reserveErrorSpace: false,
      ),
    );
  }
}

/// Ochiladigan filtr.
class AdminSelect<T> extends StatelessWidget {
  const AdminSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hintKey,
    this.width = 180,
    this.allLabelKey = 'admin.common.all',
  });

  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;
  final String hintKey;
  final double width;

  /// `null` qiymatning yozuvi. Odatda "Hammasi", lekin ba'zi filtrlarda
  /// `null` boshqa ma'noga ega (masalan support'da — faqat faol navbat).
  final String allLabelKey;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        style: AppTypography.bodySmall.copyWith(color: c.text),
        dropdownColor: c.surface,
        hint: Text(
          hintKey.tr(),
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(color: c.textTertiary),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: c.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AgSpace.x3,
            vertical: AgSpace.x3,
          ),
          border: OutlineInputBorder(
            borderRadius: AgRadius.rMd,
            borderSide: BorderSide(color: c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AgRadius.rMd,
            borderSide: BorderSide(color: c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AgRadius.rMd,
            borderSide: BorderSide(color: c.borderFocus, width: 2),
          ),
        ),
        items: [
          DropdownMenuItem<T>(
            child: Text(
              allLabelKey.tr(),
              style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
            ),
          ),
          for (final (item, label) in items)
            DropdownMenuItem<T>(
              value: item,
              child: Text(label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// Tasdiq oynasining natijasi.
///
/// `String?` yetarli emas edi: `null` ham «bekor qilindi», ham «sababsiz
/// tasdiqlandi» degani bo'lib chiqardi. Sabab ixtiyoriy bo'lgan amallarda
/// (masalan e'lonni tasdiqlash) bu ikkisini ajratib bo'lmaydi va chaqiruvchi
/// kod taxmin qilishga majbur bo'lardi.
typedef ReasonResult = ({bool confirmed, String? reason});

const _cancelled = (confirmed: false, reason: null);

/// Tasdiq oynasi — sabab maydoni bilan.
///
/// TTZ §10: buzuvchi amal doim tasdiq so'raydi. Sabab majburiy bo'lsa, u
/// baza tomonida ham tekshiriladi (`REASON_REQUIRED`) — bu yerdagi
/// validatsiya faqat foydalanuvchini keraksiz so'rovdan qutqaradi.
Future<ReasonResult> showReasonDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool reasonRequired = true,
  bool danger = true,
}) async {
  final result = await showDialog<ReasonResult>(
    context: context,
    builder: (context) => _ReasonDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      reasonRequired: reasonRequired,
      danger: danger,
    ),
  );
  // Tashqariga bosib yopilsa `showDialog` `null` qaytaradi — bu bekor
  // qilish bilan bir xil.
  return result ?? _cancelled;
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.reasonRequired,
    required this.danger,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool reasonRequired;
  final bool danger;

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final text = _reason.text.trim();
    // Baza 5 ta belgidan qisqa sababni rad etadi (0010 dagi RPC lar).
    if (widget.reasonRequired && text.length < 5) {
      setState(() => _error = 'admin.errors.reason_required'.tr());
      return;
    }
    Navigator.of(
      context,
    ).pop((confirmed: true, reason: text.isEmpty ? null : text));
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: AgRadius.rLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AgSpace.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: AppTypography.h3.copyWith(color: c.text),
              ),
              const SizedBox(height: AgSpace.x2),
              Text(
                widget.message,
                style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AgSpace.x5),
              AdminField(
                controller: _reason,
                label: widget.reasonRequired
                    ? 'admin.common.reason_required'.tr()
                    : 'admin.common.reason_optional'.tr(),
                autofocus: true,
                errorText: _error,
                onSubmitted: (_) => _confirm(),
              ),
              const SizedBox(height: AgSpace.x4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AdminButton(
                    label: 'admin.common.cancel'.tr(),
                    kind: AdminButtonKind.ghost,
                    onPressed: () => Navigator.of(context).pop(_cancelled),
                  ),
                  const SizedBox(width: AgSpace.x2),
                  AdminButton(
                    label: widget.confirmLabel,
                    kind: widget.danger
                        ? AdminButtonKind.danger
                        : AdminButtonKind.primary,
                    onPressed: _confirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Forma oynasining umumiy qobig'i: sarlavha, izoh, maydonlar, tugmalar.
///
/// Har bir modul o'z `Dialog` + `Padding` + tugmalar qatorini yozsa, oynalar
/// bir-biridan kenglik va oraliqda farq qilib qolardi.
class AdminFormDialog extends StatelessWidget {
  const AdminFormDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    required this.children,
    this.subtitle,
    this.showCancel = true,
    this.maxWidth = 480,
    this.busy = false,
  });

  final String title;
  final String? subtitle;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final List<Widget> children;
  final bool showCancel;
  final double maxWidth;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: AgRadius.rLg),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AgSpace.x6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: AppTypography.h3.copyWith(color: c.text)),
              if (subtitle != null) ...[
                const SizedBox(height: AgSpace.x2),
                Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AgSpace.x5),
              ...children,
              const SizedBox(height: AgSpace.x2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (showCancel) ...[
                    AdminButton(
                      label: 'admin.common.cancel'.tr(),
                      kind: AdminButtonKind.ghost,
                      onPressed: busy
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AgSpace.x2),
                  ],
                  AdminButton(
                    label: confirmLabel,
                    busy: busy,
                    onPressed: onConfirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O'ng tomondan chiqadigan tafsilot paneli — fon qoraytiriladi, tashqariga
/// bosilsa yopiladi.
///
/// `Stack` ichida, sahifa kontentidan KEYIN qo'yiladi. [footer] — pastda
/// qotib turadigan qism (javob maydoni, amal tugmalari); u [body] bilan
/// birga aylanmaydi.
class AdminSidePanel extends StatelessWidget {
  const AdminSidePanel({
    super.key,
    required this.title,
    required this.onClose,
    required this.body,
    this.subtitle,
    this.badges = const [],
    this.footer,
    this.width = 540,
  });

  final String title;
  final String? subtitle;
  final List<Widget> badges;
  final VoidCallback onClose;
  final Widget body;
  final Widget? footer;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: c.surface,
              elevation: 8,
              child: SizedBox(
                width: width,
                height: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AgSpace.x6),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: c.border)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: AppTypography.h3.copyWith(
                                    color: c.text,
                                  ),
                                ),
                                if (subtitle != null) ...[
                                  const SizedBox(height: AgSpace.x1),
                                  Text(
                                    subtitle!,
                                    style: AppTypography.caption.copyWith(
                                      color: c.textTertiary,
                                    ),
                                  ),
                                ],
                                if (badges.isNotEmpty) ...[
                                  const SizedBox(height: AgSpace.x2),
                                  Wrap(
                                    spacing: AgSpace.x1,
                                    runSpacing: AgSpace.x1,
                                    children: badges,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: onClose,
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: c.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: body),
                    if (footer != null)
                      Container(
                        padding: const EdgeInsets.all(AgSpace.x5),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: c.border)),
                        ),
                        child: footer,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel ichidagi sarlavha + matn bloki.
class AdminFactBlock extends StatelessWidget {
  const AdminFactBlock({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AgSpace.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AgSpace.x2),
          child,
        ],
      ),
    );
  }
}

/// Yozishma pufakchasi. [mine] — chap tomonda foydalanuvchi, o'ngda javob
/// beruvchi (AI yoki xodim). Support moduli ham shu tartibda.
class AdminChatBubble extends StatelessWidget {
  const AdminChatBubble({
    super.key,
    required this.text,
    required this.time,
    required this.mine,
    required this.label,
    required this.colors,
    this.highlighted = false,
  });

  final String text;
  final DateTime time;
  final bool mine;
  final String label;
  final AppColors colors;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(AgSpace.x4),
          decoration: BoxDecoration(
            color: mine ? colors.surfaceSunken : colors.surfaceBrand,
            borderRadius: AgRadius.rMd,
            border: highlighted
                ? Border.all(color: colors.borderFocus, width: 1.5)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label · ${Fmt.dateTime(time)}',
                style: AppTypography.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
              const SizedBox(height: AgSpace.x1),
              SelectableText(
                text,
                style: AppTypography.bodySmall.copyWith(color: colors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
