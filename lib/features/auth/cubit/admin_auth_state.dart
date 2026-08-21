part of 'admin_auth_cubit.dart';

/// Kirish oqimining holati.
///
/// `stage` — router qaysi ekranni ko'rsatishini hal qiladi; `busy` va
/// `failure` — joriy ekran ichidagi holat.
class AdminAuthState extends Equatable {
  const AdminAuthState({
    this.stage = AuthStage.signedOut,
    this.permissions = const AdminPermissions.none(),
    this.busy = false,
    this.failure,
    this.bootstrapped = false,
  });

  final AuthStage stage;
  final AdminPermissions permissions;

  final bool busy;
  final AppFailure? failure;

  /// Birinchi tekshiruv tugadimi. Tugamaguncha router splash ko'rsatadi —
  /// aks holda ilova ochilishida login ekrani bir zumga miltillab ketardi.
  final bool bootstrapped;

  bool get isReady => stage == AuthStage.ready;

  AdminAuthState copyWith({
    AuthStage? stage,
    AdminPermissions? permissions,
    bool? busy,
    AppFailure? failure,
    bool? bootstrapped,
    bool clearFailure = false,
  }) => AdminAuthState(
    stage: stage ?? this.stage,
    permissions: permissions ?? this.permissions,
    busy: busy ?? this.busy,
    failure: clearFailure ? null : (failure ?? this.failure),
    bootstrapped: bootstrapped ?? this.bootstrapped,
  );

  @override
  List<Object?> get props => [
    stage,
    permissions.roleCode,
    permissions.codes,
    permissions.languageCode,
    busy,
    failure?.messageKey,
    bootstrapped,
  ];
}
