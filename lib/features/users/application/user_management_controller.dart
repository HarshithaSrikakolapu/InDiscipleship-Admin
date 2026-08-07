import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_user.dart';
import '../data/user_management_repository.dart';

final userManagementControllerProvider =
    AsyncNotifierProvider<UserManagementController, void>(() {
      return UserManagementController();
    });

class UserManagementController extends AsyncNotifier<void> {
  UserManagementRepository get _repository =>
      ref.read(userManagementRepositoryProvider);

  @override
  FutureOr<void> build() {}

  Future<bool> updateAccountStatus(String uid, AccountStatus status) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateAccountStatus(uid, status);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> softDeleteUser(String uid, String deletedBy) async {
    state = const AsyncValue.loading();
    try {
      await _repository.softDeleteUser(uid, deletedBy);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> restoreUser(String uid) async {
    state = const AsyncValue.loading();
    try {
      await _repository.restoreUser(uid);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> assignMentor(String uid, String mentorId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.assignMentor(uid, mentorId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> removeMentor(String uid) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeMentor(uid);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> bulkUpdateAccountStatus(
    List<String> uids,
    AccountStatus status,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repository.bulkUpdateAccountStatus(uids, status);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> bulkAssignMentor(List<String> uids, String mentorId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.bulkAssignMentor(uids, mentorId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateUserProfile(
    String uid, {
    String? displayName,
    String? country,
    String? language,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUserProfile(
        uid,
        displayName: displayName,
        country: country,
        language: language,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
