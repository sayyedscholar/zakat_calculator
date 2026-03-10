import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/zakat_calculation.dart';
import '../models/metal_rates.dart';
import '../services/storage_service.dart';
import '../services/rates_service.dart';
import '../services/location_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  final RatesService _ratesService = RatesService();
  final LocationService _locationService = LocationService();

  Locale _locale = const Locale('en');
  String _themeModePreference = 'system';
  MetalRates? _metalRates;
  String? _location;
  String? _countryCode;
  ZakatCalculation? _lastCalculation;
  List<ZakatCalculation> _savedCalculations = [];
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  int _selectedIndex = 0;
  bool? _isFirstLaunchValue;
  bool _isInitialized = false;

  Locale get locale => _locale;
  String get themeModePreference => _themeModePreference;
  bool get isDarkMode => _themeModePreference == 'dark';
  MetalRates? get metalRates => _metalRates;
  String? get location => _location;
  String? get countryCode => _countryCode;
  ZakatCalculation? get lastCalculation => _lastCalculation;
  List<ZakatCalculation> get savedCalculations => _savedCalculations;
  bool get isLoading => _isLoading;
  bool get notificationsEnabled => _notificationsEnabled;
  int get selectedIndex => _selectedIndex;
  bool? get isFirstLaunchValue => _isFirstLaunchValue;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint("AppProvider: Starting initialization");
      _isLoading = true;

      // 1. Critical values for UI routing - Load these first
      final isFirstLaunch = await _storageService.isFirstLaunch();
      _themeModePreference = await _storageService.getTheme();

      final savedLanguage = await _storageService.getLanguage();
      if (savedLanguage != null) {
        _locale = Locale(savedLanguage);
      }

      _isFirstLaunchValue = isFirstLaunch;
      _isInitialized = true;

      debugPrint("AppProvider: Critical initialization complete");
      notifyListeners();

      // 2. Load secondary values
      _metalRates = await _storageService.getMetalRates();
      if (_metalRates == null) {
        _metalRates = _ratesService.getLatestOfflineRates();
        await _storageService.saveMetalRates(_metalRates!);
      }

      _location = await _storageService.getLocation();
      _countryCode = await _storageService.getCountryCode();
      _lastCalculation = await _storageService.getLastCalculation();
      _savedCalculations = await _storageService.getSavedCalculations();
      _notificationsEnabled = await _storageService.getNotificationsEnabled();

      notifyListeners();

      // 3. Auto-update rates in background if online (non-blocking)
      _autoUpdateRatesIfOnline();

    } catch (e) {
      debugPrint("Initialization error: $e");
      _isFirstLaunchValue ??= false;
      _metalRates ??= _ratesService.getLatestOfflineRates();
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Auto-updates rates silently in the background if internet is available.
  /// Also auto-detects location if none is saved, and invalidates stale cache.
  Future<void> _autoUpdateRatesIfOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOnline = connectivityResult.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);

      if (isOnline) {
        debugPrint("AppProvider: Online — checking location and updating rates");

        // Auto-detect location silently if not saved
        if (_location == null && _countryCode == null) {
          await _trySilentLocationDetect();
        }

        // Force update if cache is stale (older than 8 hours)
        final bool cacheStale = _metalRates == null ||
            DateTime.now().difference(_metalRates!.lastUpdated).inHours >= 8;

        if (cacheStale) {
          debugPrint("AppProvider: Cache stale — force-refreshing rates");
          await updateMetalRates(silent: true);
        } else {
          debugPrint("AppProvider: Cache fresh — skipping auto-update");
        }
      } else {
        debugPrint("AppProvider: Offline — using cached/offline rates");
      }
    } catch (e) {
      debugPrint("AppProvider: Auto-update check failed: $e");
    }
  }

  /// Silently tries to detect GPS location without showing loading spinner.
  Future<void> _trySilentLocationDetect() async {
    try {
      final locationData = await _locationService.autoDetectLocation();
      if (locationData['location'] != null) {
        _location = locationData['location'];
        _countryCode = locationData['countryCode'];
        await _storageService.saveLocation(_location!);
        if (_countryCode != null) {
          await _storageService.saveCountryCode(_countryCode!);
        }
        debugPrint("AppProvider: Silent location detected: $_location ($_countryCode)");
      }
    } catch (e) {
      debugPrint("AppProvider: Silent location detect failed: $e");
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    await _storageService.saveLanguage(languageCode);
    notifyListeners();
  }

  Future<void> setThemeMode(String themeMode) async {
    _themeModePreference = themeMode;
    await _storageService.saveTheme(themeMode);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final nextTheme = _themeModePreference == 'light' ? 'dark' : 'light';
    await setThemeMode(nextTheme);
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  /// Fetch and update metal rates.
  /// [manualCurrency]: Override the currency (e.g. from settings).
  /// [silent]: If true, doesn't show a loading spinner (for background refresh).
  Future<bool> updateMetalRates({String? manualCurrency, bool silent = false}) async {
    try {
      if (!silent) {
        _isLoading = true;
        notifyListeners();
      }

      // Determine currency from location if not manually overridden
      String currency = manualCurrency ?? _resolveCurrency();

      // Resolve city name for city-level India adjustments
      final cityName = _extractCityName(_location);

      _metalRates = await _ratesService.fetchCurrentRates(
        currency: currency,
        cityName: cityName,
      );
      await _storageService.saveMetalRates(_metalRates!);

      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
      return true;
    } catch (e) {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
      return false;
    }
  }

  /// Resolves the correct currency in priority order:
  /// 1. Saved country code (from GPS)
  /// 2. Location text match
  /// 3. Device locale (e.g. en_IN → INR)
  /// 4. INR as safe default (never USD — most Zakat app users are not USD-based)
  String _resolveCurrency() {
    if (_countryCode != null) {
      final c = _ratesService.getCurrencyForCountry(_countryCode!);
      debugPrint("AppProvider: currency from countryCode '$_countryCode' = $c");
      return c;
    }
    if (_location != null) {
      final c = _ratesService.getCurrencyForLocation(_location!);
      if (c != 'USD') {
        debugPrint("AppProvider: currency from location '$_location' = $c");
        return c;
      }
    }
    // Fallback: try device locale (works without GPS)
    try {
      final localeStr = Platform.localeName; // e.g. "hi_IN", "en_US"
      final parts = localeStr.split('_');
      if (parts.length >= 2) {
        final localeCountry = parts.last; // "IN", "US", "PK", etc.
        final c = _ratesService.getCurrencyForCountry(localeCountry);
        if (c != 'USD') {
          debugPrint("AppProvider: currency from locale '$localeStr' = $c");
          return c;
        }
      }
    } catch (_) {}
    // Safe fallback — INR (not USD)
    return 'INR';
  }

  /// Extracts the first meaningful word/segment from a location string as city name.
  String? _extractCityName(String? location) {
    if (location == null || location.isEmpty) return null;
    // Location is typically "City, State, Country" — take first segment
    return location.split(',').first.trim();
  }

  Future<List<Map<String, dynamic>>> fetchLocationSuggestions(String query) async {
    return await _locationService.fetchLocationSuggestions(query);
  }

  Future<void> autoDetectLocation() async {
    try {
      _isLoading = true;
      notifyListeners();

      final locationData = await _locationService.autoDetectLocation();
      if (locationData['location'] != null) {
        _location = locationData['location'];
        _countryCode = locationData['countryCode'];
        await _storageService.saveLocation(_location!);
        if (_countryCode != null) {
          await _storageService.saveCountryCode(_countryCode!);
        }

        await updateMetalRates();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLocation(String location, {String? countryCode}) async {
    _location = location;
    _countryCode = countryCode;
    await _storageService.saveLocation(location);
    if (countryCode != null) {
      await _storageService.saveCountryCode(countryCode);
    }

    await updateMetalRates();
    notifyListeners();
  }

  Future<void> saveCalculation(ZakatCalculation calculation) async {
    _lastCalculation = calculation;
    await _storageService.saveLastCalculation(calculation);
    await _storageService.saveCalculation(calculation);
    _savedCalculations = await _storageService.getSavedCalculations();
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _storageService.clearAllData();
    _lastCalculation = null;
    _savedCalculations = [];
    _location = null;
    _countryCode = null;
    _isFirstLaunchValue = true;
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _notificationsEnabled = !_notificationsEnabled;
    await _storageService.setNotificationsEnabled(_notificationsEnabled);
    notifyListeners();
  }

  Future<void> setFirstLaunchDone() async {
    _isFirstLaunchValue = false;
    await _storageService.setFirstLaunchDone();
    notifyListeners();
  }
}