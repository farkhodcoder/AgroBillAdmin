import 'dart:async';

import 'idle_store.dart' as store;

/// Harakatsizlikda avtomatik chiqish.
///
/// Panel ochiq internetda turadi va sessiya `localStorage` da saqlanadi:
/// umumiy yoki qarovsiz qoldirilgan kompyuterda keyingi odam to'g'ridan-to'g'ri
/// ichkariga kirardi. [timeout] davomida sichqoncha ham, klaviatura ham
/// ishlatilmasa [onTimeout] chaqiriladi.
///
/// Vaqt va saqlash tashqaridan beriladi — test haqiqiy 30 daqiqa kutmaydi.
class IdleGuard {
  IdleGuard({
    required this.onTimeout,
    this.timeout = defaultTimeout,
    this.checkEvery = const Duration(seconds: 30),
    DateTime Function()? now,
    int? Function()? read,
    void Function(int)? write,
    void Function()? clear,
  }) : _now = now ?? DateTime.now,
       _read = read ?? store.readLastActivity,
       _write = write ?? store.writeLastActivity,
       _clear = clear ?? store.clearLastActivity;

  static const defaultTimeout = Duration(minutes: 30);

  /// Har sichqoncha harakatida `localStorage` ga yozmaslik uchun.
  static const _writeEvery = Duration(seconds: 10);

  final Duration timeout;
  final Duration checkEvery;
  final void Function() onTimeout;

  final DateTime Function() _now;
  final int? Function() _read;
  final void Function(int) _write;
  final void Function() _clear;

  Timer? _timer;
  int _lastWrite = 0;

  /// Saqlangan oxirgi faollikdan beri [timeout] o'tganmi.
  ///
  /// Yozuv yo'q bo'lsa — `false`: birinchi kirishda (yoki `localStorage`
  /// yopiq brauzerda) admin darhol chiqarib yuborilmasin.
  static bool isExpired({
    required int? lastActivityMs,
    required DateTime now,
    Duration timeout = defaultTimeout,
  }) {
    if (lastActivityMs == null) return false;
    return now.millisecondsSinceEpoch - lastActivityMs >=
        timeout.inMilliseconds;
  }

  bool get expired =>
      isExpired(lastActivityMs: _read(), now: _now(), timeout: timeout);

  /// Kuzatuvni boshlaydi. Sessiya tayyor bo'lganda chaqiriladi.
  void start() {
    _timer?.cancel();
    touch(force: true);
    _timer = Timer.periodic(checkEvery, (_) => check());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Foydalanuvchi faolligi — sichqoncha, g'ildirak yoki klaviatura.
  void touch({bool force = false}) {
    final now = _now().millisecondsSinceEpoch;
    if (!force && now - _lastWrite < _writeEvery.inMilliseconds) return;
    _lastWrite = now;
    _write(now);
  }

  /// Muddat o'tgan bo'lsa chiqaradi. Boshqa tab yozgan vaqt ham hisobga
  /// olinadi, chunki [expired] saqlangan qiymatga qaraydi.
  void check() {
    if (!expired) return;
    stop();
    _clear();
    onTimeout();
  }

  /// Chiqishda: keyingi kirish eski vaqt bilan boshlanmasin.
  void reset() {
    stop();
    _lastWrite = 0;
    _clear();
  }
}
