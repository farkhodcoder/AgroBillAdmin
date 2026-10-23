import '../../core/i18n/ref_name.dart';

/// Kunlik AI foydalanishi (`ai_usage_limits`).
class AiUsageRow {
  const AiUsageRow({
    required this.userId,
    required this.usageDate,
    required this.questionsCount,
    required this.scansCount,
    this.userName,
    this.userEmail,
  });

  factory AiUsageRow.fromJson(Map<String, dynamic> json) {
    final user = json['profiles'] as Map<String, dynamic>?;
    return AiUsageRow(
      userId: json['user_id'] as String,
      usageDate: DateTime.parse(json['usage_date'] as String),
      questionsCount: (json['questions_count'] as num?)?.toInt() ?? 0,
      scansCount: (json['scans_count'] as num?)?.toInt() ?? 0,
      userName: user?['full_name'] as String?,
      userEmail: user?['email'] as String?,
    );
  }

  final String userId;
  final DateTime usageDate;
  final int questionsCount;
  final int scansCount;
  final String? userName;
  final String? userEmail;
}

/// Skan natijasi (`scan_results`).
class ScanRow {
  const ScanRow({
    required this.id,
    required this.diseaseName,
    required this.confidence,
    required this.severity,
    required this.isPlant,
    required this.createdAt,
    this.diseaseLatin,
    this.modelVersion,
    this.latencyMs,
    this.userName,
    this.userEmail,
    this.cropName,
    this.imagePath,
    this.symptoms = const [],
    this.treatments = const [],
    this.prevention,
  });

