import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/admin_error_codes.dart';
import '../../../core/rbac/permission.dart';
import '../../../core/supabase/db.dart';
import '../../../core/utils/result.dart';
import '../../../data/repositories/admin_auth_repository.dart';

part 'admin_auth_state.dart';

/// Kirish oqimi va sessiya holati.
///
/// Router shu cubit'ga qaraydi (`refreshListenable`), ekranlar esa unga
/// buyruq beradi. Bosqichni ekranlar emas, `resolveStage()` hal qiladi —
/// yagona haqiqat manbai.
class AdminAuthCubit extends Cubit<AdminAuthState> {
  AdminAuthCubit(this._repo) : super(const AdminAuthState());

  final AdminAuthRepository _repo;
  StreamSubscription<dynamic>? _authSub;

  /// `main()` dan keyin bir marta. Mavjud sessiyani tiklaydi va Supabase
  /// hodisalariga obuna bo'ladi.
  Future<void> bootstrap() async {
    if (!Db.isReady) {
      // Kalitlar berilmagan — panel ochiladi, lekin kirish ishlamaydi.
      emit(state.copyWith(bootstrapped: true, stage: AuthStage.signedOut));
      return;
    }

    _authSub ??= Db.authChanges.listen((event) {
      // Sessiya tashqaridan tugasa (token muddati, boshqa tabda chiqish)
      // router darhol kirish ekraniga qaytarsin.
      if (Db.currentUser == null && state.stage != AuthStage.signedOut) {
        emit(
          state.copyWith(
            stage: AuthStage.signedOut,
            permissions: const AdminPermissions.none(),
          ),
        );
      }
    });

    await _refresh(markBootstrapped: true);
  }

  /// Email/parol bilan kirish.
  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(busy: true, clearFailure: true));

    final res = await _repo.signIn(email: email, password: password);
    if (res case Fail(:final failure)) {
      // Parol xato — urinish jurnalga tushmaydi, chunki sessiya hosil
      // bo'lmagan va `admin_record_login()` `auth.uid()` ni talab qiladi.
      // Parol bosqichidagi urinishlarni yozish TTZ §5.9 bo'yicha Edge
      // Function ishi.
      emit(state.copyWith(busy: false, failure: failure));
      return;
    }

    await _refresh(recordSuccess: true);
  }

  Future<void> signOut() async {
    emit(state.copyWith(busy: true, clearFailure: true));
    await _repo.signOut();
    emit(const AdminAuthState(stage: AuthStage.signedOut, bootstrapped: true));
  }

  /// Interfeys tilini o'zgartiradi va bazaga saqlaydi.
  Future<void> changeLanguage(BuildContext context, String languageCode) async {
    await context.setLocale(Locale(languageCode));
    // Xodim bo'lmasa saqlaydigan qator ham yo'q — faqat sessiya tili.
    if (!state.isReady) return;

    await _repo.updateLanguage(languageCode);
    emit(
      state.copyWith(
        permissions: AdminPermissions(
          roleCode: state.permissions.roleCode,
          codes: state.permissions.codes,
          languageCode: languageCode,
        ),
      ),
    );
  }

  /// Bosqichni qayta aniqlaydi va tayyor bo'lsa ruxsatlarni yuklaydi.
  Future<void> _refresh({
    bool markBootstrapped = false,
    bool recordSuccess = false,
  }) async {
    final stageRes = await _repo.resolveStage();

    if (stageRes case Fail(:final failure)) {
      emit(
        state.copyWith(
          busy: false,
          failure: failure,
          bootstrapped: markBootstrapped ? true : null,
        ),
      );
      return;
    }

    final stage = stageRes.valueOrNull!;

    if (stage != AuthStage.ready) {
      // Xodim emasligi ham jurnalga tushadi — kim urinayotgani ko'rinsin.
      if (stage == AuthStage.notAdmin) {
        unawaited(
          _repo.recordLogin(
            success: false,
            failureCode: AdminErrorCode.notAdmin,
          ),
        );
      }
      emit(
        state.copyWith(
          stage: stage,
          busy: false,
          permissions: const AdminPermissions.none(),
          bootstrapped: markBootstrapped ? true : null,
        ),
      );
      return;
    }

    final permsRes = await _repo.loadPermissions();
    final perms = permsRes.valueOrNull ?? const AdminPermissions.none();

    if (recordSuccess) {
      unawaited(_repo.recordLogin(success: true));
    }

    emit(
      state.copyWith(
        stage: AuthStage.ready,
        permissions: perms,
        busy: false,
        clearFailure: true,
        bootstrapped: markBootstrapped ? true : null,
      ),
    );
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
