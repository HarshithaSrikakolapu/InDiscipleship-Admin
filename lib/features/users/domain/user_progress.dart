import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgress {
  final String uid;
  final int currentWeek;
  final int currentDay;
  final int dayStreak;
  final double completionPercentage;
  final List<String> completedLessons;
  final DateTime? lastCompletedAt;

  UserProgress({
    required this.uid,
    this.currentWeek = 1,
    this.currentDay = 1,
    this.dayStreak = 0,
    this.completionPercentage = 0.0,
    this.completedLessons = const [],
    this.lastCompletedAt,
  });

  factory UserProgress.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProgress(
      uid: uid,
      currentWeek: data['currentWeek'] as int? ?? 1,
      currentDay: data['currentDay'] as int? ?? 1,
      dayStreak: (data['dayStreak'] as num?)?.toInt() ?? 0,
      completionPercentage: (data['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      completedLessons: (data['completedLessons'] is List)
          ? (data['completedLessons'] as List<dynamic>).map((e) => e.toString()).toList()
          : [],
      lastCompletedAt: (data['lastCompletedAt'] as Timestamp?)?.toDate(),
    );
  }

  int get completedLessonsCount => completedLessons.length;
}
