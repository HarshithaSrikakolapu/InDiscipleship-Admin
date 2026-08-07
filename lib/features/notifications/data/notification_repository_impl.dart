import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_model.dart';
import 'notification_repository.dart';
import '../../users/data/user_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return NotificationRepositoryImpl(firestore);
});

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('notifications');

  @override
  Stream<List<NotificationModel>> getNotificationsStream() {
    return _notificationsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Stream<List<NotificationModel>> getRecentNotificationsStream({
    int limit = 5,
  }) {
    return _notificationsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  @override
  Future<NotificationModel?> getNotificationById(String id) async {
    final doc = await _notificationsRef.doc(id).get();
    if (doc.exists && doc.data() != null) {
      return NotificationModel.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  Stream<NotificationModel?> getNotificationByIdStream(String id) {
    return _notificationsRef.doc(id).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return NotificationModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }

  @override
  Future<void> createNotification(NotificationModel notification) async {
    await _notificationsRef.doc(notification.id).set(notification.toMap());
  }

  @override
  Future<void> updateNotification(NotificationModel notification) async {
    await _notificationsRef
        .doc(notification.id)
        .set(notification.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _notificationsRef.doc(id).delete();
  }
}
