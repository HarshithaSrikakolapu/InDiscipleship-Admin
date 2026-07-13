import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../users/domain/app_user.dart';

abstract class MentorRepository {
  /// Stream of all users who have the mentor role
  Stream<List<AppUser>> getMentorsStream();

  /// Stream of all users who do not have a mentor assigned (for assignment purposes)
  Stream<List<AppUser>> getAvailableDisciplesStream();

  /// Promotes a user to a mentor
  Future<void> promoteToMentor(String uid, String adminUid);

  /// Suspends an active mentor
  Future<void> suspendMentor(String uid);

  /// Reactivates a suspended mentor
  Future<void> reactivateMentor(String uid);

  /// Removes the mentor role from a user entirely
  Future<void> removeMentorRole(String uid);

  /// Assigns a list of users to a specific mentor
  Future<void> assignUsersToMentor(String mentorId, List<String> userIds);

  /// Removes a user from their assigned mentor
  Future<void> removeUserFromMentor(String userId);
  
  /// Gets all users assigned to a specific mentor
  Stream<List<AppUser>> getAssignedUsersStream(String mentorId);
  
  /// Get users eligible for promotion (e.g. finished the program)
  /// Currently assuming we can query users by a completion flag or similar.
  /// For this implementation we will fetch users who are not mentors.
  /// In a real app with progress tracking, this would query by week=12, day=5, etc.
  Future<List<AppUser>> getEligibleUsersForPromotion();
}
