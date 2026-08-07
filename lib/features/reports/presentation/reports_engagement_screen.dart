import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/reports_controller.dart';
import 'widgets/reports_date_filter.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsEngagementScreen extends ConsumerWidget {
  const ReportsEngagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(reportsControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: reportsState.when(
              data: (state) {
                final lessonEngagement = state.lessonEngagement;
                if (lessonEngagement == null || lessonEngagement.isEmpty) {
                  return const Center(
                    child: Text('No engagement data available.'),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEngagementChart(lessonEngagement),
                      const SizedBox(height: 24),
                      _buildEngagementTable(lessonEngagement),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Lesson Engagement',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          ReportsDateFilter(),
        ],
      ),
    );
  }

  Widget _buildEngagementChart(List<dynamic> engagementList) {
    // Take top 5 for the chart
    final topEngagement = engagementList.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 Lessons Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    topEngagement.fold<double>(
                      0,
                      (max, e) => e.startedCount > max
                          ? e.startedCount.toDouble()
                          : max,
                    ) *
                    1.2,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 ||
                            value.toInt() >= topEngagement.length) {
                          return const SizedBox.shrink();
                        }
                        final title = topEngagement[value.toInt()].lessonTitle;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            title.length > 15
                                ? '${title.substring(0, 15)}...'
                                : title,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF475569),
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: topEngagement.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.startedCount.toDouble(),
                        color: Colors.blue.shade400,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: item.completedCount.toDouble(),
                        color: Colors.green.shade400,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.blue.shade400, 'Started'),
              const SizedBox(width: 24),
              _buildLegendItem(Colors.green.shade400, 'Completed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
      ],
    );
  }

  Widget _buildEngagementTable(List<dynamic> engagementList) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'All Lessons Engagement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          DataTable(
            headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
            columns: const [
              DataColumn(label: Text('Lesson Title')),
              DataColumn(label: Text('Started')),
              DataColumn(label: Text('Completed')),
              DataColumn(label: Text('Completion Rate')),
            ],
            rows: engagementList.map((e) {
              return DataRow(
                cells: [
                  DataCell(Text(e.lessonTitle)),
                  DataCell(Text(e.startedCount.toString())),
                  DataCell(Text(e.completedCount.toString())),
                  DataCell(
                    Text(
                      '${e.completionRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: e.completionRate > 75
                            ? Colors.green
                            : (e.completionRate < 25
                                  ? Colors.red
                                  : Colors.orange),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
