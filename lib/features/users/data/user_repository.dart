import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/app_user.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.watch(firebaseFirestoreProvider));
});

final usersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).getAllUsersStream();
});

final userStreamProvider = StreamProvider.family<AppUser?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).getUserStreamById(uid);
});

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  Stream<List<AppUser>> getAllUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppUser.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Stream<AppUser?> getUserStreamById(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return AppUser.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    });
  }

  Future<void> updateUserStatus(String uid, bool isActive) async {
    try {
      await _firestore.collection('users').doc(uid).update({'isActive': isActive});
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }
}
