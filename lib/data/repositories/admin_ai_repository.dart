import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/ref_name.dart';
import '../../core/supabase/admin_config.dart';
import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';
import '../models/admin_ai.dart';

/// AI monitoringi va kasallik ma'lumotnomasi (TTZ §6.6, §6.7).
///
/// TOKEN VA XARAJAT HISOBI YO'Q. `ai_messages` da `prompt_tokens`,
/// `completion_tokens`, `model` ustunlari yo'q — ularni qo'shish MOBIL
/// ILOVADA ham o'zgarish talab qiladi (`ai_repository.dart` dagi
/// `_saveMessage`), shuning uchun TTZ §6.6 uni P1 ga qo'ygan.
///
/// Hozircha kuzatiladigan narsa: kunlik savol/skan soni
/// (`ai_usage_limits`), `scan_results.model_version` (zanjirdagi qaysi model
/// javob berdi — kvota tugashi shundan bilinadi) va `latency_ms`.
class AdminAiRepository {
  /// Kunlik foydalanish — eng faol foydalanuvchilar.
  Future<Result<List<AiUsageRow>>> usage({
    required int days,
    required int page,
    int pageSize = AdminConfig.pageSize,
  }) => guard(() async {
    final from = DateTime.now().subtract(Duration(days: days - 1));

    final rows = await Db.client
        .from('ai_usage_limits')
        .select(
          'user_id, usage_date, questions_count, scans_count, '
          'profiles(full_name, email)',
        )
        .gte('usage_date', _date(from))
        .order('usage_date', ascending: false)
        .order('questions_count', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize);

    return [
      for (final r in rows) AiUsageRow.fromJson(Map<String, dynamic>.from(r)),
    ];
  });

