import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/admin_config.dart';
import '../../../core/utils/result.dart';
import '../../../data/repositories/admin_audit_repository.dart';

class AuditState extends Equatable {
  const AuditState({
    this.rows = const [],
    this.actions = const [],
    this.filter = const AuditFilter(),
    this.page = 0,
    this.hasMore = false,
    this.loading = true,
    this.failure,
    this.selectedId,
  });

  final List<AuditRow> rows;
  final List<String> actions;
  final AuditFilter filter;
  final int page;
  final bool hasMore;
  final bool loading;
  final AppFailure? failure;
  final String? selectedId;

  AuditRow? get selected => rows.where((r) => r.id == selectedId).firstOrNull;

  AuditState copyWith({
    List<AuditRow>? rows,
    List<String>? actions,
    AuditFilter? filter,
    int? page,
    bool? hasMore,
    bool? loading,
    AppFailure? failure,
    String? selectedId,
    bool clearFailure = false,
    bool clearSelection = false,
  }) => AuditState(
    rows: rows ?? this.rows,
    actions: actions ?? this.actions,
    filter: filter ?? this.filter,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
    selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
  );

  @override
  List<Object?> get props => [
    rows.map((r) => r.id).join(),
    actions.length,
    filter.action,
    filter.targetType,
    filter.actorId,
    page,
    hasMore,
    loading,
    failure?.messageKey,
    selectedId,
  ];
}

/// Audit jurnali — faqat o'qish (0010 dagi triggerlar yozuvni o'zgarmas
/// qiladi), shuning uchun cubit'da amal metodi yo'q.
class AuditCubit extends Cubit<AuditState> {
  AuditCubit(this._repo) : super(const AuditState());

  final AdminAuditRepository _repo;

  Future<void> init() async {
    final actionsRes = await _repo.actions();
    emit(state.copyWith(actions: actionsRes.valueOrNull ?? const []));
    await load();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));

    final res = await _repo.list(filter: state.filter, page: state.page);

    switch (res) {
      case Ok(:final value):
        final hasMore = value.length > AdminConfig.pageSize;
        emit(
          state.copyWith(
            loading: false,
            rows: hasMore ? value.sublist(0, AdminConfig.pageSize) : value,
            hasMore: hasMore,
            clearFailure: true,
          ),
        );
      case Fail(:final failure):
        emit(state.copyWith(loading: false, failure: failure, rows: const []));
    }
  }

  Future<void> applyFilter(AuditFilter filter) async {
    emit(state.copyWith(filter: filter, page: 0, clearSelection: true));
    await load();
  }

  Future<void> goToPage(int page) async {
    emit(state.copyWith(page: page, clearSelection: true));
    await load();
  }

  void select(String id) => emit(state.copyWith(selectedId: id));
  void closeDetail() => emit(state.copyWith(clearSelection: true));
}
