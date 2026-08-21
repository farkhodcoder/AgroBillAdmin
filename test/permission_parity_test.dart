import 'dart:io';

import 'package:agrobilladminpc_web/core/rbac/permission.dart';
import 'package:flutter_test/flutter_test.dart';

/// `AdminPermission` va `AdminRole` — `0016_seed_rbac.sql` ning nusxasi.
///
/// Nusxa asl bilan mos kelmasa xato JIM boʻladi: frontend menyu bandini
/// koʻrsatadi, baza esa soʻrovni rad etadi va admin "nega ishlamayapti" deb
/// qidiradi. Shuning uchun ikkalasi build vaqtida solishtiriladi.
///
/// Migratsiyalar mobil repozitoriyda turadi (`agrobill/supabase/migrations/`),
/// admin esa mustaqil loyiha — yoʻl nisbiy. Fayl topilmasa test OʻTKAZIB
/// YUBORILADI, chunki papka koʻchirilgan boʻlishi mumkin va bu tarjima yoki
/// kod xatosi emas.
void main() {
  final seed = File('../../agrobill/supabase/migrations/0016_seed_rbac.sql');

  test('ruxsat kodlari 0016_seed_rbac.sql bilan bir xil', () {
    if (!seed.existsSync()) {
      markTestSkipped('0016_seed_rbac.sql topilmadi: ${seed.path}');
      return;
    }

    final sql = seed.readAsStringSync();

    // `insert into admin_permissions (...) values` blokidagi birinchi ustun.
    final block = _between(sql, 'insert into admin_permissions', 'on conflict');
    final fromSql = RegExp(
      r"\('([a-z]+\.[a-z_]+)'",
    ).allMatches(block).map((m) => m.group(1)!).toSet();

    expect(fromSql, isNotEmpty, reason: 'SQL dan ruxsat kodlari oʻqilmadi');
    expect(
      AdminPermission.all.toSet(),
      equals(fromSql),
      reason: 'permission.dart va 0016_seed_rbac.sql mos kelmayapti',
    );
  });

  test('rol kodlari 0016_seed_rbac.sql bilan bir xil', () {
    if (!seed.existsSync()) {
      markTestSkipped('0016_seed_rbac.sql topilmadi: ${seed.path}');
      return;
    }

    final sql = seed.readAsStringSync();
    final block = _between(sql, 'insert into admin_roles', 'on conflict');
    final fromSql = RegExp(
      r"\('([a-z_]+)',",
    ).allMatches(block).map((m) => m.group(1)!).toSet();

    expect(fromSql, isNotEmpty, reason: 'SQL dan rol kodlari oʻqilmadi');
    expect(
      AdminRole.all.toSet(),
      equals(fromSql),
      reason: 'permission.dart va 0016_seed_rbac.sql mos kelmayapti',
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
