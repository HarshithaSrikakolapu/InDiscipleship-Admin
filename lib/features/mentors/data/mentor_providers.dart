import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mentor_repository.dart';
import 'mentor_repository_impl.dart';

final mentorRepositoryProvider = Provider<MentorRepository>((ref) {
  return MentorRepositoryImpl();
});
