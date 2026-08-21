import 'package:intl/intl.dart';

/// Admin panel formatlari.
///
/// Mobil ilovadagi `AgFormat` to'liq ko'chirilmadi: uning yarmi ob-havo va
/// telefon raqami uchun (`windSpeed`, `temperature`, `phone`) — admin
/// paneliga aloqasi yo'q. Bu yerda faqat jadval va KPI kartalarga keraklisi.
abstract final class Fmt {
  static final _integer = NumberFormat('#,##0', 'en_US');
  static final _decimal = NumberFormat('#,##0.0', 'en_US');

  /// Guruh ajratgichini o'zbek/rus konvensiyasiga o'giradi (probel).
  ///
  /// `NumberFormat` ni `uz` bilan yaratish ishonchsiz: paketda o'zbek
  /// lokali to'liq emas va ba'zi muhitlarda vergul chiqadi.
  static String _localize(String raw) => raw.replaceAll(',', ' ');

  /// Ro'yxatlardagi sonlar: 1 234, 12 456.
  static String count(num value) => _localize(_integer.format(value));

  static String decimal(num value) => _localize(_decimal.format(value));

  /// Gektar: 1 234.5
  static String hectares(num value) => _localize(_decimal.format(value));

  /// Pul — so'm. Katta sonlar qisqartiriladi, aks holda KPI kartaga sig'maydi.
  static String sum(num value) {
    if (value >= 1000000000) {
      return '${_localize(_decimal.format(value / 1000000000))} mlrd';
    }
    if (value >= 1000000) {
      return '${_localize(_decimal.format(value / 1000000))} mln';
    }
    return _localize(_integer.format(value));
  }

  /// Jadvaldagi sana: 20.08.2026
  static String date(DateTime? value) {
    if (value == null) return '—';
    final d = value.toLocal();
    return '${_two(d.day)}.${_two(d.month)}.${d.year}';
  }

  /// Audit va jurnal uchun: 20.08.2026 14:32
  static String dateTime(DateTime? value) {
    if (value == null) return '—';
    final d = value.toLocal();
    return '${date(d)} ${_two(d.hour)}:${_two(d.minute)}';
  }

  /// "3 kun oldin" — nisbiy vaqt. Tilga bog'liq bo'lmasin uchun qisqa
  /// shaklda; aniq sana kerak bo'lsa `dateTime` ishlatiladi.
  static String ago(DateTime? value) {
    if (value == null) return '—';
    final diff = DateTime.now().difference(value.toLocal());
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    return date(value);
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
