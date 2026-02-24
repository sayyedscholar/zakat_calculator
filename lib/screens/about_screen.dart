import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('about_title'.tr(context)), backgroundColor: Colors.teal),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16.0), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.teal, Colors.tealAccent]), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.mosque, size: 64, color: Colors.teal)),
              const SizedBox(height: 16), Text('app_name'.tr(context), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8), Text('${'version'.tr(context)}: 1.0.0', style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ]),
          ),
          const SizedBox(height: 24),
          Card(child: Padding(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('developed_by'.tr(context), style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('developer_name'.tr(context), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 4),
            Text('software_engineer'.tr(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.school, color: Colors.teal, size: 28), const SizedBox(width: 12), Expanded(child: Text('based_on'.tr(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))]),
            const SizedBox(height: 12),
            Text('hanafi_ruling'.tr(context), style: Theme.of(context).textTheme.bodyMedium),
          ]))),
          const SizedBox(height: 16),
          Card(child: ExpansionTile(
            leading: const Icon(Icons.info_outline, color: Colors.teal),
            title: Text('purpose'.tr(context), style: const TextStyle(fontWeight: FontWeight.bold)),
            children: [Padding(padding: const EdgeInsets.all(16.0), child: Text('purpose_text'.tr(context), style: Theme.of(context).textTheme.bodyMedium))],
          )),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('key_features'.tr(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
            _buildFeatureItem(Icons.calculate, 'feature_1'.tr(context)),
            _buildFeatureItem(Icons.language, 'feature_2'.tr(context)),
            _buildFeatureItem(Icons.trending_up, 'feature_3'.tr(context)),
            _buildFeatureItem(Icons.offline_bolt, 'feature_4'.tr(context)),
            _buildFeatureItem(Icons.privacy_tip, 'feature_5'.tr(context)),
          ]))),
        ],
      )),
    );
  }
  Widget _buildFeatureItem(IconData icon, String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Row(children: [Icon(icon, size: 20, color: Colors.teal), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontSize: 14)))]));
}