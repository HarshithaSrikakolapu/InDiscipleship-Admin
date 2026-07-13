import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/settings_model.dart';
import '../../application/settings_providers.dart';
import '../../../auth/data/auth_repository.dart';

class SettingsGeneralTab extends ConsumerStatefulWidget {
  final GeneralSettings settings;

  const SettingsGeneralTab({
    super.key,
    required this.settings,
  });

  @override
  ConsumerState<SettingsGeneralTab> createState() => _SettingsGeneralTabState();
}

class _SettingsGeneralTabState extends ConsumerState<SettingsGeneralTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _appNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _websiteController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController(text: widget.settings.appName);
    _companyNameController = TextEditingController(text: widget.settings.companyName);
    _websiteController = TextEditingController(text: widget.settings.website);
    _emailController = TextEditingController(text: widget.settings.supportEmail);
    _phoneController = TextEditingController(text: widget.settings.supportPhone);
    _addressController = TextEditingController(text: widget.settings.supportAddress);
  }

  @override
  void didUpdateWidget(SettingsGeneralTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _appNameController.text = widget.settings.appName;
      _companyNameController.text = widget.settings.companyName;
      _websiteController.text = widget.settings.website;
      _emailController.text = widget.settings.supportEmail;
      _phoneController.text = widget.settings.supportPhone;
      _addressController.text = widget.settings.supportAddress;
    }
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _companyNameController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final user = ref.read(authRepositoryProvider).currentUser;
      final userId = user?.email ?? user?.uid ?? 'unknown';

      final updated = GeneralSettings(
        appName: _appNameController.text.trim(),
        companyName: _companyNameController.text.trim(),
        website: _websiteController.text.trim(),
        supportEmail: _emailController.text.trim(),
        supportPhone: _phoneController.text.trim(),
        supportAddress: _addressController.text.trim(),
        updatedAt: DateTime.now(),
        updatedBy: userId,
      );

      final success = await ref
          .read(settingsControllerProvider.notifier)
          .updateGeneral(updated, userId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('General settings saved successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save settings. Please try again.'),
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
                    'Global Application Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _appNameController,
                          label: 'Application Name',
                          validator: (v) => v!.trim().isEmpty ? 'Application Name is required' : null,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTextField(
                          controller: _companyNameController,
                          label: 'Company Name',
                          validator: (v) => v!.trim().isEmpty ? 'Company Name is required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _websiteController,
                    label: 'Website URL',
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'Website URL is required';
                      final uri = Uri.tryParse(v);
                      if (uri == null || !uri.hasAbsolutePath) return 'Enter a valid URL (e.g., https://example.com)';
                      return null;
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
                    'Contact & Support Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _emailController,
                          label: 'Support Email Address',
                          validator: (v) {
                            if (v!.trim().isEmpty) return 'Support Email is required';
                            final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                            if (!regex.hasMatch(v)) return 'Enter a valid email address';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTextField(
                          controller: _phoneController,
                          label: 'Support Phone Number',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Support Address',
                    maxLines: 3,
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
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                )
              else
                const SizedBox.shrink(),
              ElevatedButton.icon(
                onPressed: isLoading ? null : _saveSettings,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save General Settings'),
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
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
