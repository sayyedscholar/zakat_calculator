import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/zakat_calculation.dart';
import '../providers/app_provider.dart';
import '../services/localization_service.dart';
import 'calculator_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _screens = [
    const DashboardScreen(),
    const CalculatorScreen(),
    const SettingsScreen(),
    const AboutScreen()
  ];
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    return Scaffold(
      body: IndexedStack(
        index: provider.selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: provider.selectedIndex,
        onTap: (index) => provider.setSelectedIndex(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home), label: 'home'.tr(context)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.calculate),
              label: 'calculate'.tr(context)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.settings),
              label: 'settings'.tr(context)),
          BottomNavigationBarItem(
              icon: const Icon(Icons.info), label: 'about'.tr(context)),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _formatCurrency(BuildContext context, double amount) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final currency = provider.metalRates?.currency ?? 'INR';
    final format = NumberFormat.decimalPattern('en_IN');
    format.maximumFractionDigits = 2;
    format.minimumFractionDigits = 2;
    return "${format.format(amount)} $currency";
  }

  String _formatNumber(double number, {int decimalPlaces = 2}) {
    final format = NumberFormat.decimalPattern('en_IN');
    if (number == number.truncate()) {
      return format.format(number);
    } else {
      format.maximumFractionDigits = decimalPlaces;
      format.minimumFractionDigits = decimalPlaces;
      return format.format(number);
    }
  }

  void _showLocationSearchDialog(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final controller = TextEditingController();
    List<Map<String, dynamic>> suggestions = [];
    bool isSearchingSuggestions = false;
    Timer? debounce;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('search_location'.tr(context)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'enter_city_name'.tr(context),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: isSearchingSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
                autofocus: true,
                onChanged: (value) {
                  if (debounce?.isActive ?? false) debounce?.cancel();
                  debounce = Timer(const Duration(milliseconds: 500), () async {
                    if (value.length >= 3) {
                      setDialogState(() => isSearchingSuggestions = true);
                      final results = await provider.fetchLocationSuggestions(value);
                      setDialogState(() {
                        suggestions = results;
                        isSearchingSuggestions = false;
                      });
                    } else {
                      setDialogState(() => suggestions = []);
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              if (suggestions.isNotEmpty)
                SizedBox(
                  height: 200,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: suggestions.length,
                    itemBuilder: (context, index) {
                      final item = suggestions[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on, size: 20),
                        title: Text(item['display_name'] ?? ''),
                        onTap: () {
                          provider.setLocation(item['display_name'] ?? '',
                              countryCode: item['country_code']);
                          Navigator.pop(dialogContext);
                        },
                      );
                    },
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.my_location, color: Colors.teal),
                title: Text('use_current_location'.tr(context)),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  await provider.autoDetectLocation();
                  if (context.mounted && provider.location == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('location_detect_failed'.tr(context))),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('cancel'.tr(context))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final metalRates = provider.metalRates;
    return Scaffold(
      appBar: AppBar(
          title: Text('app_name'.tr(context)), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.teal, Colors.tealAccent]),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.mosque, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text('app_name'.tr(context),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)))
                        ]),
                        const SizedBox(height: 12),
                        Text('based_on'.tr(context),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                        if (provider.location != null) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(provider.location!,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white70, size: 16),
                              onPressed: () => _showLocationSearchDialog(context),
                              tooltip: 'edit_location'.tr(context),
                              visualDensity: VisualDensity.compact,
                            ),
                          ]),
                        ],
                        const Divider(color: Colors.white24, height: 24),
                        if (metalRates != null) ...[
                          _buildNisabInfoRow(
                              context,
                              'gold_nisab'.tr(context),
                              ZakatCalculation.nisabGoldGrams,
                              7.5,
                              metalRates.goldRatePerGram * ZakatCalculation.nisabGoldGrams,
                              Icons.star,
                              Colors.amber),
                          const SizedBox(height: 12),
                          _buildNisabInfoRow(
                              context,
                              'silver_nisab'.tr(context),
                              ZakatCalculation.nisabSilverGrams,
                              52.5,
                              metalRates.silverRatePerGram * ZakatCalculation.nisabSilverGrams,
                              Icons.circle,
                              Colors.grey[300]!),
                        ]
                      ]),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('live_rates'.tr(context),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (metalRates != null)
                    Text(_formatDate(metalRates.lastUpdated),
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              if (metalRates != null && metalRates.location != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_pin, size: 14, color: Colors.teal),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Rates for ${metalRates.location}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.teal, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              if (metalRates != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                  child: Text('gold_purity'.tr(context),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal)),
                ),
                Row(children: [
                  Expanded(
                    child: _buildRateCard(
                        context,
                        'karat_24'.tr(context),
                        metalRates.goldRatePerGram,
                        Icons.star,
                        Colors.amber),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRateCard(
                        context,
                        'karat_22'.tr(context),
                        metalRates.goldRatePerGram * 0.916,
                        Icons.star_half,
                        Colors.amber[600]!),
                  ),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: _buildRateCard(
                        context,
                        'karat_18'.tr(context),
                        metalRates.goldRatePerGram * 0.75,
                        Icons.star_outline,
                        Colors.amber[400]!),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRateCard(
                        context,
                        'karat_14'.tr(context),
                        metalRates.goldRatePerGram * 0.585,
                        Icons.settings_input_component,
                        Colors.amber[200]!),
                  ),
                ]),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('silver_purity'.tr(context),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal)),
                ),
                _buildRateCard(
                    context,
                    'purity_99'.tr(context),
                    metalRates.silverRatePerGram,
                    Icons.circle,
                    Colors.grey),
              ],
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          final success = await provider.updateMetalRates();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(success
                                        ? 'rates_updated'.tr(context)
                                        : 'update_failed'.tr(context))));
                          }
                        },
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh),
                  label: Text('update_rates'.tr(context)),
                ),
              ),
              const SizedBox(height: 12),
              if (provider.location == null)
                Card(
                    child: ListTile(
                        leading: const Icon(Icons.location_on, color: Colors.teal),
                        title: Text('select_city'.tr(context)),
                        onTap: () => _showLocationSearchDialog(context),
                        trailing: IconButton(
                            icon: const Icon(Icons.my_location),
                            onPressed: provider.isLoading
                                ? null
                                : () async {
                                    await provider.autoDetectLocation();
                                  }))),
              const SizedBox(height: 24),
              _buildReligiousContent(context),
              const SizedBox(height: 24),
            ],
          )),
    );
  }

  Widget _buildReligiousContent(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.menu_book, color: Colors.teal, size: 24),
                const SizedBox(height: 12),
                Text(
                  'quran_verse'.tr(context),
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'quran_ref'.tr(context),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.format_quote, color: Colors.teal, size: 24),
                const SizedBox(height: 12),
                Text(
                  'hadith_text'.tr(context),
                  style: const TextStyle(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'hadith_ref'.tr(context),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNisabInfoRow(BuildContext context, String title, double grams, double tola, double amount, IconData icon, Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(_formatCurrency(context, amount), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text('${_formatNumber(grams, decimalPlaces: 2)} ${'grams'.tr(context)} (${_formatNumber(tola, decimalPlaces: 1)} ${'tola'.tr(context)})', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildRateCard(BuildContext context, String title, double rate, IconData icon, Color color) {
    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(title,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(_formatCurrency(context, rate),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold))
            ])));
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}