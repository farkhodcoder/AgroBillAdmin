import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/admin_error_codes.dart';
import '../utils/result.dart';
import 'admin_config.dart';

/// Supabase mijoziga yagona kirish nuqtasi.
///
/// Mobil ilovadagi `lib/core/supabase/supabase_client.dart` ning admin uchun
/// moslashtirilgan nusxasi: xato xaritalashga `AdminErrorCode` qatlami
/// qo'shilgan, Google/AI ga aloqador qismlar olib tashlangan.
abstract final class Db {
  static SupabaseClient? _client;

  /// `main()` da bir marta chaqiriladi.
  static Future<void> init() async {
    if (!AdminConfig.isConfigured) return;

    await Supabase.initialize(
      url: AdminConfig.url,
      publishableKey: AdminConfig.clientKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.error,
      ),
      // Sukut bo'yicha PostgREST so'rovlarida timeout YO'Q ("When null (the
      // default) no timeout is applied") — javob kelmasa so'rov abadiy osilib
      // qoladi va jadval ustidagi spinner to'xtamaydi. TTZ §10: "cheksiz
      // yuklanish taqiqlanadi".
      postgrestOptions: const PostgrestClientOptions(
        requestTimeout: kSupabaseTimeout,
      ),
    );
    _client = Supabase.instance.client;
  }

  static bool get isReady => _client != null;

  static SupabaseClient get client {
    final c = _client;
    if (c == null) {
      throw StateError(
        'Supabase sozlanmagan. --dart-define=SUPABASE_URL va '
        '--dart-define=SUPABASE_PUBLISHABLE_KEY bilan ishga tushiring.',
      );
    }
    return c;
  }

  static GoTrueClient get auth => client.auth;
  static User? get currentUser => _client?.auth.currentUser;
  static String? get userId => currentUser?.id;

  /// Sessiya o'zgarishi oqimi — router shu orqali qayta yo'naltiradi.
  static Stream<AuthState> get authChanges => client.auth.onAuthStateChange;
}

/// Supabase so'rovlari uchun umumiy muddat.
///
/// GoTrue paketida (kirish, ro'yxatdan o'tish) timeout UMUMAN YO'Q — tarmoq
/// javobi kelmasa `Future` hech qachon tugamaydi va kirish tugmasi cheksiz
/// aylanib qoladi. Bu chegara har bir so'rovni majburan uzadi.
const kSupabaseTimeout = Duration(seconds: 20);

/// Supabase istisnolarini `AppFailure` ga o'giradi.
///
/// Foydalanuvchi hech qachon "PostgrestException 42501" ko'rmasligi kerak —
/// har bir xato tarjima kalitiga bog'lanadi.
AppFailure mapSupabaseError(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login') ||
        message.contains('invalid credentials')) {
      return const AppFailure(
        FailureKind.auth,
        'admin.errors.invalid_credentials',
      );
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return const AppFailure(
        FailureKind.rateLimit,
        'admin.errors.too_many_requests',
      );
    }
    return AppFailure(
      FailureKind.auth,
      'admin.errors.auth_failed',
      detail: error.message,
    );
  }

  if (error is PostgrestException) {
    // Avval admin RPC lari ko'taradigan aniq kodlar — ular umumiy SQLSTATE
    // dan ko'ra ancha ko'proq narsa aytadi. Masalan `42501` "ruxsat yo'q"
    // degani, lekin `CANNOT_BLOCK_ADMIN` "nega yo'q" ini ham aytadi.
    final known = AdminErrorCode.failureFrom(error.message);
    if (known != null) return known;

    return switch (error.code) {
      // RLS ruxsat bermadi.
      '42501' => const AppFailure(
        FailureKind.permission,
        'admin.errors.permission_denied',
      ),
      '23505' => const AppFailure(
        FailureKind.conflict,
        'admin.errors.already_exists',
      ),
      '23503' => const AppFailure(
        FailureKind.validation,
        'admin.errors.invalid_reference',
      ),
      '23514' || '22023' => const AppFailure(
        FailureKind.validation,
        'admin.errors.invalid_value',
      ),
      'PGRST116' || 'P0002' => const AppFailure(
        FailureKind.notFound,
        'admin.errors.not_found',
      ),
      _ => AppFailure(
        FailureKind.unknown,
        'admin.errors.server',
        detail: error.message,
      ),
    };
  }

  if (error is StorageException) {
    return AppFailure(
      FailureKind.storage,
      'admin.errors.storage',
      detail: error.message,
    );
  }

  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection') ||
      text.contains('network')) {
    return const AppFailure(FailureKind.network, 'admin.errors.no_internet');
  }

  return AppFailure(
    FailureKind.unknown,
    'admin.errors.unknown',
    detail: error.toString(),
  );
}

/// Repozitoriylardagi takrorlanadigan `try/catch` ni bitta joyga yig'adi.
///
/// Har bir repozitoriy metodi shu orqali o'tadi — shunda Cubit'da xatoni
/// unutib yuborish imkonsiz bo'ladi (`Result<T>` majburiy tarmoqlanadi).
Future<Result<T>> guard<T>(
  Future<T> Function() action, {
  Duration timeout = kSupabaseTimeout,
}) async {
  try {
    return Result.ok(await action().timeout(timeout));
  } on TimeoutException {
    return const Result.fail(
      AppFailure(FailureKind.network, 'admin.errors.timeout'),
    );
  } catch (e) {
    return Result.fail(mapSupabaseError(e));
  }
}
