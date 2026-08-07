import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../domain/app_user.dart';
import '../domain/user_progress.dart';
import '../domain/user_management_view_model.dart';
import 'user_management_repository.dart';
import 'user_repository.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  final Ref _ref;
  FirebaseFirestore get _firestore => _ref.read(firebaseFirestoreProvider);

  UserManagementRepositoryImpl(this._ref);

  @override
  Stream<List<UserManagementViewModel>> getUsersStream() {
    final usersStream = _firestore.collection('users').snapshots();
    final progressStream = _firestore.collection('user_progress').snapshots();

    return Rx.combineLatest2(usersStream, progressStream, (
      QuerySnapshot usersSnap,
      QuerySnapshot progressSnap,
    ) {
      final progressMap = {
        for (var doc in progressSnap.docs)
          doc.id: UserProgress.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          ),
      };

      // Parse users and build mentor lookup map in one pass
      final allUsers = usersSnap.docs
          .map(
            (doc) => AppUser.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      final mentorsMap = {
        for (var user in allUsers)
          if (user.isMentor && user.accountStatus == AccountStatus.active)
            user.uid: user,
      };

      return allUsers.map((user) {
        final progress = progressMap[user.uid] ?? UserProgress(uid: user.uid);
        return UserManagementViewModel(
          user: user,
          progress: progress,
          mentor: user.mentorId != null ? mentorsMap[user.mentorId] : null,
        );
      }).toList();
    }).asBroadcastStream();
  }

  @override
  Stream<UserManagementViewModel?> getUserStreamById(String uid) {
    final userStream = _firestore.collection('users').doc(uid).snapshots();
    final progressStream = _firestore
        .collection('user_progress')
        .doc(uid)
        .snapshots();

    return Rx.combineLatest2(userStream, progressStream, (
      DocumentSnapshot userSnap,
      DocumentSnapshot progressSnap,
    ) async {
      if (!userSnap.exists || userSnap.data() == null) return null;

      final user = AppUser.fromFirestore(
        userSnap.data() as Map<String, dynamic>,
        userSnap.id,
      );

      UserProgress? progress;
      if (progressSnap.exists && progressSnap.data() != null) {
        progress = UserProgress.fromFirestore(
          progressSnap.data() as Map<String, dynamic>,
          progressSnap.id,
        );
      }

      AppUser? mentor;
      if (user.mentorId != null && user.mentorId!.isNotEmpty) {
        final mentorDoc = await _firestore
            .collection('users')
            .doc(user.mentorId)
            .get();
        if (mentorDoc.exists && mentorDoc.data() != null) {
          mentor = AppUser.fromFirestore(
            mentorDoc.data() as Map<String, dynamic>,
            mentorDoc.id,
          );
        }
      }

      return UserManagementViewModel(
        user: user,
        progress: progress,
        mentor: mentor,
      );
    }).asyncMap((event) => event);
  }

  @override
  Future<void> updateAccountStatus(String uid, AccountStatus status) async {
    await _firestore.collection('users').doc(uid).update({
      'accountStatus': status.name,
      'isActive': status == AccountStatus.active, // Backwards compatibility
    });
  }

  @override
  Future<void> softDeleteUser(String uid, String deletedBy) async {
    await _firestore.collection('users').doc(uid).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedBy': deletedBy,
      'accountStatus': AccountStatus.disabled.name,
      'isActive': false,
    });
  }

  @override
  Future<void> restoreUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isDeleted': false,
      'deletedAt': FieldValue.delete(),
      'deletedBy': FieldValue.delete(),
    });
  }

  @override
  Future<void> assignMentor(String uid, String mentorId) async {
    await _firestore.collection('users').doc(uid).update({
      'mentorId': mentorId,
      'mentorSince': FieldValue.serverTimestamp(),
      'mentorStatus': 'active',
    });
  }

  @override
  Future<void> removeMentor(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'mentorId': FieldValue.delete(),
      'mentorSince': FieldValue.delete(),
      'mentorStatus': FieldValue.delete(),
    });
  }

  @override
  Future<void> bulkUpdateAccountStatus(
    List<String> uids,
    AccountStatus status,
  ) async {
    final batch = _firestore.batch();
    for (final uid in uids) {
      batch.update(_firestore.collection('users').doc(uid), {
        'accountStatus': status.name,
        'isActive': status == AccountStatus.active,
      });
    }
    await batch.commit();
  }

  @override
  Future<void> bulkAssignMentor(List<String> uids, String mentorId) async {
    final batch = _firestore.batch();
    for (final uid in uids) {
      batch.update(_firestore.collection('users').doc(uid), {
        'mentorId': mentorId,
        'mentorSince': FieldValue.serverTimestamp(),
        'mentorStatus': 'active',
      });
    }
    await batch.commit();
  }

  @override
  Future<void> updateUserProfile(
    String uid, {
    String? displayName,
    String? country,
    String? language,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (country != null) updates['country'] = country;
    if (language != null) updates['selectedLanguage'] = language;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }
  }
}