  factory ScanRow.fromJson(Map<String, dynamic> json, {String locale = 'uz'}) {
    final user = json['profiles'] as Map<String, dynamic>?;
    final crop = json['crop_types'] as Map<String, dynamic>?;

    return ScanRow(
      id: json['id'] as String,
      diseaseName: json['disease_name'] as String? ?? '',
      diseaseLatin: json['disease_latin'] as String?,
      confidence: (json['confidence'] as num?)?.toInt() ?? 0,
      severity: json['severity'] as String? ?? 'unknown',
      isPlant: json['is_plant'] as bool? ?? true,
      modelVersion: json['model_version'] as String?,
      latencyMs: (json['latency_ms'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: user?['full_name'] as String?,
      userEmail: user?['email'] as String?,
      cropName: refName(crop, locale),
      imagePath: json['image_path'] as String?,
      symptoms: [
        for (final s in (json['symptoms'] as List?) ?? const [])
          if (s is String && s.isNotEmpty) s,
      ],
      treatments: TreatmentStep.listFrom(json['treatments']),
      prevention: json['prevention'] as String?,
    );
  }

  final String id;
  final String diseaseName;
  final String? diseaseLatin;
  final int confidence;
  final String severity;

  /// AI rasmda o'simlik topmagan bo'lsa `false` — sifat muammosi belgisi.
  final bool isPlant;

  /// Zanjirdagi qaysi model javob berdi (`gemini-3.6-flash` va h.k.).
  /// Kvota tugashini shu orqali kuzatiladi (TTZ §6.6).
  final String? modelVersion;

  final int? latencyMs;
  final DateTime createdAt;
  final String? userName;
  final String? userEmail;
  final String? cropName;

  /// `scan-images` buketidagi yo'l (`<user_id>/<ms>.jpg`). Yuklash
  /// muvaffaqiyatsiz bo'lsa mobil ilova natijani rasmsiz saqlaydi — `null`.
  final String? imagePath;
  final List<String> symptoms;
  final List<TreatmentStep> treatments;
  final String? prevention;
}

/// Davolash qadami — `scan_results.treatments` va
/// `disease_reference.treatments` da bir xil shakl:
/// `[{"step":1,"title":"...","detail":"..."}]`.
class TreatmentStep {
  const TreatmentStep({required this.title, this.detail = ''});

  final String title;
  final String detail;

  Map<String, dynamic> toJson(int step) => {
    'step': step,
    'title': title,
    'detail': detail,
  };

  /// Eski yozuvlarda qadam oddiy matn bo'lishi ham mumkin — u sarlavha
  /// sifatida olinadi, yozuv tashlab ketilmaydi.
  static List<TreatmentStep> listFrom(Object? raw) => [
    for (final t in (raw as List?) ?? const [])
      if (t is Map && (t['title'] as String? ?? '').isNotEmpty)
        TreatmentStep(
          title: t['title'] as String,
          detail: t['detail'] as String? ?? '',
        )
      else if (t is String && t.isNotEmpty)
        TreatmentStep(title: t),
  ];
}

/// Foydalanuvchi AI ga bergan savol (`ai_messages`, `role = 'user'`).
///
/// O'qish `ai.moderate` talab qiladi (0009) — bu shaxsiy yozishma.
class AiQuestion {
  const AiQuestion({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.createdAt,
    this.conversationTitle,
    this.userName,
    this.userEmail,
  });

  factory AiQuestion.fromJson(Map<String, dynamic> json) {
    final conv = json['ai_conversations'] as Map<String, dynamic>?;
    final user = conv?['profiles'] as Map<String, dynamic>?;
    return AiQuestion(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      conversationTitle: conv?['title'] as String?,
      userName: user?['full_name'] as String?,
      userEmail: user?['email'] as String?,
    );
  }

  final String id;
  final String conversationId;
  final String content;
  final DateTime createdAt;
  final String? conversationTitle;
  final String? userName;
  final String? userEmail;
}

/// Suhbatdagi bitta xabar — savol yoki AI javobi.
class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.isUser,
    required this.content,
    required this.createdAt,
  });

  factory AiChatMessage.fromJson(Map<String, dynamic> json) => AiChatMessage(
    id: json['id'] as String,
    isUser: json['role'] == 'user',
    content: json['content'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String id;
  final bool isUser;
  final String content;
  final DateTime createdAt;
}

/// Davr bo'yicha jami foydalanish — AI sahifasi tepasidagi kartalar.
class AiTotals {
  const AiTotals({this.questions = 0, this.scans = 0, this.activeUsers = 0});

  final int questions;
  final int scans;
  final int activeUsers;
}

/// Model bo'yicha yig'ma — kvota va sifatni kuzatish uchun.
class ModelUsage {
  const ModelUsage({
    required this.model,
    required this.count,
    required this.avgLatencyMs,
    required this.avgConfidence,
  });

  final String model;
  final int count;
  final int avgLatencyMs;
  final int avgConfidence;
}

/// Kasallik ma'lumotnomasi yozuvi (`disease_reference`, 0013 da kengaytirilgan).
class DiseaseRow {
  const DiseaseRow({
    required this.id,
    required this.code,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.status,
    this.latinName,
    this.description,
    this.causes,
    this.prevention,
    this.cropName,
    this.cropTypeId,
    this.symptoms = const [],
    this.treatments = const [],
    this.updatedAt,
  });

  factory DiseaseRow.fromJson(
    Map<String, dynamic> json, {
    String locale = 'uz',
  }) {
    final crop = json['crop_types'] as Map<String, dynamic>?;

    return DiseaseRow(
      // `disease_reference.id` — `smallint`, `uuid` EMAS (0001). Admin CRUD
      // shuni hisobga oladi; 0013 da unga ketma-ketlik qo'shilgan, aks holda
      // yangi qator qo'shish `null value in column "id"` bilan tugardi.
      id: (json['id'] as num).toInt(),
      code: json['code'] as String? ?? '',
      nameUz: json['name_uz'] as String? ?? '',
      nameRu: json['name_ru'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      latinName: json['latin_name'] as String?,
      description: json['description'] as String?,
      causes: json['causes'] as String?,
      prevention: json['prevention'] as String?,
      status: json['status'] as String? ?? 'published',
      cropName: refName(crop, locale),
      cropTypeId: (json['crop_type_id'] as num?)?.toInt(),
      symptoms: [
        for (final s in (json['symptoms'] as List?) ?? const [])
          if (s is String && s.isNotEmpty) s,
      ],
      treatments: TreatmentStep.listFrom(json['treatments']),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }

  final int id;
  final String code;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final String? latinName;
  final String? description;
  final String? causes;
  final String? prevention;
  final String status;
  final String? cropName;
  final int? cropTypeId;
  final List<String> symptoms;
  final List<TreatmentStep> treatments;
  final DateTime? updatedAt;

  int get symptomCount => symptoms.length;
  int get treatmentCount => treatments.length;

  /// Tarjima to'liqligi — `content_translation_state()` bilan bir xil mantiq,
  /// lekin bu jadvalda `name_ru`/`name_en` MAJBURIY, shuning uchun tekshiruv
  /// bo'sh matnga qaraydi.
  bool get isTranslated => nameRu.isNotEmpty && nameEn.isNotEmpty;
}

/// Ekin turi — kasallik formasidagi tanlov uchun (`crop_types`).
class CropOption {
  const CropOption({required this.id, required this.name});

  final int id;
  final String name;
}

/// Kasallik formasidan bazaga ketadigan maydonlar.
class DiseaseDraft {
  const DiseaseDraft({
    required this.code,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    this.cropTypeId,
    this.latinName,
    this.description,
    this.causes,
    this.prevention,
    this.symptoms = const [],
    this.treatments = const [],
  });

  final String code;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final int? cropTypeId;
  final String? latinName;
  final String? description;
  final String? causes;
  final String? prevention;
  final List<String> symptoms;
  final List<TreatmentStep> treatments;

  /// Bo'sh matn `null` bo'lib yoziladi — bazada `''` va `null` aralashib
  /// ketmasin (tarjima to'liqligi tekshiruvi bo'sh satrga qaraydi).
  Map<String, dynamic> toJson() {
    String? clean(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();
    return {
      'code': code.trim(),
      'name_uz': nameUz.trim(),
      'name_ru': nameRu.trim(),
      'name_en': nameEn.trim(),
      'crop_type_id': cropTypeId,
      'latin_name': clean(latinName),
      'description': clean(description),
      'causes': clean(causes),
      'prevention': clean(prevention),
      'symptoms': symptoms,
      'treatments': [
        for (var i = 0; i < treatments.length; i++) treatments[i].toJson(i + 1),
      ],
    };
  }
}

/// Kontent lifecycle holatlari (`content_status` enum, 0013).
abstract final class ContentStatus {
  static const draft = 'draft';
  static const review = 'review';
  static const published = 'published';
  static const archived = 'archived';

  static const all = <String>[draft, review, published, archived];
}
