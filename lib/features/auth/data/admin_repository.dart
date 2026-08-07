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
        final data = doc.data()!;
        return AdminUser.fromFirestore(data, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch admin doc: $e');
    }
  }

  Future<bool> verifyAdminStatus(String uid) async {
    final adminUser = await getAdmin(uid);
    if (adminUser != null) {
      if (adminUser.role != 'admin') {
        throw Exception(
          "Access denied: User role is '${adminUser.role}', expected 'admin'.",
        );
      }
      if (adminUser.isActive != true) {
        throw Exception(
          "Access denied: Account is not marked as active (isActive = ${adminUser.isActive}).",
        );
      }
      return true;
    }
    throw Exception(
      "Access denied: No document found in 'admins' collection for your UID ($uid). Please ensure the document ID exactly matches your Auth UID.",
    );
  }
}
