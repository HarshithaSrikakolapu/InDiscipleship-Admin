import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/settings_model.dart';
import '../../application/settings_providers.dart';

class SettingsLanguagesTab extends ConsumerStatefulWidget {
  final LanguagesSettings settings;

  const SettingsLanguagesTab({
    super.key,
    required this.settings,
  });

  @override
  ConsumerState<SettingsLanguagesTab> createState() => _SettingsLanguagesTabState();
}

class _SettingsLanguagesTabState extends ConsumerState<SettingsLanguagesTab> {
  late List<SupportedLanguage> _languages;
  late String _defaultLanguageCode;

  @override
  void initState() {
    super.initState();
    _initLanguages();
  }

  void _initLanguages() {
    _languages = List.from(widget.settings.supportedLanguages);
    // Sort by display order
    _languages.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    _defaultLanguageCode = widget.settings.defaultLanguage;
  }

  @override
  void didUpdateWidget(SettingsLanguagesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      setState(() {
        _initLanguages();
      });
    }
  }

  void _saveLanguages() async {
    // Validation: Check if a default language is selected
    if (_defaultLanguageCode.isEmpty) {
      _showError('Please select a default language.');
      return;
    }

    // Validation: Check if the selected default language is enabled
    final defaultLanguage = _languages.firstWhere(
      (l) => l.code == _defaultLanguageCode,
      orElse: () => const SupportedLanguage(name: '', code: '', enabled: false, rtl: false, displayOrder: 0),
    );

    if (defaultLanguage.code.isEmpty || !defaultLanguage.enabled) {
      _showError('The default language must be enabled.');
      return;
    }

    final updated = LanguagesSettings(
      defaultLanguage: _defaultLanguageCode,
      supportedLanguages: _languages,
    );

    final success = await ref
        .read(settingsControllerProvider.notifier)
        .updateLanguages(updated);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Language settings saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save language settings.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _addNewLanguageDialog() {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final orderController = TextEditingController(text: '${_languages.length + 1}');
    bool isEnabled = true;
    bool isRtl = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Supported Language', style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Language Name (e.g. Arabic)'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Language Code (e.g. ar)'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: orderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Display Order'),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Enabled'),
                      value: isEnabled,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setDialogState(() => isEnabled = val),
                    ),
                    SwitchListTile(
                      title: const Text('RTL (Right-to-Left)'),
                      value: isRtl,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setDialogState(() => isRtl = val),
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
                    final name = nameController.text.trim();
                    final code = codeController.text.trim().toLowerCase();
                    final order = int.tryParse(orderController.text) ?? (_languages.length + 1);

                    if (name.isEmpty || code.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields')),
                      );
                      return;
                    }

                    if (_languages.any((l) => l.code == code)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Language code already exists')),
                      );
                      return;
                    }

                    setState(() {
                      _languages.add(SupportedLanguage(
                        name: name,
                        code: code,
                        enabled: isEnabled,
                        rtl: isRtl,
                        displayOrder: order,
                      ));
                      _languages.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
                    });

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Add'),
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

    final enabledLanguages = _languages.where((l) => l.enabled).toList();

    return Column(
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
                  'Default Language',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose the fallback language for users when their system language is unsupported.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 320,
                  child: DropdownButtonFormField<String>(
                    value: _defaultLanguageCode.isNotEmpty &&
                            _languages.any((l) => l.code == _defaultLanguageCode)
                        ? _defaultLanguageCode
                        : null,
                    hint: const Text('Select default language'),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: enabledLanguages.map((lang) {
                      return DropdownMenuItem<String>(
                        value: lang.code,
                        child: Text('${lang.name} (${lang.code.toUpperCase()})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _defaultLanguageCode = val;
                        });
                      }
                    },
                    validator: (v) => v == null ? 'Default Language is required' : null,
                  ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Supported Languages',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addNewLanguageDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Language'),
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
                  itemCount: _languages.length,
                  separatorBuilder: (c, i) => const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              lang.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                lang.code.toUpperCase(),
                                style: const TextStyle(fontFamily: 'Courier', fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                const Text('RTL ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                Checkbox(
                                  value: lang.rtl,
                                  activeColor: AppColors.primary,
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _languages[index] = lang.copyWith(rtl: val);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                const Text('Order ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                SizedBox(
                                  width: 50,
                                  height: 35,
                                  child: TextFormField(
                                    initialValue: '${lang.displayOrder}',
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (val) {
                                      final order = int.tryParse(val) ?? lang.displayOrder;
                                      setState(() {
                                        _languages[index] = lang.copyWith(displayOrder: order);
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: lang.enabled,
                            activeColor: AppColors.success,
                            onChanged: (val) {
                              setState(() {
                                _languages[index] = lang.copyWith(enabled: val);
                                // If disabling, and it was the default, reset default
                                if (!val && _defaultLanguageCode == lang.code) {
                                  _defaultLanguageCode = '';
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: isLoading ? null : _saveLanguages,
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Languages'),
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
