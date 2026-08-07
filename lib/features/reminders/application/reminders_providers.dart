import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../users/data/user_repository.dart'; // contains firebaseFirestoreProvider
import '../../auth/data/auth_repository.dart'; // contains firebaseAuthProvider
import '../domain/reminders_repository.dart';
import '../domain/reminders_model.dart';
import '../data/reminders_repository_impl.dart';
import 'reminders_controller.dart';

final remindersRepositoryProvider = Provider<RemindersRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return RemindersRepositoryImpl(firestore, auth);
});

final remindersStreamProvider = StreamProvider.autoDispose<RemindersSettings>((
  ref,
) {
  final repo = ref.watch(remindersRepositoryProvider);
  return repo.getRemindersStream();
});

final remindersControllerProvider =
    AsyncNotifierProvider.autoDispose<RemindersController, RemindersSettings>(
      () {
        return RemindersController();
      },
    );
