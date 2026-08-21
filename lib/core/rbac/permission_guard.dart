import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/cubit/admin_auth_cubit.dart';
import '../../ui/admin_feedback.dart';
import 'permission.dart';

/// Ruxsat bo'lmasa bolani ko'rsatmaydi.
///
/// DIQQAT — bu FAQAT UX. Haqiqiy himoya bazada: `admin_has()` RLS
/// siyosatlarida va RPC lar ichida (0008–0018). Bu vidjetni chetlab o'tish
/// hech narsa bermaydi — so'rovni server rad etadi yoki bo'sh ro'yxat
/// qaytaradi. Uning vazifasi shunchaki ishlamaydigan tugmani ko'rsatmaslik.
class PermissionGuard extends StatelessWidget {
  const PermissionGuard({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  final String permission;
  final Widget child;

  /// Ruxsat yo'q bo'lganda ko'rsatiladigan vidjet. Berilmasa — tushuntirish
  /// bilan sahifa (`AdminNoAccess`). Menyu bandlari uchun `SizedBox.shrink()`
  /// beriladi: yashirin band tushuntirishga muhtoj emas.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final perms = context.select<AdminAuthCubit, AdminPermissions>(
      (cubit) => cubit.state.permissions,
    );

    if (perms.has(permission)) return child;
    return fallback ?? AdminNoAccess(permission: permission);
  }
}

/// `context.perms` — ruxsatlarga qisqa yo'l.
extension PermissionContext on BuildContext {
  AdminPermissions get perms => read<AdminAuthCubit>().state.permissions;

  bool can(String permission) => perms.has(permission);
}
