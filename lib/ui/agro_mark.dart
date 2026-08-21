import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// AgroBill brend belgisi — to'q yashil kvadrat ustidagi barg.
///
/// Ayni shakl uch joyda takrorlanadi va uchalasi mos kelishi kerak:
/// brauzer yorlig'idagi ikonka (`web/icons/*.png`, `tool/make_icons.js`),
/// yuklanish ekrani (`web/index.html` dagi ichki SVG) va shu vidjet.
/// Geometriya raqamlari uchalasida bir xil.
///
/// Rasm emas, chizma: har o'lchamda tiniq chiqadi va qo'shimcha fayl
/// yuklashni talab qilmaydi.
class AgroMark extends StatelessWidget {
  const AgroMark({super.key, this.size = 32});

  final double size;

  /// Barg konturi — ikki doira KESISHMASI.
  ///
  /// Ochiq, chunki `agro_mark_test.dart` uni to'g'ridan-to'g'ri sinaydi:
  /// chizmani ko'z bilan tekshirib bo'lmaydi, lekin nuqta bargning ichidami
  /// yoki tashqarisidami — buni aniq tekshirsa bo'ladi.
  static Path leafPath(double side) {
    final c = side / 2;
    final r = 1.04 * c;
    final d = 0.499 * c;
    return Path.combine(
      PathOperation.intersect,
      Path()..addOval(Rect.fromCircle(center: Offset(c - d, c - d), radius: r)),
      Path()..addOval(Rect.fromCircle(center: Offset(c + d, c + d), radius: r)),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: const _AgroMarkPainter()),
  );
}

class _AgroMarkPainter extends CustomPainter {
  const _AgroMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = s / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, s, s),
        Radius.circular(s * 0.22),
      ),
      Paint()..color = AgPalette.green900,
    );

    // Barg — ikki doira KESISHMASI. Markazlar diagonal bo'ylab siljigani
    // uchun natija pastdan-chapdan yuqoriga-o'ngga cho'zilgan barg beradi.
    final r = 1.04 * c;
    final d = 0.499 * c;
    final leaf = Path.combine(
      PathOperation.intersect,
      Path()..addOval(Rect.fromCircle(center: Offset(c - d, c - d), radius: r)),
      Path()..addOval(Rect.fromCircle(center: Offset(c + d, c + d), radius: r)),
    );
    canvas.drawPath(leaf, Paint()..color = AgPalette.green400);

    // O'rta tomir — bargni ikkiga bo'lib, uni shunchaki oval emas,
    // barg sifatida o'qishga yordam beradi.
    final m = 0.54 * c;
    canvas.drawLine(
      Offset(c - m, c + m),
      Offset(c + m, c - m),
      Paint()
        ..color = AgPalette.green900.withValues(alpha: 0.55)
        ..strokeWidth = s * 0.052,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
