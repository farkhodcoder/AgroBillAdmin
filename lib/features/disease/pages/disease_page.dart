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
import '../../../data/models/admin_ai.dart';
import '../../../data/repositories/admin_ai_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_field.dart';
import '../../../ui/admin_table.dart';
import '../cubit/disease_cubit.dart';

BadgeTone contentTone(String status) => switch (status) {
  ContentStatus.published => BadgeTone.success,
  ContentStatus.review => BadgeTone.warning,
  ContentStatus.draft => BadgeTone.neutral,
  ContentStatus.archived => BadgeTone.neutral,
  _ => BadgeTone.neutral,
};

/// Kasallik ma'lumotnomasi (TTZ §6.7).
class DiseasePage extends StatelessWidget {
  const DiseasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.diseaseRead,
      child: BlocProvider(
        create: (_) => DiseaseCubit(
          getIt<AdminAiRepository>(),
          context.locale.languageCode,
        )..init(),
        child: const _DiseaseView(),
      ),
    );
  }
}

class _DiseaseView extends StatelessWidget {
  const _DiseaseView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocConsumer<DiseaseCubit, DiseaseState>(
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
        final cubit = context.read<DiseaseCubit>();

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AgSpace.x7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPageHeader(
                    title: 'admin.nav.disease'.tr(),
                    subtitle: 'admin.disease.subtitle'.tr(),
                    actions: [
                      PermissionGuard(
                        permission: AdminPermission.diseaseWrite,
                        fallback: const SizedBox.shrink(),
                        child: AdminButton(
                          label: 'admin.disease.add'.tr(),
                          icon: Icons.add,
                          onPressed: () => _openEditor(context, null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AgSpace.x5),

                  if (state.untranslatedCount > 0) ...[
                    AdminNote(
                      text: 'admin.disease.untranslated'.tr(
                        args: ['${state.untranslatedCount}'],
                      ),
                      icon: Icons.translate_outlined,
                    ),
                    const SizedBox(height: AgSpace.x4),
                  ],

                  Wrap(
                    spacing: AgSpace.x3,
                    runSpacing: AgSpace.x3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AdminSearchField(
                        hintKey: 'admin.disease.search_hint',
                        onChanged: cubit.setSearch,
                      ),
                      AdminSelect<String>(
                        value: state.status,
                        hintKey: 'admin.disease.filter_status',
                        width: 190,
                        items: [
                          for (final s in ContentStatus.all)
                            (s, 'admin.content_status.$s'.tr()),
                        ],
                        onChanged: cubit.setStatus,
                      ),
                    ],
                  ),
                  const SizedBox(height: AgSpace.x4),

                  Expanded(
                    child: AdminTable<DiseaseRow>(
                      rows: state.rows,
                      loading: state.loading,
                      failure: state.failure,
                      onRetry: cubit.load,
                      emptyTitle: 'admin.disease.empty'.tr(),
                      onRowTap: (row) => cubit.select(row.id),
                      columns: _columns(c),
                    ),
                  ),
                ],
              ),
            ),

            if (state.selected != null)
              _DetailPanel(
                disease: state.selected!,
                onClose: cubit.closeDetail,
              ),
          ],
        );
      },
    );
  }

  List<AdminColumn<DiseaseRow>> _columns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.disease.col_name',
      flex: 3,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.nameUz,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            row.latinName ?? row.code,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: c.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.disease.col_crop',
      flex: 2,
      build: (row) => Text(
        row.cropName ?? '—',
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.disease.col_content',
      width: 150,
      build: (row) => Text(
        'admin.disease.counts'.tr(
          args: ['${row.symptomCount}', '${row.treatmentCount}'],
        ),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.disease.col_status',
      width: 170,
      build: (row) => Wrap(
        spacing: AgSpace.x1,
        children: [
          StatusBadge(
            label: 'admin.content_status.${row.status}'.tr(),
            tone: contentTone(row.status),
          ),
          if (!row.isTranslated)
            StatusBadge(
              label: 'admin.disease.partial'.tr(),
              tone: BadgeTone.warning,
            ),
        ],
      ),
    ),
  ];
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.disease, required this.onClose});

  final DiseaseRow disease;
  final VoidCallback onClose;

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
              child: SizedBox(
                width: 520,
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
                                  disease.nameUz,
                                  style: AppTypography.h3.copyWith(
                                    color: c.text,
                                  ),
                                ),
                                const SizedBox(height: AgSpace.x1),
                                Text(
                                  disease.latinName ?? disease.code,
                                  style: AppTypography.caption.copyWith(
                                    color: c.textTertiary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
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
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AgSpace.x6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _names(c),
                            const SizedBox(height: AgSpace.x5),
                            _text(
                              c,
                              'admin.disease.description',
                              disease.description,
                            ),
                            _text(c, 'admin.disease.causes', disease.causes),
                            _text(
                              c,
                              'admin.disease.prevention',
                              disease.prevention,
                            ),
                            _DiseaseBody(disease: disease, colors: c),
                            const SizedBox(height: AgSpace.x5),
                            _StatusActions(disease: disease),
                          ],
                        ),
                      ),
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

  Widget _names(AppColors c) => Column(
    children: [
      for (final (label, value) in [
        ('UZ', disease.nameUz),
        ('RU', disease.nameRu),
        ('EN', disease.nameEn),
        ('ID', '${disease.id} · ${disease.code}'),
        if (disease.updatedAt != null)
          ('admin.disease.updated', Fmt.dateTime(disease.updatedAt)),
      ])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AgSpace.x1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  label.startsWith('admin.') ? label.tr() : label,
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
              ),
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: AppTypography.bodySmall.copyWith(
                    color: value.isEmpty ? c.warningText : c.text,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );

  Widget _text(AppColors c, String labelKey, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AgSpace.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelKey.tr(),
            style: AppTypography.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AgSpace.x1),
          Text(value, style: AppTypography.bodySmall.copyWith(color: c.text)),
        ],
      ),
    );
  }
}

