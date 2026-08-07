import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/settings_model.dart';
import '../../application/settings_providers.dart';
import '../../../auth/data/auth_repository.dart';

class SettingsVersionTab extends ConsumerStatefulWidget {
  final AppVersionSettings settings;

  const SettingsVersionTab({super.key, required this.settings});

  @override
  ConsumerState<SettingsVersionTab> createState() => _SettingsVersionTabState();
}

class _SettingsVersionTabState extends ConsumerState<SettingsVersionTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _androidVersionController;
  late TextEditingController _iosVersionController;
  late TextEditingController _minimumVersionController;
  late TextEditingController _notesController;
  late bool _forceUpdate;
  late bool _recommendedUpdate;

  @override
  void initState() {
    super.initState();
    _androidVersionController = TextEditingController(
      text: widget.settings.androidVersion,
    );
    _iosVersionController = TextEditingController(
      text: widget.settings.iosVersion,
    );
    _minimumVersionController = TextEditingController(
      text: widget.settings.minimumVersion,
    );
    _notesController = TextEditingController(
      text: widget.settings.releaseNotes,
    );
    _forceUpdate = widget.settings.forceUpdate;
    _recommendedUpdate = widget.settings.recommendedUpdate;
  }

  @override
  void didUpdateWidget(SettingsVersionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      setState(() {
        _androidVersionController.text = widget.settings.androidVersion;
        _iosVersionController.text = widget.settings.iosVersion;
        _minimumVersionController.text = widget.settings.minimumVersion;
        _notesController.text = widget.settings.releaseNotes;
        _forceUpdate = widget.settings.forceUpdate;
        _recommendedUpdate = widget.settings.recommendedUpdate;
      });
    }
  }

  @override
  void dispose() {
    _androidVersionController.dispose();
    _iosVersionController.dispose();
    _minimumVersionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isValidVersion(String version) {
    final regex = RegExp(r'^\d+\.\d+\.\d+$');
    return regex.hasMatch(version.trim());
  }

  void _saveVersion() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authRepositoryProvider).currentUser;
      final userId = user?.email ?? user?.uid ?? 'unknown';

      // Detect if versions changed to update releaseDate
      final isVersionChanged =
          _androidVersionController.text.trim() !=
              widget.settings.androidVersion ||
          _iosVersionController.text.trim() != widget.settings.iosVersion;

      final updated = AppVersionSettings(
        androidVersion: _androidVersionController.text.trim(),
        iosVersion: _iosVersionController.text.trim(),
        minimumVersion: _minimumVersionController.text.trim(),
        releaseNotes: _notesController.text.trim(),
        releaseDate: isVersionChanged
            ? DateTime.now()
            : widget.settings.releaseDate,
        forceUpdate: _forceUpdate,
        recommendedUpdate: _recommendedUpdate,
        updatedAt: DateTime.now(),
        updatedBy: userId,
      );

      final success = await ref
          .read(settingsControllerProvider.notifier)
          .updateAppVersion(updated, userId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('App version settings saved successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save version settings.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final isLoading = state.isLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
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
                  const Text(
                    'Active Target Build Versions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVersionField(
                          controller: _androidVersionController,
                          label: 'Latest Android Version',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildVersionField(
                          controller: _iosVersionController,
                          label: 'Latest iOS Version',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildVersionField(
                          controller: _minimumVersionController,
                          label: 'Minimum Supported Version',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Latest Release Date',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat(
                                  'MMMM d, y - h:mm a',
                                ).format(widget.settings.releaseDate),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
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
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            color: AppColors.cardWhite,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Version Control Behavior',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text(
                      'Force Update Required',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'If active, mobile app users running version below minimum will be completely blocked from using the app.',
                    ),
                    value: _forceUpdate,
                    activeThumbColor: AppColors.danger,
                    onChanged: (val) {
                      setState(() {
                        _forceUpdate = val;
                        if (val) {
                          _recommendedUpdate = false; // mutually exclusive
                        }
                      });
                    },
                  ),
                  const Divider(color: AppColors.border),
                  SwitchListTile(
                    title: const Text(
                      'Recommended Update Available',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'If active, mobile app users running version below latest will see a dismissible update dialog suggestion.',
                    ),
                    value: _recommendedUpdate,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _recommendedUpdate = val;
                        if (val) {
                          _forceUpdate = false; // mutually exclusive
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
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
                  const Text(
                    'Release Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 6,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Latest Release Notes',
                      labelStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.settings.updatedBy.isNotEmpty)
                Text(
                  'Last updated by ${widget.settings.updatedBy}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                )
              else
                const SizedBox.shrink(),
              ElevatedButton.icon(
                onPressed: isLoading ? null : _saveVersion,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save App Version Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersionField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Version number is required';
        if (!_isValidVersion(v)) {
          return 'Invalid format. Use x.y.z (e.g., 1.0.4)';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
