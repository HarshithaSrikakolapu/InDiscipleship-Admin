import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/reports_model.dart';
import 'reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final FirebaseFirestore _firestore;

  ReportsRepositoryImpl(this._firestore);

  Query<Map<String, dynamic>> _getFilteredUsers({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('users');
    if (startDate != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }
    return query;
  }

  @override
  Future<UserGrowthSummary> getUserGrowthSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // In a production app, aggregations should ideally be done via Cloud Functions to save reads.
    // For now, doing it client-side.
    final usersSnapshot = await _getFilteredUsers(
      startDate: startDate,
      endDate: endDate,
    ).get();

    int totalUsers = usersSnapshot.docs.length;
    int newUsersToday = 0;
    int newUsersThisWeek = 0;
    int newUsersThisMonth = 0;
    int returningUsers = 0;
    int inactiveUsers = 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(Duration(days: today.weekday - 1));
    final thisMonth = DateTime(now.year, now.month, 1);
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      final lastAppOpenAt = (data['lastAppOpenAt'] as Timestamp?)?.toDate();

      if (createdAt != null) {
        if (createdAt.isAfter(today) || createdAt.isAtSameMomentAs(today)) {
          newUsersToday++;
        }
        if (createdAt.isAfter(thisWeek) ||
            createdAt.isAtSameMomentAs(thisWeek)) {
          newUsersThisWeek++;
        }
        if (createdAt.isAfter(thisMonth) ||
            createdAt.isAtSameMomentAs(thisMonth)) {
          newUsersThisMonth++;
        }
      }

      if (lastAppOpenAt != null) {
        if (lastAppOpenAt.isAfter(thirtyDaysAgo)) {
          returningUsers++;
        } else {
          inactiveUsers++;
        }
      } else {
        inactiveUsers++; // Assuming inactive if never opened
      }
    }

    final lessonsSnapshot = await _firestore
        .collection('lessons')
        .count()
        .get();
    int publishedLessons = lessonsSnapshot.count ?? 0;

    return UserGrowthSummary(
      totalUsers: totalUsers,
      newUsersToday: newUsersToday,
      newUsersThisWeek: newUsersThisWeek,
      newUsersThisMonth: newUsersThisMonth,
      returningUsers: returningUsers,
      inactiveUsers: inactiveUsers,
      publishedLessons: publishedLessons,
    );
  }

  @override
  Future<List<LocationReport>> getLocationReports({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final usersSnapshot = await _getFilteredUsers(
      startDate: startDate,
      endDate: endDate,
    ).get();
    Map<String, int> countryCounts = {};
    int totalUsers = usersSnapshot.docs.length;

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final country = data['country'] as String? ?? 'Unknown';
      countryCounts[country] = (countryCounts[country] ?? 0) + 1;
    }

    return countryCounts.entries.map((e) {
      return LocationReport(
        country: e.key,
        userCount: e.value,
        percentage: totalUsers > 0 ? (e.value / totalUsers) * 100 : 0,
      );
    }).toList()..sort((a, b) => b.userCount.compareTo(a.userCount));
  }

  @override
  Future<List<LanguageReport>> getLanguageReports({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final usersSnapshot = await _getFilteredUsers(
      startDate: startDate,
      endDate: endDate,
    ).get();
    Map<String, int> languageCounts = {};
    int totalUsers = usersSnapshot.docs.length;

    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final language =
          data['selectedLanguage'] as String? ??
          data['language'] as String? ??
          'Unknown';
      languageCounts[language] = (languageCounts[language] ?? 0) + 1;
    }

    return languageCounts.entries.map((e) {
      return LanguageReport(
        language: e.key,
        userCount: e.value,
        percentage: totalUsers > 0 ? (e.value / totalUsers) * 100 : 0,
      );
    }).toList()..sort((a, b) => b.userCount.compareTo(a.userCount));
  }

  @override
  Future<List<RegistrationTrend>> getRegistrationTrends({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final usersSnapshot = await _firestore
        .collection('users')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    Map<DateTime, int> dailyCounts = {};
    for (var doc in usersSnapshot.docs) {
      final createdAt = (doc.data()['createdAt'] as Timestamp?)?.toDate();
      if (createdAt != null) {
        final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
        dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
      }
    }

    return dailyCounts.entries
        .map((e) => RegistrationTrend(date: e.key, newUsers: e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<List<LessonEngagementSummary>> getLessonEngagement({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final progressSnapshot = await _firestore.collection('user_progress').get();

    // In a real app, this should join with the lessons collection to get titles.
    // Here we'll map them from the lessons collection first.
    final lessonsSnapshot = await _firestore.collection('lessons').get();
    Map<String, String> lessonTitles = {
      for (var doc in lessonsSnapshot.docs)
        doc.id: doc.data()['lessonTitle'] as String? ?? 'Unknown Lesson',
    };

    Map<String, int> startedCounts = {};
    Map<String, int> completedCounts = {};

    for (var doc in progressSnapshot.docs) {
      final data = doc.data();
      final lessonId = data['lessonId'] as String?;
      final isCompleted = data['isCompleted'] as bool? ?? false;

      if (lessonId != null) {
        startedCounts[lessonId] = (startedCounts[lessonId] ?? 0) + 1;
        if (isCompleted) {
          completedCounts[lessonId] = (completedCounts[lessonId] ?? 0) + 1;
        }
      }
    }

    return lessonTitles.entries.map((e) {
      final started = startedCounts[e.key] ?? 0;
      final completed = completedCounts[e.key] ?? 0;
      return LessonEngagementSummary(
        lessonId: e.key,
        lessonTitle: e.value,
        startedCount: started,
        completedCount: completed,
        completionRate: started > 0 ? (completed / started) * 100 : 0,
      );
    }).toList()..sort((a, b) => b.startedCount.compareTo(a.startedCount));
  }

  @override
  Future<List<ActiveWeekSummary>> getActiveWeekSummary() async {
    final usersSnapshot = await _firestore.collection('users').get();
    Map<int, int> weekCounts = {};
    for (var doc in usersSnapshot.docs) {
      final data = doc.data();
      final currentWeek = data['currentWeek'] as int?;
      if (currentWeek != null) {
        weekCounts[currentWeek] = (weekCounts[currentWeek] ?? 0) + 1;
      }
    }

    return weekCounts.entries
        .map(
          (e) =>
              ActiveWeekSummary(weekNumber: e.key, activeUsersCount: e.value),
        )
        .toList()
      ..sort((a, b) => a.weekNumber.compareTo(b.weekNumber));
  }
}
