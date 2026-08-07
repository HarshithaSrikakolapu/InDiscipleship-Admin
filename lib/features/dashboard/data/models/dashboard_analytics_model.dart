class DashboardAnalyticsModel {
  // KPI Metrics
  final int totalUsers;
  final int activeUsersToday;
  final int totalLessons;
  final int publishedLessons;
  final int completedLessonsToday;
  final double averageCompletion; // Percentage 0-100
  final double averageStreak;
  final int activeMentors;
  final int totalMentors;

  // Graceful Degradation Flags
  final bool hasMentorData;
  final bool hasProgressData;
  final bool hasActivityLogs;

  // Pre-computed Chart Data
  final Map<String, int> monthlyRegistrations; // e.g., {'Jan': 10, 'Feb': 15}
  final Map<String, int> dailyActiveUsers; // e.g., {'2026-07-01': 5, ...}
  final Map<String, double>
  lessonCompletionByWeek; // e.g., {'Week 1': 80.5, ...}
  final Map<String, int> topCompletedLessons; // e.g., {'Lesson A': 100, ...}
  final Map<String, int>
  deviceDistribution; // e.g., {'Android': 50, 'iOS': 30, 'Web': 20}
  final Map<String, int>
  ageGroupDistribution; // e.g., {'Youth': 40, 'Adult': 60}
  final Map<String, int>
  languageDistribution; // e.g., {'English': 80, 'Spanish': 20}
  final Map<String, int>
  geographyDistribution; // e.g., {'India': 50, 'Australia': 30}

  // Recent Activity Lists
  final List<Map<String, dynamic>> recentUsers;
  final List<Map<String, dynamic>> recentlyUpdatedLessons;
  final List<Map<String, dynamic>> recentActivityTimeline;

  DashboardAnalyticsModel({
    this.totalUsers = 0,
    this.activeUsersToday = 0,
    this.totalLessons = 0,
    this.publishedLessons = 0,
    this.completedLessonsToday = 0,
    this.averageCompletion = 0.0,
    this.averageStreak = 0.0,
    this.activeMentors = 0,
    this.totalMentors = 0,
    this.hasMentorData = false,
    this.hasProgressData = false,
    this.hasActivityLogs = false,
    this.monthlyRegistrations = const {},
    this.dailyActiveUsers = const {},
    this.lessonCompletionByWeek = const {},
    this.topCompletedLessons = const {},
    this.deviceDistribution = const {},
    this.ageGroupDistribution = const {},
    this.languageDistribution = const {},
    this.geographyDistribution = const {},
    this.recentUsers = const [],
    this.recentlyUpdatedLessons = const [],
    this.recentActivityTimeline = const [],
  });

  DashboardAnalyticsModel copyWith({
    int? totalUsers,
    int? activeUsersToday,
    int? totalLessons,
    int? publishedLessons,
    int? completedLessonsToday,
    double? averageCompletion,
    double? averageStreak,
    int? activeMentors,
    int? totalMentors,
    bool? hasMentorData,
    bool? hasProgressData,
    bool? hasActivityLogs,
    Map<String, int>? monthlyRegistrations,
    Map<String, int>? dailyActiveUsers,
    Map<String, double>? lessonCompletionByWeek,
    Map<String, int>? topCompletedLessons,
    Map<String, int>? deviceDistribution,
    Map<String, int>? ageGroupDistribution,
    Map<String, int>? languageDistribution,
    Map<String, int>? geographyDistribution,
    List<Map<String, dynamic>>? recentUsers,
    List<Map<String, dynamic>>? recentlyUpdatedLessons,
    List<Map<String, dynamic>>? recentActivityTimeline,
  }) {
    return DashboardAnalyticsModel(
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsersToday: activeUsersToday ?? this.activeUsersToday,
      totalLessons: totalLessons ?? this.totalLessons,
      publishedLessons: publishedLessons ?? this.publishedLessons,
      completedLessonsToday:
          completedLessonsToday ?? this.completedLessonsToday,
      averageCompletion: averageCompletion ?? this.averageCompletion,
      averageStreak: averageStreak ?? this.averageStreak,
      activeMentors: activeMentors ?? this.activeMentors,
      totalMentors: totalMentors ?? this.totalMentors,
      hasMentorData: hasMentorData ?? this.hasMentorData,
      hasProgressData: hasProgressData ?? this.hasProgressData,
      hasActivityLogs: hasActivityLogs ?? this.hasActivityLogs,
      monthlyRegistrations: monthlyRegistrations ?? this.monthlyRegistrations,
      dailyActiveUsers: dailyActiveUsers ?? this.dailyActiveUsers,
      lessonCompletionByWeek:
          lessonCompletionByWeek ?? this.lessonCompletionByWeek,
      topCompletedLessons: topCompletedLessons ?? this.topCompletedLessons,
      deviceDistribution: deviceDistribution ?? this.deviceDistribution,
      ageGroupDistribution: ageGroupDistribution ?? this.ageGroupDistribution,
      languageDistribution: languageDistribution ?? this.languageDistribution,
      geographyDistribution:
          geographyDistribution ?? this.geographyDistribution,
      recentUsers: recentUsers ?? this.recentUsers,
      recentlyUpdatedLessons:
          recentlyUpdatedLessons ?? this.recentlyUpdatedLessons,
      recentActivityTimeline:
          recentActivityTimeline ?? this.recentActivityTimeline,
    );
  }
}
