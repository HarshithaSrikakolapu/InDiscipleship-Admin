import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_repository.dart';

class AdditionalMetrics {
  final bool hasMentorData;
  final bool hasProgressData;
  final bool hasActivityLogs;

  final int activeMentors;
  final int completedLessonsToday;
  final double averageCompletion;
  final double averageStreak;
  final Map<String, double> lessonCompletionByWeek;
  final Map<String, int> topCompletedLessons;
  final List<Map<String, dynamic>> recentActivityTimeline;

  AdditionalMetrics({
    this.hasMentorData = false,
    this.hasProgressData = false,
    this.hasActivityLogs = false,
    this.activeMentors = 0,
    this.completedLessonsToday = 0,
    this.averageCompletion = 0.0,
    this.averageStreak = 0.0,
    this.lessonCompletionByWeek = const {},
    this.topCompletedLessons = const {},
    this.recentActivityTimeline = const [],
  });
}

class DashboardRepositoryImpl implements DashboardRepository {
  final FirebaseFirestore _firestore;

  DashboardRepositoryImpl(this._firestore);

  @override
  Stream<AdditionalMetrics> watchAdditionalMetrics() {
    final controller = StreamController<AdditionalMetrics>();

    AdditionalMetrics currentModel = AdditionalMetrics();

    StreamSubscription? mentorsSub;
    StreamSubscription? progressSub;
    StreamSubscription? activitySub;

    void updateAndEmit(AdditionalMetrics model) {
      currentModel = model;
      if (controller.hasListener) controller.add(currentModel);
    }

    controller.onListen = () async {
      // 1. Initial Checks
      try {
        final mentorCheck = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'mentor')
            .limit(1)
            .get();
        currentModel = AdditionalMetrics(
          hasMentorData: mentorCheck.docs.isNotEmpty,
          hasProgressData: currentModel.hasProgressData,
          hasActivityLogs: currentModel.hasActivityLogs,
        );
      } catch (e) {
        currentModel = AdditionalMetrics(
          hasMentorData: false,
          hasProgressData: currentModel.hasProgressData,
          hasActivityLogs: currentModel.hasActivityLogs,
        );
      }

      try {
        final progressCheck = await _firestore
            .collection('user_progress')
            .limit(1)
            .get();
        currentModel = AdditionalMetrics(
          hasMentorData: currentModel.hasMentorData,
          hasProgressData: progressCheck.docs.isNotEmpty,
          hasActivityLogs: currentModel.hasActivityLogs,
        );
      } catch (e) {
        currentModel = AdditionalMetrics(
          hasMentorData: currentModel.hasMentorData,
          hasProgressData: false,
          hasActivityLogs: currentModel.hasActivityLogs,
        );
      }

      try {
        final activityCheck = await _firestore
            .collection('activity_logs')
            .limit(1)
            .get();
        currentModel = AdditionalMetrics(
          hasMentorData: currentModel.hasMentorData,
          hasProgressData: currentModel.hasProgressData,
          hasActivityLogs: activityCheck.docs.isNotEmpty,
        );
      } catch (e) {
        currentModel = AdditionalMetrics(
          hasMentorData: currentModel.hasMentorData,
          hasProgressData: currentModel.hasProgressData,
          hasActivityLogs: false,
        );
      }

      updateAndEmit(currentModel);

      // 2. Stream Mentors
      if (currentModel.hasMentorData) {
        mentorsSub = _firestore
            .collection('users')
            .where('role', isEqualTo: 'mentor')
            .snapshots()
            .listen((snapshot) {
              int active = 0;
              for (final doc in snapshot.docs) {
                if (doc.data()['isActive'] == true ||
                    doc.data()['mentorStatus'] == 'active') {
                  active++;
                }
              }
              updateAndEmit(
                AdditionalMetrics(
                  hasMentorData: currentModel.hasMentorData,
                  hasProgressData: currentModel.hasProgressData,
                  hasActivityLogs: currentModel.hasActivityLogs,
                  activeMentors: active,
                  completedLessonsToday: currentModel.completedLessonsToday,
                  averageCompletion: currentModel.averageCompletion,
                  averageStreak: currentModel.averageStreak,
                  lessonCompletionByWeek: currentModel.lessonCompletionByWeek,
                  topCompletedLessons: currentModel.topCompletedLessons,
                  recentActivityTimeline: currentModel.recentActivityTimeline,
                ),
              );
            });
      }

      // 3. Stream Progress
      if (currentModel.hasProgressData) {
        progressSub = _firestore.collection('user_progress').snapshots().listen(
          (snapshot) {
            final now = DateTime.now();
            final startOfToday = DateTime(now.year, now.month, now.day);

            int completedToday = 0;
            double totalComp = 0.0;
            double totalStreak = 0.0;
            int count = 0;
            final completionByWeek = <String, double>{};
            final completionCounts = <String, int>{};
            final topLessons = <String, int>{};

            for (final doc in snapshot.docs) {
              final data = doc.data();
              count++;

              final lastCompleted = data['lastCompletedAt'] as Timestamp?;
              if (lastCompleted != null &&
                  lastCompleted.toDate().isAfter(startOfToday)) {
                completedToday++;
              }

              totalComp +=
                  (data['completionPercentage'] as num?)?.toDouble() ?? 0.0;
              totalStreak += (data['dayStreak'] as num?)?.toDouble() ?? 0.0;

              final week = 'Week ${data['currentWeek'] ?? 1}';
              completionByWeek[week] =
                  (completionByWeek[week] ?? 0.0) +
                  ((data['completionPercentage'] as num?)?.toDouble() ?? 0.0);
              completionCounts[week] = (completionCounts[week] ?? 0) + 1;

              final completedList = data['completedLessons'] is List
                  ? (data['completedLessons'] as List<dynamic>)
                  : [];
              for (final l in completedList) {
                final lStr = l.toString();
                topLessons[lStr] = (topLessons[lStr] ?? 0) + 1;
              }
            }

            for (final key in completionByWeek.keys) {
              completionByWeek[key] =
                  completionByWeek[key]! / completionCounts[key]!;
            }

            final sortedTop = Map.fromEntries(
              topLessons.entries.toList()
                ..sort((e1, e2) => e2.value.compareTo(e1.value)),
            );

            updateAndEmit(
              AdditionalMetrics(
                hasMentorData: currentModel.hasMentorData,
                hasProgressData: currentModel.hasProgressData,
                hasActivityLogs: currentModel.hasActivityLogs,
                activeMentors: currentModel.activeMentors,
                completedLessonsToday: completedToday,
                averageCompletion: count > 0 ? totalComp / count : 0.0,
                averageStreak: count > 0 ? totalStreak / count : 0.0,
                lessonCompletionByWeek: completionByWeek,
                topCompletedLessons: Map.fromEntries(sortedTop.entries.take(5)),
                recentActivityTimeline: currentModel.recentActivityTimeline,
              ),
            );
          },
        );
      }

      // 4. Stream Activity
      if (currentModel.hasActivityLogs) {
        activitySub = _firestore
            .collection('activity_logs')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .snapshots()
            .listen((snapshot) {
              final logs = snapshot.docs.map((d) => d.data()).toList();
              updateAndEmit(
                AdditionalMetrics(
                  hasMentorData: currentModel.hasMentorData,
                  hasProgressData: currentModel.hasProgressData,
                  hasActivityLogs: currentModel.hasActivityLogs,
                  activeMentors: currentModel.activeMentors,
                  completedLessonsToday: currentModel.completedLessonsToday,
                  averageCompletion: currentModel.averageCompletion,
                  averageStreak: currentModel.averageStreak,
                  lessonCompletionByWeek: currentModel.lessonCompletionByWeek,
                  topCompletedLessons: currentModel.topCompletedLessons,
                  recentActivityTimeline: logs,
                ),
              );
            });
      }
    };

    controller.onCancel = () {
      mentorsSub?.cancel();
      progressSub?.cancel();
      activitySub?.cancel();
    };

    return controller.stream;
  }
}
