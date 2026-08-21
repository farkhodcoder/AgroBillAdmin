import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/admin_metrics.dart';

/// Kunlik ko'rsatkich grafigi.
///
/// Ma'lumot `admin_daily_metrics` matview'idan keladi (0015) — u har kuni
/// 00:30 da yangilanadi, ya'ni BUGUNGI qator kechagi holatni ko'rsatishi
/// mumkin. Shuning uchun bugungi sonlar KPI kartalarda alohida turadi.
class MetricsChart extends StatelessWidget {
  const MetricsChart({
    super.key,
    required this.title,
    required this.metrics,
    required this.value,
    this.tone,
  });

  final String title;
  final List<DailyMetric> metrics;

  /// Qaysi maydon chizilishi.
  final double Function(DailyMetric) value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    final color = tone ?? c.actionPrimary;

    return Container(
      height: 240,
      padding: const EdgeInsets.all(AgSpace.x5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AgRadius.rLg,
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.label.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AgSpace.x4),
          Expanded(
            child: metrics.length < 2
                ? Center(
                    child: Text(
                      'admin.dashboard.no_data'.tr(),
                      style: AppTypography.caption.copyWith(
                        color: c.textTertiary,
                      ),
                    ),
                  )
                : _chart(c, color),
          ),
        ],
      ),
    );
  }

  Widget _chart(AppColors c, Color color) {
    final spots = [
      for (var i = 0; i < metrics.length; i++)
        FlSpot(i.toDouble(), value(metrics[i])),
    ];

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    // Hamma qiymat nol bo'lsa `maxY = 0` va grafik chizilmaydi — shkalaga
    // eng kam balandlik beriladi.
    final top = maxY <= 0 ? 1.0 : maxY * 1.2;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: top,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: top / 3,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: c.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: top / 3,
              getTitlesWidget: (v, _) => Text(
                _short(v),
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              // Har kunni yozish o'qni o'qib bo'lmas qiladi — beshtadan.
              interval: (metrics.length / 5).ceilToDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= metrics.length) return const SizedBox();
                final d = metrics[i].day;
                return Text(
                  '${d.day}.${d.month}',
                  style: AppTypography.caption.copyWith(color: c.textTertiary),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  static String _short(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}
