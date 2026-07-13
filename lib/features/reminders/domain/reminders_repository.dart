import 'reminders_model.dart';

abstract class RemindersRepository {
  Stream<RemindersSettings> getRemindersStream();
  Future<void> saveSettings(RemindersSettings settings);
}
