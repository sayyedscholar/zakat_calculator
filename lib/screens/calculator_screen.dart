import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/zakat_calculation.dart';
import '../services/localization_service.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _cashController = TextEditingController();
  final _goldController = TextEditingController();
  final _silverController = TextEditingController();
  final _businessController = TextEditingController();
  final _propertiesController = TextEditingController();
  final _sharesController = TextEditingController();
  final _receivableController = TextEditingController();
  final _otherController = TextEditingController();
  final _loansController = TextEditingController();
  final _billsController = TextEditingController();
  ZakatCalculation? _calculation;
  bool _showResults = false;
  double _goldPurity = 1.0;
  double _silverPurity = 1.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.lastCalculation != null) {
      final calc = provider.lastCalculation!;
      _cashController.text = calc.cashInHand > 0 ? calc.cashInHand.toString() : '';
      _goldController.text = calc.goldWeight > 0 ? calc.goldWeight.toString() : '';
      _silverController.text = calc.silverWeight > 0 ? calc.silverWeight.toString() : '';
      _goldPurity = calc.goldPurity;
      _silverPurity = calc.silverPurity;
      _businessController.text = calc.businessAssets > 0 ? calc.businessAssets.toString() : '';
      _propertiesController.text = calc.investmentProperties > 0 ? calc.investmentProperties.toString() : '';
      _sharesController.text = calc.sharesSecurities > 0 ? calc.sharesSecurities.toString() : '';
      _receivableController.text = calc.receivableLoans > 0 ? calc.receivableLoans.toString() : '';
      _otherController.text = calc.otherZakatable > 0 ? calc.otherZakatable.toString() : '';
      _loansController.text = calc.payableLoans > 0 ? calc.payableLoans.toString() : '';
      _billsController.text = calc.outstandingBills > 0 ? calc.outstandingBills.toString() : '';
      _calculation = calc;
      _showResults = true;
    }
  }

  String _formatCurrency(double amount) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final currency = provider.metalRates?.currency ?? 'INR';
    final format = NumberFormat.decimalPattern('en_IN');
    format.maximumFractionDigits = 2;
    format.minimumFractionDigits = 2;
    return "${format.format(amount)} $currency";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = Provider.of<AppProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('calculate'.tr(context)), backgroundColor: Colors.teal, actions: [IconButton(icon: const Icon(Icons.delete_outline), onPressed: _clearForm)]),
      body: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Form(key: _formKey, child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('assets_section'.tr(context)),
              _buildTextField(_cashController, 'cash_in_hand'.tr(context), Icons.money),
              
              _buildSectionHeader('${'gold_weight'.tr(context)} & ${'purity'.tr(context)}'),
              _buildPurityDropdown(
                label: 'gold_purity'.tr(context),
                value: _goldPurity,
                items: [
                  DropdownMenuItem(value: 1.0, child: Text('karat_24'.tr(context))),
                  DropdownMenuItem(value: 0.916, child: Text('karat_22'.tr(context))),
                  DropdownMenuItem(value: 0.75, child: Text('karat_18'.tr(context))),
                  DropdownMenuItem(value: 0.585, child: Text('karat_14'.tr(context))),
                ],
                onChanged: (val) => setState(() => _goldPurity = val!),
              ),
              _buildTextField(_goldController, 'gold_weight'.tr(context), Icons.star, 'enter_weight'.tr(context)),
              
              _buildSectionHeader('${'silver_weight'.tr(context)} & ${'purity'.tr(context)}'),
              _buildPurityDropdown(
                label: 'silver_purity'.tr(context),
                value: _silverPurity,
                items: [
                  DropdownMenuItem(value: 1.0, child: Text('purity_99'.tr(context))),
                  DropdownMenuItem(value: 0.925, child: Text('purity_92'.tr(context))),
                ],
                onChanged: (val) => setState(() => _silverPurity = val!),
              ),
              _buildTextField(_silverController, 'silver_weight'.tr(context), Icons.circle, 'enter_weight'.tr(context)),
              
              _buildSectionHeader('other_zakatable'.tr(context)),
              _buildTextField(_businessController, 'business_assets'.tr(context), Icons.business),
              _buildTextField(_propertiesController, 'investment_properties'.tr(context), Icons.home_work),
              _buildTextField(_sharesController, 'shares_securities'.tr(context), Icons.trending_up),
              _buildTextField(_receivableController, 'receivable_loans'.tr(context), Icons.account_balance_wallet),
              _buildTextField(_otherController, 'other_zakatable'.tr(context), Icons.add_circle_outline),
              
              const SizedBox(height: 24),
              _buildSectionHeader('liabilities_section'.tr(context)),
              _buildTextField(_loansController, 'payable_loans'.tr(context), Icons.payment),
              _buildTextField(_billsController, 'outstanding_bills'.tr(context), Icons.receipt_long),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: provider.metalRates == null ? null : _calculateZakat,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('calculate'.tr(context), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              if (_showResults && _calculation != null) ...[
                const SizedBox(height: 32),
                _buildResultsSection(),
              ],
            ],
          ))),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)));

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, [String? hint]) {
    return Padding(padding: const EdgeInsets.only(bottom: 16.0), child: TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
      decoration: InputDecoration(labelText: label, hintText: hint ?? 'enter_amount'.tr(context), prefixIcon: Icon(icon, color: Colors.teal), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.teal, width: 2))),
    ));
  }

  Widget _buildPurityDropdown({required String label, required double value, required List<DropdownMenuItem<double>> items, required ValueChanged<double?> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<double>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.verified, color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  void _calculateZakat() {
    HapticFeedback.lightImpact();
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      final metalRates = provider.metalRates!;
      
      final calculation = ZakatCalculation(
        cashInHand: _parseDouble(_cashController.text),
        goldWeight: _parseDouble(_goldController.text),
        silverWeight: _parseDouble(_silverController.text),
        goldPurity: _goldPurity,
        silverPurity: _silverPurity,
        businessAssets: _parseDouble(_businessController.text),
        investmentProperties: _parseDouble(_propertiesController.text),
        sharesSecurities: _parseDouble(_sharesController.text),
        receivableLoans: _parseDouble(_receivableController.text),
        otherZakatable: _parseDouble(_otherController.text),
        payableLoans: _parseDouble(_loansController.text),
        outstandingBills: _parseDouble(_billsController.text),
        goldRatePerGram: metalRates.goldRatePerGram,
        silverRatePerGram: metalRates.silverRatePerGram,
        location: provider.location ?? 'Not specified',
      );

      setState(() {
        _calculation = calculation;
        _showResults = true;
      });

      // Save in background
      provider.saveCalculation(calculation);

      // Auto scroll to results
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  double _parseDouble(String text) => double.tryParse(text) ?? 0.0;
  void _clearForm() {
    _cashController.clear(); _goldController.clear(); _silverController.clear(); _businessController.clear();
    _propertiesController.clear(); _sharesController.clear(); _receivableController.clear(); _otherController.clear();
    _loansController.clear(); _billsController.clear();
    setState(() { _showResults = false; _calculation = null; });
  }

  Widget _buildResultsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: _calculation!.isEligible ? [Colors.green, Colors.lightGreen] : [Colors.orange, Colors.orangeAccent]), borderRadius: BorderRadius.circular(16)),
        child: Column(children: [Icon(_calculation!.isEligible ? Icons.check_circle : Icons.info, color: Colors.white, size: 48), const SizedBox(height: 12),
          Text(_calculation!.isEligible ? 'eligible'.tr(context) : 'not_eligible'.tr(context), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          if (_calculation!.isEligible) ...[const SizedBox(height: 8), Text('${'zakat_due'.tr(context)}: ${_formatCurrency(_calculation!.zakatDue)}', style: const TextStyle(color: Colors.white, fontSize: 20))]]),
      ),
      const SizedBox(height: 24),
      Card(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('calculation_breakdown'.tr(context), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const Divider(),
        _buildBreakdownRow('total_assets'.tr(context), _calculation!.totalAssets),
        _buildBreakdownRow('total_liabilities'.tr(context), _calculation!.totalLiabilities),
        const Divider(),
        _buildBreakdownRow('net_zakatable_wealth'.tr(context), _calculation!.netZakatableWealth, true, Colors.teal),
        _buildBreakdownRow('nisab_threshold'.tr(context), _calculation!.nisabThreshold),
        const Divider(),
        if (_calculation!.isEligible) _buildBreakdownRow('zakat_due'.tr(context), _calculation!.zakatDue, true, Colors.teal),
      ]))),
    ]);
  }

  Widget _buildBreakdownRow(String label, double value, [bool isBold = false, Color? color]) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14))), Text(_formatCurrency(value), style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14, color: color))]));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cashController.dispose(); _goldController.dispose(); _silverController.dispose();
    _businessController.dispose(); _propertiesController.dispose(); _sharesController.dispose();
    _receivableController.dispose(); _otherController.dispose(); _loansController.dispose(); _billsController.dispose();
    super.dispose();
  }
}