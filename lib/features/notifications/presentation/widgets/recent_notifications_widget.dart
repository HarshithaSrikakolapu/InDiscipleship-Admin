import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/notification_model.dart';
import '../../application/notification_providers.dart';

class RecentNotificationsWidget extends ConsumerWidget {
  const RecentNotificationsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentNotificationsStreamProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Recent Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/notifications'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(height: 32),

            // Statistics Summary
            recentAsync.maybeWhen(
              data: (notifications) {
                final sentToday = notifications
                    .where(
                      (n) =>
                          n.status == NotificationStatus.sent &&
                          n.sentAt != null &&
                          _isToday(n.sentAt!),
                    )
                    .length;
                final scheduled = notifications
                    .where((n) => n.status == NotificationStatus.scheduled)
                    .length;
                final failed = notifications
                    .where((n) => n.status == NotificationStatus.failed)
                    .length;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      'Sent Today',
                      sentToday.toString(),
                      color: Colors.green,
                    ),
                    _buildStat(
                      'Scheduled',
                      scheduled.toString(),
                      color: Colors.blue,
                    ),
                    _buildStat('Failed', failed.toString(), color: Colors.red),
                  ],
                );
              },
              orElse: () => const SizedBox(),
            ),
            const SizedBox(height: 24),

            // List of recent 5
            recentAsync.when(
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'No recent notifications.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        n.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        n.deliveryType == 'scheduled'
                            ? 'Scheduled: ${n.scheduledAt != null ? DateFormat('dd MMM, HH:mm').format(n.scheduledAt!) : ""}'
                            : (n.sentAt != null
                                  ? DateFormat(
                                      'dd MMM, HH:mm',
                                    ).format(n.sentAt!)
                                  : 'Draft'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: _buildStatusChip(n.status),
                      onTap: () => context.push('/notifications/${n.id}'),
                    );
                  },
                );
              },
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => SizedBox(
                height: 100,
                child: Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Widget _buildStat(
    String label,
    String value, {
    Color color = Colors.black87,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusChip(NotificationStatus status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case NotificationStatus.draft:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        break;
      case NotificationStatus.scheduled:
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case NotificationStatus.sending:
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case NotificationStatus.sent:
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case NotificationStatus.failed:
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
