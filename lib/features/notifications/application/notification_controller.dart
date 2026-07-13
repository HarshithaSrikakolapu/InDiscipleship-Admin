import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/notification_repository.dart';
import '../data/notification_repository_impl.dart';
import '../domain/notification_model.dart';

class NotificationController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  NotificationRepository get _repository => ref.read(notificationRepositoryProvider);

  Future<void> saveDraft(NotificationModel draft) async {
    state = const AsyncLoading();
    try {
      final notification = draft.copyWith(
        id: draft.id.isEmpty ? const Uuid().v4() : draft.id,
        status: NotificationStatus.draft,
        updatedAt: DateTime.now(),
      );

      if (draft.id.isEmpty) {
        await _repository.createNotification(notification);
      } else {
        await _repository.updateNotification(notification);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> scheduleNotification(NotificationModel notification) async {
    state = const AsyncLoading();
    try {
      final scheduled = notification.copyWith(
        status: NotificationStatus.scheduled,
        updatedAt: DateTime.now(),
      );
      await _repository.updateNotification(scheduled);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> sendNow(NotificationModel notification) async {
    state = const AsyncLoading();
    try {
      final sending = notification.copyWith(
        status: NotificationStatus.sent,
        sentAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repository.updateNotification(sending);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> cancelScheduled(String id) async {
    state = const AsyncLoading();
    try {
      final notification = await _repository.getNotificationById(id);
      if (notification != null && notification.status == NotificationStatus.scheduled) {
        final canceled = notification.copyWith(
          status: NotificationStatus.draft,
          updatedAt: DateTime.now(),
        );
        await _repository.updateNotification(canceled);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> duplicateNotification(String originalId, String createdBy) async {
    state = const AsyncLoading();
    try {
      final original = await _repository.getNotificationById(originalId);
      if (original != null) {
        final duplicated = original.copyWith(
          id: const Uuid().v4(),
          status: NotificationStatus.draft,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: createdBy,
          sentAt: null,
          totalRecipients: 0,
          delivered: 0,
          failed: 0,
          opened: 0,
          clickRate: 0.0,
          deliveryDurationMs: null,
        );
        await _repository.createNotification(duplicated);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteNotification(String id) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteNotification(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
