import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/admin_user.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(firebaseFirestoreProvider));
});

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository(this._firestore);

  Future<AdminUser?> getAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AdminUser.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> verifyAdminStatus(String uid) async {
    final adminUser = await getAdmin(uid);
    if (adminUser != null) {
      return adminUser.role == 'admin' && adminUser.isActive;
    }
    return false;
  }
}
