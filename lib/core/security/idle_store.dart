import 'idle_store_stub.dart'
    if (dart.library.js_interop) 'idle_store_web.dart'
    as impl;

/// Oxirgi faollik vaqtini saqlaydigan qatlam (millisekund, epoch).
///
/// `localStorage` da turadi, xotirada emas — ikkita sabab:
///   * bir nechta tab: bir tabdagi ish ikkinchisini "harakatsiz" deb
///     chiqarib yubormasin;
///   * brauzer yopilib ertasi kuni ochilsa, saqlangan sessiya bilan panel
///     to'g'ridan-to'g'ri ochilmasin — muddat o'tgan bo'lsa kirish so'raladi.
///
/// Shartli import sababi `theme_storage.dart` dagi bilan bir xil:
/// `package:web` Dart VM da (testlarda) yo'q.
int? readLastActivity() => impl.readLastActivity();

void writeLastActivity(int epochMs) => impl.writeLastActivity(epochMs);

void clearLastActivity() => impl.clearLastActivity();
