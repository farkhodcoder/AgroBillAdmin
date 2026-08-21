import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/admin_config.dart';
import '../../../core/utils/result.dart';
import '../../../data/models/admin_ai.dart';
import '../../../data/repositories/admin_ai_repository.dart';

/// AI moduli ikkita ko'rinishga bo'lingan: foydalanish (kim qancha
/// so'ramoqda) va skanlar (nima aniqlandi, qaysi model, qancha vaqtda).
enum AiTab { usage, scans }

class AiState extends Equatable {
  const AiState({
    this.tab = AiTab.usage,
    this.usage = const [],
    this.scans = const [],
    this.models = const [],
    this.days = 7,
    this.severity,
    this.problemsOnly = false,
    this.page = 0,
    this.hasMore = false,
    this.loading = true,
    this.failure,
  });

  final AiTab tab;
  final List<AiUsageRow> usage;
  final List<ScanRow> scans;
  final List<ModelUsage> models;
  final int days;
  final String? severity;
  final bool problemsOnly;
  final int page;
  final bool hasMore;
  final bool loading;
  final AppFailure? failure;

  AiState copyWith({
    AiTab? tab,
    List<AiUsageRow>? usage,
    List<ScanRow>? scans,
    List<ModelUsage>? models,
    int? days,
    String? severity,
    bool? problemsOnly,
    int? page,
    bool? hasMore,
    bool? loading,
    AppFailure? failure,
    bool clearFailure = false,
    bool clearSeverity = false,
  }) => AiState(
    tab: tab ?? this.tab,
    usage: usage ?? this.usage,
    scans: scans ?? this.scans,
    models: models ?? this.models,
    days: days ?? this.days,
    severity: clearSeverity ? null : (severity ?? this.severity),
    problemsOnly: problemsOnly ?? this.problemsOnly,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
  );

  @override
  List<Object?> get props => [
    tab,
    usage.length,
    scans.map((s) => s.id).join(),
    models.length,
    days,
    severity,
    problemsOnly,
    page,
    hasMore,
    loading,
    failure?.messageKey,
  ];
}

class AiCubit extends Cubit<AiState> {
  AiCubit(this._repo, this._locale) : super(const AiState());

  final AdminAiRepository _repo;
  final String _locale;

  Future<void> init() async {
    // Model taqsimoti ikkala ko'rinishda ham tepada turadi, shuning uchun
    // bir marta yuklanadi va tab almashganda qayta so'ralmaydi.
    final modelsRes = await _repo.modelBreakdown();
    emit(state.copyWith(models: modelsRes.valueOrNull ?? const []));
    await load();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));

    if (state.tab == AiTab.usage) {
      final res = await _repo.usage(days: state.days, page: state.page);
      switch (res) {
        case Ok(:final value):
          final hasMore = value.length > AdminConfig.pageSize;
          emit(
            state.copyWith(
              loading: false,
              usage: hasMore ? value.sublist(0, AdminConfig.pageSize) : value,
              hasMore: hasMore,
              clearFailure: true,
            ),
          );
        case Fail(:final failure):
          emit(
            state.copyWith(loading: false, failure: failure, usage: const []),
          );
      }
      return;
    }

    final res = await _repo.scans(
      page: state.page,
      severity: state.severity,
      problemsOnly: state.problemsOnly,
      locale: _locale,
    );
    switch (res) {
      case Ok(:final value):
        final hasMore = value.length > AdminConfig.pageSize;
        emit(
          state.copyWith(
            loading: false,
            scans: hasMore ? value.sublist(0, AdminConfig.pageSize) : value,
            hasMore: hasMore,
            clearFailure: true,
          ),
        );
      case Fail(:final failure):
        emit(state.copyWith(loading: false, failure: failure, scans: const []));
    }
  }

  Future<void> switchTab(AiTab tab) async {
    if (tab == state.tab) return;
    emit(state.copyWith(tab: tab, page: 0));
    await load();
  }

  Future<void> setDays(int days) async {
    emit(state.copyWith(days: days, page: 0));
    await load();
  }

  Future<void> setSeverity(String? severity) async {
    emit(
      state.copyWith(
        page: 0,
        severity: severity,
        clearSeverity: severity == null,
      ),
    );
    await load();
  }

  Future<void> toggleProblems() async {
    emit(state.copyWith(problemsOnly: !state.problemsOnly, page: 0));
    await load();
  }

  Future<void> goToPage(int page) async {
    emit(state.copyWith(page: page));
    await load();
  }
}
