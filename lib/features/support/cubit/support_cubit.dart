import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/admin_config.dart';
import '../../../core/supabase/db.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/safe_emit.dart';
import '../../../data/models/admin_support.dart';
import '../../../data/repositories/admin_support_repository.dart';

class SupportState extends Equatable {
  const SupportState({
    this.tickets = const [],
    this.counts = const {},
    this.status,
    this.priority,
    this.mineOnly = false,
    this.search = '',
    this.page = 0,
    this.hasMore = false,
    this.loading = true,
    this.failure,
    this.actionFailure,
    this.selectedId,
    this.messages = const [],
    this.messagesLoading = false,
    this.messagesFailure,
    this.busy = false,
  });

  final List<SupportTicket> tickets;

  /// Holat -> murojaatlar soni (barcha murojaatlar bo'yicha, filtrsiz).
  final Map<String, int> counts;

  final String? status;
  final String? priority;

  /// Faqat menga biriktirilganlar.
  final bool mineOnly;
  final String search;
  final int page;
  final bool hasMore;
  final bool loading;
  final AppFailure? failure;
  final AppFailure? actionFailure;

  final String? selectedId;
  final List<SupportMessage> messages;
  final bool messagesLoading;
  final AppFailure? messagesFailure;

  /// Javob yoki holat o'zgarishi ketmoqda.
  final bool busy;

  SupportTicket? get selected =>
      tickets.where((t) => t.id == selectedId).firstOrNull;

  SupportState copyWith({
    List<SupportTicket>? tickets,
    Map<String, int>? counts,
    String? status,
    String? priority,
    bool? mineOnly,
    String? search,
    int? page,
    bool? hasMore,
    bool? loading,
    AppFailure? failure,
    AppFailure? actionFailure,
    String? selectedId,
    List<SupportMessage>? messages,
    bool? messagesLoading,
    AppFailure? messagesFailure,
    bool? busy,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearFailure = false,
    bool clearActionFailure = false,
    bool clearSelection = false,
    bool clearMessagesFailure = false,
  }) => SupportState(
    tickets: tickets ?? this.tickets,
    counts: counts ?? this.counts,
    status: clearStatus ? null : (status ?? this.status),
    priority: clearPriority ? null : (priority ?? this.priority),
    mineOnly: mineOnly ?? this.mineOnly,
    search: search ?? this.search,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
    selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
    messages: clearSelection ? const [] : (messages ?? this.messages),
    messagesLoading: messagesLoading ?? this.messagesLoading,
    messagesFailure: clearMessagesFailure || clearSelection
        ? null
        : (messagesFailure ?? this.messagesFailure),
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [
    tickets
        .map(
          (t) => '${t.id}${t.status}${t.priority}${t.assignedTo}${t.updatedAt}',
        )
        .join(),
    counts.entries.map((e) => '${e.key}${e.value}').join(),
    status,
    priority,
    mineOnly,
    search,
    page,
    hasMore,
    loading,
    failure?.messageKey,
    actionFailure?.messageKey,
    selectedId,
    messages.map((m) => m.id).join(),
    messagesLoading,
    messagesFailure?.messageKey,
    busy,
  ];
}

class SupportCubit extends Cubit<SupportState> with SafeEmit<SupportState> {
  SupportCubit(this._repo) : super(const SupportState());

  final AdminSupportRepository _repo;

  Future<void> init() async {
    await Future.wait([load(), _loadCounts()]);
  }

  Future<void> _loadCounts() async {
    final res = await _repo.statusCounts();
    if (res.valueOrNull case final counts?) {
      emit(state.copyWith(counts: counts));
    }
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));

    final res = await _repo.tickets(
      page: state.page,
      status: state.status,
      priority: state.priority,
      assignedTo: state.mineOnly ? Db.userId : null,
      search: state.search,
    );

