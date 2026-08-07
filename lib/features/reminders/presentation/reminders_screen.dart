import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../application/reminders_providers.dart';
import '../domain/reminders_model.dart';

class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isInitialized = false;

  late bool _prayerEnabled;
  late TextEditingController _prayerTitleController;
  late TextEditingController _prayerMessageController;
  late String _prayerTime; // "HH:mm"

  late bool _lessonEnabled;
  late TextEditingController _lessonTitleController;
  late TextEditingController _lessonMessageController;
  late String _lessonTime; // "HH:mm"

  @override
  void dispose() {
    if (_isInitialized) {
      _prayerTitleController.dispose();
      _prayerMessageController.dispose();
      _lessonTitleController.dispose();
      _lessonMessageController.dispose();
    }
    super.dispose();
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return const TimeOfDay(hour: 7, minute: 0);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeDisplay(String time24h) {
    try {
      final parts = time24h.split(':');
      final hourVal = int.parse(parts[0]);
      final minVal = int.parse(parts[1]);
      final dt = DateTime(2026, 1, 1, hourVal, minVal);
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return time24h;
    }
  }

  String? _validateRequired(String? val, bool isEnabled) {
    if (!isEnabled) return null;
    if (val == null || val.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  void _saveSettings(RemindersSettings currentSettings) async {
    if (_formKey.currentState!.validate()) {
      final updated = RemindersSettings(
        prayerReminder: ReminderConfig(
          enabled: _prayerEnabled,
          title: _prayerTitleController.text.trim(),
          message: _prayerMessageController.text.trim(),
          defaultTime: _prayerTime,
        ),
        lessonReminder: ReminderConfig(
          enabled: _lessonEnabled,
          title: _lessonTitleController.text.trim(),
          message: _lessonMessageController.text.trim(),
          defaultTime: _lessonTime,
        ),
        updatedAt: DateTime.now(),
        updatedBy: '', // Resolved in Repo
        version: currentSettings.version,
      );

      final success = await ref
          .read(remindersControllerProvider.notifier)
          .saveSettings(updated);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reminders saved successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save reminders.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(remindersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: remindersAsync.when(
        data: (settings) {
          if (!_isInitialized) {
            _prayerEnabled = settings.prayerReminder.enabled;
            _prayerTitleController = TextEditingController(
              text: settings.prayerReminder.title,
            );
            _prayerMessageController = TextEditingController(
              text: settings.prayerReminder.message,
            );
            _prayerTime = settings.prayerReminder.defaultTime;

            _lessonEnabled = settings.lessonReminder.enabled;
            _lessonTitleController = TextEditingController(
              text: settings.lessonReminder.title,
            );
            _lessonMessageController = TextEditingController(
              text: settings.lessonReminder.message,
            );
            _lessonTime = settings.lessonReminder.defaultTime;

            _isInitialized = true;
          }

          final isSaving = ref.watch(remindersControllerProvider).isLoading;

          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Reminders',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Configure recurring reminder notifications and default delivery schedules.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildReminderCard(
                            title: 'Prayer Reminder',
                            icon: Icons.notifications_active,
                            enabled: _prayerEnabled,
                            onEnabledChanged: (val) {
                              setState(() {
                                _prayerEnabled = val;
                              });
                            },
                            titleController: _prayerTitleController,
                            messageController: _prayerMessageController,
                            time24h: _prayerTime,
                            onSelectTime: () async {
                              final current = _parseTime(_prayerTime);
                              final selected = await showTimePicker(
                                context: context,
                                initialTime: current,
                              );
                              if (selected != null) {
                                setState(() {
                                  _prayerTime = _formatTime(selected);
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildReminderCard(
                            title: 'Daily Lesson Reminder',
                            icon: Icons.menu_book,
                            enabled: _lessonEnabled,
                            onEnabledChanged: (val) {
                              setState(() {
                                _lessonEnabled = val;
                              });
                            },
                            titleController: _lessonTitleController,
                            messageController: _lessonMessageController,
                            time24h: _lessonTime,
                            onSelectTime: () async {
                              final current = _parseTime(_lessonTime);
                              final selected = await showTimePicker(
                                context: context,
                                initialTime: current,
                              );
                              if (selected != null) {
                                setState(() {
                                  _lessonTime = _formatTime(selected);
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () => _saveSettings(settings),
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: const Text('Save Changes'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 18,
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
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error loading reminders: $err',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard({
    required String title,
    required IconData icon,
    required bool enabled,
    required ValueChanged<bool> onEnabledChanged,
    required TextEditingController titleController,
    required TextEditingController messageController,
    required String time24h,
    required VoidCallback onSelectTime,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: enabled,
                  onChanged: onEnabledChanged,
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
            if (enabled) ...[
              const Divider(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: titleController,
                      label: 'Reminder Title',
                      validator: (val) => _validateRequired(val, enabled),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Schedule Time',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: onSelectTime,
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(_formatTimeDisplay(time24h)),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.centerLeft,
                            foregroundColor: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: messageController,
                label: 'Reminder Message',
                maxLines: 3,
                validator: (val) => _validateRequired(val, enabled),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Text(
                'This reminder type is currently disabled.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      validator: validator,
    );
  }
}
