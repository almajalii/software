import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../model/pharmacy.dart';

class PharmacyService {
  // REPLACE WITH YOUR API KEY
  static const String _apiKey = 'AIzaSyDPD7MUIcH7GOjuuNtEmsn_NosQNj7crJk';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Get current location with better error handling
  Future<Position?> getCurrentLocation() async {
    try {
      print('🔍 Checking location services...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📍 Location service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔐 Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('⚠️ Permission denied, requesting...');
        permission = await Geolocator.requestPermission();
        print('🔐 New permission: $permission');
        
        if (permission == LocationPermission.denied) {
          print('❌ Permission denied by user');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permission denied forever');
        return null;
      }

      print('✅ Getting current position...');
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('✅ Got location: ${position.latitude}, ${position.longitude}');
      return position;
      
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  // Calculate distance between two points (in kilometers)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // Search for nearby pharmacies
  Future<List<Pharmacy>> searchNearbyPharmacies({
    required double latitude,
    required double longitude,
    int radius = 5000, // 5km radius
  }) async {
    try {
      print('🔍 Searching pharmacies near: $latitude, $longitude');
      
      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json?location=$latitude,$longitude&radius=$radius&type=pharmacy&key=$_apiKey',
      );

      print('🌐 API URL: $url');
      
      final response = await http.get(url);

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('📊 API Status: ${data['status']}');
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          print('✅ Found ${results.length} pharmacies');
          
          return results.map((json) {
            final pharmLat = json['geometry']['location']['lat'].toDouble();
            final pharmLng = json['geometry']['location']['lng'].toDouble();
            final distance = calculateDistance(latitude, longitude, pharmLat, pharmLng);
            
            return Pharmacy.fromJson(json, distance);
          }).toList()
            ..sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0)); // Sort by distance
        } else {
          print('❌ API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
      }

      return [];
    } catch (e) {
      print('❌ Error searching pharmacies: $e');
      return [];
    }
  }

  // Get place details (for phone number, etc.)
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json?place_id=$placeId&fields=formatted_phone_number,website&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }
}