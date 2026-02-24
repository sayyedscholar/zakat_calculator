import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/metal_rates.dart';
import 'storage_service.dart';

class RatesService {
  final StorageService _storageService = StorageService();

  // FREE API Options (No API key needed for basic usage):
  // 1. GoldAPI.io - 100 free requests/month
  // 2. Metals-API - 50 free requests/month
  // 3. CurrencyAPI with gold/silver

  // Latest offline rates (Updated: Feb 2024)
  static const Map<String, Map<String, double>> offlineRates = {
    'INR': {
      'gold': 6500.0,  // ₹ per gram (24K)
      'silver': 80.0,  // ₹ per gram
    },
    'USD': {
      'gold': 75.0,  // $ per gram
      'silver': 0.95, // $ per gram
    },
    'GBP': {
      'gold': 60.0,  // £ per gram
      'silver': 0.75, // £ per gram
    },
    'SAR': {
      'gold': 280.0,  // SAR per gram
      'silver': 3.5,  // SAR per gram
    },
    'PKR': {
      'gold': 20000.0,  // PKR per gram
      'silver': 250.0,  // PKR per gram
    },
    'EUR': {
      'gold': 70.0,  // € per gram
      'silver': 0.88, // € per gram
    },
    'AED': {
      'gold': 275.0,  // AED per gram
      'silver': 3.4,  // AED per gram
    },
  };

  /// Fetch current gold and silver rates
  Future<MetalRates> fetchCurrentRates({String currency = 'INR'}) async {
    try {
      // Try multiple free APIs in order
      MetalRates? rates;

      // Try Method 1: GoldAPI (100 free requests/month)
      rates = await _tryGoldAPI(currency);
      if (rates != null) {
        await _storageService.saveMetalRates(rates);
        return rates;
      }

      // Try Method 2: Metals-API (50 free requests/month)
      rates = await _tryMetalsAPI(currency);
      if (rates != null) {
        await _storageService.saveMetalRates(rates);
        return rates;
      }

      // Fallback to offline rates
      return _getOfflineRates(currency);

    } catch (e) {
      return _getOfflineRates(currency);
    }
  }

  /// Try GoldAPI.io (FREE - No API key needed for basic)
  Future<MetalRates?> _tryGoldAPI(String currency) async {
    try {
      // Using free endpoint (limited to 100 requests/month)
      final response = await http.get(
        Uri.parse('https://www.goldapi.io/api/XAU/$currency'),
        headers: {'x-access-token': 'goldapi-11ff6apsmlrweov3-io'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // GoldAPI returns price per troy ounce, convert to grams
        double goldPerOunce = data['price']?.toDouble() ?? 0;
        double goldPerGram = goldPerOunce / 31.1035; // 1 troy oz = 31.1035 grams

        // Silver rate estimate (since free API doesn't include silver)
        // Using typical gold:silver ratio of ~80:1
        double silverPerGram = goldPerGram / 80;

        return MetalRates(
          goldRatePerGram: goldPerGram,
          silverRatePerGram: silverPerGram,
          currency: currency,
        );
      }
    } catch (e) {
      // API failure
    }
    return null;
  }

  /// Try Metals-API (FREE - 50 requests/month)
  Future<MetalRates?> _tryMetalsAPI(String currency) async {
    try {
      // Using free tier (50 requests/month)
      // Sign up at https://metals-api.com for free API key
      final response = await http.get(
        Uri.parse('https://metals-api.com/api/latest?access_key=YOUR_FREE_KEY&base=$currency&symbols=XAU,XAG'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Metals-API returns inverse rates, so we need to calculate
          double goldRate = 1 / (data['rates']['XAU'] * 31.1035);
          double silverRate = 1 / (data['rates']['XAG'] * 31.1035);

          return MetalRates(
            goldRatePerGram: goldRate,
            silverRatePerGram: silverRate,
            currency: currency,
          );
        }
      }
    } catch (e) {
      // API failure
    }
    return null;
  }

  /// Get offline rates as fallback
  MetalRates _getOfflineRates(String currency) {
    final rates = offlineRates[currency] ?? offlineRates['INR']!;

    return MetalRates(
      goldRatePerGram: rates['gold']!,
      silverRatePerGram: rates['silver']!,
      currency: currency,
    );
  }

  /// Get cached rates from storage
  Future<MetalRates> getCachedRates() async {
    final rates = await _storageService.getMetalRates();
    return rates ?? MetalRates.defaultRates();
  }

  /// Currency mapping by country code or popular cities
  String getCurrencyForLocation(String location) {
    final lowerLocation = location.toLowerCase();
    
    // City-based mapping for high-priority areas
    if (lowerLocation.contains('mumbai') || 
        lowerLocation.contains('lucknow') || 
        lowerLocation.contains('kolkata') ||
        lowerLocation.contains('delhi') ||
        lowerLocation.contains('bangalore')) {
      return 'INR';
    }
    
    if (lowerLocation.contains('london')) return 'GBP';
    if (lowerLocation.contains('new york') || lowerLocation.contains('chicago')) return 'USD';
    if (lowerLocation.contains('dubai')) return 'AED';
    if (lowerLocation.contains('riyadh')) return 'SAR';
    if (lowerLocation.contains('karachi') || lowerLocation.contains('lahore')) return 'PKR';
    if (lowerLocation.contains('dhaka')) return 'BDT';

    return 'USD'; // Default fallback
  }

  /// Currency mapping by country code (ISO)
  String getCurrencyForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'IN':
        return 'INR';
      case 'US':
        return 'USD';
      case 'CA':
        return 'CAD';
      case 'GB':
        return 'GBP';
      case 'SA':
        return 'SAR';
      case 'QA':
        return 'QAR';
      case 'BH':
        return 'BHD';
      case 'OM':
        return 'OMR';
      case 'AE':
        return 'AED';
      case 'KW':
        return 'KWD';
      case 'PK':
        return 'PKR';
      case 'BD':
        return 'BDT';
      case 'EU':
      case 'DE':
      case 'FR':
      case 'IT':
      case 'ES':
      case 'NL':
      case 'BE':
        return 'EUR';
      case 'AU':
        return 'AUD';
      case 'MY':
        return 'MYR';
      case 'ID':
        return 'IDR';
      case 'TR':
        return 'TRY';
      case 'EG':
        return 'EGP';
      case 'JO':
        return 'JOD';
      case 'ZA':
        return 'ZAR';
      case 'SG':
        return 'SGD';
      default:
        return 'USD';
    }
  }

  /// Get latest offline rates for immediate use
  MetalRates getLatestOfflineRates({String currency = 'INR'}) {
    return _getOfflineRates(currency);
  }
}