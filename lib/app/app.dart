import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../data/repositories/admin_auth_repository.dart';
import '../features/auth/cubit/admin_auth_cubit.dart';
import 'di.dart';
import 'router.dart';

/// Admin panelining ildiz vidjeti.
class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  // Ikkalasi ham `build` da yaratilmaydi: har qayta qurishda yangi GoRouter
  // navigatsiya tarixini nolga qaytarardi, yangi cubit esa sessiyani.
  late final AdminAuthCubit _auth = AdminAuthCubit(getIt<AdminAuthRepository>())
    ..bootstrap();

  late final _router = createRouter(_auth);

  final _theme = getIt<ThemeController>();

  @override
  void dispose() {
    _auth.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _auth,
      // Til `admin_users.language_code` dan yuklanganda MaterialApp qayta
      // qurilishi kerak, shuning uchun listener shu yerda.
      child: BlocListener<AdminAuthCubit, AdminAuthState>(
        listenWhen: (prev, next) =>
            prev.permissions.languageCode != next.permissions.languageCode,
        listener: (context, state) {
          final code = state.permissions.languageCode;
          if (context.locale.languageCode != code) {
            context.setLocale(Locale(code));
          }
        },
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: _theme,
          builder: (context, themeMode, _) => MaterialApp.router(
            title: 'AgroBill Admin',
            debugShowCheckedModeBanner: false,

            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,

            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,

            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
