import 'package:flutter/material.dart';
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
      
      // Critical values are loaded, sets the flag
      _isFirstLaunchValue = isFirstLaunch;
      _isInitialized = true;
      
      debugPrint("AppProvider: Critical initialization complete");
      notifyListeners();

      // 2. Secondary values - load these afterwards
      _metalRates = await _storageService.getMetalRates();
      if (_metalRates == null) {
        _metalRates = _ratesService.getLatestOfflineRates();
        _storageService.saveMetalRates(_metalRates!);
      }

      _location = await _storageService.getLocation();
      _lastCalculation = await _storageService.getLastCalculation();
      _savedCalculations = await _storageService.getSavedCalculations();
      _notificationsEnabled = await _storageService.getNotificationsEnabled();
    } catch (e) {
      debugPrint("Initialization error: $e");
      // Fallback to ensure UI doesn't hang if storage fails
      _isFirstLaunchValue ??= false;
      _metalRates ??= _ratesService.getLatestOfflineRates();
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<bool> updateMetalRates({String? manualCurrency}) async {
    try {
      _isLoading = true;
      notifyListeners();

      String currency = manualCurrency ?? 'INR';
      
      // If no manual currency, try to determine from location
      if (manualCurrency == null && _location != null) {
        currency = _ratesService.getCurrencyForLocation(_location!);
      }

      _metalRates = await _ratesService.fetchCurrentRates(currency: currency);
      await _storageService.saveMetalRates(_metalRates!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
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
        await _storageService.saveLocation(_location!);
        
        // Determine currency and update rates
        String currency = 'INR';
        if (locationData['countryCode'] != null) {
          currency = _ratesService.getCurrencyForCountry(locationData['countryCode']!);
        } else {
          currency = _ratesService.getCurrencyForLocation(_location!);
        }
        
        await updateMetalRates(manualCurrency: currency);
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
    await _storageService.saveLocation(location);
    
    // Determine currency and update rates
    String currency = 'INR';
    if (countryCode != null) {
      currency = _ratesService.getCurrencyForCountry(countryCode);
    } else {
      currency = _ratesService.getCurrencyForLocation(location);
    }
    
    await updateMetalRates(manualCurrency: currency);
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