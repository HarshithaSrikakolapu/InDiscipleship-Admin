import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../users/domain/app_user.dart';
import '../data/mentor_providers.dart';
import '../../auth/data/auth_repository.dart';

final mentorsStreamProvider = StreamProvider<List<AppUser>>((ref) {
  final repository = ref.watch(mentorRepositoryProvider);
  return repository.getMentorsStream();
});

final assignedUsersProvider = StreamProvider.family<List<AppUser>, String>((ref, mentorId) {
  final repository = ref.watch(mentorRepositoryProvider);
  return repository.getAssignedUsersStream(mentorId);
});

class MentorController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> promoteToMentor(String uid) async {
    state = const AsyncLoading();
    try {
      final authState = ref.read(authStateProvider).value;
      if (authState == null) throw Exception('Not authenticated');
      final repository = ref.read(mentorRepositoryProvider);
      await repository.promoteToMentor(uid, authState.uid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> suspendMentor(String uid) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(mentorRepositoryProvider);
      await repository.suspendMentor(uid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> reactivateMentor(String uid) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(mentorRepositoryProvider);
      await repository.reactivateMentor(uid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> removeMentorRole(String uid) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(mentorRepositoryProvider);
      
      // Verification check (must not have assigned users)
      // This is ideally checked on the UI or backend, but we'll enforce here as well.
      final assignedStream = repository.getAssignedUsersStream(uid);
      final assignedUsers = await assignedStream.first;
      if (assignedUsers.isNotEmpty) {
        throw Exception('This mentor still has assigned disciples. Please reassign them before removing the mentor role.');
      }
      
      await repository.removeMentorRole(uid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> assignUsers(String mentorId, List<String> userIds) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(mentorRepositoryProvider);
      await repository.assignUsersToMentor(mentorId, userIds);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  
  Future<void> removeUserFromMentor(String userId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(mentorRepositoryProvider);
      await repository.removeUserFromMentor(userId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final mentorControllerProvider = AsyncNotifierProvider.autoDispose<MentorController, void>(() {
  return MentorController();
});