class _StatusActions extends StatelessWidget {
  const _StatusActions({required this.disease});

  final DiseaseRow disease;

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.diseaseWrite,
      fallback: const SizedBox.shrink(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'admin.disease.change_status'.tr(),
            style: AppTypography.label.copyWith(
              color: Theme.of(context).extension<AppColors>()!.textSecondary,
            ),
          ),
          const SizedBox(height: AgSpace.x3),
          Wrap(
            spacing: AgSpace.x2,
            runSpacing: AgSpace.x2,
            children: [
              for (final status in ContentStatus.all)
                AdminButton(
                  label: 'admin.content_status.$status'.tr(),
                  kind: disease.status == status
                      ? AdminButtonKind.primary
                      : AdminButtonKind.secondary,
                  // Joriy holatga qayta o'tkazish ma'nosiz — tugma o'chiq.
                  onPressed: disease.status == status
                      ? null
                      : () => context.read<DiseaseCubit>().setStatusOf(
                          disease.id,
                          status,
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _openEditor(BuildContext context, DiseaseRow? row) async {
  final cubit = context.read<DiseaseCubit>();

  final draft = await showDialog<DiseaseDraft>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DiseaseEditor(row: row, crops: cubit.state.crops),
  );
  if (draft == null) return;

  final ok = await cubit.save(row?.id, draft);
  if (!ok || !context.mounted) return;

  final c = Theme.of(context).extension<AppColors>()!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: c.successBg,
      content: Text(
        row == null ? 'admin.disease.created'.tr() : 'admin.disease.saved'.tr(),
        style: AppTypography.bodySmall.copyWith(color: c.successText),
      ),
    ),
  );
}

/// Alomatlar va davolash qadamlari — panelda o'qish uchun.
class _DiseaseBody extends StatelessWidget {
  const _DiseaseBody({required this.disease, required this.colors});

  final DiseaseRow disease;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodySmall.copyWith(color: colors.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (disease.symptoms.isNotEmpty)
          AdminFactBlock(
            label: 'admin.disease.symptoms'.tr(),
            child: Text(
              disease.symptoms.map((s) => '•  $s').join('\n'),
              style: style,
            ),
          ),
        if (disease.treatments.isNotEmpty)
          AdminFactBlock(
            label: 'admin.disease.treatments'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, t) in disease.treatments.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AgSpace.x2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}. ${t.title}', style: style),
                        if (t.detail.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: AgSpace.x4),
                            child: Text(
                              t.detail,
                              style: AppTypography.caption.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        PermissionGuard(
          permission: AdminPermission.diseaseWrite,
          fallback: const SizedBox.shrink(),
          child: AdminButton(
            label: 'admin.disease.edit'.tr(),
            icon: Icons.edit_outlined,
            kind: AdminButtonKind.secondary,
            onPressed: () => _openEditor(context, disease),
          ),
        ),
      ],
    );
  }
}

