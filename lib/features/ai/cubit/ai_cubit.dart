import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/admin_config.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/safe_emit.dart';
import '../../../data/models/admin_ai.dart';
import '../../../data/repositories/admin_ai_repository.dart';

/// AI moduli uchta ko'rinishga bo'lingan: foydalanish (kim qancha
/// so'ramoqda), savollar (nima so'ralmoqda) va skanlar (nima aniqlandi,
/// qaysi model, qancha vaqtda, qaysi rasm bo'yicha).
enum AiTab { usage, questions, scans }

class AiState extends Equatable {
  const AiState({
    this.tab = AiTab.usage,
    this.usage = const [],
    this.questions = const [],
    this.scans = const [],
    this.models = const [],
    this.totals = const AiTotals(),
    this.imageUrls = const {},
    this.days = 7,
    this.severity,
    this.problemsOnly = false,
    this.search = '',
    this.page = 0,
    this.hasMore = false,
    this.loading = true,
    this.failure,
    this.selectedScanId,
    this.selectedQuestion,
    this.conversation = const [],
    this.conversationLoading = false,
    this.conversationFailure,
  });

  final AiTab tab;
  final List<AiUsageRow> usage;
  final List<AiQuestion> questions;
  final List<ScanRow> scans;
  final List<ModelUsage> models;
  final AiTotals totals;

  /// Skan rasmlari: `image_path -> signed URL`. Joriy sahifa uchun bir
  /// so'rov bilan olinadi — har qator uchun alohida so'rov 50 ta tarmoq
  /// chaqiruvi bo'lardi.
  final Map<String, String> imageUrls;

  final int days;
  final String? severity;
  final bool problemsOnly;
  final String search;
  final int page;
  final bool hasMore;
  final bool loading;
  final AppFailure? failure;

  final String? selectedScanId;
  final AiQuestion? selectedQuestion;
  final List<AiChatMessage> conversation;
  final bool conversationLoading;
  final AppFailure? conversationFailure;

  ScanRow? get selectedScan =>
      scans.where((s) => s.id == selectedScanId).firstOrNull;

  AiState copyWith({
    AiTab? tab,
    List<AiUsageRow>? usage,
    List<AiQuestion>? questions,
    List<ScanRow>? scans,
    List<ModelUsage>? models,
    AiTotals? totals,
    Map<String, String>? imageUrls,
    int? days,
    String? severity,
    bool? problemsOnly,
    String? search,
    int? page,
    bool? hasMore,
    bool? loading,
    AppFailure? failure,
    String? selectedScanId,
    AiQuestion? selectedQuestion,
    List<AiChatMessage>? conversation,
    bool? conversationLoading,
    AppFailure? conversationFailure,
    bool clearFailure = false,
    bool clearSeverity = false,
    bool clearSelection = false,
    bool clearConversationFailure = false,
  }) => AiState(
    tab: tab ?? this.tab,
    usage: usage ?? this.usage,
    questions: questions ?? this.questions,
    scans: scans ?? this.scans,
    models: models ?? this.models,
    totals: totals ?? this.totals,
    imageUrls: imageUrls ?? this.imageUrls,
    days: days ?? this.days,
    severity: clearSeverity ? null : (severity ?? this.severity),
    problemsOnly: problemsOnly ?? this.problemsOnly,
    search: search ?? this.search,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    loading: loading ?? this.loading,
    failure: clearFailure ? null : (failure ?? this.failure),
    selectedScanId: clearSelection
        ? null
        : (selectedScanId ?? this.selectedScanId),
    selectedQuestion: clearSelection
        ? null
        : (selectedQuestion ?? this.selectedQuestion),
    conversation: clearSelection
        ? const []
        : (conversation ?? this.conversation),
    conversationLoading: conversationLoading ?? this.conversationLoading,
    conversationFailure: clearConversationFailure || clearSelection
        ? null
        : (conversationFailure ?? this.conversationFailure),
  );

  @override
  List<Object?> get props => [
    tab,
    usage.length,
    questions.map((q) => q.id).join(),
    scans.map((s) => s.id).join(),
    models.length,
    totals.questions,
    totals.scans,
    totals.activeUsers,
    imageUrls.length,
    days,
    severity,
    problemsOnly,
    search,
    page,
    hasMore,
    loading,
    failure?.messageKey,
    selectedScanId,
    selectedQuestion?.id,
    conversation.length,
    conversationLoading,
    conversationFailure?.messageKey,
  ];
}

