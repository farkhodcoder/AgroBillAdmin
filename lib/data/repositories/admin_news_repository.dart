import '../../core/supabase/db.dart';
import '../../core/utils/result.dart';

/// AI agro-yangiliklari navbati (`news_posts`, mobil ilova 0048 migratsiyasi).
///
/// Server kuniga 3 marta yangilik tayyorlaydi va ularni `pending` holatida
/// 30 daqiqa ushlab turadi. Shu vaqtda admin tasdiqlaydi yoki rad etadi;
/// hech kim qaramasa yangilik avtomatik e'lon qilinadi.
class AdminNewsRepository {
  Future<Result<List<NewsRow>>> list({String? status}) => guard(() async {
    var query = Db.client
        .from('news_posts')
        .select(
          'id, source, source_url, title_uz, body_uz, title_cyrl, topic, '
          'status, publish_after, published_at, created_at',
        );
    if (status != null) query = query.eq('status', status);

    final rows = await query.order('created_at', ascending: false).limit(100);
    return [for (final r in rows) NewsRow.fromJson(r)];
  });

  /// Holat `review_news` RPC orqali o'zgaradi — u `content.write`
  /// huquqini serverda tekshiradi.
  Future<Result<void>> review(String id, {required bool approve}) =>
      guard(() async {
        await Db.client.rpc<void>(
          'review_news',
          params: {'p_id': id, 'p_approve': approve},
        );
      });
}

class NewsRow {
  const NewsRow({
    required this.id,
    required this.source,
    required this.sourceUrl,
    required this.titleUz,
    required this.bodyUz,
    required this.titleCyrl,
    required this.status,
    required this.publishAfter,
    required this.createdAt,
    this.publishedAt,
    this.topic,
  });

  factory NewsRow.fromJson(Map<String, dynamic> m) => NewsRow(
    id: m['id'] as String,
    source: m['source'] as String? ?? '',
    sourceUrl: m['source_url'] as String? ?? '',
    titleUz: m['title_uz'] as String? ?? '',
    bodyUz: m['body_uz'] as String? ?? '',
    titleCyrl: m['title_cyrl'] as String? ?? '',
    status: m['status'] as String? ?? 'pending',
    publishAfter: DateTime.parse(m['publish_after'] as String),
    createdAt: DateTime.parse(m['created_at'] as String),
    publishedAt: m['published_at'] == null
        ? null
        : DateTime.parse(m['published_at'] as String),
    topic: m['topic'] as String?,
  );

  final String id;
  final String source;
  final String sourceUrl;
  final String titleUz;
  final String bodyUz;
  final String titleCyrl;

  /// `pending` | `published` | `rejected`
  final String status;
  final DateTime publishAfter;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final String? topic;

  bool get isPending => status == 'pending';

  /// Avtomatik e'longacha qolgan vaqt (0 dan kichik bo'lmaydi).
  Duration get remaining {
    final left = publishAfter.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }
}
