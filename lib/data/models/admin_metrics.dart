/// Dashboard KPI — `admin_dashboard_kpi()` javobi (0015).
class DashboardKpi {
  const DashboardKpi({
    required this.totalUsers,
    required this.activeUsers7d,
    required this.newUsersToday,
    required this.totalFarms,
    required this.totalHectares,
    required this.activeListings,
    required this.pendingListings,
    required this.ordersPending,
    required this.scansToday,
    required this.aiQuestionsToday,
    required this.premiumUsers,
    required this.openTickets,
  });

  factory DashboardKpi.fromJson(Map<String, dynamic> json) => DashboardKpi(
    totalUsers: _int(json['total_users']),
    activeUsers7d: _int(json['active_users_7d']),
    newUsersToday: _int(json['new_users_today']),
    totalFarms: _int(json['total_farms']),
    totalHectares: _double(json['total_hectares']),
    activeListings: _int(json['active_listings']),
    pendingListings: _int(json['pending_listings']),
    ordersPending: _int(json['orders_pending']),
    scansToday: _int(json['scans_today']),
    aiQuestionsToday: _int(json['ai_questions_today']),
    premiumUsers: _int(json['premium_users']),
    openTickets: _int(json['open_tickets']),
  );

  final int totalUsers;
  final int activeUsers7d;
  final int newUsersToday;
  final int totalFarms;
  final double totalHectares;
  final int activeListings;
  final int pendingListings;
  final int ordersPending;
  final int scansToday;
  final int aiQuestionsToday;
  final int premiumUsers;
  final int openTickets;
}

/// `admin_metrics_range()` dan bitta kun.
class DailyMetric {
  const DailyMetric({
    required this.day,
    required this.totalUsers,
    required this.newUsers,
    required this.totalFarms,
    required this.totalHectares,
    required this.activeListings,
    required this.pendingListings,
    required this.ordersCreated,
    required this.gmv,
    required this.scans,
    required this.aiQuestions,
    required this.aiActiveUsers,
    required this.premiumUsers,
  });

  factory DailyMetric.fromJson(Map<String, dynamic> json) => DailyMetric(
    day: DateTime.parse(json['day'] as String),
    totalUsers: _int(json['total_users']),
    newUsers: _int(json['new_users']),
    totalFarms: _int(json['total_farms']),
    totalHectares: _double(json['total_hectares']),
    activeListings: _int(json['active_listings']),
    pendingListings: _int(json['pending_listings']),
    ordersCreated: _int(json['orders_created']),
    gmv: _double(json['gmv']),
    scans: _int(json['scans']),
    aiQuestions: _int(json['ai_questions']),
    aiActiveUsers: _int(json['ai_active_users']),
    premiumUsers: _int(json['premium_users']),
  );

  final DateTime day;
  final int totalUsers;
  final int newUsers;
  final int totalFarms;
  final double totalHectares;
  final int activeListings;
  final int pendingListings;
  final int ordersCreated;
  final double gmv;
  final int scans;
  final int aiQuestions;
  final int aiActiveUsers;
  final int premiumUsers;
}

/// PostgREST `numeric` ni matn sifatida qaytaradi (aniqlik yo'qolmasin
/// uchun), `bigint` ni esa son sifatida — shuning uchun ikkala holat ham
/// qo'llab-quvvatlanadi.
int _int(Object? v) => switch (v) {
  int i => i,
  num n => n.round(),
  String s => int.tryParse(s) ?? 0,
  _ => 0,
};

double _double(Object? v) => switch (v) {
  double d => d,
  num n => n.toDouble(),
  String s => double.tryParse(s) ?? 0,
  _ => 0,
};
