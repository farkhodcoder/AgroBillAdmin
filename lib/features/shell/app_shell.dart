import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
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
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
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
    );
  }
}