/// Kasallik maqolasi muharriri — uch tilda nom, tavsif, alomatlar va
/// davolash qadamlari.
///
/// Yangi yozuv `draft` bo'lib yaratiladi va mobil ilovada ko'rinmaydi:
/// nashr — alohida, ongli qadam (`admin_publish_disease`, auditga tushadi).
class _DiseaseEditor extends StatefulWidget {
  const _DiseaseEditor({required this.row, required this.crops});

  final DiseaseRow? row;
  final List<CropOption> crops;

  @override
  State<_DiseaseEditor> createState() => _DiseaseEditorState();
}

class _DiseaseEditorState extends State<_DiseaseEditor> {
  late final _code = TextEditingController(text: widget.row?.code);
  late final _latin = TextEditingController(text: widget.row?.latinName);
  late final _nameUz = TextEditingController(text: widget.row?.nameUz);
  late final _nameRu = TextEditingController(text: widget.row?.nameRu);
  late final _nameEn = TextEditingController(text: widget.row?.nameEn);
  late final _description = TextEditingController(
    text: widget.row?.description,
  );
  late final _causes = TextEditingController(text: widget.row?.causes);
  late final _prevention = TextEditingController(text: widget.row?.prevention);
  late final _symptoms = TextEditingController(
    text: widget.row?.symptoms.join('\n'),
  );
  late final List<(TextEditingController, TextEditingController)> _steps = [
    for (final t in widget.row?.treatments ?? const <TreatmentStep>[])
      (
        TextEditingController(text: t.title),
        TextEditingController(text: t.detail),
      ),
  ];
  late int? _cropId = widget.row?.cropTypeId;
  final _errors = <String, String>{};

  /// `code` — mobil ilova va AI javoblari shu kalit orqali bog'lanadi,
  /// shuning uchun faqat lotin kichik harf, raqam va `_`.
  static final _codeRe = RegExp(r'^[a-z0-9_]{3,60}$');

