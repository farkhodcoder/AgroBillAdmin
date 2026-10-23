import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/safe_emit.dart';
import '../../../data/models/admin_ai.dart';
import '../../../data/repositories/admin_ai_repository.dart';

class DiseaseState extends Equatable {
  const DiseaseState({
    this.rows = const [],
    this.search = '',
    this.status,
    this.loading = true,
    this.failure,
    this.actionFailure,
    this.selectedId,
    this.crops = const [],
    this.saving = false,
  });

  final List<DiseaseRow> rows;
  final String search;
  final String? status;
  final bool loading;
  final AppFailure? failure;
  final AppFailure? actionFailure;
  final int? selectedId;

  /// Formadagi ekin tanlovi — bir marta yuklanadi.
  final List<CropOption> crops;

  /// Forma saqlanmoqda — tugma takror bosilmasin.
  final bool saving;

  DiseaseRow? get selected => rows.where((r) => r.id == selectedId).firstOrNull;

  /// Tarjimasi to'liq bo'lmaganlar — ro'yxat tepasidagi ogohlantirish.
  int get untranslatedCount => rows.where((r) => !r.isTranslated).length;

  DiseaseState copyWith({
    List<DiseaseRow>? rows,
    String? search,
    String? status,
    bool? loading,
    AppFailure? failure,
    AppFailure? actionFailure,
    int? selectedId,
    List<CropOption>? crops,
    bool? saving,
    bool clearStatus = false,
    bool clearFailure = false,
    bool clearActionFailure = false,
    bool clearSelection = false,
  }) => DiseaseState(
    rows: rows ?? this.rows,
    search: search ?? this.search,
    status: clearStatus ? null : (status ?? this.status),
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
    selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
    crops: crops ?? this.crops,
    saving: saving ?? this.saving,
  );

  @override
  List<Object?> get props => [
    rows.map((r) => '${r.id}${r.status}').join(),
    search,
    status,
    loading,
    failure?.messageKey,
    actionFailure?.messageKey,
    selectedId,
    crops.length,
    saving,
  ];
}

class DiseaseCubit extends Cubit<DiseaseState> with SafeEmit<DiseaseState> {
  DiseaseCubit(this._repo, this._locale) : super(const DiseaseState());

  final AdminAiRepository _repo;
  final String _locale;

  /// Ma'lumotnomada o'nlab qator bor, minglab emas — sahifalash kerak emas,
  /// hammasi bir marta yuklanadi.
  Future<void> init() async {
    final crops = await _repo.crops(locale: _locale);
    emit(state.copyWith(crops: crops.valueOrNull ?? const []));
    await load();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));

    final res = await _repo.diseases(
      search: state.search,
      status: state.status,
      locale: _locale,
    );

    switch (res) {
      case Ok(:final value):
        emit(state.copyWith(loading: false, rows: value, clearFailure: true));
      case Fail(:final failure):
        emit(state.copyWith(loading: false, failure: failure, rows: const []));
    }
  }

  Future<void> setSearch(String search) async {
    emit(state.copyWith(search: search, clearSelection: true));
    await load();
  }

  Future<void> setStatus(String? status) async {
    emit(
      state.copyWith(
        status: status,
        clearStatus: status == null,
        clearSelection: true,
      ),
    );
    await load();
  }

  void select(int id) => emit(state.copyWith(selectedId: id));
  void closeDetail() => emit(state.copyWith(clearSelection: true));

  Future<bool> setStatusOf(int id, String status) async {
    emit(state.copyWith(clearActionFailure: true));

    final res = await _repo.setDiseaseStatus(id, status);
    if (res case Fail(:final failure)) {
      emit(state.copyWith(actionFailure: failure));
      return false;
    }

    await load();
    return true;
  }

  /// Yangi yozuv yoki tahrir. [id] `null` bo'lsa yaratiladi (`draft`).
  ///
  /// Muvaffaqiyatda yozuv tanlangan holda qoladi — admin natijani darhol
  /// tafsilot panelida ko'radi.
  Future<bool> save(int? id, DiseaseDraft draft) async {
    emit(state.copyWith(clearActionFailure: true, saving: true));

    final Result<int> res = id == null
        ? await _repo.createDisease(draft)
        : (await _repo.updateDisease(id, draft)).map((_) => id);

    switch (res) {
      case Ok(:final value):
        emit(state.copyWith(saving: false));
        await load();
        emit(state.copyWith(selectedId: value));
        return true;
      case Fail(:final failure):
        emit(state.copyWith(saving: false, actionFailure: failure));
        return false;
    }
  }
}
