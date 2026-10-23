import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../core/rbac/permission.dart';
import '../../../core/rbac/permission_guard.dart';
import '../../../core/supabase/db.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/admin_support.dart';
import '../../../data/repositories/admin_support_repository.dart';
import '../../../ui/admin_bits.dart';
import '../../../ui/admin_button.dart';
import '../../../ui/admin_feedback.dart';
import '../../../ui/admin_field.dart';
import '../../../ui/admin_table.dart';
import '../../dashboard/widgets/kpi_card.dart';
import '../cubit/support_cubit.dart';

BadgeTone _statusTone(String status) => switch (status) {
  TicketStatus.open => BadgeTone.warning,
  TicketStatus.inProgress => BadgeTone.info,
  TicketStatus.waitingUser => BadgeTone.brand,
  TicketStatus.resolved => BadgeTone.success,
  _ => BadgeTone.neutral,
};

BadgeTone _priorityTone(String priority) => switch (priority) {
  TicketPriority.urgent => BadgeTone.danger,
  TicketPriority.high => BadgeTone.warning,
  TicketPriority.low => BadgeTone.neutral,
  _ => BadgeTone.info,
};

/// Qo'llab-quvvatlash (TTZ §6.12).
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PermissionGuard(
      permission: AdminPermission.supportRead,
      child: BlocProvider(
        create: (_) => SupportCubit(getIt<AdminSupportRepository>())..init(),
        child: const _SupportView(),
      ),
    );
  }
}

class _SupportView extends StatelessWidget {
  const _SupportView();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return BlocConsumer<SupportCubit, SupportState>(
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
        final cubit = context.read<SupportCubit>();

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AgSpace.x7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminPageHeader(
                    title: 'admin.nav.support'.tr(),
                    subtitle: 'admin.support.subtitle'.tr(),
                    actions: [
                      AdminButton(
                        label: 'admin.common.retry'.tr(),
                        icon: Icons.refresh,
                        kind: AdminButtonKind.secondary,
                        onPressed: state.loading ? null : cubit.init,
                      ),
                    ],
                  ),
                  const SizedBox(height: AgSpace.x5),

                  _Counters(state: state, cubit: cubit, colors: c),
                  const SizedBox(height: AgSpace.x5),

                  Wrap(
                    spacing: AgSpace.x3,
                    runSpacing: AgSpace.x3,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AdminSearchField(
                        hintKey: 'admin.support.search_hint',
                        onChanged: cubit.setSearch,
                      ),
                      AdminSelect<String>(
                        // Kartani bosish ham filtrni o'zgartiradi — `initialValue`
                        // faqat birinchi kadrda o'qilgani uchun kalit kerak.
                        key: ValueKey('status-${state.status}'),
                        // `null` — faol navbat (yopilganlarsiz), shuning uchun
                        // "Hammasi" emas, alohida yozuv.
                        value: state.status,
                        hintKey: 'admin.support.filter_status',
                        allLabelKey: 'admin.support.active_queue',
                        width: 210,
                        items: [
                          for (final s in TicketStatus.all)
                            (s, 'admin.ticket_status.$s'.tr()),
                        ],
                        onChanged: cubit.setStatus,
                      ),
                      AdminSelect<String>(
                        value: state.priority,
                        hintKey: 'admin.support.filter_priority',
                        width: 180,
                        items: [
                          for (final p in TicketPriority.all)
                            (p, 'admin.ticket_priority.$p'.tr()),
                        ],
                        onChanged: cubit.setPriority,
                      ),
                      AdminButton(
                        label: 'admin.support.mine'.tr(),
                        icon: Icons.person_pin_outlined,
                        kind: state.mineOnly
                            ? AdminButtonKind.primary
                            : AdminButtonKind.secondary,
                        onPressed: cubit.toggleMine,
                      ),
                    ],
                  ),
                  const SizedBox(height: AgSpace.x4),

