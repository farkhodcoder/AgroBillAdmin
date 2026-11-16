import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../auth/cubit/admin_auth_cubit.dart';
import 'widgets/sidebar.dart';
import 'widgets/top_bar.dart';

/// Panel ichidagi barcha ekranlar uchun karkas: chapda sidebar, tepada
/// TopBar, o'rtada modul.
///
/// `ShellRoute` ostida turadi, ya'ni modul almashganda qayta qurilmaydi —
/// sidebar holati (yig'ilgan/ochiq) saqlanadi.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.title,
    required this.currentRoute,
  });

  final Widget child;
  final String title;
  final String currentRoute;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    // Klaviatura hodisalari fokusdan qat'i nazar shu yerga keladi — matn
    // yozayotgan admin "harakatsiz" hisoblanmasin.
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    _touch();
    // `false` — hodisa yutilmaydi, odatdagidek ishlov beriladi.
    return false;
  }

  /// Faollik belgisi — harakatsizlikda avtomatik chiqish taymeri uchun
  /// (`IdleGuard`). Yozish 10 soniyada bir martadan ko'p bo'lmaydi.
  void _touch() => context.read<AdminAuthCubit>().touch();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Listener(
      // `translucent` — ichidagi vidjetlar hodisani odatdagidek oladi.
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _touch(),
      onPointerHover: (_) => _touch(),
      onPointerSignal: (_) => _touch(),
      child: Scaffold(
        backgroundColor: c.bg,
        body: Row(
          children: [
            Sidebar(
              collapsed: _collapsed,
              onToggle: () => setState(() => _collapsed = !_collapsed),
              currentRoute: widget.currentRoute,
            ),
            Expanded(
              child: Column(
                children: [
                  TopBar(title: widget.title),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
