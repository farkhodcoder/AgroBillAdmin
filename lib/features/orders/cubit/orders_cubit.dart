import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/admin_config.dart';
import '../../../core/utils/result.dart';
import '../../../data/models/admin_order.dart';
import '../../../data/repositories/admin_order_repository.dart';

class OrdersState extends Equatable {
  const OrdersState({
    this.rows = const [],
    this.filter = const OrderFilter(),
    this.page = 0,
    this.hasMore = false,
    this.loading = true,
    this.failure,
    this.actionFailure,
    this.selectedId,
    this.history = const [],
    this.reviews = const [],
    this.detailLoading = false,
  });

  final List<AdminOrderRow> rows;
  final OrderFilter filter;
  final int page;
  final bool hasMore;
  final bool loading;
  final AppFailure? failure;
  final AppFailure? actionFailure;

  final String? selectedId;
  final List<OrderHistoryEntry> history;
  final List<Map<String, dynamic>> reviews;
  final bool detailLoading;

  AdminOrderRow? get selected =>
      rows.where((r) => r.id == selectedId).firstOrNull;

  OrdersState copyWith({
    List<AdminOrderRow>? rows,
    OrderFilter? filter,
    int? page,
    bool? hasMore,
    bool? loading,
    AppFailure? failure,
    AppFailure? actionFailure,
    String? selectedId,
    List<OrderHistoryEntry>? history,
    List<Map<String, dynamic>>? reviews,
    bool? detailLoading,
    bool clearFailure = false,
    bool clearActionFailure = false,
    bool clearSelection = false,
  }) => OrdersState(
    rows: rows ?? this.rows,
    filter: filter ?? this.filter,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
    selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
    history: clearSelection ? const [] : (history ?? this.history),
    reviews: clearSelection ? const [] : (reviews ?? this.reviews),
    detailLoading: detailLoading ?? this.detailLoading,
  );

  @override
  List<Object?> get props => [
    rows.map((r) => '${r.id}${r.status}').join(),
    filter.status,
    filter.overdueOnly,
    page,
    hasMore,
    loading,
    failure?.messageKey,
    actionFailure?.messageKey,
    selectedId,
    history.length,
    reviews.length,
    detailLoading,
  ];
}

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._repo) : super(const OrdersState());

  final AdminOrderRepository _repo;

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

  Future<void> applyFilter(OrderFilter filter) async {
    emit(state.copyWith(filter: filter, page: 0, clearSelection: true));
    await load();
  }

  Future<void> goToPage(int page) async {
    emit(state.copyWith(page: page, clearSelection: true));
    await load();
  }

  Future<void> select(String orderId) async {
    emit(
      state.copyWith(
        selectedId: orderId,
        history: const [],
        reviews: const [],
        detailLoading: true,
      ),
    );

    final results = await Future.wait([
      _repo.history(orderId),
      _repo.reviews(orderId),
    ]);

    emit(
      state.copyWith(
        history:
            (results[0] as Result<List<OrderHistoryEntry>>).valueOrNull ??
            const [],
        reviews:
            (results[1] as Result<List<Map<String, dynamic>>>).valueOrNull ??
            const [],
        detailLoading: false,
      ),
    );
  }

  void closeDetail() => emit(state.copyWith(clearSelection: true));

  Future<bool> cancel(String orderId, String reason) async {
    emit(state.copyWith(clearActionFailure: true));

    final res = await _repo.cancel(orderId, reason);
    if (res case Fail(:final failure)) {
      emit(state.copyWith(actionFailure: failure));
      return false;
    }

    emit(state.copyWith(clearSelection: true));
    await load();
    return true;
  }
}
