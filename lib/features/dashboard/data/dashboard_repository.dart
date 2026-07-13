import 'dashboard_repository_impl.dart';

abstract class DashboardRepository {
  Stream<AdditionalMetrics> watchAdditionalMetrics();
}
