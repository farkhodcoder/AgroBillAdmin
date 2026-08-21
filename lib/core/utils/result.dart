/// Repozitoriylar xatoni istisno (exception) sifatida emas, qiymat sifatida
/// qaytaradi — Cubit'da xatoni unutib yuborish imkonsiz bo'ladi.
///
/// MOBIL NUSXADAN FARQ: `AppFailure.network()` va `.unknown()` tarjima
/// kalitlari `admin.errors.*` prefiksiga o'tkazilgan. Mobil ilovada ular
/// `errors.*` — u yerda tarjima fayli boshqacha tuzilgan. Prefikssiz
/// qoldirilsa foydalanuvchi xato o'rniga xom kalitni ko'rardi
/// (`easy_localization` topilmagan kalitni jimgina ekranga chiqaradi).
/// `translation_usage_test` shuni ushlab qoladi.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.fail(AppFailure failure) = Fail<T>;

  bool get isOk => this is Ok<T>;
  T? get valueOrNull => this is Ok<T> ? (this as Ok<T>).value : null;
  AppFailure? get failureOrNull =>
      this is Fail<T> ? (this as Fail<T>).failure : null;

  R when<R>({
    required R Function(T value) ok,
    required R Function(AppFailure failure) fail,
  }) => switch (this) {
    Ok<T>(:final value) => ok(value),
    Fail<T>(:final failure) => fail(failure),
  };

  /// Muvaffaqiyatli qiymatni boshqa turga o'giradi, xatoni o'zgarishsiz uzatadi.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Ok<R>(transform(value)),
    Fail<T>(:final failure) => Fail<R>(failure),
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Fail<T> extends Result<T> {
  const Fail(this.failure);
  final AppFailure failure;
}

/// Xato turlari. TTZ 7.2 talabi: foydalanuvchi hech qachon "Xatolik 500"
/// ko'rmaydi — har bir xato tarjima kalitiga bog'lanadi.
enum FailureKind {
  network,
  auth,
  permission,
  notFound,
  validation,
  conflict,
  storage,
  rateLimit,
  aiRefusal,
  aiUnavailable,
  subscription,
  unknown,
}

class AppFailure {
  const AppFailure(this.kind, this.messageKey, {this.detail, this.args});

  /// Tarmoq yo'q — oflayn banner bilan birga ko'rsatiladi.
  const AppFailure.network([this.detail])
    : kind = FailureKind.network,
      messageKey = 'admin.errors.no_internet',
      args = null;

  const AppFailure.unknown([this.detail])
    : kind = FailureKind.unknown,
      messageKey = 'admin.errors.unknown',
      args = null;

  final FailureKind kind;

  /// `easy_localization` kaliti, masalan `admin.errors.not_found`.
  final String messageKey;

  /// Faqat log uchun — foydalanuvchiga ko'rsatilmaydi.
  final String? detail;

  /// Tarjimadagi `{}` o'rniga qo'yiladigan qiymatlar.
  final Map<String, String>? args;

  /// Qayta urinish mantiqan to'g'ri bo'ladigan xatolar.
  bool get isRetryable => switch (kind) {
    FailureKind.network ||
    FailureKind.rateLimit ||
    FailureKind.aiUnavailable ||
    FailureKind.unknown => true,
    _ => false,
  };

  @override
  String toString() => 'AppFailure($kind, $messageKey, $detail)';
}
