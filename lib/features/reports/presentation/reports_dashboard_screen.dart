import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/reports_controller.dart';
import 'widgets/reports_date_filter.dart';
import 'widgets/kpi_card.dart';
import 'widgets/registration_trend_chart.dart';

class ReportsDashboardScreen extends ConsumerWidget {
  const ReportsDashboardScreen({super.key});

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
                final summary = state.userGrowthSummary;
                if (summary == null) {
                  return const Center(child: Text('No data available.'));
                }
                
                final totalCountries = state.locationReports?.length ?? 0;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKpiGrid(summary, totalCountries),
                      const SizedBox(height: 24),
                      if (state.registrationTrends != null)
                        RegistrationTrendChart(trends: state.registrationTrends!),
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
            'Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          ReportsDateFilter(),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(dynamic summary, int totalCountries) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            KpiCard(
              title: 'Total Users',
              value: summary.totalUsers.toString(),
              icon: Icons.people,
              iconColor: Colors.blue,
            ),
            KpiCard(
              title: 'Countries Represented',
              value: totalCountries.toString(),
              icon: Icons.public,
              iconColor: Colors.purple,
            ),
            KpiCard(
              title: 'New Users Today',
              value: summary.newUsersToday.toString(),
              icon: Icons.person_add,
              iconColor: Colors.green,
            ),
            KpiCard(
              title: 'New Users This Week',
              value: summary.newUsersThisWeek.toString(),
              icon: Icons.trending_up,
              iconColor: Colors.orange,
            ),
            KpiCard(
              title: 'New Users This Month',
              value: summary.newUsersThisMonth.toString(),
              icon: Icons.calendar_month,
              iconColor: Colors.teal,
            ),
            KpiCard(
              title: 'Returning Users',
              value: summary.returningUsers.toString(),
              icon: Icons.replay,
              iconColor: Colors.indigo,
            ),
            KpiCard(
              title: 'Inactive Users',
              value: summary.inactiveUsers.toString(),
              icon: Icons.snooze,
              iconColor: Colors.grey,
            ),
            KpiCard(
              title: 'Published Lessons',
              value: summary.publishedLessons.toString(),
              icon: Icons.menu_book,
              iconColor: Colors.deepOrange,
            ),
          ],
        );
      },
    );
  }
}
