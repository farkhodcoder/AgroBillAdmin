import '../../core/errors/admin_error_codes.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';
import '../models/admin_metrics.dart';

/// Dashboard ma'lumotlari.
///
/// Ikkita manba, chunki ikkita turli talab bor (0015_admin_analytics.sql):
///   * `admin_dashboard_kpi()`   — bugungi sonlar, real vaqtda
///   * `admin_metrics_range()`   — 365 kunlik agregat, matview ustidan
class AdminDashboardRepository {
  /// KPI kartalar.
  Future<Result<DashboardKpi>> loadKpi() => guard(() async {
    final json = await Db.client.rpc('admin_dashboard_kpi');
    final map = Map<String, dynamic>.from(json as Map);

    // Funksiya ruxsatni O'Z ICHIDA tekshiradi va xatoni jsonb sifatida
    // qaytaradi, istisno emas (0015). Sabab: dashboard bitta so'rov bilan
    // ochiladi va ruxsat yo'qligi frontend uchun xato emas, holat.
    if (map['error'] == AdminErrorCode.permissionDenied) {
      throw const _PermissionDenied();
    }

    return DashboardKpi.fromJson(map);
  });

  /// Grafiklar uchun kunlik qator.
  Future<Result<List<DailyMetric>>> loadMetrics({int days = 30}) =>
      guard(() async {
        final to = DateTime.now();
        final from = to.subtract(Duration(days: days - 1));

        final rows = await Db.client.rpc(
          'admin_metrics_range',
          params: {'p_from': _date(from), 'p_to': _date(to)},
        );

        return [
          for (final row in rows as List)
            DailyMetric.fromJson(Map<String, dynamic>.from(row as Map)),
        ];
      });

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// `mapSupabaseError` uni `PERMISSION_DENIED` deb tanishi uchun.
class _PermissionDenied implements Exception {
  const _PermissionDenied();

  @override
  String toString() => AdminErrorCode.permissionDenied;
}
