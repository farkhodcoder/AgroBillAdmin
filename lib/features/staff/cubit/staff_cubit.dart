import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/result.dart';
import '../../../core/utils/safe_emit.dart';
import '../../../data/models/admin_staff.dart';
import '../../../data/repositories/admin_staff_repository.dart';

class StaffState extends Equatable {
  const StaffState({
    this.staff = const [],
    this.roles = const [],
    this.events = const [],
    this.loading = true,
    this.busy = false,
    this.search = '',
    this.roleFilter,
    this.activeFilter,
    this.failure,
    this.actionFailure,
  });

  final List<StaffRow> staff;
  final List<RoleWithPermissions> roles;
  final List<LoginEvent> events;
  final bool loading;

  /// Amal so'rovi ketmoqda — tugmalar takror bosilmasin.
  final bool busy;

  /// Ro'yxat filtrlari. Xodimlar o'nlab, minglab emas — filtrlash mijozda,
  /// har o'zgarishda bazaga qayta so'rov yuborilmaydi.
  final String search;
  final String? roleFilter;
  final bool? activeFilter;
  final AppFailure? failure;
  final AppFailure? actionFailure;

  List<StaffRow> get visible {
    final q = search.toLowerCase();
    return [
      for (final s in staff)
        if ((roleFilter == null || s.roleCode == roleFilter) &&
            (activeFilter == null || s.isActive == activeFilter) &&
            (q.isEmpty ||
                (s.fullName ?? '').toLowerCase().contains(q) ||
                (s.email ?? '').toLowerCase().contains(q)))
          s,
    ];
  }

  int get activeCount => staff.where((s) => s.isActive).length;

  StaffState copyWith({
    List<StaffRow>? staff,
    List<RoleWithPermissions>? roles,
    List<LoginEvent>? events,
    bool? loading,
    bool? busy,
    String? search,
    String? roleFilter,
    bool? activeFilter,
    bool clearRoleFilter = false,
    bool clearActiveFilter = false,
    AppFailure? failure,
    AppFailure? actionFailure,
    bool clearFailure = false,
    bool clearActionFailure = false,
  }) => StaffState(
    staff: staff ?? this.staff,
    roles: roles ?? this.roles,
    events: events ?? this.events,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    search: search ?? this.search,
    roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
    activeFilter: clearActiveFilter
        ? null
        : (activeFilter ?? this.activeFilter),
    failure: clearFailure ? null : (failure ?? this.failure),
    actionFailure: clearActionFailure
        ? null
        : (actionFailure ?? this.actionFailure),
  );

  @override
  List<Object?> get props => [
    staff.map((s) => '${s.id}${s.roleCode}${s.isActive}').join(),
    roles.length,
    events.length,
    loading,
    busy,
    search,
    roleFilter,
    activeFilter,
    failure?.messageKey,
    actionFailure?.messageKey,
  ];
}

class StaffCubit extends Cubit<StaffState> with SafeEmit<StaffState> {
  StaffCubit(this._repo, this._locale) : super(const StaffState());

  final AdminStaffRepository _repo;
  final String _locale;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));

    // Uchtasi ham bir ekranda ko'rinadi — ketma-ket so'ralsa sahifa
    // uch marta sakrardi.
    final results = await Future.wait([
      _repo.staff(),
      _repo.roles(locale: _locale),
      _repo.loginEvents(),
    ]);

    final staffRes = results[0] as Result<List<StaffRow>>;
    if (staffRes case Fail(:final failure)) {
      emit(state.copyWith(loading: false, failure: failure));
      return;
    }

    emit(
      state.copyWith(
        loading: false,
        staff: staffRes.valueOrNull ?? const [],
        roles:
            (results[1] as Result<List<RoleWithPermissions>>).valueOrNull ??
            const [],
        // Kirish jurnali `audit.read` talab qiladi — ruxsat bo'lmasa
        // bo'sh qoladi, bu xato emas.
        events:
            (results[2] as Result<List<LoginEvent>>).valueOrNull ?? const [],
        clearFailure: true,
      ),
    );
  }

  void setSearch(String value) => emit(state.copyWith(search: value.trim()));

  void setRoleFilter(String? role) =>
      emit(state.copyWith(roleFilter: role, clearRoleFilter: role == null));

  void setActiveFilter(bool? active) => emit(
    state.copyWith(activeFilter: active, clearActiveFilter: active == null),
  );

  Future<bool> setRole(String userId, String? roleCode, String reason) =>
      _act(() => _repo.setRole(userId, roleCode, reason));

  Future<bool> createStaff({
    required String email,
    required String password,
    required String fullName,
    required String roleCode,
    required String reason,
  }) => _act(
    () => _repo.createStaff(
      email: email,
      password: password,
      fullName: fullName,
      roleCode: roleCode,
      reason: reason,
    ),
  );

  /// Parol ro'yxatda ko'rinmaydi — qayta yuklash shart emas.
  Future<bool> setPassword(String userId, String password, String reason) =>
      _act(() => _repo.setPassword(userId, password, reason), reload: false);

  Future<bool> setActive(String userId, bool active, String reason) =>
      _act(() => _repo.setActive(userId, active, reason));

  /// Har bir amalning umumiy qismi: xatoni tozalash, so'rov, xato bo'lsa
  /// snackbar uchun holatga yozish, muvaffaqiyatda ro'yxatni yangilash.
  Future<bool> _act(
    Future<Result<void>> Function() action, {
    bool reload = true,
  }) async {
    emit(state.copyWith(clearActionFailure: true, busy: true));

    final res = await action();
    if (res case Fail(:final failure)) {
      emit(state.copyWith(actionFailure: failure, busy: false));
      return false;
    }

    emit(state.copyWith(busy: false));
    if (reload) await load();
    return true;
  }
}
