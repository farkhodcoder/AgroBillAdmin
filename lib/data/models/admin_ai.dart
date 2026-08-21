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
      cropName: crop?['name_$locale'] as String?,
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
    this.symptomCount = 0,
    this.treatmentCount = 0,
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
      cropName: crop?['name_$locale'] as String?,
      symptomCount: (json['symptoms'] as List?)?.length ?? 0,
      treatmentCount: (json['treatments'] as List?)?.length ?? 0,
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
  final int symptomCount;
  final int treatmentCount;
  final DateTime? updatedAt;

  /// Tarjima to'liqligi — `content_translation_state()` bilan bir xil mantiq,
  /// lekin bu jadvalda `name_ru`/`name_en` MAJBURIY, shuning uchun tekshiruv
  /// bo'sh matnga qaraydi.
  bool get isTranslated => nameRu.isNotEmpty && nameEn.isNotEmpty;
}

/// Kontent lifecycle holatlari (`content_status` enum, 0013).
abstract final class ContentStatus {
  static const draft = 'draft';
  static const review = 'review';
  static const published = 'published';
  static const archived = 'archived';

  static const all = <String>[draft, review, published, archived];
}
