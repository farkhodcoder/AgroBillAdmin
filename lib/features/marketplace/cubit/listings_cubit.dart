import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/admin_config.dart';
import '../../../core/utils/result.dart';
import '../../../data/models/admin_listing.dart';
import '../../../data/models/admin_user.dart';
import '../../../data/repositories/admin_listing_repository.dart';
import '../../../data/repositories/admin_user_repository.dart';

class ListingsState extends Equatable {
  const ListingsState({
    this.rows = const [],
    this.regions = const [],
    this.filter = const ListingFilter(status: ListingStatus.pending),
    this.page = 0,
    this.hasMore = false,
    this.loading = true,
    this.failure,
    this.actionFailure,
    this.pendingCount = 0,
    this.selectedId,
    this.imageUrls = const [],
    this.history = const [],
    this.detailLoading = false,
  });

  final List<AdminListingRow> rows;
  final List<RefItem> regions;
  final ListingFilter filter;
  final int page;
  final bool hasMore;
  final bool loading;
  final AppFailure? failure;
  final AppFailure? actionFailure;

  /// Navbatdagi e'lonlar soni — sidebar va sarlavhada koʻrsatiladi.
  final int pendingCount;

  final String? selectedId;
  final List<String> imageUrls;
  final List<ModerationEntry> history;
  final bool detailLoading;

  AdminListingRow? get selected =>
      rows.where((r) => r.id == selectedId).firstOrNull;

  ListingsState copyWith({
    List<AdminListingRow>? rows,
    List<RefItem>? regions,
    ListingFilter? filter,
    int? page,
    bool? hasMore,
    bool? loading,
    AppFailure? failure,
    AppFailure? actionFailure,
    int? pendingCount,
    String? selectedId,
    List<String>? imageUrls,
    List<ModerationEntry>? history,
    bool? detailLoading,
    bool clearFailure = false,
    bool clearActionFailure = false,
    bool clearSelection = false,
  }) => ListingsState(
    rows: rows ?? this.rows,
    regions: regions ?? this.regions,
    filter: filter ?? this.filter,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
    pendingCount: pendingCount ?? this.pendingCount,
    selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
    imageUrls: clearSelection ? const [] : (imageUrls ?? this.imageUrls),
    history: clearSelection ? const [] : (history ?? this.history),
    detailLoading: detailLoading ?? this.detailLoading,
  );

  @override
  List<Object?> get props => [
    rows.map((r) => '${r.id}${r.status}').join(),
    regions.length,
    filter.search,
    filter.status,
    filter.regionId,
    page,
    hasMore,
    loading,
    failure?.messageKey,
    actionFailure?.messageKey,
    pendingCount,
    selectedId,
    imageUrls.length,
    history.length,
    detailLoading,
  ];
}

class ListingsCubit extends Cubit<ListingsState> {
  ListingsCubit(this._repo, this._userRepo, this._locale)
    : super(const ListingsState());

  final AdminListingRepository _repo;
  final AdminUserRepository _userRepo;
  final String _locale;

  Future<void> init() async {
    final regionsRes = await _userRepo.regions(locale: _locale);
    emit(state.copyWith(regions: regionsRes.valueOrNull ?? const []));
    await load();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));

    final res = await _repo.list(
      filter: state.filter,
      page: state.page,
      locale: _locale,
    );
    final countRes = await _repo.pendingCount();

    switch (res) {
      case Ok(:final value):
        final hasMore = value.length > AdminConfig.pageSize;
        emit(
          state.copyWith(
            loading: false,
            rows: hasMore ? value.sublist(0, AdminConfig.pageSize) : value,
            hasMore: hasMore,
            pendingCount: countRes.valueOrNull ?? state.pendingCount,
            clearFailure: true,
          ),
        );
      case Fail(:final failure):
        emit(state.copyWith(loading: false, failure: failure, rows: const []));
    }
  }

  Future<void> applyFilter(ListingFilter filter) async {
    emit(state.copyWith(filter: filter, page: 0, clearSelection: true));
    await load();
  }

  Future<void> goToPage(int page) async {
    emit(state.copyWith(page: page, clearSelection: true));
    await load();
  }

  /// E'lonni ochadi: rasmlar uchun signed URL va moderatsiya tarixi.
  Future<void> select(String listingId) async {
    final row = state.rows.where((r) => r.id == listingId).firstOrNull;
    emit(
      state.copyWith(
        selectedId: listingId,
        imageUrls: const [],
        history: const [],
        detailLoading: true,
      ),
    );

    final results = await Future.wait([
      _repo.imageUrls(row?.imagePaths ?? const []),
      _repo.history(listingId),
    ]);

    emit(
      state.copyWith(
        imageUrls: (results[0] as Result<List<String>>).valueOrNull ?? const [],
        history:
            (results[1] as Result<List<ModerationEntry>>).valueOrNull ??
            const [],
        detailLoading: false,
      ),
    );
  }

  void closeDetail() => emit(state.copyWith(clearSelection: true));

  Future<bool> moderate(String listingId, String status, String? reason) =>
      _action(
        () => _repo.moderate(
          listingId: listingId,
          status: status,
          reason: reason,
        ),
      );

  Future<bool> delete(String listingId, String reason) =>
      _action(() => _repo.delete(listingId, reason));

  /// Amaldan keyin ro'yxat yangilanadi va panel yopiladi — qaror qabul
  /// qilingach navbatdagi e'longa o'tiladi.
  Future<bool> _action(Future<Result<void>> Function() run) async {
    emit(state.copyWith(clearActionFailure: true));

    final res = await run();
    if (res case Fail(:final failure)) {
      emit(state.copyWith(actionFailure: failure));
      return false;
    }

    emit(state.copyWith(clearSelection: true));
    await load();
    return true;
  }
}
