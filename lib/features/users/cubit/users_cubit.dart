import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/supabase/admin_config.dart';
import '../../../core/utils/result.dart';
import '../../../data/models/admin_user.dart';
import '../../../data/repositories/admin_user_repository.dart';

class UsersState extends Equatable {
  const UsersState({
    this.rows = const [],
    this.regions = const [],
    this.filter = const UserFilter(),
    this.page = 0,
    this.hasMore = false,
    this.loading = true,
    this.failure,
    this.actionFailure,
  });

  final List<AdminUserRow> rows;
  final List<RefItem> regions;
  final UserFilter filter;
  final int page;
  final bool hasMore;
  final bool loading;

  /// Ro'yxatni yuklashdagi xato.
  final AppFailure? failure;

  /// Bloklash/rol berish kabi amaldagi xato — ro'yxat joyida qoladi,
  /// shuning uchun alohida maydon.
  final AppFailure? actionFailure;

  UsersState copyWith({
    List<AdminUserRow>? rows,
    List<RefItem>? regions,
    UserFilter? filter,
    int? page,
    bool? hasMore,
    bool? loading,
    AppFailure? failure,
    AppFailure? actionFailure,
    bool clearFailure = false,
    bool clearActionFailure = false,
  }) => UsersState(
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
  );

  @override
  List<Object?> get props => [
    rows.map((r) => '${r.id}${r.isBlocked}').join(),
    regions.length,
    filter.search,
    filter.role,
    filter.regionId,
    filter.activity,
    filter.blocked,
    page,
    hasMore,
    loading,
    failure?.messageKey,
    actionFailure?.messageKey,
  ];
}

class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._repo, this._locale) : super(const UsersState());

  final AdminUserRepository _repo;
  final String _locale;

  Future<void> init() async {
    final regionsRes = await _repo.regions(locale: _locale);
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
        // `pageSize + 1` so'ralgan: ortiqcha qator keyingi sahifa borligini
        // bildiradi va ekranga chiqarilmaydi.
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

  /// Filtr o'zgarganda doim birinchi sahifaga qaytiladi — aks holda
  /// foydalanuvchi 5-sahifada turib filtr almashtirsa bo'sh ekran ko'rardi.
  Future<void> applyFilter(UserFilter filter) async {
    emit(state.copyWith(filter: filter, page: 0));
    await load();
  }

  Future<void> goToPage(int page) async {
    emit(state.copyWith(page: page));
    await load();
  }

  Future<bool> block(String userId, String reason) =>
      _action(() => _repo.block(userId, reason));

  Future<bool> unblock(String userId, String? reason) =>
      _action(() => _repo.unblock(userId, reason));

  Future<bool> setRole(String userId, String? roleCode, String reason) =>
      _action(() => _repo.setRole(userId, roleCode, reason));

  /// Amal bajaradi va ro'yxatni yangilaydi.
  ///
  /// `true` qaytsa amal o'tdi. Xato bo'lsa `actionFailure` da qoladi va
  /// ro'yxat tegilmaydi — admin nima bo'lganini ko'rib, qayta urina oladi.
  Future<bool> _action(Future<Result<void>> Function() run) async {
    emit(state.copyWith(clearActionFailure: true));

    final res = await run();
    if (res case Fail(:final failure)) {
      emit(state.copyWith(actionFailure: failure));
      return false;
    }

    await load();
    return true;
  }
}
