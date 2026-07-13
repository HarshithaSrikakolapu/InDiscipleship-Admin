import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/reports_model.dart';
import 'reports_providers.dart';

class ReportsState {
  final UserGrowthSummary? userGrowthSummary;
  final List<LocationReport>? locationReports;
  final List<LanguageReport>? languageReports;
  final List<RegistrationTrend>? registrationTrends;
  final List<LessonEngagementSummary>? lessonEngagement;
  final List<ActiveWeekSummary>? activeWeekSummary;
  final DateTime? startDate;
  final DateTime? endDate;

  ReportsState({
    this.userGrowthSummary,
    this.locationReports,
    this.languageReports,
    this.registrationTrends,
    this.lessonEngagement,
    this.activeWeekSummary,
    this.startDate,
    this.endDate,
  });

  ReportsState copyWith({
    UserGrowthSummary? userGrowthSummary,
    List<LocationReport>? locationReports,
    List<LanguageReport>? languageReports,
    List<RegistrationTrend>? registrationTrends,
    List<LessonEngagementSummary>? lessonEngagement,
    List<ActiveWeekSummary>? activeWeekSummary,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ReportsState(
      userGrowthSummary: userGrowthSummary ?? this.userGrowthSummary,
      locationReports: locationReports ?? this.locationReports,
      languageReports: languageReports ?? this.languageReports,
      registrationTrends: registrationTrends ?? this.registrationTrends,
      lessonEngagement: lessonEngagement ?? this.lessonEngagement,
      activeWeekSummary: activeWeekSummary ?? this.activeWeekSummary,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class ReportsController extends AsyncNotifier<ReportsState> {
  @override
  Future<ReportsState> build() async {
    // Default to 'Last 30 Days'
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    final endDate = now;

    return await _fetchReports(startDate: startDate, endDate: endDate);
  }

  Future<void> updateDateRange(DateTime? startDate, DateTime? endDate) async {
    state = const AsyncValue.loading();
    try {
      final newState = await _fetchReports(startDate: startDate, endDate: endDate);
      state = AsyncValue.data(newState);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> refresh() async {
    final currentState = state.value;
    await updateDateRange(currentState?.startDate, currentState?.endDate);
  }

  Future<ReportsState> _fetchReports({DateTime? startDate, DateTime? endDate}) async {
    final repo = ref.read(reportsRepositoryProvider);

    final results = await Future.wait([
      repo.getUserGrowthSummary(startDate: startDate, endDate: endDate),
      repo.getLocationReports(startDate: startDate, endDate: endDate),
      repo.getLanguageReports(startDate: startDate, endDate: endDate),
      repo.getLessonEngagement(startDate: startDate, endDate: endDate),
      repo.getActiveWeekSummary(),
    ]);

    // registration trend needs specific start/end to be meaningful, or defaults to 30 days
    final finalStartDate = startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final finalEndDate = endDate ?? DateTime.now();
    
    final trends = await repo.getRegistrationTrends(startDate: finalStartDate, endDate: finalEndDate);

    return ReportsState(
      userGrowthSummary: results[0] as UserGrowthSummary,
      locationReports: results[1] as List<LocationReport>,
      languageReports: results[2] as List<LanguageReport>,
      lessonEngagement: results[3] as List<LessonEngagementSummary>,
      activeWeekSummary: results[4] as List<ActiveWeekSummary>,
      registrationTrends: trends,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

final reportsControllerProvider = AsyncNotifierProvider<ReportsController, ReportsState>(() {
  return ReportsController();
});
