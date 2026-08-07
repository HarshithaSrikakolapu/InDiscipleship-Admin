import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../application/settings_providers.dart';
import '../domain/settings_model.dart';
import 'widgets/settings_general_tab.dart';
import 'widgets/settings_languages_tab.dart';
import 'widgets/settings_policy_tab.dart';
import 'widgets/settings_maintenance_tab.dart';
import 'widgets/settings_feature_flags_tab.dart';
import 'widgets/settings_version_tab.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _activeTabOverride;

  final List<Map<String, dynamic>> _tabs = [
    {'key': 'general', 'label': 'General', 'icon': Icons.tune},
    {'key': 'languages', 'label': 'Languages', 'icon': Icons.language},
    {'key': 'privacy', 'label': 'Privacy Policy', 'icon': Icons.gavel},
    {'key': 'terms', 'label': 'Terms & Conditions', 'icon': Icons.description},
    {'key': 'maintenance', 'label': 'Maintenance Mode', 'icon': Icons.build},
    {'key': 'feature_flags', 'label': 'Feature Flags', 'icon': Icons.toggle_on},
    {'key': 'app_version', 'label': 'App Version', 'icon': Icons.system_update},
    {'key': 'profile', 'label': 'Admin Profile', 'icon': Icons.person},
  ];

  void _changePasswordDialog() {
    final passController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: passController,
                  obscureText: true,
                  validator: (v) => v!.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                  decoration: const InputDecoration(labelText: 'New Password'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  validator: (v) => v != passController.text
                      ? 'Passwords do not match'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await ref
                        .read(authRepositoryProvider)
                        .updatePassword(passController.text.trim());
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password updated successfully!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error updating password: ${e.toString()}',
                          ),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    // Read current query param
    final uri = GoRouterState.of(context).uri;
    final tabParam = uri.queryParameters['tab'];

    final activeTab = _activeTabOverride ?? tabParam ?? 'general';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: settingsAsync.when(
        data: (settings) => Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings Portal',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure core application variables and manage terms dynamically.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column navigation list
                          SizedBox(
                            width: 250,
                            child: ListView.builder(
                              itemCount: _tabs.length,
                              itemBuilder: (context, index) {
                                final tab = _tabs[index];
                                final isSelected = activeTab == tab['key'];
                                return _buildDesktopTabButton(tab, isSelected);
                              },
                            ),
                          ),
                          const SizedBox(width: 32),
                          // Right column tab content
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildTabContent(activeTab, settings),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          // Top horizontal scrollable tabs
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _tabs.length,
                              itemBuilder: (context, index) {
                                final tab = _tabs[index];
                                final isSelected = activeTab == tab['key'];
                                return _buildMobileTabButton(tab, isSelected);
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Bottom tab content
                          Expanded(
                            child: SingleChildScrollView(
                              child: _buildTabContent(activeTab, settings),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        loading: () => Padding(
          padding: const EdgeInsets.all(32.0),
          child: _buildSkeleton(),
        ),
        error: (err, stack) => Padding(
          padding: const EdgeInsets.all(32.0),
          child: _buildErrorScreen(),
        ),
      ),
    );
  }

  Widget _buildDesktopTabButton(Map<String, dynamic> tab, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _activeTabOverride = tab['key'];
            });
            // Update URL to match without full page reload
            context.go('/settings?tab=${tab['key']}');
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  tab['icon'],
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  tab['label'],
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTabButton(Map<String, dynamic> tab, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _activeTabOverride = tab['key'];
          });
          context.go('/settings?tab=${tab['key']}');
        },
        icon: Icon(
          tab['icon'],
          size: 16,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
        label: Text(tab['label']),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : Colors.white,
          foregroundColor: isSelected ? Colors.white : AppColors.textPrimary,
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildTabContent(String key, SettingsModel settings) {
    switch (key) {
      case 'general':
        return SettingsGeneralTab(settings: settings.general);
      case 'languages':
        return SettingsLanguagesTab(settings: settings.languages);
      case 'privacy':
        return SettingsPolicyTab(
          title: 'Privacy Policy',
          content: settings.privacy.content,
          draftContent: settings.privacy.draftContent,
          version: settings.privacy.version,
          lastUpdated: settings.privacy.lastUpdated,
          updatedBy: settings.privacy.updatedBy,
          publishedAt: settings.privacy.publishedAt,
          publishedBy: settings.privacy.publishedBy,
          onSave: (c, u) =>
              ref.read(settingsControllerProvider.notifier).savePrivacy(c, u),
          onPublish: (c, u) => ref
              .read(settingsControllerProvider.notifier)
              .publishPrivacy(c, u),
        );
      case 'terms':
        return SettingsPolicyTab(
          title: 'Terms & Conditions',
          content: settings.terms.content,
          draftContent: settings.terms.draftContent,
          version: settings.terms.version,
          lastUpdated: settings.terms.lastUpdated,
          updatedBy: settings.terms.updatedBy,
          publishedAt: settings.terms.publishedAt,
          publishedBy: settings.terms.publishedBy,
          onSave: (c, u) =>
              ref.read(settingsControllerProvider.notifier).saveTerms(c, u),
          onPublish: (c, u) =>
              ref.read(settingsControllerProvider.notifier).publishTerms(c, u),
        );
      case 'maintenance':
        return SettingsMaintenanceTab(settings: settings.maintenance);
      case 'feature_flags':
        return SettingsFeatureFlagsTab(settings: settings.featureFlags);
      case 'app_version':
        return SettingsVersionTab(settings: settings.appVersion);
      case 'profile':
        return _buildProfileTab();
      default:
        return SettingsGeneralTab(settings: settings.general);
    }
  }

  Widget _buildProfileTab() {
    final user = ref.read(authRepositoryProvider).currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          color: AppColors.cardWhite,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Account Info',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email Address',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'Unknown Email',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: _changePasswordDialog,
                      icon: const Icon(Icons.lock_outline, size: 16),
                      label: const Text('Change Password'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          color: AppColors.cardWhite,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Danger Zone',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Log out of the admin portal securely.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 350,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: List.generate(
                    8,
                    (i) => Container(
                      width: 250,
                      height: 44,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Container(
                    height: 480,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1200.ms, color: const Color(0xFFF1F5F9))
        .fade(begin: 0.6, end: 1.0);
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
          const SizedBox(height: 16),
          const Text(
            'Failed to load settings configuration',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please verify your connection and permissions, then try again.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(settingsStreamProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Loading'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