  @override
  void dispose() {
    for (final c in [
      _code,
      _latin,
      _nameUz,
      _nameRu,
      _nameEn,
      _description,
      _causes,
      _prevention,
      _symptoms,
    ]) {
      c.dispose();
    }
    for (final (a, b) in _steps) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  void _submit() {
    setState(() {
      _errors.clear();
      if (!_codeRe.hasMatch(_code.text.trim())) {
        _errors['code'] = 'admin.disease.code_invalid'.tr();
      }
      if (_nameUz.text.trim().length < 2) {
        _errors['name_uz'] = 'admin.disease.name_required'.tr();
      }
    });
    if (_errors.isNotEmpty) return;

    Navigator.of(context).pop(
      DiseaseDraft(
        code: _code.text,
        nameUz: _nameUz.text,
        nameRu: _nameRu.text,
        nameEn: _nameEn.text,
        cropTypeId: _cropId,
        latinName: _latin.text,
        description: _description.text,
        causes: _causes.text,
        prevention: _prevention.text,
        symptoms: [
          for (final line in _symptoms.text.split('\n'))
            if (line.trim().isNotEmpty) line.trim(),
        ],
        treatments: [
          for (final (title, detail) in _steps)
            if (title.text.trim().isNotEmpty)
              TreatmentStep(
                title: title.text.trim(),
                detail: detail.text.trim(),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: AgSpace.x3),
        Expanded(child: b),
      ],
    );

    final names = [
      ('UZ', _nameUz, _errors['name_uz']),
      ('RU', _nameRu, null),
      ('EN', _nameEn, null),
    ];

    return AdminFormDialog(
      title: widget.row == null
          ? 'admin.disease.add'.tr()
          : 'admin.disease.edit'.tr(),
      subtitle: widget.row == null ? 'admin.disease.add_hint'.tr() : null,
      confirmLabel: 'admin.disease.save'.tr(),
      maxWidth: 760,
      onConfirm: _submit,
      children: [
        pair(
          AdminField(
            controller: _code,
            label: 'admin.disease.code'.tr(),
            hint: 'wheat_leaf_rust',
            // Kod bog'lanish kaliti — yaratilgandan keyin o'zgarmaydi.
            enabled: widget.row == null,
            errorText: _errors['code'],
          ),
          AdminField(
            controller: _latin,
            label: 'admin.disease.latin'.tr(),
            hint: 'Puccinia triticina',
          ),
        ),
        Text(
          'admin.disease.col_crop'.tr(),
          style: AppTypography.label.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AgSpace.x2),
        AdminSelect<int>(
          value: _cropId,
          hintKey: 'admin.disease.col_crop',
          width: 320,
          items: [for (final crop in widget.crops) (crop.id, crop.name)],
          onChanged: (v) => setState(() => _cropId = v),
        ),
        const SizedBox(height: AgSpace.x4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, (lang, ctrl, err)) in names.indexed) ...[
              if (i > 0) const SizedBox(width: AgSpace.x3),
              Expanded(
                child: AdminField(
                  controller: ctrl,
                  label: '${'admin.disease.col_name'.tr()} · $lang',
                  errorText: err,
                ),
              ),
            ],
          ],
        ),
        AdminField(
          controller: _description,
          label: 'admin.disease.description'.tr(),
          maxLines: 4,
          minLines: 2,
        ),
        pair(
          AdminField(
            controller: _causes,
            label: 'admin.disease.causes'.tr(),
            maxLines: 4,
            minLines: 2,
          ),
          AdminField(
            controller: _prevention,
            label: 'admin.disease.prevention'.tr(),
            maxLines: 4,
            minLines: 2,
          ),
        ),
        AdminField(
          controller: _symptoms,
          label: 'admin.disease.symptoms_hint'.tr(),
          maxLines: 6,
          minLines: 3,
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'admin.disease.treatments'.tr(),
                style: AppTypography.label.copyWith(color: c.textSecondary),
              ),
            ),
            AdminButton(
              label: 'admin.disease.add_step'.tr(),
              icon: Icons.add,
              kind: AdminButtonKind.ghost,
              onPressed: () => setState(
                () => _steps.add((
                  TextEditingController(),
                  TextEditingController(),
                )),
              ),
            ),
          ],
        ),
        const SizedBox(height: AgSpace.x2),
        for (final (i, (title, detail)) in _steps.indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AgSpace.x3),
                child: SizedBox(
                  width: 24,
                  child: Text(
                    '${i + 1}.',
                    style: AppTypography.bodySmall.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: AdminField(
                  controller: title,
                  label: '',
                  hint: 'admin.disease.step_title'.tr(),
                ),
              ),
              const SizedBox(width: AgSpace.x2),
              Expanded(
                flex: 3,
                child: AdminField(
                  controller: detail,
                  label: '',
                  hint: 'admin.disease.step_detail'.tr(),
                ),
              ),
              IconButton(
                tooltip: 'admin.disease.remove_step'.tr(),
                onPressed: () => setState(() {
                  final (a, b) = _steps.removeAt(i);
                  a.dispose();
                  b.dispose();
                }),
                icon: Icon(Icons.close, size: 16, color: c.textTertiary),
              ),
            ],
          ),
        if (_steps.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AgSpace.x4),
            child: Text(
              'admin.disease.no_steps'.tr(),
              style: AppTypography.caption.copyWith(color: c.textTertiary),
            ),
          ),
      ],
    );
  }
}