class AiCubit extends Cubit<AiState> with SafeEmit<AiState> {
  AiCubit(this._repo, this._locale) : super(const AiState());

  final AdminAiRepository _repo;
  final String _locale;

  Future<void> init() async {
    // Model taqsimoti va jami ko'rsatkichlar barcha ko'rinishlarda tepada
    // turadi, shuning uchun tab almashganda qayta so'ralmaydi.
    final results = await Future.wait([
      _repo.modelBreakdown(),
      _repo.totals(days: state.days),
    ]);
    emit(
      state.copyWith(
        models:
            (results[0] as Result<List<ModelUsage>>).valueOrNull ?? const [],
        totals:
            (results[1] as Result<AiTotals>).valueOrNull ?? const AiTotals(),
      ),
    );
    await load();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));

    switch (state.tab) {
      case AiTab.usage:
        final res = await _repo.usage(days: state.days, page: state.page);
        _apply(res, (rows) => state.copyWith(usage: rows));

      case AiTab.questions:
        final res = await _repo.questions(
          page: state.page,
          search: state.search,
        );
        _apply(res, (rows) => state.copyWith(questions: rows));

      case AiTab.scans:
        final res = await _repo.scans(
          page: state.page,
          severity: state.severity,
          problemsOnly: state.problemsOnly,
          locale: _locale,
        );
        _apply(res, (rows) => state.copyWith(scans: rows));
        await _loadImages();
    }
  }

  /// Sahifalash umumiy: `pageSize + 1` qator so'ralgan, ortiqchasi faqat
  /// "keyingi sahifa bor" belgisi.
  void _apply<T>(Result<List<T>> res, AiState Function(List<T>) put) {
    switch (res) {
      case Ok(:final value):
        final hasMore = value.length > AdminConfig.pageSize;
        final rows = hasMore ? value.sublist(0, AdminConfig.pageSize) : value;
        emit(
          put(
            rows,
          ).copyWith(loading: false, hasMore: hasMore, clearFailure: true),
        );
      case Fail(:final failure):
        emit(
          put(<T>[]).copyWith(loading: false, hasMore: false, failure: failure),
        );
    }
  }

  Future<void> _loadImages() async {
    final paths = [
      for (final s in state.scans)
        if (s.imagePath != null && !state.imageUrls.containsKey(s.imagePath))
          s.imagePath!,
    ];
    if (paths.isEmpty) return;

    final res = await _repo.scanImageUrls(paths);
    final urls = res.valueOrNull;
    if (urls == null || urls.isEmpty) return;
    emit(state.copyWith(imageUrls: {...state.imageUrls, ...urls}));
  }

  Future<void> switchTab(AiTab tab) async {
    if (tab == state.tab) return;
    emit(state.copyWith(tab: tab, page: 0, clearSelection: true));
    await load();
  }

  Future<void> setDays(int days) async {
    emit(state.copyWith(days: days, page: 0));
    final totals = await _repo.totals(days: days);
    emit(state.copyWith(totals: totals.valueOrNull ?? const AiTotals()));
    await load();
  }

  Future<void> setSeverity(String? severity) async {
    emit(
      state.copyWith(
        page: 0,
        severity: severity,
        clearSeverity: severity == null,
        clearSelection: true,
      ),
    );
    await load();
  }

  Future<void> toggleProblems() async {
    emit(
      state.copyWith(
        problemsOnly: !state.problemsOnly,
        page: 0,
        clearSelection: true,
      ),
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

  void selectScan(String id) => emit(state.copyWith(selectedScanId: id));

  Future<void> openQuestion(AiQuestion question) async {
    emit(
      state.copyWith(
        selectedQuestion: question,
        conversation: const [],
        conversationLoading: true,
        clearConversationFailure: true,
      ),
    );

    final res = await _repo.conversation(question.conversationId);
    // Panel yopilgan yoki boshqa savol tanlangan bo'lsa eski javob tashlanadi.
    if (state.selectedQuestion?.id != question.id) return;

    switch (res) {
      case Ok(:final value):
        emit(state.copyWith(conversation: value, conversationLoading: false));
      case Fail(:final failure):
        emit(
          state.copyWith(
            conversationLoading: false,
            conversationFailure: failure,
          ),
        );
    }
  }

  void closeDetail() => emit(state.copyWith(clearSelection: true));
}
