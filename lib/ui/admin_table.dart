import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/result.dart';
import 'admin_button.dart';
import 'admin_feedback.dart';

/// Ustun ta'rifi.
class AdminColumn<T> {
  const AdminColumn({
    required this.labelKey,
    required this.build,
    this.width,
    this.flex = 1,
    this.align = Alignment.centerLeft,
  });

  final String labelKey;
  final Widget Function(T row) build;

  /// Qat'iy kenglik. Berilmasa `flex` ishlaydi.
  final double? width;
  final int flex;
  final Alignment align;
}

/// Zich desktop jadvali.
///
/// Flutter'ning `DataTable` i ishlatilmadi: u har bir qatorni o'lchaydi va
/// yuzlab qatorda sezilarli sekinlashadi, ustun kengligini boshqarish esa
/// noqulay. Bu yerda oddiy `Row` + `ListView.builder` — virtualizatsiya
/// tekin keladi.
///
/// TTZ §10 dagi olti holat shu vidjetda: yuklanmoqda · muvaffaqiyat ·
/// bo'sh · xato · qayta urinish. Oltinchisi ("ruxsat yo'q") `PermissionGuard`
/// darajasida hal qilinadi — jadvalga umuman yetib kelinmaydi.
class AdminTable<T> extends StatelessWidget {
  const AdminTable({
    super.key,
    required this.columns,
    required this.rows,
    this.loading = false,
    this.failure,
    this.onRetry,
    this.onRowTap,
    this.emptyTitle,
    this.emptyHint,
  });

  final List<AdminColumn<T>> columns;
  final List<T> rows;
  final bool loading;
  final AppFailure? failure;
  final VoidCallback? onRetry;
  final void Function(T row)? onRowTap;
  final String? emptyTitle;
  final String? emptyHint;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AgRadius.rLg,
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _HeaderRow(columns: columns, colors: c),
          Expanded(child: _body(c)),
        ],
      ),
    );
  }

  Widget _body(AppColors c) {
    if (failure != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AgSpace.x7),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AdminErrorBanner(failure: failure!, onRetry: onRetry),
          ),
        ),
      );
    }

    // Qayta yuklashda eski qatorlar ustida spinner — jadval bo'shab
    // ketmasin, aks holda filtr o'zgarganda ekran miltillaydi.
    if (loading && rows.isEmpty) return const AdminLoading();

    if (rows.isEmpty) {
      return _Empty(title: emptyTitle, hint: emptyHint, colors: c);
    }

    return Stack(
      children: [
        ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, i) => _DataRow<T>(
            row: rows[i],
            columns: columns,
            colors: c,
            onTap: onRowTap == null ? null : () => onRowTap!(rows[i]),
          ),
        ),
        if (loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _HeaderRow<T> extends StatelessWidget {
  const _HeaderRow({required this.columns, required this.colors});

  final List<AdminColumn<T>> columns;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: AgSpace.x4),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          for (final col in columns)
            _cell(
              col,
              Text(
                col.labelKey.tr(),
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(AdminColumn<T> col, Widget child) {
    final content = Align(alignment: col.align, child: child);
    return col.width != null
        ? SizedBox(width: col.width, child: content)
        : Expanded(flex: col.flex, child: content);
  }
}

class _DataRow<T> extends StatefulWidget {
  const _DataRow({
    required this.row,
    required this.columns,
    required this.colors,
    required this.onTap,
  });

  final T row;
  final List<AdminColumn<T>> columns;
  final AppColors colors;
  final VoidCallback? onTap;

  @override
  State<_DataRow<T>> createState() => _DataRowState<T>();
}

class _DataRowState<T> extends State<_DataRow<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AgSpace.x4),
          decoration: BoxDecoration(
            color: _hovered ? c.surfaceSunken : Colors.transparent,
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              for (final col in widget.columns)
                if (col.width != null)
                  SizedBox(
                    width: col.width,
                    child: Align(
                      alignment: col.align,
                      child: col.build(widget.row),
                    ),
                  )
                else
                  Expanded(
                    flex: col.flex,
                    child: Align(
                      alignment: col.align,
                      child: col.build(widget.row),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.hint, required this.colors});

  final String? title;
  final String? hint;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 28, color: colors.textTertiary),
          const SizedBox(height: AgSpace.x3),
          Text(
            title ?? 'admin.common.empty'.tr(),
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          if (hint != null) ...[
            const SizedBox(height: AgSpace.x1),
            Text(
              hint!,
              style: AppTypography.caption.copyWith(color: colors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sahifalash boshqaruvi.
///
/// Umumiy sonni PostgREST `count: exact` bilan olish katta jadvalda qimmat,
/// shuning uchun "keyingi sahifa bormi" oddiy usulda aniqlanadi: `pageSize + 1`
/// qator so'raladi, ortiqchasi ko'rsatilmaydi.
class AdminPagination extends StatelessWidget {
  const AdminPagination({
    super.key,
    required this.page,
    required this.hasMore,
    required this.onChanged,
    this.loading = false,
  });

  final int page;
  final bool hasMore;
  final ValueChanged<int> onChanged;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'admin.common.page'.tr(args: ['${page + 1}']),
          style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
        ),
        const SizedBox(width: AgSpace.x4),
        AdminButton(
          label: 'admin.common.prev'.tr(),
          kind: AdminButtonKind.secondary,
          icon: Icons.chevron_left,
          onPressed: (page > 0 && !loading) ? () => onChanged(page - 1) : null,
        ),
        const SizedBox(width: AgSpace.x2),
        AdminButton(
          label: 'admin.common.next'.tr(),
          kind: AdminButtonKind.secondary,
          onPressed: (hasMore && !loading) ? () => onChanged(page + 1) : null,
        ),
      ],
    );
  }
}
