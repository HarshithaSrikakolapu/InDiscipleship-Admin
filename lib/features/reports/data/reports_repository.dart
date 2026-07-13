import '../domain/reports_model.dart';

abstract class ReportsRepository {
  Future<UserGrowthSummary> getUserGrowthSummary({DateTime? startDate, DateTime? endDate});
  Future<List<LocationReport>> getLocationReports({DateTime? startDate, DateTime? endDate});
  Future<List<LanguageReport>> getLanguageReports({DateTime? startDate, DateTime? endDate});
  Future<List<RegistrationTrend>> getRegistrationTrends({required DateTime startDate, required DateTime endDate});
  Future<List<LessonEngagementSummary>> getLessonEngagement({DateTime? startDate, DateTime? endDate});
  Future<List<ActiveWeekSummary>> getActiveWeekSummary();
}
