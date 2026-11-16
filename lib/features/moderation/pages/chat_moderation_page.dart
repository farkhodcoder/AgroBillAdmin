import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/di.dart';
import '../../../core/rbac/permission.dart';
import '../../../core/rbac/permission_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/result.dart';
import '../../../data/repositories/admin_moderation_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_field.dart';
import '../../../ui/admin_table.dart';

/// Chat moderatsiyasi: foydalanuvchi shikoyatlari, AI to'sib qo'ygan
/// xabarlar va tezlik cheklovlari (mobil 0026 / 0027 / 0049).
///
/// Shaxsiy yozishma maxfiy: ro'yxatda faqat SHIKOYAT QILINGAN xabar
/// ko'rinadi. Butun suhbatni o'qish uchun sabab yoziladi va amal auditga
/// tushadi (`admin_read_flagged_chat`).
class ChatModerationPage extends StatefulWidget {
  const ChatModerationPage({super.key});

  @override
  State<ChatModerationPage> createState() => _ChatModerationPageState();
}

enum _Tab { reports, auto, limits }

class _ChatModerationPageState extends State<ChatModerationPage> {
  _Tab _tab = _Tab.reports;

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.listingsModerate,
      child: Padding(
        padding: const EdgeInsets.all(AgSpace.x7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminPageHeader(
              title: 'admin.nav.moderation'.tr(),
              subtitle: 'admin.moderation.subtitle'.tr(),
            ),
            const SizedBox(height: AgSpace.x4),
            SegmentedButton<_Tab>(
              showSelectedIcon: false,
              segments: [
                for (final t in _Tab.values)
                  ButtonSegment(
                    value: t,
                    label: Text(switch (t) {
                      _Tab.reports => 'admin.moderation.tab_reports'.tr(),
                      _Tab.auto => 'admin.moderation.tab_auto'.tr(),
                      _Tab.limits => 'admin.moderation.tab_limits'.tr(),
                    }),
                  ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
            const SizedBox(height: AgSpace.x4),
            Expanded(
              child: switch (_tab) {
                _Tab.reports => const _ReportsTab(),
                _Tab.auto => const _AutoTab(),
                _Tab.limits => const _LimitsTab(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _showError(BuildContext context, AppFailure failure) {
  final c = Theme.of(context).extension<AppColors>()!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: c.errorBg,
      content: Text(
        failure.messageKey.tr(),
        style: AppTypography.bodySmall.copyWith(color: c.errorText),
      ),
    ),
  );
}

// =============================================================================
// Shikoyatlar
// =============================================================================

class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  final _repo = getIt<AdminModerationRepository>();

  List<MessageReport> _rows = const [];
  String? _status = 'open';
  bool _loading = true;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _repo.reports(status: _status);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (res) {
        case Ok(:final value):
          _rows = value;
          _failure = null;
        case Fail(:final failure):
          _failure = failure;
      }
    });
  }

  Future<void> _setStatus(MessageReport row, String status) async {
    // "Chora ko'rildi" va "rad etildi" — yakuniy qaror, izoh so'raladi.
    String? note;
    if (status != 'reviewed') {
      final ok = await showReasonDialog(
        context,
        title: 'admin.report_status.$status'.tr(),
        message: 'admin.moderation.status_message'.tr(),
        confirmLabel: 'admin.common.save'.tr(),
        reasonRequired: false,
        danger: false,
      );
      if (!ok.confirmed || !mounted) return;
      note = ok.reason;
    }

    final res = await _repo.setReportStatus(row.id, status, note: note);
    if (!mounted) return;
    if (res case Fail(:final failure)) return _showError(context, failure);
    await _load();
  }

  Future<void> _readConversation(MessageReport row) async {
    final ok = await showReasonDialog(
      context,
      title: 'admin.moderation.read_title'.tr(),
      message: 'admin.moderation.read_message'.tr(),
      confirmLabel: 'admin.moderation.read'.tr(),
      danger: false,
    );
    if (!ok.confirmed || !mounted) return;

    final res = await _repo.readConversation(row.conversationId, ok.reason!);
    if (!mounted) return;
    switch (res) {
      case Fail(:final failure):
        _showError(context, failure);
      case Ok(:final value):
        await showDialog<void>(
          context: context,
          builder: (_) => _ConversationDialog(report: row, messages: value),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AgSpace.x2,
          children: [
            for (final s in const [
              'open',
              'reviewed',
              'actioned',
              'dismissed',
              null,
            ])
              ChoiceChip(
                label: Text('admin.report_status.${s ?? 'all'}'.tr()),
                selected: _status == s,
                onSelected: (_) {
                  setState(() {
                    _status = s;
                    _loading = true;
                  });
                  _load();
                },
              ),
          ],
        ),
        const SizedBox(height: AgSpace.x4),
        Expanded(child: _body(c)),
      ],
    );
  }

  Widget _body(AppColors c) {
    if (_loading) return const AdminLoading();
    if (_failure != null && _rows.isEmpty) {
      return Align(
        alignment: Alignment.topCenter,
        child: AdminErrorBanner(failure: _failure!, onRetry: _load),
      );
    }
    if (_rows.isEmpty) {
      return Center(
        child: Text(
          'admin.moderation.reports_empty'.tr(),
          style: AppTypography.body.copyWith(color: c.textTertiary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: AgSpace.x3),
        itemBuilder: (context, i) => _ReportCard(
          key: ValueKey(_rows[i].id),
          row: _rows[i],
          onStatus: (s) => _setStatus(_rows[i], s),
          onRead: () => _readConversation(_rows[i]),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    super.key,
    required this.row,
    required this.onStatus,
    required this.onRead,
  });

  final MessageReport row;
  final ValueChanged<String> onStatus;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Container(
      padding: const EdgeInsets.all(AgSpace.x5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AgRadius.rMd,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AgSpace.x2,
            runSpacing: AgSpace.x1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(
                label: 'admin.report_status.${row.status}'.tr(),
                tone: switch (row.status) {
                  'open' => BadgeTone.warning,
                  'actioned' => BadgeTone.danger,
                  'reviewed' => BadgeTone.info,
                  _ => BadgeTone.neutral,
                },
              ),
              StatusBadge(
                label: 'admin.conversation_kind.${row.conversationKind}'.tr(),
              ),
              if (row.reportCount > 1)
                StatusBadge(
                  label: 'admin.moderation.report_count'.tr(
                    namedArgs: {'count': '${row.reportCount}'},
                  ),
                  tone: BadgeTone.danger,
                ),
              if (row.messageDeleted)
                StatusBadge(label: 'admin.moderation.message_deleted'.tr()),
              Text(
                Fmt.dateTime(row.createdAt),
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AgSpace.x3),
          Text(
            'admin.moderation.reported_by'.tr(
              namedArgs: {
                'name': row.reporterName ?? '—',
                'reason': row.reason,
              },
            ),
            style: AppTypography.bodySmall.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AgSpace.x3),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AgSpace.x4),
            decoration: BoxDecoration(
              color: c.surfaceSunken,
              borderRadius: AgRadius.rMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    row.senderName ?? '—',
                    if (row.conversationTitle != null) row.conversationTitle!,
                    if (row.sentAt != null) Fmt.dateTime(row.sentAt),
                  ].join(' · '),
                  style: AppTypography.caption.copyWith(color: c.textTertiary),
                ),
                const SizedBox(height: AgSpace.x1),
                SelectableText(
                  row.content.trim().isEmpty
                      ? 'admin.moderation.no_text'.tr()
                      : row.content,
                  style: AppTypography.bodySmall.copyWith(color: c.text),
                ),
                if (row.hasAttachment) ...[
                  const SizedBox(height: AgSpace.x1),
                  Text(
                    'admin.moderation.has_attachment'.tr(),
                    style: AppTypography.caption.copyWith(
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AgSpace.x4),
          Wrap(
            spacing: AgSpace.x2,
            runSpacing: AgSpace.x2,
            children: [
              AdminButton(
                label: 'admin.moderation.read'.tr(),
                icon: Icons.forum_outlined,
                kind: AdminButtonKind.secondary,
                onPressed: onRead,
              ),
              if (row.status != 'reviewed')
                AdminButton(
                  label: 'admin.report_status.reviewed'.tr(),
                  kind: AdminButtonKind.ghost,
                  onPressed: () => onStatus('reviewed'),
                ),
              if (row.status != 'actioned')
                AdminButton(
                  label: 'admin.report_status.actioned'.tr(),
                  kind: AdminButtonKind.ghost,
                  onPressed: () => onStatus('actioned'),
                ),
              if (row.status != 'dismissed')
                AdminButton(
                  label: 'admin.report_status.dismissed'.tr(),
                  kind: AdminButtonKind.ghost,
                  onPressed: () => onStatus('dismissed'),
                ),
              if (!row.isOpen)
                AdminButton(
                  label: 'admin.moderation.reopen'.tr(),
                  kind: AdminButtonKind.ghost,
                  onPressed: () => onStatus('open'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConversationDialog extends StatelessWidget {
  const _ConversationDialog({required this.report, required this.messages});

  final MessageReport report;
  final List<FlaggedMessage> messages;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Dialog(
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: AgRadius.rLg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AgSpace.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                report.conversationTitle ??
                    'admin.conversation_kind.${report.conversationKind}'.tr(),
                style: AppTypography.h3.copyWith(color: c.text),
              ),
              const SizedBox(height: AgSpace.x1),
              Text(
                'admin.moderation.read_audited'.tr(),
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
              const SizedBox(height: AgSpace.x4),
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(
                          'admin.moderation.no_messages'.tr(),
                          style: AppTypography.body.copyWith(
                            color: c.textTertiary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: messages.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AgSpace.x2),
                        itemBuilder: (context, i) {
                          final m = messages[i];
                          final reported = m.senderId == report.senderId;
                          return AdminChatBubble(
                            text: m.content,
                            time: m.sentAt,
                            mine: !reported,
                            label: reported
                                ? (report.senderName ?? '—')
                                : 'admin.moderation.participant'.tr(),
                            colors: c,
                            highlighted:
                                m.id == report.messageId || m.isFlagged,
                          );
                        },
                      ),
              ),
              const SizedBox(height: AgSpace.x4),
              Align(
                alignment: Alignment.centerRight,
                child: AdminButton(
                  label: 'admin.common.close'.tr(),
                  kind: AdminButtonKind.ghost,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Avto-moderatsiya jurnali
// =============================================================================

class _AutoTab extends StatefulWidget {
  const _AutoTab();

  @override
  State<_AutoTab> createState() => _AutoTabState();
}

class _AutoTabState extends State<_AutoTab> {
  final _repo = getIt<AdminModerationRepository>();

  List<ModerationEntry> _rows = const [];
  bool _loading = true;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _repo.moderationLog();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (res) {
        case Ok(:final value):
          _rows = value;
          _failure = null;
        case Fail(:final failure):
          _failure = failure;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminNote(
          text: 'admin.moderation.auto_note'.tr(),
          icon: Icons.shield_outlined,
        ),
        const SizedBox(height: AgSpace.x4),
        Expanded(
          child: AdminTable<ModerationEntry>(
            rows: _rows,
            loading: _loading,
            failure: _failure,
            onRetry: _load,
            emptyTitle: 'admin.moderation.auto_empty'.tr(),
            columns: [
              AdminColumn(
                labelKey: 'admin.moderation.col_time',
                width: 150,
                build: (r) => Text(
                  Fmt.dateTime(r.createdAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
              AdminColumn(
                labelKey: 'admin.moderation.col_sender',
                flex: 2,
                build: (r) => Text(
                  r.senderName ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: c.text),
                ),
              ),
              AdminColumn(
                labelKey: 'admin.moderation.col_category',
                width: 140,
                build: (r) => StatusBadge(label: r.category),
              ),
              AdminColumn(
                labelKey: 'admin.moderation.col_content',
                flex: 4,
                build: (r) => Tooltip(
                  message: r.reason ?? '',
                  child: Text(
                    r.originalContent,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(color: c.text),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Tezlik cheklovlari
// =============================================================================

class _LimitsTab extends StatefulWidget {
  const _LimitsTab();

  @override
  State<_LimitsTab> createState() => _LimitsTabState();
}

class _LimitsTabState extends State<_LimitsTab> {
  final _repo = getIt<AdminModerationRepository>();

  List<RateOverride> _rows = const [];
  bool _loading = true;
  AppFailure? _failure;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _repo.rateOverrides();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (res) {
        case Ok(:final value):
          _rows = value;
          _failure = null;
        case Fail(:final failure):
          _failure = failure;
      }
    });
  }

  Future<void> _add() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddLimitDialog(),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(RateOverride row) async {
    final ok = await showReasonDialog(
      context,
      title: 'admin.moderation.delete_limit_title'.tr(),
      message: 'admin.moderation.delete_limit_message'.tr(),
      confirmLabel: 'admin.common.delete'.tr(),
      reasonRequired: false,
    );
    if (!ok.confirmed || !mounted) return;

    final res = await _repo.deleteRateOverride(row.id);
    if (!mounted) return;
    if (res case Fail(:final failure)) return _showError(context, failure);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AdminNote(
                text: 'admin.moderation.limits_note'.tr(),
                icon: Icons.speed_outlined,
              ),
            ),
            const SizedBox(width: AgSpace.x4),
            AdminButton(
              label: 'admin.moderation.add_limit'.tr(),
              icon: Icons.add,
              onPressed: _add,
            ),
          ],
        ),
        const SizedBox(height: AgSpace.x4),
        Expanded(
          child: AdminTable<RateOverride>(
            rows: _rows,
            loading: _loading,
            failure: _failure,
            onRetry: _load,
            emptyTitle: 'admin.moderation.limits_empty'.tr(),
            columns: [
              AdminColumn(
                labelKey: 'admin.moderation.col_target',
                flex: 3,
                build: (r) => Text(
                  [
                    if (r.userId != null) r.userName ?? r.userEmail ?? '—',
                    if (r.conversationId != null) r.conversationTitle ?? '—',
                    if (r.conversationId == null)
                      'admin.moderation.all_chats'.tr(),
                  ].join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(color: c.text),
                ),
              ),
              AdminColumn(
                labelKey: 'admin.moderation.col_slow',
                width: 130,
                build: (r) => _seconds(r.slowModeSeconds, c),
              ),
              AdminColumn(
                labelKey: 'admin.moderation.col_image',
                width: 130,
                build: (r) => _seconds(r.imageCooldownSeconds, c),
              ),
              AdminColumn(
                labelKey: 'admin.moderation.col_note',
                flex: 3,
                build: (r) => Text(
                  [
                    if (r.note != null && r.note!.trim().isNotEmpty) r.note!,
                    if (r.editorName != null) r.editorName!,
                    Fmt.date(r.updatedAt),
                  ].join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
              AdminColumn(
                labelKey: 'admin.common.actions',
                width: 64,
                align: Alignment.center,
                build: (r) => IconButton(
                  tooltip: 'admin.common.delete'.tr(),
                  onPressed: () => _delete(r),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: c.errorText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _seconds(int? value, AppColors c) => Text(
    limitLabel(value),
    style: AppTypography.bodySmall.copyWith(
      color: value == null ? c.textTertiary : c.text,
    ),
  );
}

/// `null` — tegilmaydi, `0` — chegara yo'q, aks holda soniyalar.
String limitLabel(int? seconds) => switch (seconds) {
  null => '—',
  0 => 'admin.moderation.no_limit'.tr(),
  final s => 'admin.moderation.seconds'.tr(namedArgs: {'n': '$s'}),
};

/// Maydondagi matnni cheklov qiymatiga aylantiradi: bo'sh — `null`,
/// noto'g'ri yoki 0..86400 dan tashqari — xato (`-1`).
int? parseLimit(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final v = int.tryParse(t);
  if (v == null || v < 0 || v > 86400) return -1;
  return v;
}

class _AddLimitDialog extends StatefulWidget {
  const _AddLimitDialog();

  @override
  State<_AddLimitDialog> createState() => _AddLimitDialogState();
}

class _AddLimitDialogState extends State<_AddLimitDialog> {
  final _repo = getIt<AdminModerationRepository>();
  final _search = TextEditingController();
  final _slow = TextEditingController();
  final _image = TextEditingController();
  final _note = TextEditingController();

  List<UserPick> _found = const [];
  List<(String, String)> _communities = const [];
  UserPick? _user;
  String? _conversation;
  String? _error;
  bool _busy = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _repo.communities().then((res) {
      if (!mounted) return;
      if (res case Ok(:final value)) setState(() => _communities = value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _slow.dispose();
    _image.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final res = await _repo.findUsers(text);
      if (!mounted) return;
      if (res case Ok(:final value)) setState(() => _found = value);
    });
  }

  Future<void> _save() async {
    final slow = parseLimit(_slow.text);
    final image = parseLimit(_image.text);
    String? error;
    if (_user == null && _conversation == null) {
      error = 'admin.moderation.err_target'.tr();
    } else if (slow == -1 || image == -1) {
      error = 'admin.moderation.err_seconds'.tr();
    } else if (slow == null && image == null) {
      error = 'admin.moderation.err_empty'.tr();
    }
    if (error != null) return setState(() => _error = error);

    setState(() {
      _busy = true;
      _error = null;
    });
    final note = _note.text.trim();
    final res = await _repo.addRateOverride(
      userId: _user?.id,
      conversationId: _conversation,
      slowModeSeconds: slow,
      imageCooldownSeconds: image,
      note: note.isEmpty ? null : note,
    );
    if (!mounted) return;
    switch (res) {
      case Ok():
        Navigator.of(context).pop(true);
      case Fail(:final failure):
        setState(() {
          _busy = false;
          _error = failure.messageKey.tr();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return AdminFormDialog(
      title: 'admin.moderation.add_limit'.tr(),
      subtitle: 'admin.moderation.add_limit_hint'.tr(),
      confirmLabel: 'admin.common.save'.tr(),
      busy: _busy,
      onConfirm: _busy ? null : _save,
      maxWidth: 520,
      children: [
        if (_user == null) ...[
          AdminField(
            controller: _search,
            label: 'admin.moderation.user'.tr(),
            hint: 'admin.moderation.user_hint'.tr(),
            reserveErrorSpace: false,
            onSubmitted: _onSearch,
          ),
          // `AdminField` `onChanged` bermaydi — tinglovchi orqali.
          _SearchListener(controller: _search, onChanged: _onSearch),
          for (final u in _found)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.person_outline,
                size: 18,
                color: c.textTertiary,
              ),
              title: Text(
                u.label,
                style: AppTypography.bodySmall.copyWith(color: c.text),
              ),
              onTap: () => setState(() => _user = u),
            ),
        ] else
          InputChip(
            label: Text(_user!.label),
            onDeleted: () => setState(() => _user = null),
          ),
        const SizedBox(height: AgSpace.x4),
        AdminSelect<String>(
          value: _conversation,
          width: double.infinity,
          hintKey: 'admin.moderation.channel',
          allLabelKey: 'admin.moderation.all_chats',
          items: _communities,
          onChanged: (v) => setState(() => _conversation = v),
        ),
        const SizedBox(height: AgSpace.x4),
        Row(
          children: [
            Expanded(
              child: AdminField(
                controller: _slow,
                label: 'admin.moderation.col_slow'.tr(),
                hint: 'admin.moderation.seconds_hint'.tr(),
                keyboardType: TextInputType.number,
                inputFormatters: digits,
              ),
            ),
            const SizedBox(width: AgSpace.x3),
            Expanded(
              child: AdminField(
                controller: _image,
                label: 'admin.moderation.col_image'.tr(),
                hint: 'admin.moderation.seconds_hint'.tr(),
                keyboardType: TextInputType.number,
                inputFormatters: digits,
              ),
            ),
          ],
        ),
        AdminField(
          controller: _note,
          label: 'admin.moderation.col_note'.tr(),
          maxLength: 200,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AgSpace.x2),
            child: Text(
              _error!,
              style: AppTypography.bodySmall.copyWith(color: c.errorText),
            ),
          ),
      ],
    );
  }
}

/// Controller o'zgarishini tinglab, faqat matn o'zgarganda chaqiradi.
class _SearchListener extends StatefulWidget {
  const _SearchListener({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchListener> createState() => _SearchListenerState();
}

class _SearchListenerState extends State<_SearchListener> {
  late String _last = widget.controller.text;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final text = widget.controller.text;
    if (text == _last) return;
    _last = text;
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
