import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notification_repository_impl.dart';
import '../domain/notification_model.dart';
import 'notification_controller.dart';

final notificationsStreamProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotificationsStream();
});

final recentNotificationsStreamProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getRecentNotificationsStream(limit: 5);
});

final notificationDetailsProvider = StreamProvider.autoDispose.family<NotificationModel?, String>((ref, id) {
  final repo = ref.watch(notificationRepositoryProvider);
  return (repo as NotificationRepositoryImpl)
      .getNotificationByIdStream(id); // We will add this method
});

final notificationControllerProvider = AsyncNotifierProvider.autoDispose<NotificationController, void>(() {
  return NotificationController();
});