    switch (res) {
      case Ok(:final value):
        final hasMore = value.length > AdminConfig.pageSize;
        emit(
          state.copyWith(
            loading: false,
            tickets: hasMore ? value.sublist(0, AdminConfig.pageSize) : value,
            hasMore: hasMore,
            clearFailure: true,
          ),
        );
      case Fail(:final failure):
        emit(
          state.copyWith(loading: false, failure: failure, tickets: const []),
        );
    }
  }

  Future<void> setStatus(String? status) async {
    emit(
      state.copyWith(
        status: status,
        clearStatus: status == null,
        page: 0,
        clearSelection: true,
      ),
    );
    await load();
  }

  Future<void> setPriority(String? priority) async {
    emit(
      state.copyWith(
        priority: priority,
        clearPriority: priority == null,
        page: 0,
        clearSelection: true,
      ),
    );
    await load();
  }

  Future<void> toggleMine() async {
    emit(
      state.copyWith(mineOnly: !state.mineOnly, page: 0, clearSelection: true),
    );
    await load();
  }

  Future<void> setSearch(String search) async {
    if (search == state.search) return;
    emit(state.copyWith(search: search, page: 0, clearSelection: true));
    await load();
  }

  Future<void> goToPage(int page) async {
    emit(state.copyWith(page: page, clearSelection: true));
    await load();
  }

  Future<void> open(String ticketId) async {
    emit(
      state.copyWith(
        selectedId: ticketId,
        messages: const [],
        messagesLoading: true,
        clearMessagesFailure: true,
      ),
    );
    await _loadMessages(ticketId);
  }

  Future<void> _loadMessages(String ticketId) async {
    final res = await _repo.messages(ticketId);
    // Boshqa murojaat ochilgan bo'lsa eski javob tashlanadi.
    if (state.selectedId != ticketId) return;

    switch (res) {
      case Ok(:final value):
        emit(state.copyWith(messages: value, messagesLoading: false));
      case Fail(:final failure):
        emit(state.copyWith(messagesLoading: false, messagesFailure: failure));
    }
  }

  void closeDetail() => emit(state.copyWith(clearSelection: true));

  /// Javob yuborish. [thenStatus] berilsa javobdan keyin holat ham
  /// o'zgaradi (masalan "foydalanuvchi javobini kutish").
  Future<bool> reply(String content, {String? thenStatus}) async {
    final id = state.selectedId;
    if (id == null || content.trim().isEmpty) return false;

    final ok = await _act(() => _repo.reply(id, content));
    if (!ok) return false;

    if (thenStatus != null) {
      await _act(() => _repo.update(id, status: thenStatus));
    }
    await _refresh(id);
    return true;
  }

  Future<bool> setTicketStatus(String status, {String? resolution}) =>
      _change((id) => _repo.update(id, status: status, resolution: resolution));

  Future<bool> setTicketPriority(String priority) =>
      _change((id) => _repo.update(id, priority: priority));

  Future<bool> assignToMe() =>
      _change((id) => _repo.update(id, assignedTo: Db.userId));

  Future<bool> unassign() => _change((id) => _repo.update(id, unassign: true));

  Future<bool> _change(Future<Result<void>> Function(String id) action) async {
    final id = state.selectedId;
    if (id == null) return false;

    final ok = await _act(() => action(id));
    if (ok) await _refresh(id);
    return ok;
  }

  Future<bool> _act(Future<Result<void>> Function() action) async {
    emit(state.copyWith(busy: true, clearActionFailure: true));
    final res = await action();
    if (res case Fail(:final failure)) {
      emit(state.copyWith(busy: false, actionFailure: failure));
      return false;
    }
    emit(state.copyWith(busy: false));
    return true;
  }

  /// Amaldan keyin ro'yxat, sonlar va yozishma yangilanadi.
  ///
  /// Hal qilingan murojaat faol navbatdan chiqadi va panel o'zi yopiladi —
  /// bu ataylab: xodim keyingi murojaatga o'tadi.
  Future<void> _refresh(String id) =>
      Future.wait([load(), _loadCounts(), _loadMessages(id)]);
}
