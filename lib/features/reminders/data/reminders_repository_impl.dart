import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/reminders_model.dart';
import '../domain/reminders_repository.dart';

class RemindersRepositoryImpl implements RemindersRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RemindersRepositoryImpl(this._firestore, this._auth);

  DocumentReference<Map<String, dynamic>> get _remindersRef =>
      _firestore.collection('settings').doc('reminders');

  @override
  Stream<RemindersSettings> getRemindersStream() {
    return _remindersRef.snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return RemindersSettings.empty();
      }
      return RemindersSettings.fromMap(snapshot.data()!);
    });
  }

  @override
  Future<void> saveSettings(RemindersSettings settings) async {
    final user = _auth.currentUser;
    final userId = user?.email ?? user?.uid ?? 'unknown_admin';

    await _remindersRef.set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': userId,
    }, SetOptions(merge: true));
  }
}