  /// Skanlar ro'yxati.
  Future<Result<List<ScanRow>>> scans({
    required int page,
    String? severity,
    bool problemsOnly = false,
    String locale = 'uz',
    int pageSize = AdminConfig.pageSize,
  }) => guard(() async {
    var query = Db.client
        .from('scan_results')
        .select(
          'id, disease_name, disease_latin, confidence, severity, is_plant, '
          'model_version, latency_ms, created_at, image_path, symptoms, '
          'treatments, prevention, '
          'profiles(full_name, email), crop_types(name_uz, name_ru, name_en)',
        );

    if (severity != null) query = query.eq('severity', severity);

    // Sifat muammolari: AI rasmda o'simlik topmagan holatlar. Ular
    // odatda foydalanuvchi noto'g'ri rasm yuborganini bildiradi — yoki
    // modelning o'zi xato qilganini.
    if (problemsOnly) query = query.eq('is_plant', false);

    final rows = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize);

    return [
      for (final r in rows)
        ScanRow.fromJson(Map<String, dynamic>.from(r), locale: locale),
    ];
  });

  /// Skan rasmlari uchun signed URL — `yo'l -> URL`.
  ///
  /// `scan-images` private buket. Admin unga `storage_admin_read` (0009) va
  /// `storage_admin_scan_read` (0044) orqali kiradi. Ruxsat yo'q yoki fayl
  /// o'chirilgan bo'lsa o'sha yo'l xaritada bo'lmaydi va ekranda rasm o'rniga
  /// belgi chiqadi — sahifa baribir ishlaydi.
  Future<Result<Map<String, String>>> scanImageUrls(List<String> paths) =>
      guard(() async {
        if (paths.isEmpty) return const <String, String>{};

        final results = await Db.client.storage
            .from(AdminConfig.bucketScanImages)
            .createSignedUrlsResult(paths, AdminConfig.signedUrlTtl.inSeconds);

        return {
          for (final r in results)
            if (r is SignedUrlSuccess) r.path: r.signedUrl,
        };
      });

  /// Foydalanuvchilar AI ga bergan savollar, yangisidan boshlab.
  ///
  /// Faqat `role = 'user'` — javoblar suhbat panelida ko'rinadi. RLS
  /// `ai.moderate` talab qiladi (0009). Ruxsat bo'lmasa PostgREST xato
  /// qaytarmaydi, shunchaki bo'sh ro'yxat beradi — "savol yo'q" deb
  /// adashmaslik uchun ekran ruxsatni o'zi oldindan tekshiradi.
  Future<Result<List<AiQuestion>>> questions({
    required int page,
    String search = '',
    int pageSize = AdminConfig.pageSize,
  }) => guard(() async {
    var query = Db.client
        .from('ai_messages')
        .select(
          'id, conversation_id, content, created_at, '
          'ai_conversations!inner(title, user_id, profiles(full_name, email))',
        )
        .eq('role', 'user');

    final q = search.trim().replaceAll('%', '').replaceAll(',', ' ');
    if (q.isNotEmpty) query = query.ilike('content', '%$q%');

    final rows = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, page * pageSize + pageSize);

    return [
      for (final r in rows) AiQuestion.fromJson(Map<String, dynamic>.from(r)),
    ];
  });

  /// Bitta suhbatning to'liq yozishmasi — savol va AI javoblari.
  Future<Result<List<AiChatMessage>>> conversation(String conversationId) =>
      guard(() async {
        final rows = await Db.client
            .from('ai_messages')
            .select('id, role, content, created_at')
            .eq('conversation_id', conversationId)
            .order('created_at')
            .limit(200);

        return [
          for (final r in rows)
            AiChatMessage.fromJson(Map<String, dynamic>.from(r)),
        ];
      });

  /// Davr bo'yicha jami savol, skan va faol foydalanuvchilar.
  ///
  /// `ai_usage_limits` da har foydalanuvchiga kuniga bitta qator — 90 kunda
  /// ham bir necha ming qatordan oshmaydi, mijozda qo'shish arzon.
  Future<Result<AiTotals>> totals({required int days}) => guard(() async {
    final from = DateTime.now().subtract(Duration(days: days - 1));

    final rows = await Db.client
        .from('ai_usage_limits')
        .select('user_id, questions_count, scans_count')
        .gte('usage_date', _date(from))
        .limit(10000);

    var questions = 0;
    var scans = 0;
    final users = <String>{};
    for (final r in rows) {
      questions += (r['questions_count'] as num?)?.toInt() ?? 0;
      scans += (r['scans_count'] as num?)?.toInt() ?? 0;
      users.add(r['user_id'] as String);
    }

    return AiTotals(
      questions: questions,
      scans: scans,
      activeUsers: users.length,
    );
  });

  /// Model bo'yicha yig'ma.
  ///
  /// PostgREST agregat funksiyalarini cheklangan qo'llab-quvvatlaydi va
  /// `group by` uchun alohida view kerak bo'lardi. Bu yerda oxirgi N
  /// skanni olib MIJOZDA guruhlanadi — model taqsimoti uchun namuna
  /// yetarli, aniq statistika esa Tahlil modulining ishi.
  Future<Result<List<ModelUsage>>> modelBreakdown({int sample = 500}) => guard(
    () async {
      final rows = await Db.client
          .from('scan_results')
          .select('model_version, latency_ms, confidence')
          .order('created_at', ascending: false)
          .limit(sample);

      final buckets = <String, List<Map<String, dynamic>>>{};
      for (final r in rows) {
        final model = (r['model_version'] as String?) ?? 'unknown';
        buckets.putIfAbsent(model, () => []).add(Map<String, dynamic>.from(r));
      }

      final result = <ModelUsage>[];
      buckets.forEach((model, items) {
        var latencySum = 0;
        var latencyCount = 0;
        var confidenceSum = 0;

        for (final i in items) {
          final latency = (i['latency_ms'] as num?)?.toInt();
          if (latency != null) {
            latencySum += latency;
            latencyCount++;
          }
          confidenceSum += (i['confidence'] as num?)?.toInt() ?? 0;
        }

        result.add(
          ModelUsage(
            model: model,
            count: items.length,
            avgLatencyMs: latencyCount == 0 ? 0 : latencySum ~/ latencyCount,
            avgConfidence: items.isEmpty ? 0 : confidenceSum ~/ items.length,
          ),
        );
      });

      result.sort((a, b) => b.count.compareTo(a.count));
      return result;
    },
  );

  // --- Kasallik ma'lumotnomasi ------------------------------------------------

  Future<Result<List<DiseaseRow>>> diseases({
    String search = '',
    String? status,
    String locale = 'uz',
  }) => guard(() async {
    var query = Db.client
        .from('disease_reference')
        .select(
          'id, code, crop_type_id, name_uz, name_ru, name_en, latin_name, '
          'description, causes, prevention, status, symptoms, treatments, '
          'updated_at, '
          'crop_types(name_uz, name_ru, name_en)',
        );

    if (search.trim().isNotEmpty) {
      final safe = search.trim().replaceAll(',', ' ').replaceAll('%', '');
      query = query.or(
        'name_uz.ilike.%$safe%,name_ru.ilike.%$safe%,'
        'name_en.ilike.%$safe%,code.ilike.%$safe%',
      );
    }
    if (status != null) query = query.eq('status', status);

    final rows = await query.order('id');

    return [
      for (final r in rows)
        DiseaseRow.fromJson(Map<String, dynamic>.from(r), locale: locale),
    ];
  });

  /// Nashr holatini o'zgartirish (`admin_publish_disease`, 0013).
  ///
  /// `id` — `smallint`, shuning uchun RPC ham `smallint` kutadi.
  Future<Result<void>> setDiseaseStatus(int id, String status) =>
      guard(() async {
        await Db.client.rpc(
          'admin_publish_disease',
          params: {'p_id': id, 'p_status': status},
        );
      });

  /// Ekin turlari — kasallik formasidagi tanlov.
  Future<Result<List<CropOption>>> crops({String locale = 'uz'}) =>
      guard(() async {
        final rows = await Db.client
            .from('crop_types')
            .select('id, name_uz, name_ru, name_en')
            .order('id');

        return [
          for (final r in rows)
            CropOption(
              id: (r['id'] as num).toInt(),
              name: refName(r, locale) ?? '${r['id']}',
            ),
        ];
      });

  /// Yangi kasallik — `draft` holatida.
  ///
  /// RPC yo'q: `disease_reference_admin_write` siyosati (0013) `for all`,
  /// ya'ni to'g'ridan-to'g'ri `insert` ishlaydi. Yangi yozuv mobil ilovaga
  /// faqat `published` qilinganda ko'rinadi — nashr esa
  /// `admin_publish_disease` orqali, auditga tushib o'tadi.
  Future<Result<int>> createDisease(DiseaseDraft draft) => guard(() async {
    final row = await Db.client
        .from('disease_reference')
        .insert({
          ...draft.toJson(),
          'status': ContentStatus.draft,
          'author_id': Db.userId,
        })
        .select('id')
        .single();
    return (row['id'] as num).toInt();
  });

  /// Mavjud yozuvni tahrirlash. Holat bu yerda o'zgarmaydi.
  Future<Result<void>> updateDisease(int id, DiseaseDraft draft) =>
      guard(() async {
        await Db.client
            .from('disease_reference')
            .update(draft.toJson())
            .eq('id', id);
      });

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
