import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_repository.dart';

class Sidebar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const Sidebar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 260,
      color: AppColors.sidebar,
      child: Column(
        children: [
          _buildLogo(),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () => _goBranch(0),
                ),

                _SidebarItem(
                  icon: Icons.people,
                  label: 'Users',
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () => _goBranch(1),
                ),
                _SidebarItem(
                  icon: Icons.school,
                  label: 'Mentors',
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () => _goBranch(2),
                ),
                _ExpandableSidebarItem(
                  icon: Icons.bar_chart,
                  label: 'Reports',
                  isExpanded:
                      navigationShell.currentIndex == 3 &&
                      GoRouterState.of(context).uri.path != '/reports/overview',
                  onExpand: () {
                    if (navigationShell.currentIndex != 3) {
                      _goBranch(3);
                    }
                  },
                  children: [
                    _SidebarSubItem(
                      label: 'Overview',
                      onTap: () {
                        if (navigationShell.currentIndex != 3) _goBranch(3);
                        GoRouter.of(context).go('/reports/overview');
                      },
                    ),
                    _SidebarSubItem(
                      label: 'Geography',
                      onTap: () {
                        if (navigationShell.currentIndex != 3) _goBranch(3);
                        GoRouter.of(context).go('/reports/geography');
                      },
                    ),
                    _SidebarSubItem(
                      label: 'Languages',
                      onTap: () {
                        if (navigationShell.currentIndex != 3) _goBranch(3);
                        GoRouter.of(context).go('/reports/languages');
                      },
                    ),
                    _SidebarSubItem(
                      label: 'Engagement',
                      onTap: () {
                        if (navigationShell.currentIndex != 3) _goBranch(3);
                        GoRouter.of(context).go('/reports/engagement');
                      },
                    ),
                    _SidebarSubItem(
                      label: 'Exports',
                      onTap: () {
                        if (navigationShell.currentIndex != 3) _goBranch(3);
                        GoRouter.of(context).go('/reports/exports');
                      },
                    ),
                  ],
                ),
                _ExpandableSidebarItem(
                  icon: Icons.folder,
                  label: 'Content Management',
                  isExpanded: navigationShell.currentIndex == 4,
                  onExpand: () {
                    if (navigationShell.currentIndex != 4) {
                      _goBranch(4);
                    }
                  },
                  children: [
                    _SidebarSubItem(
                      label: 'Lessons',
                      onTap: () {
                        if (navigationShell.currentIndex != 4) _goBranch(4);
                        GoRouter.of(context).go('/content/lessons');
                      },
                    ),
                    _SidebarSubItem(
                      label: 'Published Lessons',
                      onTap: () {
                        if (navigationShell.currentIndex != 4) _goBranch(4);
                        GoRouter.of(context).go('/content/published');
                      },
                    ),
                    _SidebarSubItem(
                      label: 'Draft Lessons',
                      onTap: () {
                        if (navigationShell.currentIndex != 4) _goBranch(4);
                        GoRouter.of(context).go('/content/drafts');
                      },
                    ),
                    _SidebarSubItem(
                      label: 'Import Lessons',
                      onTap: () {
                        if (navigationShell.currentIndex != 4) _goBranch(4);
                        GoRouter.of(context).go('/content/import');
                      },
                    ),
                  ],
                ),
                _SidebarItem(
                  icon: Icons.campaign,
                  label: 'Broadcast Notifications',
                  isSelected: navigationShell.currentIndex == 5,
                  onTap: () => _goBranch(5),
                ),
                _SidebarItem(
                  icon: Icons.alarm,
                  label: 'Daily Reminders',
                  isSelected: navigationShell.currentIndex == 6,
                  onTap: () => _goBranch(6),
                ),
                _SidebarItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected:
                      navigationShell.currentIndex == 7 &&
                      GoRouterState.of(context).uri.queryParameters['tab'] !=
                          'profile',
                  onTap: () {
                    if (navigationShell.currentIndex != 7) _goBranch(7);
                    GoRouter.of(context).go('/settings?tab=general');
                  },
                ),
                _SidebarItem(
                  icon: Icons.person,
                  label: 'Profile',
                  isSelected:
                      navigationShell.currentIndex == 7 &&
                      GoRouterState.of(context).uri.queryParameters['tab'] ==
                          'profile',
                  onTap: () {
                    if (navigationShell.currentIndex != 7) _goBranch(7);
                    GoRouter.of(context).go('/settings?tab=profile');
                  },
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _SidebarItem(
              icon: Icons.logout,
              label: 'Logout',
              isSelected: false,
              onTap: () {
                ref.read(authRepositoryProvider).signOut();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(Icons.shield, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Admin Portal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badgeCount;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    // ignore: unused_element_parameter
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.sidebarHover,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 4,
              ),
            ),
            color: isSelected ? AppColors.sidebarActive : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white60,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
              if (badgeCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeCount!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableSidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final VoidCallback onExpand;
  final List<Widget> children;

  const _ExpandableSidebarItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.onExpand,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SidebarItem(
          icon: icon,
          label: label,
          isSelected: isExpanded,
          onTap: onExpand,
        ),
        if (isExpanded)
          Container(
            color: AppColors.sidebarActive.withValues(alpha: 0.3),
            padding: const EdgeInsets.only(left: 16),
            child: Column(children: children),
          ),
      ],
    );
  }
}

class _SidebarSubItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SidebarSubItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.sidebarHover,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          width: double.infinity,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
