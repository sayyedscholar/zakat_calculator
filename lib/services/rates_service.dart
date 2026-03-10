import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/metal_rates.dart';
import 'storage_service.dart';

class RatesService {
  final StorageService _storageService = StorageService();

  // ─── Offline Fallback Rates (Updated: March 2026) ──────────────────────────
  // Gold: ~$5,800/troy oz ≈ $187/gram. Silver: ~$34/troy oz ≈ $1.09/gram
  // INR: gold ₹16,100/gram (24K), silver ₹290/gram — verified by user
  static const Map<String, Map<String, double>> offlineRates = {
    'INR': {
      'gold': 16100.0,  // ₹ per gram (24K) - MCX/Mumbai base, Mar 2026
      'silver': 290.0,  // ₹ per gram (Retail verified)
    },
    'USD': {
      'gold': 187.0,   // $ per gram (XAU ~$5,800/troy oz)
      'silver': 1.15,  // $ per gram (Retail approx)
    },
    'GBP': {
      'gold': 145.0,   // £ per gram
      'silver': 0.89,
    },
    'SAR': {
      'gold': 701.0,   // SAR per gram
      'silver': 4.31,
    },
    'PKR': {
      'gold': 52200.0, // PKR per gram
      'silver': 320.0,
    },
    'EUR': {
      'gold': 172.0,   // € per gram
      'silver': 1.05,
    },
    'AED': {
      'gold': 687.0,   // AED per gram
      'silver': 4.22,
    },
    'BDT': {
      'gold': 20570.0, // BDT per gram
      'silver': 126.0,
    },
    'MYR': {
      'gold': 849.0,   // MYR per gram
      'silver': 5.2,
    },
    'IDR': {
      'gold': 3007000.0, // IDR per gram
      'silver': 18500.0,
    },
    'CAD': {
      'gold': 260.0,   // CAD per gram
      'silver': 1.6,
    },
    'QAR': {
      'gold': 681.0,   // QAR per gram
      'silver': 4.18,
    },
    'KWD': {
      'gold': 57.5,
      'silver': 0.35,
    },
    'BHD': {
      'gold': 70.5,
      'silver': 0.43,
    },
    'OMR': {
      'gold': 72.0,
      'silver': 0.44,
    },
  };

  // Retail premium multipliers for India (Duty + GST + Market Premium)
  // Indian gold/silver prices are significantly higher than global spot.
  // Benchmarks for Mar 2026: Gold ₹16,100/g, Silver ₹290/g.
  // Global Spot (gold-api): Gold ~$92/g, Silver ~$1.1/g.
  static const double goldRetailPremiumINR = 2.08;
  static const double silverRetailPremiumINR = 3.16;

  // ─── India City-Wise Gold Adjustment Map ────────────────────────────────────
  // Gold rates within India vary city to city due to state-specific taxes
  // (VAT, octroi, local levies). Factors are relative to base INR rate.
  // Source data cross-referenced from goodreturns.in, goldmeter.in, bullions.co.in
  static const Map<String, double> indiaCityGoldAdjustment = {
    // Maharashtra
    'mumbai': 0.0,        // Base rate (Maharashtra average)
    'pune': -0.002,       // Slightly lower
    'nagpur': -0.003,
    'nashik': -0.003,
    'aurangabad': -0.003,
    // Delhi / NCR
    'delhi': -0.005,      // Delhi typically ~0.5% lower than Mumbai
    'new delhi': -0.005,
    'gurgaon': -0.005,
    'gurugram': -0.005,
    'noida': -0.005,
    'faridabad': -0.005,
    // Tamil Nadu
    'chennai': 0.005,     // Tamil Nadu has slightly higher rates
    'coimbatore': 0.005,
    'madurai': 0.005,
    'salem': 0.004,
    // Karnataka
    'bangalore': -0.002,
    'bengaluru': -0.002,
    'mysore': -0.003,
    'mysuru': -0.003,
    // West Bengal
    'kolkata': -0.004,
    'calcutta': -0.004,
    // Andhra Pradesh / Telangana
    'hyderabad': 0.003,
    'vijayawada': 0.003,
    'visakhapatnam': 0.004,
    'vizag': 0.004,
    // Kerala
    'kochi': 0.006,       // Kerala has higher gold rates
    'cochin': 0.006,
    'thiruvananthapuram': 0.007,
    'trivandrum': 0.007,
    'calicut': 0.006,
    'kozhikode': 0.006,
    // Gujarat
    'ahmedabad': -0.003,
    'surat': -0.003,
    'vadodara': -0.003,
    'rajkot': -0.004,
    // Rajasthan
    'jaipur': -0.004,
    'jodhpur': -0.004,
    'udaipur': -0.004,
    // Uttar Pradesh
    'lucknow': -0.004,
    'kanpur': -0.005,
    'varanasi': -0.004,
    'agra': -0.005,
    'allahabad': -0.004,
    'prayagraj': -0.004,
    // Punjab / Haryana
    'chandigarh': -0.006,
    'amritsar': -0.006,
    'ludhiana': -0.006,
    // Madhya Pradesh
    'bhopal': -0.004,
    'indore': -0.003,
  };

