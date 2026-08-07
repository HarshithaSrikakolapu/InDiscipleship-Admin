import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/settings_model.dart';
import '../../application/settings_providers.dart';
import '../../../auth/data/auth_repository.dart';

class SettingsMaintenanceTab extends ConsumerStatefulWidget {
  final MaintenanceSettings settings;

  const SettingsMaintenanceTab({super.key, required this.settings});

  @override
  ConsumerState<SettingsMaintenanceTab> createState() =>
      _SettingsMaintenanceTabState();
}

class _SettingsMaintenanceTabState
    extends ConsumerState<SettingsMaintenanceTab> {
  final _formKey = GlobalKey<FormState>();
  late bool _enabled;
  late TextEditingController _messageController;
  DateTime? _estimatedEndTime;

  @override
  void initState() {
    super.initState();
    _enabled = widget.settings.enabled;
    _messageController = TextEditingController(text: widget.settings.message);
    _estimatedEndTime = widget.settings.estimatedEndTime;
  }

  @override
  void didUpdateWidget(SettingsMaintenanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      setState(() {
        _enabled = widget.settings.enabled;
        _messageController.text = widget.settings.message;
        _estimatedEndTime = widget.settings.estimatedEndTime;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _selectEndDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _estimatedEndTime ?? now.add(const Duration(hours: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _estimatedEndTime ?? now.add(const Duration(hours: 2)),
      ),
    );

    if (pickedTime == null) return;

    setState(() {
      _estimatedEndTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _clearEndDateTime() {
    setState(() {
      _estimatedEndTime = null;
    });
  }

  void _saveMaintenance() async {
    if (_enabled && _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a maintenance message when enabled.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final user = ref.read(authRepositoryProvider).currentUser;
    final userId = user?.email ?? user?.uid ?? 'unknown';

    final updated = MaintenanceSettings(
      enabled: _enabled,
      message: _messageController.text.trim(),
      estimatedEndTime: _estimatedEndTime,
      updatedAt: DateTime.now(),
      updatedBy: userId,
    );

    final success = await ref
        .read(settingsControllerProvider.notifier)
        .updateMaintenance(updated, userId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance settings updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update maintenance settings.'),
            backgroundColor: AppColors.danger,
          ),
        );
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Maintenance Mode Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _enabled
                                ? 'ON - Mobile application is locked for normal users.'
                                : 'OFF - Mobile application is fully active.',
                            style: TextStyle(
                              color: _enabled
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: _enabled
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _enabled,
                        activeThumbColor: AppColors.warning,
                        onChanged: (val) {
                          setState(() {
                            _enabled = val;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_enabled) ...[
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _messageController,
                      maxLines: 4,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Maintenance Message',
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        hintText:
                            'e.g. The application is currently under maintenance. Please try again later.',
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
                    const SizedBox(height: 24),
                    const Text(
                      'Estimated Completion (Optional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
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
                            child: Text(
                              _estimatedEndTime != null
                                  ? DateFormat(
                                      'EEEE, MMMM d, y - h:mm a',
                                    ).format(_estimatedEndTime!)
                                  : 'No completion time set',
                              style: TextStyle(
                                color: _estimatedEndTime != null
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _selectEndDateTime,
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: const Text('Pick Date/Time'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        if (_estimatedEndTime != null) ...[
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            onPressed: _clearEndDateTime,
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('Clear'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
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
                onPressed: isLoading ? null : _saveMaintenance,
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
                label: const Text('Save Maintenance Settings'),
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
}
