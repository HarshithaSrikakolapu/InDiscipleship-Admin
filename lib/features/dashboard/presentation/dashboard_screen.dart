import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/responsive/responsive.dart';
import '../application/dashboard_providers.dart';
import '../data/models/dashboard_analytics_model.dart';
import 'widgets/dashboard_charts.dart';
import '../../notifications/presentation/widgets/recent_notifications_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(dashboardAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner if Maintenance Mode is Enabled (Hidden until client permission)
            // settingsAsync.when(
            //   data: (settings) {
            //     if (settings.maintenance.enabled) {
            //       final endTimeStr = settings.maintenance.estimatedEndTime != null
            //           ? ' Expected completion: ${DateFormat('h:mm a (MMM d)').format(settings.maintenance.estimatedEndTime!)}.'
            //           : '';
            //       return Container(
            //         margin: const EdgeInsets.only(bottom: 24),
            //         padding: const EdgeInsets.all(16),
            //         decoration: BoxDecoration(
            //           color: AppColors.warning.withOpacity(0.12),
            //           borderRadius: BorderRadius.circular(12),
            //           border: Border.all(color: AppColors.warning, width: 1.5),
            //         ),
            //         child: Row(
            //           children: [
            //             const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
            //             const SizedBox(width: 12),
            //             Expanded(
            //               child: Text(
            //                 '⚠ Maintenance Mode is currently enabled.$endTimeStr Users will be locked out of the mobile app.',
            //                 style: const TextStyle(
            //                   color: AppColors.textPrimary,
            //                   fontWeight: FontWeight.bold,
            //                   fontSize: 15,
            //                 ),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ).animate().shake(duration: 500.ms);
            //     }
            //     return const SizedBox.shrink();
            //   },
            //   loading: () => const SizedBox.shrink(),
            //   error: (_, __) => const SizedBox.shrink(),
            // ),

            const Text(
              'Welcome back, Admin',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Monitor users, mentors, lessons, and engagement.',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            analyticsAsync.when(
              data: (data) => _buildDashboardContent(context, data, ref),
              loading: () => _buildSkeleton(context),
              error: (e, s) => _buildError(ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    DashboardAnalyticsModel data,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admin Summary Card (Hidden until client permission)
        // settingsAsync.when(
        //   data: (settings) => _buildAdminSummaryCard(context, settings),
        //   loading: () => const SizedBox.shrink(),
        //   error: (_, __) => const SizedBox.shrink(),
        // ),
        // const SizedBox(height: 32),
        _buildKPIs(context, data),
        const SizedBox(height: 32),
        _buildCharts(context, data),
        const SizedBox(height: 32),
        _buildRecentActivity(context, data),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildKPIs(BuildContext context, DashboardAnalyticsModel data) {
    final crossAxisCount = Responsive.isMobile(context)
        ? 1
        : Responsive.isTablet(context)
        ? 2
        : 4;

    final cards = [
      _kpiCard(
        'Total Users',
        data.totalUsers.toString(),
        Icons.people,
        AppColors.primary,
      ),
      _kpiCard(
        'Active Users Today',
        data.activeUsersToday.toString(),
        Icons.local_fire_department,
        AppColors.success,
      ),
      _kpiCard(
        'Total Lessons',
        data.totalLessons.toString(),
        Icons.menu_book,
        AppColors.warning,
      ),
      _kpiCard(
        'Published Lessons',
        data.publishedLessons.toString(),
        Icons.check_circle,
        AppColors.success,
      ),

      if (data.hasProgressData)
        _kpiCard(
          'Completed Lessons Today',
          data.completedLessonsToday.toString(),
          Icons.task_alt,
          AppColors.primaryAccent,
        ),
      if (data.hasProgressData)
        _kpiCard(
          'Average Completion',
          '${data.averageCompletion.toStringAsFixed(1)}%',
          Icons.pie_chart,
          AppColors.primary,
        ),
      if (data.hasProgressData)
        _kpiCard(
          'Average Streak',
          data.averageStreak.toStringAsFixed(1),
          Icons.bolt,
          AppColors.warning,
        ),
      _kpiCard(
        'Total Mentors',
        data.totalMentors.toString(),
        Icons.school,
        const Color(0xFF7C3AED),
      ),
    ];

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 140,
      ),
      children: cards,
    );
  }

  Widget _kpiCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts(BuildContext context, DashboardAnalyticsModel data) {
    final crossAxisCount = Responsive.isMobile(context)
        ? 1
        : Responsive.isTablet(context)
        ? 1
        : 2;

    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 400,
      ),
      children: [
        _chartCard(
          'User Registrations by Month',
          DashboardCharts.buildLineChart(data.monthlyRegistrations),
        ),
        _chartCard(
          'Daily Active Users',
          DashboardCharts.buildBarChart(data.dailyActiveUsers),
        ),
        _chartCard(
          'Lesson Completion Rate by Week',
          DashboardCharts.buildLineChart(data.lessonCompletionByWeek),
        ),
        _chartCard(
          'User Growth',
          DashboardCharts.buildLineChart(
            data.monthlyRegistrations,
            isArea: true,
          ),
        ),
        _chartCard(
          'Top Completed Lessons',
          DashboardCharts.buildHorizontalBar(data.topCompletedLessons),
        ),
        _chartCard(
          'Geography Distribution',
          DashboardCharts.buildPieChart(data.geographyDistribution),
        ),
        _chartCard(
          'Age Group Distribution',
          DashboardCharts.buildPieChart(
            data.ageGroupDistribution,
            isDoughnut: true,
          ),
        ),
        _chartCard(
          'Language Distribution',
          DashboardCharts.buildPieChart(data.languageDistribution),
        ),
      ],
    );
  }

  Widget _chartCard(String title, Widget child) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    DashboardAnalyticsModel data,
  ) {
    if (Responsive.isDesktop(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildRecentUsersTable(data)),
          const SizedBox(width: 24),
          Expanded(child: _buildRecentLessonsTable(data)),
          const SizedBox(width: 24),
          const Expanded(child: RecentNotificationsWidget()),
          const SizedBox(width: 24),
          Expanded(child: _buildActivityTimeline(data)),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecentUsersTable(data),
          const SizedBox(height: 24),
          _buildRecentLessonsTable(data),
          const SizedBox(height: 24),
          const RecentNotificationsWidget(),
          const SizedBox(height: 24),
          _buildActivityTimeline(data),
        ],
      );
    }
  }

  Widget _buildRecentUsersTable(DashboardAnalyticsModel data) {
    return _listCard(
      'Recent Users',
      data.recentUsers.map((u) {
        final date = u['joinedDate'] != null
            ? DateFormat('MMM d, y').format(u['joinedDate'] as DateTime)
            : '';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          title: Text(
            u['name'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text('${u['email']}', style: const TextStyle(fontSize: 12)),
          trailing: Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentLessonsTable(DashboardAnalyticsModel data) {
    return _listCard(
      'Recently Updated Lessons',
      data.recentlyUpdatedLessons.map((l) {
        final date = l['updatedTime'] != null
            ? DateFormat('MMM d').format(l['updatedTime'] as DateTime)
            : '';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.menu_book,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          title: Text(
            l['lesson'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            'Week ${l['week']} Day ${l['day']} • By ${l['updatedBy']}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityTimeline(DashboardAnalyticsModel data) {
    if (!data.hasActivityLogs || data.recentActivityTimeline.isEmpty) {
      return _listCard('Recent Activity', [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No activity logs available',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ]);
    }

    return _listCard(
      'Recent Activity',
      data.recentActivityTimeline.map((log) {
        final date = log['createdAt'] != null
            ? DateFormat('MMM d, h:mm a').format(log['createdAt'].toDate())
            : '';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.circle, size: 12, color: AppColors.primary),
          title: Text(
            log['description'] ?? 'Activity occurred',
            style: const TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            date,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _listCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final crossAxisCount = Responsive.isMobile(context)
        ? 1
        : Responsive.isTablet(context)
        ? 2
        : 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            mainAxisExtent: 140,
          ),
          children: List.generate(
            8,
            (i) =>
                Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      child: const SizedBox(),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 1200.ms, color: Colors.white24)
                    .fade(begin: 0.5, end: 1.0),
          ),
        ),
      ],
    );
  }

  Widget _buildError(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          const Text(
            'Failed to load dashboard data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(dashboardAnalyticsProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
