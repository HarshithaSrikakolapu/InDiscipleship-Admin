import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/settings_model.dart';
import '../../application/settings_providers.dart';

class SettingsFeatureFlagsTab extends ConsumerStatefulWidget {
  final FeatureFlagsSettings settings;

  const SettingsFeatureFlagsTab({
    super.key,
    required this.settings,
  });

  @override
  ConsumerState<SettingsFeatureFlagsTab> createState() => _SettingsFeatureFlagsTabState();
}

class _SettingsFeatureFlagsTabState extends ConsumerState<SettingsFeatureFlagsTab> {
  late Map<String, bool> _flags;

  // Static Group Definitions
  final Map<String, String> _groupMappings = {
    'mentors': 'Core Management Features',
    'notes': 'Core App Features',
    'notifications': 'Engagement & Notifications',
    'dailyReminders': 'Engagement & Notifications',
    'leaderboard': 'Social & Gamification',
    'reports': 'Analytics & Reporting',
    'audioLessons': 'Lessons & Media Content',
    'videoLessons': 'Lessons & Media Content',
  };

  @override
  void initState() {
    super.initState();
    _flags = Map.from(widget.settings.flags);
  }

  @override
  void didUpdateWidget(SettingsFeatureFlagsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      setState(() {
        _flags = Map.from(widget.settings.flags);
      });
    }
  }

  String _getFlagDisplayName(String key) {
    final hardcoded = {
      'notifications': 'Push Notifications',
      'mentors': 'Mentor System',
      'reports': 'Usage Reports & Analytics',
      'dailyReminders': 'Daily Reminders',
      'notes': 'Personal Lessons Notes',
      'leaderboard': 'Gamification Leaderboard',
      'audioLessons': 'Audio Lesson Audios',
      'videoLessons': 'Video Lesson Videos',
    };
    if (hardcoded.containsKey(key)) return hardcoded[key]!;

    // Format camelCase dynamically
    if (key.isEmpty) return '';
    final result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }

  String _getFlagCategory(String key) {
    return _groupMappings[key] ?? 'Additional Custom Features';
  }

  void _saveFeatureFlags() async {
    final updated = FeatureFlagsSettings(flags: _flags);
    final success = await ref
        .read(settingsControllerProvider.notifier)
        .updateFeatureFlags(updated);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feature flags updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update feature flags.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _addNewFlagDialog() {
    final keyController = TextEditingController();
    final groupController = TextEditingController();
    bool defaultVal = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Feature Flag', style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: keyController,
                      decoration: const InputDecoration(
                        labelText: 'Flag Key (camelCase, e.g. communityChat)',
                        hintText: 'e.g. communityChat',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: groupController,
                      decoration: const InputDecoration(
                        labelText: 'Category/Group (e.g. Social, Media)',
                        hintText: 'e.g. Social Features',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Default Status (Enabled)'),
                      value: defaultVal,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setDialogState(() => defaultVal = val),
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
                  onPressed: () {
                    final key = keyController.text.trim();
                    final group = groupController.text.trim();

                    if (key.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Flag key cannot be empty')),
                      );
                      return;
                    }

                    if (_flags.containsKey(key)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Flag key already exists')),
                      );
                      return;
                    }

                    setState(() {
                      _flags[key] = defaultVal;
                      if (group.isNotEmpty) {
                        _groupMappings[key] = group;
                      }
                    });

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Add Flag'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final isLoading = state.isLoading;

    // Group the flags
    final Map<String, List<String>> categorizedFlags = {};
    _flags.keys.forEach((key) {
      final category = _getFlagCategory(key);
      categorizedFlags.putIfAbsent(category, () => []).add(key);
    });

    final categories = categorizedFlags.keys.toList();
    // Move 'Additional Custom Features' to the end if present
    categories.sort((a, b) {
      if (a == 'Additional Custom Features') return 1;
      if (b == 'Additional Custom Features') return -1;
      return a.compareTo(b);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Feature Management',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Instantly enable or disable app capabilities for mobile client instances.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _addNewFlagDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Feature Flag'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (c, i) => const SizedBox(height: 24),
          itemBuilder: (context, catIndex) {
            final categoryName = categories[catIndex];
            final flagKeys = categorizedFlags[categoryName]!;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              color: AppColors.cardWhite,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    ...flagKeys.map((key) {
                      final val = _flags[key] ?? false;
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getFlagDisplayName(key),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Key: $key',
                                  style: const TextStyle(fontFamily: 'Courier', fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            Switch(
                              value: val,
                              activeColor: AppColors.success,
                              onChanged: (newVal) {
                                setState(() {
                                  _flags[key] = newVal;
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: isLoading ? null : _saveFeatureFlags,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Feature Flags'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
