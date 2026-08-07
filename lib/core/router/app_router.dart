import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/dashboard/presentation/main_layout.dart';
import '../../features/users/presentation/user_list_screen.dart';
import '../../features/users/presentation/user_details_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/lessons/presentation/lesson_list_screen.dart';
import '../../features/lessons/presentation/lesson_form_screen.dart';
import '../../features/lessons/presentation/import_lessons_screen.dart';
import '../../features/lessons/data/models/lesson_model.dart';
import '../../features/reports/presentation/reports_layout.dart';
import '../../features/reports/presentation/reports_dashboard_screen.dart';
import '../../features/reports/presentation/reports_geography_screen.dart';
import '../../features/reports/presentation/reports_languages_screen.dart';
import '../../features/reports/presentation/reports_engagement_screen.dart';
import '../../features/reports/presentation/reports_exports_screen.dart';
import '../../features/mentors/presentation/mentor_list_screen.dart';
import '../../features/mentors/presentation/mentor_details_screen.dart';
import '../../features/notifications/presentation/notification_list_screen.dart';
import '../../features/notifications/presentation/notification_composer_screen.dart';
import '../../features/notifications/presentation/notification_details_screen.dart';
import '../../features/notifications/domain/notification_model.dart';
import '../../features/reminders/presentation/reminders_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref ref;

  RouterNotifier(this.ref) {
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      if (authState.isLoading || authState.hasError) return null;

      final isAuth = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuth && !isLoggingIn) {
        return '/login';
      }

      // We don't automatically redirect to /dashboard if they are on /login.
      // This allows the LoginScreen to verify their admin status in Firestore first,
      // and then manually route them to /dashboard if successful.
      // Otherwise, the router kicks them to the dashboard while the admin check
      // is still running in the background, leading to sudden logouts!
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          // 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // 1: Users
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/users',
                builder: (context, state) => const UserListScreen(),
                routes: [
                  GoRoute(
                    path: ':uid',
                    redirect: (context, state) {
                      if (state.pathParameters['uid']?.isEmpty ?? true) {
                        return '/users';
                      }
                      return null;
                    },
                    builder: (context, state) {
                      final uid = state.pathParameters['uid']!;
                      return UserDetailsScreen(uid: uid);
                    },
                  ),
                ],
              ),
            ],
          ),
          // 2: Mentors
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mentors',
                builder: (context, state) => const MentorListScreen(),
                routes: [
                  GoRoute(
                    path: ':uid',
                    builder: (context, state) {
                      final uid = state.pathParameters['uid']!;
                      return MentorDetailsScreen(uid: uid);
                    },
                  ),
                ],
              ),
            ],
          ),
          // 3: Reports
          StatefulShellBranch(
            routes: [
              ShellRoute(
                builder: (context, state, child) => ReportsLayout(child: child),
                routes: [
                  GoRoute(
                    path: '/reports',
                    redirect: (context, state) => '/reports/overview',
                  ),
                  GoRoute(
                    path: '/reports/overview',
                    builder: (context, state) => const ReportsDashboardScreen(),
                  ),
                  GoRoute(
                    path: '/reports/geography',
                    builder: (context, state) => const ReportsGeographyScreen(),
                  ),
                  GoRoute(
                    path: '/reports/languages',
                    builder: (context, state) => const ReportsLanguagesScreen(),
                  ),
                  GoRoute(
                    path: '/reports/engagement',
                    builder: (context, state) =>
                        const ReportsEngagementScreen(),
                  ),
                  GoRoute(
                    path: '/reports/exports',
                    builder: (context, state) => const ReportsExportsScreen(),
                  ),
                ],
              ),
            ],
          ),
          // 4: Content
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/content',
                redirect: (context, state) {
                  if (state.uri.path == '/content') {
                    return '/content/lessons';
                  }
                  return null;
                },
                routes: [
                  GoRoute(
                    path: 'lessons',
                    builder: (context, state) => const LessonListScreen(
                      filterMode: LessonFilterMode.all,
                    ),
                    routes: [
                      GoRoute(
                        path: 'create',
                        builder: (context, state) => const LessonFormScreen(),
                      ),
                      GoRoute(
                        path: 'edit/:id',
                        builder: (context, state) {
                          final lesson = state.extra as LessonModel?;
                          return LessonFormScreen(lesson: lesson);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'published',
                    builder: (context, state) => const LessonListScreen(
                      filterMode: LessonFilterMode.published,
                    ),
                  ),
                  GoRoute(
                    path: 'drafts',
                    builder: (context, state) => const LessonListScreen(
                      filterMode: LessonFilterMode.draft,
                    ),
                  ),
                  GoRoute(
                    path: 'import',
                    builder: (context, state) => const ImportLessonsScreen(),
                  ),
                ],
              ),
            ],
          ),
          // 5: Broadcast Notifications
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationListScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    builder: (context, state) =>
                        const NotificationComposerScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return NotificationDetailsScreen(id: id);
                    },
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) {
                      final draft = state.extra as NotificationModel?;
                      return NotificationComposerScreen(initialDraft: draft);
                    },
                  ),
                ],
              ),
            ],
          ),
          // 6: Daily Reminders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reminders',
                builder: (context, state) => const RemindersScreen(),
              ),
            ],
          ),
          // 7: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