  // ─── Fetch Current Rates (Main Entry Point) ─────────────────────────────────
  Future<MetalRates> fetchCurrentRates({
    String currency = 'INR',
    String? cityName,
  }) async {
    try {
      // Step 1: Fetch gold & silver in USD from gold-api.com (free, no key, no limit)
      final goldUsd = await _fetchMetalPriceUSD('XAU');
      final silverUsd = await _fetchMetalPriceUSD('XAG');

      if (goldUsd != null && silverUsd != null) {
        double goldPerGram;
        double silverPerGram;

        if (currency == 'USD') {
          goldPerGram = goldUsd;
          silverPerGram = silverUsd;
        } else {
          // Step 2: Convert to target currency
          final rate = await _fetchExchangeRate('USD', currency);
          if (rate != null) {
            goldPerGram = goldUsd * rate;
            silverPerGram = silverUsd * rate;
          } else {
            // Use offline cross-rate if exchange API fails
            final usdRates = offlineRates['USD']!;
            final targetRates = offlineRates[currency] ?? usdRates;
            final approxRate = targetRates['gold']! / usdRates['gold']!;
            goldPerGram = goldUsd * approxRate;
            silverPerGram = silverUsd * approxRate;
          }
        }

        // Step 3: Apply Retail Premiums (Duty + GST + Markups)
        // India has massive premiums (Duty/GST) that make retail ~2-3x global spot
        if (currency == 'INR') {
          goldPerGram *= goldRetailPremiumINR;
          silverPerGram *= silverRetailPremiumINR;
        } else {
          // General world retail premium (approx 5-10% above spot for jewelry/coins)
          goldPerGram *= 1.05;
          silverPerGram *= 1.10;
        }

        // Step 3: Apply India city-level adjustment if applicable
        if (currency == 'INR' && cityName != null) {
          final adjustment = getIndiaCityAdjustment(cityName);
          goldPerGram = goldPerGram * (1 + adjustment);
          // Silver adjustments are minimal and not city-specific in India
        }

        final rates = MetalRates(
          goldRatePerGram: goldPerGram,
          silverRatePerGram: silverPerGram,
          currency: currency,
          location: cityName,
        );
        await _storageService.saveMetalRates(rates);
        return rates;
      }
    } catch (e) {
      // Silently fall through to offline rates
    }

    return _getOfflineRates(currency, cityName: cityName);
  }

