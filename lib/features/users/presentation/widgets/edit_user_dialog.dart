import 'package:flutter/material.dart';
import '../../domain/app_user.dart';

class EditUserDialog extends StatefulWidget {
  final AppUser user;

  const EditUserDialog({super.key, required this.user});

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _languageCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName);
    _countryCtrl = TextEditingController(text: widget.user.country);
    _languageCtrl = TextEditingController(text: widget.user.selectedLanguage);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _countryCtrl.dispose();
    _languageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit User Profile'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _countryCtrl,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _languageCtrl,
              decoration: const InputDecoration(
                labelText: 'Language',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'displayName': _nameCtrl.text.trim(),
              'country': _countryCtrl.text.trim(),
              'language': _languageCtrl.text.trim(),
            });
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
