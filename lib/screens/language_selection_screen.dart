import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/localization_service.dart';
import 'home_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    return Scaffold(
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(24.0), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.language, size: 80, color: Colors.teal), const SizedBox(height: 32),
          Text('select_language'.tr(context), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 48),
          _buildLanguageButton(context, 'English', 'en'), const SizedBox(height: 16),
          _buildLanguageButton(context, 'اردو (Urdu)', 'ur'), const SizedBox(height: 16),
          _buildLanguageButton(context, 'العربية (Arabic)', 'ar'), const SizedBox(height: 16),
          _buildLanguageButton(context, 'हिन्दी (Hindi)', 'hi'), const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () async {
              await provider.setFirstLaunchDone();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const HomeScreen()));
              }
            },
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.teal),
            child: Text('continue'.tr(context), style: const TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),)),
    );
  }
  Widget _buildLanguageButton(BuildContext context, String label, String code) {
    final provider = Provider.of<AppProvider>(context);
    final isSelected = provider.locale.languageCode == code;
    return OutlinedButton(
      onPressed: () => provider.changeLanguage(code),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: isSelected ? Colors.teal : Colors.grey, width: isSelected ? 2 : 1),
        backgroundColor: isSelected ? Colors.teal.withValues(alpha: 0.1) : null,
      ),
      child: Row(children: [Icon(Icons.language, color: isSelected ? Colors.teal : Colors.grey), const SizedBox(width: 16), Expanded(child: Text(label)), if (isSelected) const Icon(Icons.check_circle, color: Colors.teal)]),
    );
  }
}