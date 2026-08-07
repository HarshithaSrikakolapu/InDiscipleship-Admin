import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/reports_controller.dart';
import 'widgets/reports_date_filter.dart';
import '../../../core/utils/export_helper.dart';
import 'package:intl/intl.dart';

class ReportsExportsScreen extends ConsumerWidget {
  const ReportsExportsScreen({super.key});

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
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Exports',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          _buildExportCard(
                            context: context,
                            title: 'Lesson Engagement',
                            description:
                                'Export started vs completed stats for all lessons.',
                            icon: Icons.menu_book,
                            onExportCsv: () {
                              if (state.lessonEngagement == null ||
                                  state.lessonEngagement!.isEmpty) {
                                return;
                              }
                              final rows = state.lessonEngagement!
                                  .map(
                                    (e) => [
                                      e.lessonTitle,
                                      e.startedCount,
                                      e.completedCount,
                                      '${e.completionRate.toStringAsFixed(1)}%',
                                    ],
                                  )
                                  .toList();
                              ExportHelper.exportToCsv(
                                'Lesson Engagement Report',
                                [
                                  'Lesson Title',
                                  'Started',
                                  'Completed',
                                  'Completion Rate',
                                ],
                                rows,
                                startDate: state.startDate,
                                endDate: state.endDate,
                              );
                            },
                            onExportExcel: () {
                              if (state.lessonEngagement == null ||
                                  state.lessonEngagement!.isEmpty) {
                                return;
                              }
                              final rows = state.lessonEngagement!
                                  .map(
                                    (e) => [
                                      e.lessonTitle,
                                      e.startedCount,
                                      e.completedCount,
                                      e.completionRate,
                                    ],
                                  )
                                  .toList();
                              ExportHelper.exportToExcel(
                                'Lesson Engagement Report',
                                [
                                  'Lesson Title',
                                  'Started',
                                  'Completed',
                                  'Completion Rate',
                                ],
                                rows,
                                startDate: state.startDate,
                                endDate: state.endDate,
                              );
                            },
                          ),
                          _buildExportCard(
                            context: context,
                            title: 'Geography (Locations)',
                            description:
                                'Export user counts and distribution by country.',
                            icon: Icons.public,
                            onExportCsv: () {
                              if (state.locationReports == null ||
                                  state.locationReports!.isEmpty) {
                                return;
                              }
                              final rows = state.locationReports!
                                  .map(
                                    (e) => [
                                      e.country,
                                      e.userCount,
                                      '${e.percentage.toStringAsFixed(1)}%',
                                    ],
                                  )
                                  .toList();
                              ExportHelper.exportToCsv(
                                'Geography Report',
                                ['Country', 'Users', 'Percentage'],
                                rows,
                                startDate: state.startDate,
                                endDate: state.endDate,
                              );
                            },
                            onExportExcel: () {
                              if (state.locationReports == null ||
                                  state.locationReports!.isEmpty) {
                                return;
                              }
                              final rows = state.locationReports!
                                  .map(
                                    (e) => [
                                      e.country,
                                      e.userCount,
                                      e.percentage,
                                    ],
                                  )
                                  .toList();
                              ExportHelper.exportToExcel(
                                'Geography Report',
                                ['Country', 'Users', 'Percentage'],
                                rows,
                                startDate: state.startDate,
                                endDate: state.endDate,
                              );
                            },
                          ),
                          _buildExportCard(
                            context: context,
                            title: 'Languages',
                            description:
                                'Export user counts and distribution by language.',
                            icon: Icons.translate,
                            onExportCsv: () {
                              if (state.languageReports == null ||
                                  state.languageReports!.isEmpty) {
                                return;
                              }
                              final rows = state.languageReports!
                                  .map(
                                    (e) => [
                                      e.language,
                                      e.userCount,
                                      '${e.percentage.toStringAsFixed(1)}%',
                                    ],
                                  )
                                  .toList();
                              ExportHelper.exportToCsv(
                                'Languages Report',
                                ['Language', 'Users', 'Percentage'],
                                rows,
                                startDate: state.startDate,
                                endDate: state.endDate,
                              );
                            },
                            onExportExcel: () {
                              if (state.languageReports == null ||
                                  state.languageReports!.isEmpty) {
                                return;
                              }
                              final rows = state.languageReports!
                                  .map(
                                    (e) => [
                                      e.language,
                                      e.userCount,
                                      e.percentage,
                                    ],
                                  )
                                  .toList();
                              ExportHelper.exportToExcel(
                                'Languages Report',
                                ['Language', 'Users', 'Percentage'],
                                rows,
                                startDate: state.startDate,
                                endDate: state.endDate,
                              );
                            },
                          ),
                          _buildExportCard(
                            context: context,
                            title: 'Registration Trends',
                            description: 'Export daily new user registrations.',
                            icon: Icons.timeline,
                            onExportCsv: () {
                              if (state.registrationTrends == null ||
                                  state.registrationTrends!.isEmpty) {
                                return;
                              }
                              final rows = state.registrationTrends!
                                  .map(
                                    (e) => [
                                      DateFormat('yyyy-MM-dd').format(e.date),
                                      e.newUsers,
                                    ],
                                  )
                                  .toList();
                              ExportHelper.exportToCsv(
                                'Registration Trends Report',
                                ['Date', 'New Users'],
                                rows,
                                startDate: state.startDate,
                                endDate: state.endDate,
                              );
                            },
                            onExportExcel: () {
                              if (state.registrationTrends == null ||
                                  state.registrationTrends!.isEmpty) {
                                return;
                              }
                              final rows = state.registrationTrends!
                                  .map(
                                    (e) => [
                                      DateFormat('yyyy-MM-dd').format(e.date),
                                      e.newUsers,
                                    ],
                                  )
                                  .toList();
                              ExportHelper.exportToExcel(
                                'Registration Trends Report',
                                ['Date', 'New Users'],
                                rows,
                                startDate: state.startDate,
                                endDate: state.endDate,
                              );
                            },
                          ),
                        ],
                      ),
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
            'Exports Data',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          ReportsDateFilter(),
        ],
      ),
    );
  }

  Widget _buildExportCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onExportCsv,
    required VoidCallback onExportExcel,
  }) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.blue.shade600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(color: Color(0xFF475569), height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onExportCsv,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('CSV'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onExportExcel,
                  icon: const Icon(Icons.table_chart, size: 18),
                  label: const Text('Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
