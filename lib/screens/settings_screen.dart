import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/localization_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('settings_title'.tr(context)), backgroundColor: Colors.teal),
      body: ListView(padding: const EdgeInsets.all(16.0), children: [
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.language, color: Colors.teal), title: Text('language_preference'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold))),
          const Divider(height: 1),
          _buildLanguageTile(context, 'English', 'en'),
          _buildLanguageTile(context, 'اردو (Urdu)', 'ur'),
          _buildLanguageTile(context, 'العربية (Arabic)', 'ar'),
          _buildLanguageTile(context, 'हिन्दी (Hindi)', 'hi'),
        ])),
        const SizedBox(height: 16),
        Card(child: Column(children: [
          ListTile(
            leading: const Icon(Icons.palette, color: Colors.teal),
            title: Text('theme'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          _buildThemeTile(context, 'light'.tr(context), 'light', Icons.light_mode),
          _buildThemeTile(context, 'dark'.tr(context), 'dark', Icons.dark_mode),
          _buildThemeTile(context, 'system'.tr(context), 'system', Icons.brightness_auto),
        ])),
        const SizedBox(height: 16),
        Card(child: Column(children: [
          ListTile(
            leading: const Icon(Icons.update, color: Colors.teal),
            title: Text('update_rates'.tr(context)),
            trailing: provider.isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: provider.isLoading ? null : () async {
              final success = await provider.updateMetalRates();
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'saved_successfully'.tr(context) : 'update_failed'.tr(context))));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text('clear_data'.tr(context), style: const TextStyle(color: Colors.red)),
            onTap: () => _showClearDataDialog(context),
          ),
        ])),
      ]),
    );
  }

  Widget _buildLanguageTile(BuildContext context, String label, String code) {
    final provider = Provider.of<AppProvider>(context);
    final isSelected = provider.locale.languageCode == code;
    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
      tileColor: isSelected ? Colors.teal.withValues(alpha: 0.1) : null,
      onTap: () => provider.changeLanguage(code),
    );
  }

  Widget _buildThemeTile(BuildContext context, String label, String mode, IconData icon) {
    final provider = Provider.of<AppProvider>(context);
    final isSelected = provider.themeModePreference == mode;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.teal : Colors.grey),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
      tileColor: isSelected ? Colors.teal.withValues(alpha: 0.1) : null,
      onTap: () => provider.setThemeMode(mode),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(context: context, builder: (dialogContext) {
      return AlertDialog(
        title: Text('clear_data'.tr(context)),
        content: Text('confirm_clear'.tr(context)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('no'.tr(context))),
          TextButton(
            onPressed: () async {
              await Provider.of<AppProvider>(context, listen: false).clearAllData();
              if (context.mounted) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('saved_successfully'.tr(context)), backgroundColor: Colors.green));
              }
            },
            child: Text('yes'.tr(context), style: const TextStyle(color: Colors.red)),
          ),
        ],
      );
    });
  }
}