import 'package:get_it/get_it.dart';

import '../core/theme/theme_controller.dart';

import '../data/repositories/admin_ai_repository.dart';
import '../data/repositories/admin_audit_repository.dart';
import '../data/repositories/admin_auth_repository.dart';
import '../data/repositories/admin_dashboard_repository.dart';
import '../data/repositories/admin_farm_repository.dart';
import '../data/repositories/admin_listing_repository.dart';
import '../data/repositories/admin_ops_repository.dart';
import '../data/repositories/admin_order_repository.dart';
import '../data/repositories/admin_staff_repository.dart';
import '../data/repositories/admin_user_repository.dart';

final getIt = GetIt.instance;

/// Bog'liqliklarni ro'yxatdan o'tkazish. `main()` da bir marta chaqiriladi.
///
/// Repozitoriylar `lazySingleton` — birinchi ishlatilganda yaratiladi, shuning
/// uchun panel ochilishi sekinlashmaydi (mobil ilovadagi `di.dart` naqshi).
///
/// Cubit'lar bu yerda EMAS: ular vidjet daraxtida `BlocProvider` orqali
/// beriladi, shunda ekran yopilganda o'zi tozalanadi va modul almashganda
/// eski filtr qolib ketmaydi.
Future<void> setupDependencies() async {
  getIt
    // Tema kontrolleri repozitoriy emas, lekin u ham butun ilova
    // umri davomida yagona bo'lishi kerak: ikki nusxa bo'lsa TopBar dagi
    // tugma bosilganda kirish ekranidagi tugma eskicha ko'rinib qolardi.
    ..registerLazySingleton<ThemeController>(ThemeController.new)
    ..registerLazySingleton<AdminAuthRepository>(AdminAuthRepository.new)
    ..registerLazySingleton<AdminDashboardRepository>(
      AdminDashboardRepository.new,
    )
    ..registerLazySingleton<AdminUserRepository>(AdminUserRepository.new)
    ..registerLazySingleton<AdminFarmRepository>(AdminFarmRepository.new)
    ..registerLazySingleton<AdminListingRepository>(AdminListingRepository.new)
    ..registerLazySingleton<AdminOrderRepository>(AdminOrderRepository.new)
    ..registerLazySingleton<AdminAiRepository>(AdminAiRepository.new)
    ..registerLazySingleton<AdminAuditRepository>(AdminAuditRepository.new)
    ..registerLazySingleton<AdminStaffRepository>(AdminStaffRepository.new)
    ..registerLazySingleton<AdminOpsRepository>(AdminOpsRepository.new);
}
