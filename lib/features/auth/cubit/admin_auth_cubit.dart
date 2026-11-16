import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/admin_error_codes.dart';
import '../../../core/i18n/admin_locales.dart';
import '../../../core/rbac/permission.dart';
import '../../../core/security/idle_guard.dart';
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
  AdminAuthCubit(this._repo) : super(const AdminAuthState()) {
    _idle = IdleGuard(onTimeout: () => unawaited(signOut(idle: true)));
  }

  final AdminAuthRepository _repo;
  late final IdleGuard _idle;
  StreamSubscription<dynamic>? _authSub;

  static const _lockedFailure = AppFailure(
    FailureKind.rateLimit,
    'admin.errors.login_locked',
  );

  /// `main()` dan keyin bir marta. Mavjud sessiyani tiklaydi va Supabase
  /// hodisalariga obuna bo'ladi.
  Future<void> bootstrap() async {
    if (!Db.isReady) {
      // Kalitlar berilmagan — panel ochiladi, lekin kirish ishlamaydi.
      emit(state.copyWith(bootstrapped: true, stage: AuthStage.signedOut));
      return;
    }

    _authSub ??= Db.authChanges.listen((event) {
      // Sessiya tashqaridan tugasa (chiqish, boshqa tabda chiqish)
      // router darhol kirish ekraniga qaytarsin.
      if (Db.currentUser == null) {
        if (state.stage != AuthStage.signedOut) {
          _idle.stop();
          emit(
            state.copyWith(
              stage: AuthStage.signedOut,
              permissions: const AdminPermissions.none(),
            ),
          );
        }
        return;
      }

      // Teskari yo'nalish ham kerak: brauzer yopilib qayta ochilganda
      // saqlangan token muddati o'tgan bo'lishi mumkin. Supabase uni
      // FONDA yangilaydi, lekin `bootstrap()` undan oldin ulgurib
      // so'rov yuboradi va 401 oladi — natijada haqiqiy sessiya bor
      // bo'lsa ham admin kirish ekranini ko'rardi.
      //
      // Token yangilangach hodisa keladi va bosqich qayta aniqlanadi.
      if (state.stage == AuthStage.signedOut && !state.busy) {
        unawaited(_refresh());
      }
    });

    // Brauzer yopilib, ancha keyin qayta ochilgan: saqlangan sessiya bilan
    // panel to'g'ridan-to'g'ri ochilmasin. `signOut` o'zi `bootstrapped` ni
    // qo'yadi va kirish ekranida sababni ko'rsatadi.
    if (Db.currentUser != null && _idle.expired) {
      await signOut(idle: true);
      return;
    }

    await _refresh(markBootstrapped: true);
  }

  /// Email/parol bilan kirish.
  Future<void> signIn({required String email, required String password}) async {
    emit(state.copyWith(busy: true, clearFailure: true));

    // Ketma-ket xatodan keyingi vaqtinchalik blok. Funksiya javob bermasa
    // (`null`) kirish davom etadi — `loginGuard` izohiga qarang.
    final before = await _repo.loginGuard('check', email);
    if (before?.locked ?? false) {
      emit(state.copyWith(busy: false, failure: _lockedFailure));
      return;
    }

    final res = await _repo.signIn(email: email, password: password);
    if (res case Fail(:final failure)) {
      // Parol bosqichida sessiya yo'q, `admin_record_login()` esa
      // `auth.uid()` ni talab qiladi — shuning uchun urinishni Edge
      // Function yozadi.
      var shown = failure;
      if (failure.messageKey == 'admin.errors.invalid_credentials') {
        final after = await _repo.loginGuard('fail', email);
        if (after?.locked ?? false) shown = _lockedFailure;
      }
      emit(state.copyWith(busy: false, failure: shown));
      return;
    }

    await _refresh(recordSuccess: true);
  }

  /// Kirishdagi ikkinchi bosqich — authenticator kodi.
  Future<void> verifyMfa(String code) async {
    emit(state.copyWith(busy: true, clearFailure: true));

    final res = await _repo.verifyMfa(code);
    if (res case Fail(:final failure)) {
      // Sessiya bor (parol to'g'ri), shuning uchun RPC yoza oladi: parolni
      // bilgan, lekin kodni topa olmayotgan urinish jurnalda ko'rinsin.
      unawaited(
        _repo.recordLogin(
          success: false,
          failureCode: AdminErrorCode.mfaFailed,
        ),
      );
      emit(state.copyWith(busy: false, failure: failure));
      return;
    }

    await _refresh(recordSuccess: true);
  }

  /// 2FA ulash tugagach (yoki tashqaridan holat o'zgargach) bosqichni
  /// qayta aniqlaydi.
  Future<void> refresh({bool recordSuccess = false}) =>
      _refresh(recordSuccess: recordSuccess);

  /// [idle] — harakatsizlik sababli avtomatik chiqish: kirish ekranida
  /// sababi aytiladi, aks holda admin "nega chiqib ketdim" deb o'ylaydi.
  Future<void> signOut({bool idle = false}) async {
    _idle.reset();
    emit(state.copyWith(busy: true, clearFailure: true));
    await _repo.signOut();
    emit(
      AdminAuthState(
        stage: AuthStage.signedOut,
        bootstrapped: true,
        failure: idle
            ? const AppFailure(FailureKind.auth, 'admin.auth.idle_signed_out')
            : null,
      ),
    );
  }

  /// Foydalanuvchi faolligi (sichqoncha, klaviatura) — `AppShell` chaqiradi.
  void touch() => _idle.touch();

  /// Interfeys tilini o'zgartiradi va bazaga saqlaydi.
  ///
  /// [languageCode] — `admin_users.language_code` dagi ko'rinish
  /// (`uz`, `uz-Cyrl`, `ru`, `en`, `tr`). `Locale(languageCode)` to'g'ridan
  /// to'g'ri ishlatilmaydi: `uz-Cyrl` uchun u yaroqsiz lokal yasaydi va
  /// tarjima fayli topilmaydi.
  Future<void> changeLanguage(BuildContext context, String languageCode) async {
    await context.setLocale(AdminLocales.localeFor(languageCode));
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
      _idle.stop();
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
          // Parol bosqichidagi xato 2FA ekraniga ko'chib o'tmasin; chiqish
          // sababi (masalan, harakatsizlik) esa kirish ekranida qolsin.
          clearFailure: stage != AuthStage.signedOut,
          permissions: const AdminPermissions.none(),
          bootstrapped: markBootstrapped ? true : null,
        ),
      );
      return;
    }

    final permsRes = await _repo.loadPermissions();
    final perms = permsRes.valueOrNull ?? const AdminPermissions.none();

    // Muvaffaqiyat faqat TO'LIQ kirishda yoziladi: parol to'g'ri, lekin kod
    // hali kiritilmagan sessiya "kirdi" emas.
    if (recordSuccess) {
      unawaited(_repo.recordLogin(success: true));
    }

    _idle.start();

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
    _idle.stop();
    _authSub?.cancel();
    return super.close();
  }
}
