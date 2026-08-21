/// Marshrut yo'llari va nomlari.
///
/// Yo'l matnlari bitta joyda: `context.goNamed(AdminRoutes.dashboardName)`
/// yozilsa, URL o'zgarganda hech qayerda qidirish kerak bo'lmaydi. Mobil
/// ilovadagi `lib/app/routes.dart` bilan bir xil naqsh.
abstract final class AdminRoutes {
  /// Boshlang'ich ekran — sessiya tekshirilguncha.
  static const splash = '/';
  static const splashName = 'splash';

  // --- Kirish oqimi -------------------------------------------------

  static const login = '/login';
  static const loginName = 'login';

  /// Sessiya bor, lekin admin_users da faol yozuv yoq.
  static const notAdmin = '/no-access';
  static const notAdminName = 'not-admin';

  // --- Panel ichi ------------------------------------------------------------

  static const dashboard = '/dashboard';
  static const dashboardName = 'dashboard';

  static const users = '/users';
  static const usersName = 'users';

  static const farms = '/farms';
  static const farmsName = 'farms';

  static const marketplace = '/marketplace';
  static const marketplaceName = 'marketplace';

  static const orders = '/orders';
  static const ordersName = 'orders';

  static const ai = '/ai';
  static const aiName = 'ai';

  static const disease = '/disease';
  static const diseaseName = 'disease';

  static const audit = '/audit';
  static const auditName = 'audit';

  static const staff = '/staff';
  static const staffName = 'staff';

  static const settings = '/settings';
  static const settingsName = 'settings';

  static const content = '/content';
  static const contentName = 'content';

  static const weather = '/weather';
  static const weatherName = 'weather';

  static const analytics = '/analytics';
  static const analyticsName = 'analytics';

  static const campaigns = '/campaigns';
  static const campaignsName = 'campaigns';

  /// Kirish oqimiga tegishli barcha yo'llar — router `redirect` shu ro'yxatga
  /// qaraydi.
  static const authFlow = <String>[login, notAdmin];
}