  // ─── gold-api.com — Free, No Key, No Rate Limit ─────────────────────────────
  // Returns price per troy ounce in USD. Convert: 1 troy oz = 31.1035 grams
  Future<double?> _fetchMetalPriceUSD(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.gold-api.com/price/$symbol'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Response: { "symbol": "XAU", "price": 2860.5, ... }
        final pricePerOz = (data['price'] as num?)?.toDouble();
        if (pricePerOz != null && pricePerOz > 0) {
          return pricePerOz / 31.1035; // Convert oz → gram
        }
      }
    } catch (_) {}
    return null;
  }

  // ─── exchangerate-api.com — Free, No Key, ~1500 req/month ───────────────────
  Future<double?> _fetchExchangeRate(String from, String to) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$from'),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>?;
        final rate = rates?[to];
        if (rate != null) {
          return (rate as num).toDouble();
        }
      }
    } catch (_) {}
    return null;
  }

  // ─── India City Adjustment ───────────────────────────────────────────────────
  /// Returns gold price adjustment factor for a given India city.
  /// E.g. 0.005 means 0.5% higher than base, -0.005 means 0.5% lower.
  double getIndiaCityAdjustment(String cityName) {
    final lower = cityName.toLowerCase();
    for (final entry in indiaCityGoldAdjustment.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return 0.0; // No adjustment for unknown cities
  }

  // ─── Offline Fallback ────────────────────────────────────────────────────────
  MetalRates _getOfflineRates(String currency, {String? cityName}) {
    final rates = offlineRates[currency] ?? offlineRates['USD']!;
    double goldRate = rates['gold']!;
    double silverRate = rates['silver']!;

    // Apply city adjustment even for offline rates (INR only)
    if (currency == 'INR' && cityName != null) {
      final adjustment = getIndiaCityAdjustment(cityName);
      goldRate = goldRate * (1 + adjustment);
    }

    return MetalRates(
      goldRatePerGram: goldRate,
      silverRatePerGram: silverRate,
      currency: currency,
      location: cityName,
    );
  }

  // ─── Cached Rates ────────────────────────────────────────────────────────────
  Future<MetalRates> getCachedRates() async {
    final rates = await _storageService.getMetalRates();
    return rates ?? MetalRates.defaultRates();
  }

  // ─── Currency Mapping by Location Name ──────────────────────────────────────
  String getCurrencyForLocation(String location) {
    final lower = location.toLowerCase();

    // India — check cities first since country mapping handles 'in'
    if (_isIndianCity(lower)) {
      return 'INR';
    }

    if (lower.contains('london') || lower.contains('england') ||
        lower.contains('scotland') || lower.contains('wales') ||
        lower.contains('uk') || lower.contains('united kingdom')) {
      return 'GBP';
    }

    if (lower.contains('new york') || lower.contains('chicago') ||
        lower.contains('los angeles') || lower.contains('houston') ||
        lower.contains('united states') || lower.contains(' usa')) {
      return 'USD';
    }

    if (lower.contains('dubai') || lower.contains('abu dhabi') ||
        lower.contains('sharjah') || lower.contains('uae')) {
      return 'AED';
    }

    if (lower.contains('riyadh') || lower.contains('jeddah') ||
        lower.contains('mecca') || lower.contains('makkah') ||
        lower.contains('medina') || lower.contains('saudi')) {
      return 'SAR';
    }

    if (lower.contains('karachi') || lower.contains('lahore') ||
        lower.contains('islamabad') || lower.contains('pakistan')) {
      return 'PKR';
    }

    if (lower.contains('dhaka') || lower.contains('chittagong') ||
        lower.contains('bangladesh')) {
      return 'BDT';
    }

    if (lower.contains('toronto') || lower.contains('vancouver') ||
        lower.contains('canada')) {
      return 'CAD';
    }

    if (lower.contains('kuala lumpur') || lower.contains('malaysia')) {
      return 'MYR';
    }

    if (lower.contains('jakarta') || lower.contains('indonesia')) {
      return 'IDR';
    }

    if (lower.contains('cairo') || lower.contains('egypt')) {
      return 'EGP';
    }

    if (lower.contains('doha') || lower.contains('qatar')) {
      return 'QAR';
    }

    if (lower.contains('kuwait')) {
      return 'KWD';
    }

    if (lower.contains('manama') || lower.contains('bahrain')) {
      return 'BHD';
    }

    if (lower.contains('muscat') || lower.contains('oman')) {
      return 'OMR';
    }

    if (lower.contains('sydney') || lower.contains('melbourne') ||
        lower.contains('australia')) {
      return 'AUD';
    }

    if (lower.contains('singapore')) {
      return 'SGD';
    }

    if (lower.contains('istanbul') || lower.contains('ankara') ||
        lower.contains('turkey')) {
      return 'TRY';
    }

    // European cities / countries
    if (lower.contains('berlin') || lower.contains('paris') ||
        lower.contains('rome') || lower.contains('madrid') ||
        lower.contains('amsterdam') || lower.contains('brussels') ||
        lower.contains('europe')) {
      return 'EUR';
    }

    return 'USD'; // Default
  }

  bool _isIndianCity(String lower) {
    const indianKeywords = [
      'mumbai', 'delhi', 'bangalore', 'bengaluru', 'hyderabad', 'chennai',
      'kolkata', 'calcutta', 'pune', 'ahmedabad', 'jaipur', 'surat',
      'lucknow', 'kanpur', 'nagpur', 'indore', 'bhopal', 'visakhapatnam',
      'vizag', 'vadodara', 'patna', 'kochi', 'cochin', 'thiruvananthapuram',
      'trivandrum', 'coimbatore', 'agra', 'varanasi', 'ludhiana', 'amritsar',
      'allahabad', 'prayagraj', 'chandigarh', 'mysore', 'mysuru', 'jodhpur',
      'udaipur', 'gurgaon', 'gurugram', 'noida', 'faridabad', 'nashik',
      'aurangabad', 'rajkot', 'jabalpur', 'india',
    ];
    return indianKeywords.any((kw) => lower.contains(kw));
  }

  // ─── Currency Mapping by Country Code (ISO) ─────────────────────────────────
  String getCurrencyForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'IN': { return 'INR'; }
      case 'US': { return 'USD'; }
      case 'CA': { return 'CAD'; }
      case 'GB': { return 'GBP'; }
      case 'SA': { return 'SAR'; }
      case 'QA': { return 'QAR'; }
      case 'BH': { return 'BHD'; }
      case 'OM': { return 'OMR'; }
      case 'AE': { return 'AED'; }
      case 'KW': { return 'KWD'; }
      case 'PK': { return 'PKR'; }
      case 'BD': { return 'BDT'; }
      case 'EU':
      case 'DE':
      case 'FR':
      case 'IT':
      case 'ES':
      case 'NL':
      case 'BE': { return 'EUR'; }
      case 'AU': { return 'AUD'; }
      case 'MY': { return 'MYR'; }
      case 'ID': { return 'IDR'; }
      case 'TR': { return 'TRY'; }
      case 'EG': { return 'EGP'; }
      case 'JO': { return 'JOD'; }
      case 'ZA': { return 'ZAR'; }
      case 'SG': { return 'SGD'; }
      default: { return 'USD'; }
    }
  }

  MetalRates getLatestOfflineRates({String currency = 'INR'}) {
    return _getOfflineRates(currency);
  }
}