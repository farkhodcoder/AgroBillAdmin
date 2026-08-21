import 'dart:convert';
import 'dart:io';

import 'package:agrobilladminpc_web/core/rbac/permission.dart';
import 'package:flutter_test/flutter_test.dart';

/// `AdminPermission` / `AdminRole` va `0016_seed_rbac.sql` mosligini
/// kafolatlaydi.
///
/// Nusxa asl bilan mos kelmasa xato JIM boʻladi: frontend menyu bandini
/// koʻrsatadi, baza esa soʻrovni rad etadi va admin "nega ishlamayapti" deb
/// qidiradi.
///
/// NEGA IKKI QAVAT (fixture + SQL):
/// Migratsiyalar mobil repozitoriyda (`agrobill/supabase/migrations/`), admin
/// esa mustaqil repozitoriy. CI faqat admin repozitoriysini checkout qiladi,
/// ya'ni SQL fayli u yerda UMUMAN YOʻQ. Avval test shunday holatda oʻzini
/// oʻtkazib yuborardi — natijada kafolat aynan kerak boʻlgan joyda, deploy
/// oldidan, ishlamasdi. Buni CI jurnalidagi "(skipped)" koʻrsatdi.
///
/// Endi oraliqda `test/fixtures/rbac_seed.json` turadi:
///   1-test (HAR DOIM, CI da ham): Dart kodi == fixture.
///   2-test (SQL bor boʻlsa): fixture == SQL.
/// Shunda CI haqiqiy tekshiruv oladi, mahalliy ishga tushirish esa
/// fixture eskirib qolmaganini ushlaydi.
void main() {
  final fixtureFile = File('test/fixtures/rbac_seed.json');
  final seed = File('../../agrobill/supabase/migrations/0016_seed_rbac.sql');

  late Set<String> fixturePermissions;
  late Set<String> fixtureRoles;

  setUpAll(() {
    final json =
        jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
    fixturePermissions = (json['permissions'] as List).cast<String>().toSet();
    fixtureRoles = (json['roles'] as List).cast<String>().toSet();
  });

  test('ruxsat kodlari fixture bilan bir xil', () {
    expect(fixturePermissions, hasLength(24));
    expect(
      AdminPermission.all.toSet(),
      equals(fixturePermissions),
      reason: 'permission.dart va rbac_seed.json mos kelmayapti',
    );
  });

  test('rol kodlari fixture bilan bir xil', () {
    expect(fixtureRoles, hasLength(6));
    expect(
      AdminRole.all.toSet(),
      equals(fixtureRoles),
      reason: 'permission.dart va rbac_seed.json mos kelmayapti',
    );
  });

  test('fixture 0016_seed_rbac.sql bilan bir xil', () {
    if (!seed.existsSync()) {
      // Faqat CI da kutiladi. Mahalliy ishga tushirishda bu skip koʻrinsa,
      // demak mobil repozitoriy koʻchirilgan — yoʻlni tuzating, aks holda
      // fixture jimgina eskirib boradi.
      markTestSkipped('0016_seed_rbac.sql topilmadi: ${seed.path}');
      return;
    }

    final sql = seed.readAsStringSync();

    // `insert into admin_permissions (...) values` blokidagi birinchi ustun.
    final permBlock = _between(
      sql,
      'insert into admin_permissions',
      'on conflict',
    );
    final permsFromSql = RegExp(
      r"\('([a-z]+\.[a-z_]+)'",
    ).allMatches(permBlock).map((m) => m.group(1)!).toSet();

    final roleBlock = _between(sql, 'insert into admin_roles', 'on conflict');
    final rolesFromSql = RegExp(
      r"\('([a-z_]+)',",
    ).allMatches(roleBlock).map((m) => m.group(1)!).toSet();

    expect(permsFromSql, isNotEmpty, reason: 'SQL dan ruxsat oʻqilmadi');
    expect(rolesFromSql, isNotEmpty, reason: 'SQL dan rol oʻqilmadi');

    expect(
      fixturePermissions,
      equals(permsFromSql),
      reason: 'rbac_seed.json eskirgan — SQL dan qayta yarating',
    );
    expect(
      fixtureRoles,
      equals(rolesFromSql),
      reason: 'rbac_seed.json eskirgan — SQL dan qayta yarating',
    );
  });

  test('ruxsat kodlari takrorlanmaydi', () {
    expect(AdminPermission.all.length, AdminPermission.all.toSet().length);
    expect(AdminRole.all.length, AdminRole.all.toSet().length);
  });
}

String _between(String source, String start, String end) {
  final from = source.indexOf(start);
  if (from < 0) return '';
  final to = source.indexOf(end, from);
  return to < 0 ? source.substring(from) : source.substring(from, to);
}
