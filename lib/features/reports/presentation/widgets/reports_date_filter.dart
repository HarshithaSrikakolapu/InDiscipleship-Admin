import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/reports_controller.dart';
import '../../../../core/theme/app_colors.dart';

class ReportsDateFilter extends ConsumerWidget {
  const ReportsDateFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a full implementation, we would show the currently selected range.
    // For now, we just provide a dropdown that updates the controller.

    return PopupMenuButton<String>(
      onSelected: (value) => _handleSelection(value, ref, context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: AppColors.textSecondary,
            ),
            SizedBox(width: 8),
            Text('Date Range', style: TextStyle(color: AppColors.textPrimary)),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'today', child: Text('Today')),
        const PopupMenuItem(value: '7days', child: Text('Last 7 Days')),
        const PopupMenuItem(value: '30days', child: Text('Last 30 Days')),
        const PopupMenuItem(value: '90days', child: Text('Last 90 Days')),
        const PopupMenuItem(value: 'this_year', child: Text('This Year')),
        const PopupMenuItem(value: 'all_time', child: Text('All Time')),
        const PopupMenuItem(value: 'custom', child: Text('Custom Range...')),
      ],
    );
  }

  Future<void> _handleSelection(
    String value,
    WidgetRef ref,
    BuildContext context,
  ) async {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end = now;

    switch (value) {
      case 'today':
        start = DateTime(now.year, now.month, now.day);
        break;
      case '7days':
        start = now.subtract(const Duration(days: 7));
        break;
      case '30days':
        start = now.subtract(const Duration(days: 30));
        break;
      case '90days':
        start = now.subtract(const Duration(days: 90));
        break;
      case 'this_year':
        start = DateTime(now.year, 1, 1);
        break;
      case 'all_time':
        start = null;
        end = null;
        break;
      case 'custom':
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: now,
        );
        if (range != null) {
          start = range.start;
          end = range.end
              .add(const Duration(days: 1))
              .subtract(const Duration(milliseconds: 1));
        } else {
          return; // cancelled
        }
        break;
    }

    ref.read(reportsControllerProvider.notifier).updateDateRange(start, end);
  }
}
