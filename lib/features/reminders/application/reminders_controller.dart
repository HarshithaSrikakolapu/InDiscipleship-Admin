import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/reminders_model.dart';
import '../domain/reminders_repository.dart';
import 'reminders_providers.dart';

class RemindersController extends AsyncNotifier<RemindersSettings> {
  RemindersRepository get _repository => ref.read(remindersRepositoryProvider);

  @override
  FutureOr<RemindersSettings> build() async {
    return _repository.getRemindersStream().first;
  }

  Future<bool> saveSettings(RemindersSettings settings) async {
    state = const AsyncLoading();
    try {
      await _repository.saveSettings(settings);
      state = AsyncData(settings);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
