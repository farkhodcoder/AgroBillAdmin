import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/admin_auth_repository.dart';
import '../features/auth/cubit/admin_auth_cubit.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/not_admin_page.dart';
import '../features/ai/pages/ai_page.dart';
import '../features/analytics/pages/analytics_page.dart';
import '../features/audit/pages/audit_page.dart';
import '../features/campaigns/pages/campaigns_page.dart';
import '../features/content/pages/content_page.dart';
import '../features/dashboard/pages/dashboard_page.dart';
import '../features/disease/pages/disease_page.dart';
import '../features/farms/pages/farms_page.dart';
import '../features/marketplace/pages/marketplace_page.dart';
import '../features/orders/pages/orders_page.dart';
import '../features/shell/app_shell.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/shell/pages/splash_page.dart';
import '../features/staff/pages/staff_page.dart';
import '../features/users/pages/users_page.dart';
import '../features/weather/pages/weather_page.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

/// Admin panel marshrutlari.
///
/// Yo'naltirish mantig'i BITTA joyda: `redirect`. Ekranlar o'zlari
/// "men noto'g'ri holatdaman" deb sakramaydi — aks holda ikki ekran
/// bir-birini cheksiz almashtirishi mumkin edi.
///
/// Bosqichlar TTZ §8 dagi oqim bilan bir xil:
///   sessiya yo'q      -> /login
///   xodim emas        -> /no-access
///   tayyor            -> /dashboard
GoRouter createRouter(AdminAuthCubit authCubit) => GoRouter(
  navigatorKey: _rootKey,
  initialLocation: AdminRoutes.splash,

  // Cubit holati o'zgarganda router qayta hisoblanadi.
  refreshListenable: _CubitListenable(authCubit),

  redirect: (context, state) {
    final auth = authCubit.state;
    final location = state.matchedLocation;

    // Birinchi tekshiruv tugamaguncha splash. Usiz ilova ochilishida login
    // ekrani bir zumga miltillab ketardi.
    if (!auth.bootstrapped) {
      return location == AdminRoutes.splash ? null : AdminRoutes.splash;
    }

    final target = switch (auth.stage) {
      AuthStage.signedOut => AdminRoutes.login,
      AuthStage.notAdmin => AdminRoutes.notAdmin,
      AuthStage.ready => null,
    };

    if (target != null) {
      return location == target ? null : target;
    }

    // Tayyor: kirish oqimidagi sahifada qolib ketmasin.
    if (location == AdminRoutes.splash ||
        AdminRoutes.authFlow.contains(location)) {
      return AdminRoutes.dashboard;
    }
    return null;
  },

  routes: [
    GoRoute(
      path: AdminRoutes.splash,
      name: AdminRoutes.splashName,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AdminRoutes.login,
      name: AdminRoutes.loginName,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AdminRoutes.notAdmin,
      name: AdminRoutes.notAdminName,
      builder: (context, state) => const NotAdminPage(),
    ),

    // --- Panel ichi ----------------------------------------------------------
    // `ShellRoute` — modul almashganda sidebar qayta qurilmaydi va uning
    // yig'ilgan holati saqlanadi.
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (context, state, child) => AppShell(
        currentRoute: state.matchedLocation,
        title: _titleFor(state.matchedLocation),
        child: child,
      ),
      routes: [
        GoRoute(
          path: AdminRoutes.dashboard,
          name: AdminRoutes.dashboardName,
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: AdminRoutes.users,
          name: AdminRoutes.usersName,
          builder: (context, state) => const UsersPage(),
        ),
        GoRoute(
          path: AdminRoutes.farms,
          name: AdminRoutes.farmsName,
          builder: (context, state) => const FarmsPage(),
        ),
        GoRoute(
          path: AdminRoutes.marketplace,
          name: AdminRoutes.marketplaceName,
          builder: (context, state) => const MarketplacePage(),
        ),
        GoRoute(
          path: AdminRoutes.orders,
          name: AdminRoutes.ordersName,
          builder: (context, state) => const OrdersPage(),
        ),
        GoRoute(
          path: AdminRoutes.ai,
          name: AdminRoutes.aiName,
          builder: (context, state) => const AiPage(),
        ),
        GoRoute(
          path: AdminRoutes.disease,
          name: AdminRoutes.diseaseName,
          builder: (context, state) => const DiseasePage(),
        ),
        GoRoute(
          path: AdminRoutes.audit,
          name: AdminRoutes.auditName,
          builder: (context, state) => const AuditPage(),
        ),
        GoRoute(
          path: AdminRoutes.staff,
          name: AdminRoutes.staffName,
          builder: (context, state) => const StaffPage(),
        ),
        GoRoute(
          path: AdminRoutes.settings,
          name: AdminRoutes.settingsName,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: AdminRoutes.content,
          name: AdminRoutes.contentName,
          builder: (context, state) => const ContentPage(),
        ),
        GoRoute(
          path: AdminRoutes.weather,
          name: AdminRoutes.weatherName,
          builder: (context, state) => const WeatherPage(),
        ),
        GoRoute(
          path: AdminRoutes.analytics,
          name: AdminRoutes.analyticsName,
          builder: (context, state) => const AnalyticsPage(),
        ),
        GoRoute(
          path: AdminRoutes.campaigns,
          name: AdminRoutes.campaignsName,
          builder: (context, state) => const CampaignsPage(),
        ),
      ],
    ),
  ],

  errorBuilder: (context, state) => const SplashPage(notFound: true),
);

String _titleFor(String location) => switch (location) {
  AdminRoutes.dashboard => 'admin.nav.dashboard'.tr(),
  AdminRoutes.users => 'admin.nav.users'.tr(),
  AdminRoutes.farms => 'admin.nav.farms'.tr(),
  AdminRoutes.marketplace => 'admin.nav.marketplace'.tr(),
  AdminRoutes.orders => 'admin.nav.orders'.tr(),
  AdminRoutes.ai => 'admin.nav.ai'.tr(),
  AdminRoutes.disease => 'admin.nav.disease'.tr(),
  AdminRoutes.audit => 'admin.nav.audit'.tr(),
  AdminRoutes.staff => 'admin.nav.staff'.tr(),
  AdminRoutes.settings => 'admin.nav.settings'.tr(),
  AdminRoutes.content => 'admin.nav.content'.tr(),
  AdminRoutes.weather => 'admin.nav.weather'.tr(),
  AdminRoutes.analytics => 'admin.nav.analytics'.tr(),
  AdminRoutes.campaigns => 'admin.nav.notifications'.tr(),
  _ => 'app.title'.tr(),
};

/// Cubit oqimini `Listenable` ga o'giradi — `GoRouter` shuni kutadi.
class _CubitListenable extends ChangeNotifier {
  _CubitListenable(AdminAuthCubit cubit) {
    _sub = cubit.stream.listen((_) => notifyListeners());
  }

  late final dynamic _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Repozitoriyni cubit bilan bog'lash uchun — `di.dart` da ishlatiladi.
AdminAuthCubit createAuthCubit(AdminAuthRepository repo) =>
    AdminAuthCubit(repo);