                  Expanded(
                    child: AdminTable<SupportTicket>(
                      rows: state.tickets,
                      loading: state.loading,
                      failure: state.failure,
                      onRetry: cubit.load,
                      emptyTitle: 'admin.support.empty'.tr(),
                      emptyHint: 'admin.support.empty_hint'.tr(),
                      onRowTap: (row) => cubit.open(row.id),
                      columns: _columns(c),
                    ),
                  ),
                  const SizedBox(height: AgSpace.x4),
                  AdminPagination(
                    page: state.page,
                    hasMore: state.hasMore,
                    loading: state.loading,
                    onChanged: cubit.goToPage,
                  ),
                ],
              ),
            ),

            if (state.selected != null)
              _TicketPanel(state: state, ticket: state.selected!),
          ],
        );
      },
    );
  }

  List<AdminColumn<SupportTicket>> _columns(AppColors c) => [
    AdminColumn(
      labelKey: 'admin.support.col_subject',
      flex: 4,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.subject,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            row.category,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.users.col_name',
      flex: 2,
      build: (row) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.userName ?? '—',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: c.text),
          ),
          Text(
            row.userPhone ?? row.userEmail ?? '—',
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    ),
    AdminColumn(
      labelKey: 'admin.support.col_priority',
      width: 120,
      build: (row) => StatusBadge(
        label: 'admin.ticket_priority.${row.priority}'.tr(),
        tone: _priorityTone(row.priority),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.support.col_status',
      width: 150,
      build: (row) => StatusBadge(
        label: 'admin.ticket_status.${row.status}'.tr(),
        tone: _statusTone(row.status),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.support.col_assignee',
      width: 150,
      build: (row) => Text(
        row.assigneeName ?? 'admin.support.unassigned'.tr(),
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: row.assignedTo == null ? c.textTertiary : c.textSecondary,
        ),
      ),
    ),
    AdminColumn(
      labelKey: 'admin.support.col_updated',
      width: 130,
      build: (row) => Text(
        Fmt.ago(row.updatedAt),
        style: AppTypography.caption.copyWith(color: c.textTertiary),
      ),
    ),
  ];
}

/// Holatlar bo'yicha kartalar. Bosilsa o'sha holat bo'yicha filtrlanadi.
class _Counters extends StatelessWidget {
  const _Counters({
    required this.state,
    required this.cubit,
    required this.colors,
  });

  final SupportState state;
  final SupportCubit cubit;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final cards = [
      (TicketStatus.open, Icons.mark_email_unread_outlined, colors.warningText),
      (TicketStatus.inProgress, Icons.pending_actions_outlined, null),
      (TicketStatus.waitingUser, Icons.hourglass_empty_outlined, null),
      (TicketStatus.resolved, Icons.task_alt_outlined, null),
    ];

    return Wrap(
      spacing: AgSpace.x4,
      runSpacing: AgSpace.x4,
      children: [
        for (final (status, icon, tone) in cards)
          InkWell(
            borderRadius: AgRadius.rLg,
            onTap: () =>
                cubit.setStatus(state.status == status ? null : status),
            child: KpiCard(
              label: 'admin.ticket_status.$status'.tr(),
              value: Fmt.count(state.counts[status] ?? 0),
              icon: icon,
              // Ochiq murojaat bo'lsa — e'tibor rangi (KpiCard qoidasi).
              tone: (state.counts[status] ?? 0) > 0 ? tone : null,
            ),
          ),
      ],
    );
  }
}

/// Murojaat paneli: tomonlar, yozishma, javob maydoni va amallar.
class _TicketPanel extends StatefulWidget {
  const _TicketPanel({required this.state, required this.ticket});

  final SupportState state;
  final SupportTicket ticket;

  @override
  State<_TicketPanel> createState() => _TicketPanelState();
}

