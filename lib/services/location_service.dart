import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  /// Fetch location suggestions from Nominatim (OpenStreetMap)
  Future<List<Map<String, dynamic>>> fetchLocationSuggestions(String query) async {
    if (query.length < 3) return [];

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5');
      
      final response = await http.get(url, headers: {
        'Accept-Language': 'en',
        'User-Agent': 'ZakatCalculatorApp/1.0', // Required by Nominatim policy
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final address = item['address'] as Map<String, dynamic>;
          
          // Construct a nice display name
          final cityName = address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'] ?? address['state'];
          final countryName = address['country'];
          final displayName = cityName != null ? '$cityName, $countryName' : item['display_name'];

          return {
            'display_name': displayName,
            'country_code': address['country_code']?.toString().toUpperCase(),
            'lat': item['lat'],
            'lon': item['lon'],
          };
        }).toList();
      }
    } catch (e) {
      // Handle error or timeout
    }
    return [];
  }
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
  }

  Future<String?> getLocationName(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        final List<String> parts = [];
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          parts.add(place.administrativeArea!);
        }
        if (parts.isEmpty && place.country != null && place.country!.isNotEmpty) {
          parts.add(place.country!);
        }

        final locationName = parts.join(', ');
        return locationName.isNotEmpty ? locationName : null;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<String?> getCountryCode(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        return placemarks[0].isoCountryCode;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, String?>> autoDetectLocation() async {
    try {
      final position = await getCurrentPosition();
      if (position != null) {
        final locationName = await getLocationName(position);
        final countryCode = await getCountryCode(position);
        return {
          'location': locationName,
          'countryCode': countryCode,
        };
      }
    } catch (e) {
      return {'location': null, 'countryCode': null};
    }
    return {'location': null, 'countryCode': null};
  }
}