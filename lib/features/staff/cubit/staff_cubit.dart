import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/result.dart';
import '../../../data/models/admin_staff.dart';
import '../../../data/repositories/admin_staff_repository.dart';

class StaffState extends Equatable {
  const StaffState({
    this.staff = const [],
    this.roles = const [],
    this.events = const [],
    this.loading = true,
    this.failure,
    this.actionFailure,
  });

  final List<StaffRow> staff;
  final List<RoleWithPermissions> roles;
  final List<LoginEvent> events;
  final bool loading;
  final AppFailure? failure;
  final AppFailure? actionFailure;

  StaffState copyWith({
    List<StaffRow>? staff,
    List<RoleWithPermissions>? roles,
    List<LoginEvent>? events,
    bool? loading,
    AppFailure? failure,
    AppFailure? actionFailure,
    bool clearFailure = false,
    bool clearActionFailure = false,
  }) => StaffState(
    staff: staff ?? this.staff,
    roles: roles ?? this.roles,
    events: events ?? this.events,
    loading: loading ?? this.loading,
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
    failure?.messageKey,
    actionFailure?.messageKey,
  ];
}

class StaffCubit extends Cubit<StaffState> {
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

  Future<bool> setRole(String userId, String? roleCode, String reason) async {
    emit(state.copyWith(clearActionFailure: true));

    final res = await _repo.setRole(userId, roleCode, reason);
    if (res case Fail(:final failure)) {
      emit(state.copyWith(actionFailure: failure));
      return false;
    }

    await load();
    return true;
  }
}
