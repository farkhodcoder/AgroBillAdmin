import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/rbac/permission.dart';

/// Yon menyu bandi.
class NavItem {
  const NavItem({
    required this.route,
    required this.labelKey,
    required this.icon,
    required this.permissions,
  });

  final String route;
  final String labelKey;
  final IconData icon;

  /// Band ko'rinishi uchun shu ruxsatlardan HECH BO'LMASA BITTASI kerak.
  /// Ro'yxat bo'sh bo'lsa band doim ko'rinadi.
  final List<String> permissions;

  bool visibleFor(AdminPermissions perms) =>
      permissions.isEmpty || perms.hasAny(permissions);
}

/// Menyu guruhi.
class NavGroup {
  const NavGroup({required this.titleKey, required this.items});

  final String titleKey;
  final List<NavItem> items;
}

/// Butun menyu tuzilishi.
///
/// TTZ §6 dagi 15 modul. Hozircha faqat Dashboard ekrani bor — qolganlari
/// tegishli bosqichda ulanadi va shu ro'yxatga marshrut qo'shiladi. Ular
/// ataylab OLDINDAN ko'rsatilmaydi: ishlamaydigan menyu bandi adminni
/// chalg'itadi.
const adminNavigation = <NavGroup>[
  NavGroup(
    titleKey: 'admin.nav.overview',
    items: [
      NavItem(
        route: AdminRoutes.dashboard,
        labelKey: 'admin.nav.dashboard',
        icon: Icons.dashboard_outlined,
        permissions: [AdminPermission.analyticsRead],
      ),
    ],
  ),
  NavGroup(
    titleKey: 'admin.nav.people',
    items: [
      NavItem(
        route: AdminRoutes.users,
        labelKey: 'admin.nav.users',
        icon: Icons.people_outline,
        permissions: [AdminPermission.usersRead],
      ),
      NavItem(
        route: AdminRoutes.farms,
        labelKey: 'admin.nav.farms',
        icon: Icons.agriculture_outlined,
        permissions: [AdminPermission.farmsRead],
      ),
    ],
  ),
  NavGroup(
    titleKey: 'admin.nav.commerce',
    items: [
      NavItem(
        route: AdminRoutes.marketplace,
        labelKey: 'admin.nav.marketplace',
        icon: Icons.storefront_outlined,
        permissions: [AdminPermission.listingsRead],
      ),
      NavItem(
        route: AdminRoutes.orders,
        labelKey: 'admin.nav.orders',
        icon: Icons.receipt_long_outlined,
        permissions: [AdminPermission.ordersRead],
      ),
    ],
  ),
  NavGroup(
    titleKey: 'admin.nav.knowledge',
    items: [
      NavItem(
        route: AdminRoutes.ai,
        labelKey: 'admin.nav.ai',
        icon: Icons.auto_awesome_outlined,
        permissions: [AdminPermission.aiRead],
      ),
      NavItem(
        route: AdminRoutes.disease,
        labelKey: 'admin.nav.disease',
        icon: Icons.coronavirus_outlined,
        permissions: [AdminPermission.diseaseRead],
      ),
      NavItem(
        route: AdminRoutes.content,
        labelKey: 'admin.nav.content',
        icon: Icons.article_outlined,
        permissions: [AdminPermission.contentRead],
      ),
      NavItem(
        route: AdminRoutes.weather,
        labelKey: 'admin.nav.weather',
        icon: Icons.cloud_outlined,
        permissions: [AdminPermission.contentRead],
      ),
    ],
  ),
  NavGroup(
    titleKey: 'admin.nav.outreach',
    items: [
      NavItem(
        route: AdminRoutes.analytics,
        labelKey: 'admin.nav.analytics',
        icon: Icons.insights_outlined,
        permissions: [AdminPermission.analyticsRead],
      ),
      NavItem(
        route: AdminRoutes.campaigns,
        labelKey: 'admin.nav.notifications',
        icon: Icons.campaign_outlined,
        permissions: [AdminPermission.notificationsSend],
      ),
    ],
  ),
  NavGroup(
    titleKey: 'admin.nav.system',
    items: [
      NavItem(
        route: AdminRoutes.staff,
        labelKey: 'admin.nav.staff',
        icon: Icons.badge_outlined,
        permissions: [AdminPermission.adminRead],
      ),
      NavItem(
        route: AdminRoutes.audit,
        labelKey: 'admin.nav.audit',
        icon: Icons.history_outlined,
        permissions: [AdminPermission.auditRead],
      ),
      NavItem(
        route: AdminRoutes.settings,
        labelKey: 'admin.nav.settings',
        icon: Icons.settings_outlined,
        permissions: [AdminPermission.settingsWrite],
      ),
    ],
  ),
];

/// Hali qurilmagan modullar — sidebar pastida "tez orada" deb ko'rsatiladi.
///
/// Ro'yxatda qoldirish ataylab: qurilmagan modulni yashirish adminni
/// "hammasi tayyor" deb o'ylashga majbur qilardi.
///
/// **Support** (TTZ §6.12) — jadvallar bazada tayyor (`support_tickets`,
/// `support_messages`, 0012), lekin mobil ilovada "Yordam" ekrani YO'Q,
/// ya'ni ticket yaratadigan hech kim yo'q. Admin tomonini avval qurish
/// bo'sh ro'yxat bilan tugardi.
const plannedModules = <(String, IconData, String)>[
  (
    'admin.nav.support',
    Icons.support_agent_outlined,
    AdminPermission.supportRead,
  ),
];
