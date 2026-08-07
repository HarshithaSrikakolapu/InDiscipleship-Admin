import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/notification_model.dart';
import '../application/notification_providers.dart';

class NotificationDetailsScreen extends ConsumerWidget {
  final String id;

  const NotificationDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotification = ref.watch(notificationDetailsProvider(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notification Details'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncNotification.when(
        data: (notification) {
          if (notification == null) {
            return const Center(child: Text('Notification not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(context, ref, notification),
                      const SizedBox(height: 24),
                      _buildAnalyticsCard(notification),
                      const SizedBox(height: 24),
                      _buildPayloadCard(notification),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(flex: 1, child: _buildInfoCard(notification)),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    WidgetRef ref,
    NotificationModel n,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    n.message,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusChip(n.status),
                  const SizedBox(height: 16),
                  if (n.status == NotificationStatus.draft ||
                      n.status == NotificationStatus.scheduled)
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/notifications/${n.id}/edit', extra: n),
                      icon: const Icon(Icons.edit),
                      label: Text(
                        n.status == NotificationStatus.draft
                            ? 'Edit Draft'
                            : 'Edit Scheduled',
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (n.status == NotificationStatus.scheduled)
                    OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(notificationControllerProvider.notifier)
                            .cancelScheduled(n.id);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel Schedule'),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(notificationControllerProvider.notifier)
                          .duplicateNotification(n.id, 'admin');
                      context.pop(); // Go back to list after duplicating
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Duplicate'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(NotificationModel n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Analytics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Total Recipients', n.totalRecipients.toString()),
                _buildStat(
                  'Delivered',
                  n.delivered.toString(),
                  color: Colors.green,
                ),
                _buildStat('Failed', n.failed.toString(), color: Colors.red),
                _buildStat('Opened', n.opened.toString(), color: Colors.blue),
                _buildStat(
                  'Click Rate',
                  '${(n.clickRate * 100).toStringAsFixed(1)}%',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (n.deliveryDurationMs != null)
              Text(
                'Delivery Duration: ${n.deliveryDurationMs} ms',
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    String label,
    String value, {
    Color color = Colors.black87,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPayloadCard(NotificationModel n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payload Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            if (n.imageUrl != null) ...[
              const Text(
                'Image Attachment:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Image.network(n.imageUrl!, height: 150),
              const SizedBox(height: 16),
            ],
            if (n.deepLink != null) ...[
              const Text(
                'Deep Link:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                n.deepLink!,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ] else
              const Text(
                'No extra payload attributes.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(NotificationModel n) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            _buildInfoRow('Created By', n.createdBy),
            _buildInfoRow(
              'Created At',
              DateFormat('dd MMM yyyy, HH:mm').format(n.createdAt),
            ),
            _buildInfoRow(
              'Target Type',
              n.targetType.name.replaceAll('_', ' ').toUpperCase(),
            ),
            _buildInfoRow('Delivery Method', n.deliveryType.toUpperCase()),
            _buildInfoRow('Priority', n.priority.name.toUpperCase()),
            if (n.scheduledAt != null)
              _buildInfoRow(
                'Scheduled For',
                DateFormat('dd MMM yyyy, HH:mm').format(n.scheduledAt!),
              ),
            if (n.sentAt != null)
              _buildInfoRow(
                'Sent At',
                DateFormat('dd MMM yyyy, HH:mm').format(n.sentAt!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
