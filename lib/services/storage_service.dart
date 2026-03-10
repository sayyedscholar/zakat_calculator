import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/zakat_calculation.dart';
import '../models/metal_rates.dart';

class StorageService {
  static const String _languageKey = 'selected_language';
  static const String _themeKey = 'selected_theme';
  static const String _lastCalculationKey = 'last_calculation';
  static const String _savedCalculationsKey = 'saved_calculations';
  static const String _metalRatesKey = 'metal_rates';
  static const String _locationKey = 'saved_location';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _firstLaunchKey = 'first_launch';
  static const String _countryCodeKey = 'saved_country_code';

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> saveLanguage(String languageCode) async {
    final prefs = await _getPrefs();
    await prefs.setString(_languageKey, languageCode);
  }

  Future<String?> getLanguage() async {
    final prefs = await _getPrefs();
    return prefs.getString(_languageKey);
  }

  Future<void> saveTheme(String themeMode) async {
    final prefs = await _getPrefs();
    await prefs.setString(_themeKey, themeMode);
  }

  Future<String> getTheme() async {
    final prefs = await _getPrefs();
    return prefs.getString(_themeKey) ?? 'system';
  }

  Future<void> setFirstLaunchDone() async {
    final prefs = await _getPrefs();
    await prefs.setBool(_firstLaunchKey, false);
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }

  Future<void> saveLastCalculation(ZakatCalculation calculation) async {
    final prefs = await _getPrefs();
    await prefs.setString(_lastCalculationKey, json.encode(calculation.toJson()));
  }

  Future<ZakatCalculation?> getLastCalculation() async {
    final prefs = await _getPrefs();
    final String? jsonString = prefs.getString(_lastCalculationKey);
    if (jsonString != null) {
      return ZakatCalculation.fromJson(json.decode(jsonString));
    }
    return null;
  }

  Future<void> saveCalculation(ZakatCalculation calculation) async {
    final prefs = await _getPrefs();
    final List<String> savedCalculations =
        prefs.getStringList(_savedCalculationsKey) ?? [];

    savedCalculations.insert(0, json.encode(calculation.toJson()));

    if (savedCalculations.length > 10) {
      savedCalculations.removeLast();
    }

    await prefs.setStringList(_savedCalculationsKey, savedCalculations);
  }

  Future<List<ZakatCalculation>> getSavedCalculations() async {
    final prefs = await _getPrefs();
    final List<String> savedCalculations =
        prefs.getStringList(_savedCalculationsKey) ?? [];

    return savedCalculations
        .map((jsonString) => ZakatCalculation.fromJson(json.decode(jsonString)))
        .toList();
  }

  Future<void> saveMetalRates(MetalRates rates) async {
    final prefs = await _getPrefs();
    await prefs.setString(_metalRatesKey, json.encode(rates.toJson()));
  }

  Future<MetalRates?> getMetalRates() async {
    final prefs = await _getPrefs();
    final String? jsonString = prefs.getString(_metalRatesKey);
    if (jsonString != null) {
      return MetalRates.fromJson(json.decode(jsonString));
    }
    return null;
  }

  Future<void> saveLocation(String location) async {
    final prefs = await _getPrefs();
    await prefs.setString(_locationKey, location);
  }

  Future<String?> getLocation() async {
    final prefs = await _getPrefs();
    return prefs.getString(_locationKey);
  }

  Future<void> saveCountryCode(String code) async {
    final prefs = await _getPrefs();
    await prefs.setString(_countryCodeKey, code);
  }

  Future<String?> getCountryCode() async {
    final prefs = await _getPrefs();
    return prefs.getString(_countryCodeKey);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_notificationsKey, enabled);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_notificationsKey) ?? true;
  }

  Future<void> clearAllData() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }
}