import 'settings_model.dart';

abstract class SettingsRepository {
  Stream<SettingsModel> getSettingsStream();
  Future<void> updateGeneral(GeneralSettings settings, String userId);
  Future<void> updateLanguages(LanguagesSettings settings);
  Future<void> savePrivacy(String draftContent, String userId);
  Future<void> publishPrivacy(String content, String userId);
  Future<void> saveTerms(String draftContent, String userId);
  Future<void> publishTerms(String content, String userId);
  Future<void> updateMaintenance(MaintenanceSettings settings, String userId);
  Future<void> updateFeatureFlags(FeatureFlagsSettings settings);
  Future<void> updateAppVersion(AppVersionSettings settings, String userId);
}
