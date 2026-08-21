import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';

/// Ob-havo ogohlantirishi (`weather_alerts`).
///
/// 0017 dan keyin `farm_id` ixtiyoriy va `region_id` qo'shilgan: admin
/// VILOYAT darajasida ogohlantirish yarata oladi, mobil ilova esa o'z
/// viloyatidagini ko'radi (`weather_alerts_region_read`).
class WeatherAlert {
  const WeatherAlert({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    required this.createdAt,
    this.regionId,
    this.regionName,
    this.farmId,
    this.startsAt,
    this.expiresAt,
  });

  factory WeatherAlert.fromJson(
    Map<String, dynamic> json, {
    String locale = 'uz',
  }) {
    final region = json['regions'] as Map<String, dynamic>?;
    return WeatherAlert(
      id: json['id'] as String,
      alertType: json['alert_type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'important',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      regionId: (json['region_id'] as num?)?.toInt(),
      regionName: region?['name_$locale'] as String?,
      farmId: json['farm_id'] as String?,
      startsAt: json['starts_at'] == null
          ? null
          : DateTime.parse(json['starts_at'] as String),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
    );
  }

  final String id;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final DateTime createdAt;
  final int? regionId;
  final String? regionName;
  final String? farmId;
  final DateTime? startsAt;
  final DateTime? expiresAt;

  /// Xo'jalikka bog'langan ogohlantirish mobil ilovaning o'zi tomonidan
  /// yaratilgan; admin faqat viloyat darajasidagini qo'shadi.
  bool get isRegional => regionId != null;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

/// Ob-havo va tahlil (TTZ §6.8, §6.11).
class AdminOpsRepository {
  // --- Ob-havo ----------------------------------------------------------------

  Future<Result<List<WeatherAlert>>> alerts({String locale = 'uz'}) =>
      guard(() async {
        final rows = await Db.client
            .from('weather_alerts')
            .select(
              'id, farm_id, region_id, alert_type, severity, title, message, '
              'starts_at, expires_at, created_at, '
              'regions(name_uz, name_ru, name_en)',
            )
            .order('created_at', ascending: false)
            .limit(100);

        return [
          for (final r in rows)
            WeatherAlert.fromJson(Map<String, dynamic>.from(r), locale: locale),
        ];
      });

  /// Viloyat darajasidagi ogohlantirish yaratadi.
  ///
  /// RPC yo'q — `weather_alerts_admin_write` siyosati (0017) `for all`,
  /// ya'ni to'g'ridan-to'g'ri `insert` ishlaydi. Bu ataylab: ogohlantirish
  /// buzuvchi amal emas, sabab talab qilinmaydi.
  Future<Result<void>> createAlert({
    required int regionId,
    required String alertType,
    required String severity,
    required String title,
    required String message,
    DateTime? expiresAt,
  }) => guard(() async {
    await Db.client.from('weather_alerts').insert({
      'region_id': regionId,
      'alert_type': alertType,
      'severity': severity,
      'title': title,
      'message': message,
      'starts_at': DateTime.now().toUtc().toIso8601String(),
      if (expiresAt != null) 'expires_at': expiresAt.toUtc().toIso8601String(),
    });
  });

  Future<Result<void>> deleteAlert(String id) => guard(() async {
    await Db.client.from('weather_alerts').delete().eq('id', id);
  });

  // --- Tahlil -----------------------------------------------------------------

  /// Server tomonidagi CSV eksport (`admin-export` Edge Function).
  ///
  /// Mijozda qilinmaydi: 50 000 qatorni brauzerga yuklab olish RAM ni
  /// to'ldiradi va sahifa qotib qoladi (TTZ §5.9).
  ///
  /// Funksiya deploy qilinmagan bo'lsa `FunctionException` keladi va
  /// `mapSupabaseError` uni umumiy server xatosiga o'giradi — ekranda
  /// buning sababi alohida tushuntiriladi.
  Future<Result<String>> exportCsv(String table) => guard(() async {
    final res = await Db.client.functions.invoke(
      'admin-export',
      body: {'table': table},
    );

    final data = res.data;
    if (data is String) return data;
    if (data is List<int>) return String.fromCharCodes(data);
    return data.toString();
  });

  /// Tizim holati (`admin-system-health`).
  Future<Result<Map<String, dynamic>>> systemHealth() => guard(() async {
    final res = await Db.client.functions.invoke('admin-system-health');
    return Map<String, dynamic>.from(res.data as Map);
  });

  // --- Kampaniyalar -----------------------------------------------------------

  Future<Result<List<Map<String, dynamic>>>> campaigns() => guard(() async {
    final rows = await Db.client
        .from('notification_campaigns')
        .select(
          'id, title, body, type, audience, status, scheduled_at, sent_at, '
          'recipient_count, delivered_count, created_at',
        )
        .order('created_at', ascending: false);

    return [for (final r in rows) Map<String, dynamic>.from(r)];
  });

  /// Yuborishdan oldin auditoriyani sanaydi (`campaign_audience_count`).
  Future<Result<int>> audienceCount(Map<String, dynamic> audience) =>
      guard(() async {
        final count = await Db.client.rpc(
          'campaign_audience_count',
          params: {'p_audience': audience},
        );
        return (count as num).toInt();
      });

  Future<Result<void>> createCampaign({
    required String title,
    required String body,
    required String type,
    required Map<String, dynamic> audience,
  }) => guard(() async {
    await Db.client.from('notification_campaigns').insert({
      'title': title,
      'body': body,
      'type': type,
      'audience': audience,
      'status': 'draft',
    });
  });

  /// Kampaniyani yuboradi (`admin-send-campaign`).
  Future<Result<Map<String, dynamic>>> sendCampaign(String id) =>
      guard(() async {
        final res = await Db.client.functions.invoke(
          'admin-send-campaign',
          body: {'campaign_id': id},
        );
        return Map<String, dynamic>.from(res.data as Map);
      });
}