class _TicketPanelState extends State<_TicketPanel> {
  final _reply = TextEditingController();
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant _TicketPanel old) {
    super.didUpdateWidget(old);
    // Boshqa murojaat ochilsa yozilayotgan javob unga o'tib ketmasin.
    if (old.ticket.id != widget.ticket.id) _reply.clear();
    // Yangi xabar kelganda pastga tushiriladi.
    if (old.state.messages.length != widget.state.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _reply.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send({String? thenStatus}) async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    final ok = await context.read<SupportCubit>().reply(
      text,
      thenStatus: thenStatus,
    );
    if (ok) _reply.clear();
  }

  Future<void> _resolve() async {
    final cubit = context.read<SupportCubit>();
    final result = await showReasonDialog(
      context,
      title: 'admin.support.resolve'.tr(),
      message: 'admin.support.resolve_hint'.tr(),
      confirmLabel: 'admin.support.resolve'.tr(),
      danger: false,
    );
    if (!result.confirmed || result.reason == null) return;
    await cubit.setTicketStatus(
      TicketStatus.resolved,
      resolution: result.reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final cubit = context.read<SupportCubit>();
    final t = widget.ticket;
    final state = widget.state;

    return AdminSidePanel(
      title: t.subject,
      subtitle: '${t.category} · ${Fmt.dateTime(t.createdAt)}',
      width: 620,
      onClose: cubit.closeDetail,
      badges: [
        StatusBadge(
          label: 'admin.ticket_status.${t.status}'.tr(),
          tone: _statusTone(t.status),
        ),
        StatusBadge(
          label: 'admin.ticket_priority.${t.priority}'.tr(),
          tone: _priorityTone(t.priority),
        ),
      ],
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(AgSpace.x6),
        children: [
          _Facts(ticket: t, colors: c),
          if ((t.resolution ?? '').isNotEmpty) ...[
            const SizedBox(height: AgSpace.x4),
            AdminNote(
              text: '${'admin.support.resolution'.tr()}: ${t.resolution}',
              icon: Icons.task_alt_outlined,
            ),
          ],
          const SizedBox(height: AgSpace.x5),
          Text(
            'admin.support.conversation'.tr(),
            style: AppTypography.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AgSpace.x3),
          if (state.messagesLoading)
            const Padding(
              padding: EdgeInsets.all(AgSpace.x6),
              child: AdminLoading(),
            )
          else if (state.messagesFailure != null)
            AdminErrorBanner(
              failure: state.messagesFailure!,
              onRetry: () => cubit.open(t.id),
            )
          else if (state.messages.isEmpty)
            Text(
              'admin.support.no_messages'.tr(),
              style: AppTypography.bodySmall.copyWith(color: c.textTertiary),
            )
          else
            for (final m in state.messages)
              Padding(
                padding: const EdgeInsets.only(bottom: AgSpace.x3),
                child: AdminChatBubble(
                  text: m.content,
                  time: m.createdAt,
                  mine: !m.isStaff,
                  label: m.isStaff
                      ? '${m.senderName ?? ''} · ${'admin.support.staff'.tr()}'
                      : (m.senderName ?? t.userName ?? '—'),
                  colors: c,
                ),
              ),
        ],
      ),
      footer: PermissionGuard(
        permission: AdminPermission.supportWrite,
        fallback: Text(
          'admin.support.read_only'.tr(),
          style: AppTypography.caption.copyWith(color: c.textTertiary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Actions(ticket: t, busy: state.busy, onResolve: _resolve),
            const SizedBox(height: AgSpace.x4),
            AdminField(
              controller: _reply,
              label: '',
              hint: 'admin.support.reply_hint'.tr(),
              maxLines: 5,
              minLines: 2,
              reserveErrorSpace: false,
            ),
            const SizedBox(height: AgSpace.x3),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AgSpace.x2,
              runSpacing: AgSpace.x2,
              children: [
                AdminButton(
                  label: 'admin.support.send_wait'.tr(),
                  kind: AdminButtonKind.secondary,
                  onPressed: state.busy
                      ? null
                      : () => _send(thenStatus: TicketStatus.waitingUser),
                ),
                AdminButton(
                  label: 'admin.support.send'.tr(),
                  icon: Icons.send_outlined,
                  busy: state.busy,
                  onPressed: () => _send(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.ticket, required this.colors});

  final SupportTicket ticket;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('admin.users.col_name', ticket.userName ?? '—'),
      ('admin.support.phone', ticket.userPhone ?? '—'),
      ('admin.staff.email', ticket.userEmail ?? '—'),
      (
        'admin.support.col_assignee',
        ticket.assigneeName ?? 'admin.support.unassigned'.tr(),
      ),
      if (ticket.resolvedAt != null)
        ('admin.support.resolved_at', Fmt.dateTime(ticket.resolvedAt)),
    ];

    return Column(
      children: [
        for (final (key, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AgSpace.x1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    key.tr(),
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
}

/// Holat, muhimlik va mas'ul.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.ticket,
    required this.busy,
    required this.onResolve,
  });

  final SupportTicket ticket;
  final bool busy;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SupportCubit>();
    final mine = ticket.assignedTo == Db.userId;

    return Wrap(
      spacing: AgSpace.x2,
      runSpacing: AgSpace.x2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AdminSelect<String>(
          key: ValueKey('priority-${ticket.id}-${ticket.priority}'),
          value: ticket.priority,
          hintKey: 'admin.support.col_priority',
          width: 150,
          items: [
            for (final p in TicketPriority.all)
              (p, 'admin.ticket_priority.$p'.tr()),
          ],
          onChanged: (p) {
            if (p != null && p != ticket.priority && !busy) {
              cubit.setTicketPriority(p);
            }
          },
        ),
        AdminButton(
          label: mine
              ? 'admin.support.unassign'.tr()
              : 'admin.support.assign_me'.tr(),
          icon: mine ? Icons.person_off_outlined : Icons.person_add_outlined,
          kind: AdminButtonKind.secondary,
          onPressed: busy ? null : (mine ? cubit.unassign : cubit.assignToMe),
        ),
        if (ticket.isClosed)
          AdminButton(
            label: 'admin.support.reopen'.tr(),
            icon: Icons.replay,
            kind: AdminButtonKind.secondary,
            onPressed: busy
                ? null
                : () => cubit.setTicketStatus(TicketStatus.inProgress),
          )
        else ...[
          AdminButton(
            label: 'admin.support.resolve'.tr(),
            icon: Icons.task_alt_outlined,
            onPressed: busy ? null : onResolve,
          ),
          AdminButton(
            label: 'admin.support.close'.tr(),
            kind: AdminButtonKind.ghost,
            onPressed: busy
                ? null
                : () => cubit.setTicketStatus(TicketStatus.closed),
          ),
        ],
      ],
    );
  }
}
