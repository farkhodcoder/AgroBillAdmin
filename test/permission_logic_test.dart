import 'package:agrobilladminpc_web/core/rbac/permission.dart';
import 'package:agrobilladminpc_web/features/shell/nav_items.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analystCodes = {
    AdminPermission.analyticsRead,
    AdminPermission.usersRead,
    AdminPermission.farmsRead,
    AdminPermission.listingsRead,
    AdminPermission.ordersRead,
    AdminPermission.aiRead,
    AdminPermission.diseaseRead,
  };

  group('AdminPermissions', () {
    // ESLATMA: avval bu yerda "2FA tasdiqlanmagan boʻlsa hech qanday ruxsat
    // berilmaydi" testi turardi. `0019_disable_mfa_requirement.sql` bilan
    // `admin_has()` dan `aal2` sharti olib tashlangani uchun u invariant
    // endi MAVJUD EMAS — testni saqlash yolgʻon xotirjamlik berardi.
    //
    // Qolgan himoya: rol -> ruxsat bogʻlami (RBAC) va RLS siyosatlari.

    test('faqat rolga berilgan kodlar ochiladi', () {
      const perms = AdminPermissions(
        roleCode: AdminRole.analyst,
        codes: analystCodes,
      );

      expect(perms.has(AdminPermission.analyticsRead), isTrue);
      expect(perms.has(AdminPermission.usersRead), isTrue);

      // TTZ §7: tahlilchi bloklay olmaydi va AI suhbatlarini oʻqiy olmaydi.
      expect(perms.has(AdminPermission.usersBlock), isFalse);
      expect(perms.has(AdminPermission.aiModerate), isFalse);
      expect(perms.has(AdminPermission.adminWrite), isFalse);
      expect(perms.has(AdminPermission.settingsWrite), isFalse);
    });

    test('none() — xodim emas', () {
      const perms = AdminPermissions.none();
      expect(perms.isStaff, isFalse);
      expect(perms.roleCode, isNull);
      expect(perms.has(AdminPermission.usersRead), isFalse);
    });

    test('hasAny — bittasi yetarli', () {
      const perms = AdminPermissions(
        roleCode: AdminRole.moderator,
        codes: {AdminPermission.listingsRead},
      );

      expect(
        perms.hasAny([
          AdminPermission.usersBlock,
          AdminPermission.listingsRead,
        ]),
        isTrue,
      );
      expect(
        perms.hasAny([AdminPermission.usersBlock, AdminPermission.auditRead]),
        isFalse,
      );
    });
  });

  group('Sidebar navigatsiyasi', () {
    test('rejadagi modullar ruxsat kodlari haqiqiy', () {
      // Notoʻgʻri yozilgan kod band hech qachon koʻrinmasligiga olib keladi
      // va buni faqat oʻsha rol bilan kirganda sezish mumkin.
      for (final (_, _, permission) in plannedModules) {
        expect(
          AdminPermission.all,
          contains(permission),
          reason: 'nav_items.dart da nomaʼlum ruxsat: $permission',
        );
      }
    });

    test('rejadagi modullar tarjima kaliti admin.nav bilan boshlanadi', () {
      for (final (labelKey, _, _) in plannedModules) {
        expect(labelKey, startsWith('admin.nav.'));
      }
    });

    test('tahlilchi faqat oʻqish modullarini koʻradi', () {
      // TTZ §7 matritsasi: analyst oʻqiydi, lekin hech narsani
      // oʻzgartirmaydi va xodim/audit/sozlama bandlariga tegmaydi.
      const perms = AdminPermissions(
        roleCode: AdminRole.analyst,
        codes: analystCodes,
      );

      final visible = <String>[
        for (final group in adminNavigation)
          for (final item in group.items)
            if (item.visibleFor(perms)) item.labelKey,
      ];

      expect(visible, contains('admin.nav.dashboard'));
      expect(visible, contains('admin.nav.analytics'));
      expect(visible, contains('admin.nav.users'));
      expect(visible, contains('admin.nav.farms'));
      expect(visible, contains('admin.nav.marketplace'));

      expect(visible, isNot(contains('admin.nav.staff')));
      expect(visible, isNot(contains('admin.nav.audit')));
      expect(visible, isNot(contains('admin.nav.settings')));
      expect(visible, isNot(contains('admin.nav.notifications')));
      expect(visible, isNot(contains('admin.nav.content')));
    });

    test('moderator tahlil va xodimlar bandini koʻrmaydi', () {
      const perms = AdminPermissions(
        roleCode: AdminRole.moderator,
        codes: {
          AdminPermission.listingsRead,
          AdminPermission.listingsModerate,
          AdminPermission.listingsDelete,
          AdminPermission.usersRead,
          AdminPermission.ordersRead,
        },
      );

      final visible = <String>[
        for (final group in adminNavigation)
          for (final item in group.items)
            if (item.visibleFor(perms)) item.labelKey,
      ];

      expect(visible, contains('admin.nav.marketplace'));
      expect(visible, contains('admin.nav.orders'));

      // `dashboard` `analytics.read` talab qiladi — moderatorda u yo'q.
      expect(visible, isNot(contains('admin.nav.dashboard')));
      expect(visible, isNot(contains('admin.nav.analytics')));
      expect(visible, isNot(contains('admin.nav.staff')));
    });

    test('har bir menyu bandi haqiqiy ruxsat kodiga tayanadi', () {
      // Notoʻgʻri yozilgan kod band hech qachon koʻrinmasligiga olib
      // keladi va buni faqat oʻsha rol bilan kirganda sezish mumkin.
      for (final group in adminNavigation) {
        for (final item in group.items) {
          for (final permission in item.permissions) {
            expect(
              AdminPermission.all,
              contains(permission),
              reason: '${item.route}: nomaʼlum ruxsat $permission',
            );
          }
        }
      }
    });
  });
}
