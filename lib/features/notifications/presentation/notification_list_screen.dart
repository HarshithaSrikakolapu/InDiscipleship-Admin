import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/notification_model.dart';
import '../application/notification_providers.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {
  String _searchQuery = '';
  NotificationStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    ref.listen(notificationControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: ${next.error}')));
      }
    });

    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Broadcast Notifications',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/notifications/create'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Notification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildFilters(),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: notificationsAsync.when(
                  data: (notifications) {
                    final filtered = notifications.where((n) {
                      final matchesSearch =
                          n.title.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          n.message.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                      final matchesStatus =
                          _statusFilter == null || n.status == _statusFilter;
                      return matchesSearch && matchesStatus;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('No notifications found.'),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return _buildNotificationRow(filtered[index]);
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by title or message...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<NotificationStatus?>(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            initialValue: _statusFilter,
            hint: const Text('All Statuses'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Statuses')),
              ...NotificationStatus.values.map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s.name.toUpperCase()),
                ),
              ),
            ],
            onChanged: (val) => setState(() => _statusFilter = val),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationRow(NotificationModel n) {
    return InkWell(
      onTap: () => context.push('/notifications/${n.id}'),
      hoverColor: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusChip(n.status),
                  const SizedBox(height: 4),
                  Text(
                    n.deliveryType == 'scheduled'
                        ? (n.scheduledAt != null
                              ? 'Scheduled: ${DateFormat('dd MMM yyyy, HH:mm').format(n.scheduledAt!)}'
                              : 'Scheduled')
                        : 'Immediate',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                n.targetType.name.replaceAll('_', ' '),
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Duplicate',
                  onPressed: () {
                    ref
                        .read(notificationControllerProvider.notifier)
                        .duplicateNotification(
                          n.id,
                          'admin',
                        ); // Replace with actual user ID
                  },
                ),
                if (n.status == NotificationStatus.scheduled)
                  IconButton(
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 20,
                      color: Colors.orange,
                    ),
                    tooltip: 'Cancel Schedule',
                    onPressed: () {
                      ref
                          .read(notificationControllerProvider.notifier)
                          .cancelScheduled(n.id);
                    },
                  ),
                if (n.status == NotificationStatus.draft ||
                    n.status == NotificationStatus.scheduled)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Edit',
                    onPressed: () =>
                        context.push('/notifications/${n.id}/edit', extra: n),
                  ),
                if (n.status == NotificationStatus.draft ||
                    n.status == NotificationStatus.failed)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Notification?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref
                            .read(notificationControllerProvider.notifier)
                            .deleteNotification(n.id);
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
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
