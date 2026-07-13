class UserGrowthSummary {
  final int totalUsers;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int newUsersThisMonth;
  final int returningUsers;
  final int inactiveUsers;
  final int publishedLessons;

  UserGrowthSummary({
    required this.totalUsers,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
    required this.returningUsers,
    required this.inactiveUsers,
    required this.publishedLessons,
  });
}

class LocationReport {
  final String country;
  final int userCount;
  final double percentage;

  LocationReport({
    required this.country,
    required this.userCount,
    required this.percentage,
  });
}

class LanguageReport {
  final String language;
  final int userCount;
  final double percentage;

  LanguageReport({
    required this.language,
    required this.userCount,
    required this.percentage,
  });
}

class RegistrationTrend {
  final DateTime date;
  final int newUsers;

  RegistrationTrend({
    required this.date,
    required this.newUsers,
  });
}

class LessonEngagementSummary {
  final String lessonId;
  final String lessonTitle;
  final int startedCount;
  final int completedCount;
  final double completionRate;

  LessonEngagementSummary({
    required this.lessonId,
    required this.lessonTitle,
    required this.startedCount,
    required this.completedCount,
    required this.completionRate,
  });
}

class ActiveWeekSummary {
  final int weekNumber;
  final int activeUsersCount;

  ActiveWeekSummary({
    required this.weekNumber,
    required this.activeUsersCount,
  });
}
