import 'package:cloud_firestore/cloud_firestore.dart';
import 'mentor_repository.dart';
import '../../users/domain/app_user.dart';

class MentorRepositoryImpl implements MentorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<AppUser>> getMentorsStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'mentor')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Stream<List<AppUser>> getAvailableDisciplesStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'disciple')
        .where('mentorId', isNull: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Stream<List<AppUser>> getAssignedUsersStream(String mentorId) {
    return _firestore
        .collection('users')
        .where('mentorId', isEqualTo: mentorId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  @override
  Future<List<AppUser>> getEligibleUsersForPromotion() async {
    // In a complete implementation, this would query based on completion fields
    // e.g. .where('programCompleted', isEqualTo: true).where('isMentor', isEqualTo: false)
    // For now, we fetch users who are not mentors and we simulate completion if needed,
    // or just fetch those with some criteria. We'll fetch all non-mentors as a placeholder
    // since the specific completion field wasn't provided in the AppUser model yet.

    // We'll add a dummy query for non-mentors for now to satisfy the dialog requirement.
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'disciple')
        .get();

    return snapshot.docs
        .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> promoteToMentor(String uid, String adminUid) async {
    await _firestore.collection('users').doc(uid).update({
      'role': 'mentor',
      'isMentor': true,
      'mentorStatus': 'active',
      'mentorSince': FieldValue.serverTimestamp(),
      'approvedBy': adminUid,
      'approvedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> suspendMentor(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'mentorStatus': 'suspended',
    });
  }

  @override
  Future<void> reactivateMentor(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'mentorStatus': 'active',
    });
  }

  @override
  Future<void> removeMentorRole(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'role': 'disciple',
      'isMentor': false,
      'mentorStatus': FieldValue.delete(),
      'mentorSince': FieldValue.delete(),
      'approvedBy': FieldValue.delete(),
      'approvedAt': FieldValue.delete(),
    });
  }

  @override
  Future<void> assignUsersToMentor(
    String mentorId,
    List<String> userIds,
  ) async {
    final batch = _firestore.batch();

    for (final uid in userIds) {
      final docRef = _firestore.collection('users').doc(uid);
      batch.update(docRef, {'mentorId': mentorId});
    }

    await batch.commit();
  }

  @override
  Future<void> removeUserFromMentor(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'mentorId': FieldValue.delete(),
    });
  }
}
