import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/settings_model.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final FirebaseFirestore _firestore;

  SettingsRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _settingsRef =>
      _firestore.collection('settings');

  @override
  Stream<SettingsModel> getSettingsStream() {
    return _settingsRef.snapshots().map((snapshot) {
      var general = GeneralSettings.empty();
      var languages = LanguagesSettings.empty();
      var privacy = PrivacySettings.empty();
      var terms = TermsSettings.empty();
      var maintenance = MaintenanceSettings.empty();
      var featureFlags = FeatureFlagsSettings.empty();
      var appVersion = AppVersionSettings.empty();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        switch (doc.id) {
          case 'general':
            general = GeneralSettings.fromMap(data);
            break;
          case 'languages':
            languages = LanguagesSettings.fromMap(data);
            break;
          case 'privacy':
            privacy = PrivacySettings.fromMap(data);
            break;
          case 'terms':
            terms = TermsSettings.fromMap(data);
            break;
          case 'maintenance':
            maintenance = MaintenanceSettings.fromMap(data);
            break;
          case 'feature_flags':
            featureFlags = FeatureFlagsSettings.fromMap(data);
            break;
          case 'app_version':
            appVersion = AppVersionSettings.fromMap(data);
            break;
        }
      }

      return SettingsModel(
        general: general,
        languages: languages,
        privacy: privacy,
        terms: terms,
        maintenance: maintenance,
        featureFlags: featureFlags,
        appVersion: appVersion,
      );
    });
  }

  @override
  Future<void> updateGeneral(GeneralSettings settings, String userId) async {
    await _settingsRef.doc('general').set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': userId,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateLanguages(LanguagesSettings settings) async {
    await _settingsRef
        .doc('languages')
        .set(settings.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> savePrivacy(String draftContent, String userId) async {
    await _settingsRef.doc('privacy').set({
      'draftContent': draftContent,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedBy': userId,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> publishPrivacy(String content, String userId) async {
    final docRef = _settingsRef.doc('privacy');
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      int currentVersion = 0;
      if (snapshot.exists && snapshot.data() != null) {
        currentVersion = snapshot.data()!['version'] ?? 0;
      }
      transaction.set(docRef, {
        'content': content,
        'draftContent': content,
        'version': currentVersion + 1,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': userId,
        'publishedAt': FieldValue.serverTimestamp(),
        'publishedBy': userId,
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> saveTerms(String draftContent, String userId) async {
    await _settingsRef.doc('terms').set({
      'draftContent': draftContent,
      'lastUpdated': FieldValue.serverTimestamp(),
      'updatedBy': userId,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> publishTerms(String content, String userId) async {
    final docRef = _settingsRef.doc('terms');
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      int currentVersion = 0;
      if (snapshot.exists && snapshot.data() != null) {
        currentVersion = snapshot.data()!['version'] ?? 0;
      }
      transaction.set(docRef, {
        'content': content,
        'draftContent': content,
        'version': currentVersion + 1,
        'lastUpdated': FieldValue.serverTimestamp(),
        'updatedBy': userId,
        'publishedAt': FieldValue.serverTimestamp(),
        'publishedBy': userId,
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> updateMaintenance(
    MaintenanceSettings settings,
    String userId,
  ) async {
    await _settingsRef.doc('maintenance').set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': userId,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateFeatureFlags(FeatureFlagsSettings settings) async {
    await _settingsRef.doc('feature_flags').set(settings.toMap());
  }

  @override
  Future<void> updateAppVersion(
    AppVersionSettings settings,
    String userId,
  ) async {
    await _settingsRef.doc('app_version').set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': userId,
    }, SetOptions(merge: true));
  }
}
