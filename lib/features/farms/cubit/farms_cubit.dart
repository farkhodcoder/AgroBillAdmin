import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/admin_config.dart';
import '../../../core/utils/result.dart';
import '../../../data/models/admin_farm.dart';
import '../../../data/models/admin_user.dart';
import '../../../data/repositories/admin_farm_repository.dart';
import '../../../data/repositories/admin_user_repository.dart';

class FarmsState extends Equatable {
  const FarmsState({
    this.rows = const [],
    this.regions = const [],
    this.filter = const FarmFilter(),
    this.page = 0,
    this.hasMore = false,
    this.loading = true,
    this.failure,
    this.selectedFarmId,
    this.fields = const [],
    this.fieldsLoading = false,
  });

  final List<AdminFarmRow> rows;
  final List<RefItem> regions;
  final FarmFilter filter;
  final int page;
  final bool hasMore;
  final bool loading;
  final AppFailure? failure;

  /// Ochilgan xo'jalik va uning dalalari.
  final String? selectedFarmId;
  final List<AdminFieldRow> fields;
  final bool fieldsLoading;

  AdminFarmRow? get selected =>
      rows.where((r) => r.id == selectedFarmId).firstOrNull;

  FarmsState copyWith({
    List<AdminFarmRow>? rows,
    List<RefItem>? regions,
    FarmFilter? filter,
    int? page,
    bool? hasMore,
    bool? loading,
    AppFailure? failure,
    String? selectedFarmId,
    List<AdminFieldRow>? fields,
    bool? fieldsLoading,
    bool clearFailure = false,
    bool clearSelection = false,
  }) => FarmsState(
    rows: rows ?? this.rows,
    regions: regions ?? this.regions,
    filter: filter ?? this.filter,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
    selectedFarmId: clearSelection
        ? null
        : (selectedFarmId ?? this.selectedFarmId),
    fields: clearSelection ? const [] : (fields ?? this.fields),
    fieldsLoading: fieldsLoading ?? this.fieldsLoading,
  );

  @override
  List<Object?> get props => [
    rows.map((r) => r.id).join(),
    regions.length,
    filter.search,
    filter.regionId,
    filter.irrigation,
    page,
    hasMore,
    loading,
    failure?.messageKey,
    selectedFarmId,
    fields.length,
    fieldsLoading,
  ];
}

class FarmsCubit extends Cubit<FarmsState> {
  FarmsCubit(this._repo, this._userRepo, this._locale)
    : super(const FarmsState());

  final AdminFarmRepository _repo;
  final AdminUserRepository _userRepo;
  final String _locale;

  Future<void> init() async {
    // Viloyatlar ro'yxati foydalanuvchilar moduli bilan bir xil — takroriy
    // so'rov yozilmasin uchun o'sha repozitoriy ishlatiladi.
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

  Future<void> applyFilter(FarmFilter filter) async {
    emit(state.copyWith(filter: filter, page: 0));
    await load();
  }

  Future<void> goToPage(int page) async {
    emit(state.copyWith(page: page));
    await load();
  }

  /// Xo'jalikni ochadi va dalalarini yuklaydi.
  Future<void> select(String farmId) async {
    emit(
      state.copyWith(
        selectedFarmId: farmId,
        fields: const [],
        fieldsLoading: true,
      ),
    );

    final res = await _repo.fields(farmId, locale: _locale);
    emit(
      state.copyWith(fields: res.valueOrNull ?? const [], fieldsLoading: false),
    );
  }

  void closeDetail() => emit(state.copyWith(clearSelection: true));
}
