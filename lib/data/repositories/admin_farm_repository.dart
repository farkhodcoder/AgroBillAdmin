import '../../core/supabase/admin_config.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';
import '../models/admin_farm.dart';

/// Xo'jaliklar moduli (TTZ §6.3).
///
/// `farms.read` ruxsati butun daraxtni ochadi: xo'jalik → dala → ekin
/// (0009_admin_rls.sql). Modul faqat O'QIYDI — xo'jalikni tahrirlash
/// fermerning o'z ishi, admin faqat tekshiradi.
class AdminFarmRepository {
  Future<Result<List<AdminFarmRow>>> list({
    required FarmFilter filter,
    required int page,
    String locale = 'uz',
    int pageSize = AdminConfig.pageSize,
  }) => guard(() async {
    var query = Db.client
        .from('farms')
        .select(
          'id, name, area_hectares, irrigation, created_at, '
          'profiles(id, full_name, email), '
          'regions(name_uz, name_ru, name_en), '
          'districts(name_uz, name_ru, name_en), '
          'fields(count)',
        )
        .isFilter('deleted_at', null);

    final search = filter.search.trim();
    if (search.isNotEmpty) {
      query = query.ilike('name', '%${search.replaceAll('%', '')}%');
    }
    if (filter.regionId != null) {
      query = query.eq('region_id', filter.regionId!);
    }
    if (filter.irrigation != null) {
      query = query.eq('irrigation', filter.irrigation!);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize);

    return [
      for (final row in rows)
        AdminFarmRow.fromJson(Map<String, dynamic>.from(row), locale: locale),
    ];
  });

  /// Xo'jalikning dalalari va ulardagi faol ekinlar.
  Future<Result<List<AdminFieldRow>>> fields(
    String farmId, {
    String locale = 'uz',
  }) => guard(() async {
    final rows = await Db.client
        .from('fields')
        .select(
          'id, name, area_hectares, health, health_score, boundary_geojson, '
          'field_crops(growth_percent, is_archived, '
          'crop_types(name_uz, name_ru, name_en))',
        )
        .eq('farm_id', farmId)
        .isFilter('deleted_at', null)
        .order('name');

    return [
      for (final row in rows)
        AdminFieldRow.fromJson(Map<String, dynamic>.from(row), locale: locale),
    ];
  });

  /// Dalalardagi so'nggi skanlar — kasallik holatini ko'rish uchun.
  ///
  /// `disease.read` ruxsati bo'lmasa RLS bo'sh ro'yxat qaytaradi; bu xato
  /// emas, shuning uchun alohida ishlov berilmaydi.
  Future<Result<List<Map<String, dynamic>>>> recentScans(
    List<String> fieldIds, {
    int limit = 20,
  }) => guard(() async {
    if (fieldIds.isEmpty) return const <Map<String, dynamic>>[];

    final rows = await Db.client
        .from('scan_results')
        .select('id, disease_name, severity, confidence, created_at, field_id')
        .inFilter('field_id', fieldIds)
        .order('created_at', ascending: false)
        .limit(limit);

    return [for (final r in rows) Map<String, dynamic>.from(r)];
  });
}
