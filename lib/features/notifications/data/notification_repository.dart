import '../domain/notification_model.dart';

abstract class NotificationRepository {
  Stream<List<NotificationModel>> getNotificationsStream();
  Stream<List<NotificationModel>> getRecentNotificationsStream({int limit = 5});
  Future<NotificationModel?> getNotificationById(String id);
  Future<void> createNotification(NotificationModel notification);
  Future<void> updateNotification(NotificationModel notification);
  Future<void> deleteNotification(String id);
}
