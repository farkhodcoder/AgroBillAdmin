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

  /// 2FA majburiy, lekin hali ulanmagan.
  static const mfaEnroll = '/mfa/setup';
  static const mfaEnrollName = 'mfa-enroll';

  /// 2FA ulangan — kirishdagi kod bosqichi.
  static const mfaVerify = '/mfa';
  static const mfaVerifyName = 'mfa-verify';

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

  static const news = '/news';
  static const newsName = 'news';

  static const verification = '/verification';
  static const verificationName = 'verification';

  static const disputes = '/disputes';
  static const disputesName = 'disputes';

  static const deletions = '/deletions';
  static const deletionsName = 'deletions';

  static const requests = '/requests';
  static const requestsName = 'requests';

  static const moderation = '/moderation';
  static const moderationName = 'moderation';

  static const weather = '/weather';
  static const weatherName = 'weather';

  static const analytics = '/analytics';
  static const analyticsName = 'analytics';

  static const campaigns = '/campaigns';
  static const campaignsName = 'campaigns';

  static const support = '/support';
  static const supportName = 'support';

  /// Kirish oqimiga tegishli barcha yo'llar — router `redirect` shu ro'yxatga
  /// qaraydi.
  static const authFlow = <String>[login, notAdmin, mfaEnroll, mfaVerify];
}
