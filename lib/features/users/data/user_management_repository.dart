import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_user.dart';
import '../domain/user_management_view_model.dart';
import 'user_management_repository_impl.dart';

final userManagementRepositoryProvider = Provider<UserManagementRepository>((
  ref,
) {
  return UserManagementRepositoryImpl(ref);
});

abstract class UserManagementRepository {
  Stream<List<UserManagementViewModel>> getUsersStream();
  Stream<UserManagementViewModel?> getUserStreamById(String uid);

  Future<void> updateAccountStatus(String uid, AccountStatus status);
  Future<void> softDeleteUser(String uid, String deletedBy);
  Future<void> restoreUser(String uid);

  Future<void> assignMentor(String uid, String mentorId);
  Future<void> removeMentor(String uid);

  Future<void> bulkUpdateAccountStatus(List<String> uids, AccountStatus status);
  Future<void> bulkAssignMentor(List<String> uids, String mentorId);

  Future<void> updateUserProfile(
    String uid, {
    String? displayName,
    String? country,
    String? language,
  });
}
