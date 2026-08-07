class AdminUser {
  final String uid;
  final String email;
  final String role;
  final bool isActive;

  AdminUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.isActive,
  });

  factory AdminUser.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return AdminUser(
      uid: documentId,
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'email': email, 'role': role, 'isActive': isActive};
  }
}
