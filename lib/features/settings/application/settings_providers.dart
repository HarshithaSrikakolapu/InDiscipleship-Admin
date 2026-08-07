import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../users/data/user_repository.dart';
import '../domain/settings_model.dart';
import '../domain/settings_repository.dart';
import '../data/settings_repository_impl.dart';
import 'settings_controller.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return SettingsRepositoryImpl(firestore);
});

final settingsStreamProvider = StreamProvider.autoDispose<SettingsModel>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.getSettingsStream();
});

final settingsControllerProvider =
    AsyncNotifierProvider.autoDispose<SettingsController, void>(() {
      return SettingsController();
    });
