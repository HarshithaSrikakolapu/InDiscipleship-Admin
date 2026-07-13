import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_repository_impl.dart';
import '../data/models/dashboard_analytics_model.dart';
import '../../users/data/user_repository.dart';
import '../../users/domain/app_user.dart';
import '../../lessons/application/lesson_providers.dart';
import '../../lessons/data/models/lesson_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(FirebaseFirestore.instance);
});

final additionalMetricsProvider = StreamProvider<AdditionalMetrics>((ref) {
  return ref.watch(dashboardRepositoryProvider).watchAdditionalMetrics();
});

final dashboardAnalyticsProvider = Provider<AsyncValue<DashboardAnalyticsModel>>((ref) {
  final usersAsync = ref.watch(usersStreamProvider);
  final lessonsAsync = ref.watch(lessonsStreamProvider);
  final additionalAsync = ref.watch(additionalMetricsProvider);

  if (usersAsync is AsyncLoading || lessonsAsync is AsyncLoading || additionalAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (usersAsync.hasError) return AsyncValue.error(usersAsync.error!, usersAsync.stackTrace!);
  if (lessonsAsync.hasError) return AsyncValue.error(lessonsAsync.error!, lessonsAsync.stackTrace!);
  if (additionalAsync.hasError) return AsyncValue.error(additionalAsync.error!, additionalAsync.stackTrace!);

  final users = usersAsync.value ?? [];
  final lessons = lessonsAsync.value ?? [];
  final additional = additionalAsync.value ?? AdditionalMetrics();

  return AsyncValue.data(_aggregate(users, lessons, additional));
});

DashboardAnalyticsModel _aggregate(List<AppUser> users, List<LessonModel> lessons, AdditionalMetrics additional) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  
  int activeUsers = 0;
  final monthlyReg = <String, int>{};
  for (int i = 5; i >= 0; i--) {
    int m = now.month - i;
    if (m <= 0) m += 12;
    monthlyReg[_getMonthName(m)] = 0;
  }
  final deviceDist = <String, int>{};
  final ageDist = <String, int>{};
  final langDist = <String, int>{};
  final geographyDist = <String, int>{};

  for (final user in users) {
    final lastActive = user.lastAppOpenAt ?? user.lastLoginAt;
    if (user.isActive && lastActive != null) {
      if (lastActive.year == startOfToday.year &&
          lastActive.month == startOfToday.month &&
          lastActive.day == startOfToday.day) {
        activeUsers++;
      }
    }
    
    if (user.createdAt != null) {
       final monthKey = _getMonthName(user.createdAt!.month);
       if (monthlyReg.containsKey(monthKey)) {
         monthlyReg[monthKey] = monthlyReg[monthKey]! + 1;
       }
    }

    if (user.platform != null && user.platform!.isNotEmpty) {
       deviceDist[user.platform!] = (deviceDist[user.platform!] ?? 0) + 1;
    }

    final age = user.ageGroup ?? 'Unknown';
    ageDist[age] = (ageDist[age] ?? 0) + 1;

    final lang = user.selectedLanguage ?? 'Unknown';
    langDist[lang] = (langDist[lang] ?? 0) + 1;

    final country = user.country ?? 'Unknown';
    if (country.isNotEmpty) {
      geographyDist[country] = (geographyDist[country] ?? 0) + 1;
    }
  }

  final sortedUsers = List<AppUser>.from(users)
    ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  final recentUsers = sortedUsers.take(10).map((u) => {
    'avatar': '',
    'name': u.displayName,
    'email': u.email,
    'joinedDate': u.createdAt,
  }).toList();

  int published = 0;
  for (final l in lessons) {
    if (l.isPublished) published++;
  }

  final sortedLessons = List<LessonModel>.from(lessons)
    ..sort((a, b) => (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)));
  final recentLessons = sortedLessons.take(10).map((l) => {
    'lesson': l.lessonTitle,
    'week': l.week,
    'day': l.day,
    'updatedBy': l.updatedBy ?? 'Admin',
    'updatedTime': l.updatedAt,
  }).toList();

  final dailyActiveUsers = <String, int>{};
  for (int i = 6; i >= 1; i--) {
    final date = now.subtract(Duration(days: i));
    final dateStr = '${date.month}/${date.day}';
    dailyActiveUsers[dateStr] = 0; // No historical data available yet
  }
  dailyActiveUsers['${now.month}/${now.day}'] = activeUsers;

  final totalMentors = users.where((user) => user.isMentor == true).length;

  return DashboardAnalyticsModel(
    totalUsers: users.length,
    activeUsersToday: activeUsers,
    totalLessons: lessons.length,
    publishedLessons: published,
    completedLessonsToday: additional.completedLessonsToday,
    averageCompletion: additional.averageCompletion,
    averageStreak: additional.averageStreak,
    activeMentors: additional.activeMentors,
    totalMentors: totalMentors,
    hasMentorData: additional.hasMentorData,
    hasProgressData: additional.hasProgressData,
    hasActivityLogs: additional.hasActivityLogs,
    monthlyRegistrations: monthlyReg,
    dailyActiveUsers: dailyActiveUsers,
    lessonCompletionByWeek: additional.lessonCompletionByWeek,
    topCompletedLessons: additional.topCompletedLessons,
    deviceDistribution: deviceDist,
    ageGroupDistribution: ageDist,
    languageDistribution: langDist,
    geographyDistribution: geographyDist,
    recentUsers: recentUsers,
    recentlyUpdatedLessons: recentLessons,
    recentActivityTimeline: additional.recentActivityTimeline,
  );
}

String _getMonthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return month >= 1 && month <= 12 ? months[month - 1] : '';
}
