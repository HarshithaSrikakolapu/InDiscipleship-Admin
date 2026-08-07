import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/settings_model.dart';
import '../domain/settings_repository.dart';
import 'settings_providers.dart';

class SettingsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  Future<bool> updateGeneral(GeneralSettings settings, String userId) async {
    state = const AsyncLoading();
    try {
      await _repository.updateGeneral(settings, userId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateLanguages(LanguagesSettings settings) async {
    state = const AsyncLoading();
    try {
      await _repository.updateLanguages(settings);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> savePrivacy(String draftContent, String userId) async {
    state = const AsyncLoading();
    try {
      await _repository.savePrivacy(draftContent, userId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> publishPrivacy(String content, String userId) async {
    state = const AsyncLoading();
    try {
      await _repository.publishPrivacy(content, userId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> saveTerms(String draftContent, String userId) async {
    state = const AsyncLoading();
    try {
      await _repository.saveTerms(draftContent, userId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> publishTerms(String content, String userId) async {
    state = const AsyncLoading();
    try {
      await _repository.publishTerms(content, userId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateMaintenance(
    MaintenanceSettings settings,
    String userId,
  ) async {
    state = const AsyncLoading();
    try {
      await _repository.updateMaintenance(settings, userId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateFeatureFlags(FeatureFlagsSettings settings) async {
    state = const AsyncLoading();
    try {
      await _repository.updateFeatureFlags(settings);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateAppVersion(
    AppVersionSettings settings,
    String userId,
  ) async {
    state = const AsyncLoading();
    try {
      await _repository.updateAppVersion(settings, userId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
