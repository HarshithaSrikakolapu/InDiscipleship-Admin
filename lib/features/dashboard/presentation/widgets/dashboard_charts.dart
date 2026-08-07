import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardCharts {
  static Widget buildNoData() {
    return const Center(
      child: Text(
        'No data available',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  static Widget buildLineChart(Map<String, num> data, {bool isArea = true}) {
    if (data.isEmpty) return buildNoData();

    final keys = data.keys.toList();
    final values = data.values.toList();

    double maxY = 10;
    for (var v in values) {
      if (v > maxY) maxY = v.toDouble();
    }
    maxY = (maxY * 1.2).ceilToDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 20 ? (maxY / 5) : 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFFE2E8F0),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (val, meta) {
                if (val.toInt() >= 0 && val.toInt() < keys.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      keys[val.toInt()],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (keys.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              keys.length,
              (i) => FlSpot(i.toDouble(), values[i].toDouble()),
            ),
            isCurved: true,
            curveSmoothness: 0.35,
            preventCurveOverShooting: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4,
                    color: Colors.white,
                    strokeWidth: 2,
                    strokeColor: AppColors.primary,
                  ),
            ),
            belowBarData: BarAreaData(
              show: isArea,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.4),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildBarChart(Map<String, num> data) {
    if (data.isEmpty) return buildNoData();

    final keys = data.keys.toList();
    final values = data.values.toList();

    double maxY = 10;
    for (var v in values) {
      if (v > maxY) maxY = v.toDouble();
    }
    maxY = (maxY * 1.2).ceilToDouble();

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 20 ? (maxY / 5) : 5,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (val, meta) {
                if (val.toInt() >= 0 && val.toInt() < keys.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      keys[val.toInt()],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        maxY: maxY,
        barGroups: List.generate(keys.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: values[i].toDouble(),
                color: AppColors.primaryAccent,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  static Widget buildPieChart(
    Map<String, num> data, {
    bool isDoughnut = false,
  }) {
    if (data.isEmpty) return buildNoData();

    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];
    final keys = data.keys.toList();

    double total = 0;
    for (var v in data.values) {
      total += v;
    }
    if (total == 0) total = 1;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: isDoughnut ? 50 : 0,
              sections: List.generate(keys.length, (i) {
                final val = data[keys[i]]!.toDouble();
                final percentage = (val / total * 100).round();
                return PieChartSectionData(
                  color: colors[i % colors.length],
                  value: val,
                  title: percentage > 4 ? '$percentage%' : '',
                  radius: isDoughnut ? 30 : 80,
                  titleStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: List.generate(keys.length, (i) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        keys[i],
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildHorizontalBar(Map<String, num> data) {
    if (data.isEmpty) return buildNoData();

    final keys = data.keys.toList();
    double maxVal = 0;
    for (var v in data.values) {
      if (v > maxVal) maxVal = v.toDouble();
    }
    if (maxVal == 0) maxVal = 1;

    return ListView.separated(
      itemCount: keys.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final key = keys[index];
        final val = data[key]!.toDouble();
        final ratio = val / maxVal;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  key,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  val.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.background,
                color: AppColors.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}
