// lib/domain/services/location_api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/geofence_model.dart';
import 'mock_geofence_data.dart';

class LocationApiService {
  // ✅ Toggle between mock and real API
  static const bool USE_MOCK_DATA = true; // Change to false when backend is ready
  
  // ✅ Get employee's assigned geofences
  Future<List<Geofence>> getAssignedGeofences(String employeeId) async {
    // ✅ MOCK MODE: Return hardcoded geofences
    if (USE_MOCK_DATA) {
      print("📍 Using MOCK geofence data (no API call)");
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      return MockGeofenceData.getMockGeofences();
    }
    
    // ✅ Real API call (for later when .NET backend is ready)
    try {
      // Get token from Hive
      final authBox = await Hive.openBox('authBox');
      final token = authBox.get('accessToken', defaultValue: '');
      
      // Get base URL from Hive or use default
      final settingsBox = await Hive.openBox('settingsBox');
      final baseUrl = settingsBox.get('apiBaseUrl', defaultValue: 'https://your-api.com');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/geofences/employee/$employeeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> geofencesJson = data['geofences'] ?? [];
        return geofencesJson.map((json) => Geofence.fromJson(json)).toList();
      } else {
        print('❌ Failed to load geofences: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching geofences: $e');
      return [];
    }
  }

  // ✅ Log location verification
  Future<bool> logLocationVerification({
    required String employeeId,
    required double latitude,
    required double longitude,
    required double accuracy,
    required bool isValid,
    required String? geofenceId,
    required double? distance,
  }) async {
    // ✅ MOCK MODE: Just log to console
    if (USE_MOCK_DATA) {
      print("📝 MOCK: Location verification logged");
      print("   Employee: $employeeId");
      print("   Location: $latitude, $longitude");
      print("   Valid: $isValid");
      print("   Geofence: $geofenceId");
      print("   Distance: ${distance?.toStringAsFixed(0)}m");
      return true;
    }
    
    // ✅ Real API call (for later)
    try {
      // Get token from Hive
      final authBox = await Hive.openBox('authBox');
      final token = authBox.get('accessToken', defaultValue: '');
      
      // Get base URL from Hive
      final settingsBox = await Hive.openBox('settingsBox');
      final baseUrl = settingsBox.get('apiBaseUrl', defaultValue: 'https://your-api.com');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/location/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'employeeId': employeeId,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'isValid': isValid,
          'geofenceId': geofenceId,
          'distanceFromCenter': distance,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error logging location: $e');
      return false;
    }
  }

  // ✅ Report location violation
  Future<void> reportViolation({
    required String employeeId,
    required double latitude,
    required double longitude,
    required String reason,
  }) async {
    // ✅ MOCK MODE: Just log to console
    if (USE_MOCK_DATA) {
      print("🚨 MOCK: Violation reported");
      print("   Employee: $employeeId");
      print("   Location: $latitude, $longitude");
      print("   Reason: $reason");
      return;
    }
    
    // ✅ Real API call (for later)
    try {
      // Get token from Hive
      final authBox = await Hive.openBox('authBox');
      final token = authBox.get('accessToken', defaultValue: '');
      
      // Get base URL from Hive
      final settingsBox = await Hive.openBox('settingsBox');
      final baseUrl = settingsBox.get('apiBaseUrl', defaultValue: 'https://your-api.com');
      
      await http.post(
        Uri.parse('$baseUrl/api/location/violation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'employeeId': employeeId,
          'latitude': latitude,
          'longitude': longitude,
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      
      print("✅ Violation reported to server");
    } catch (e) {
      print('❌ Error reporting violation: $e');
    }
  }
  
  // ✅ Get all geofences for admin/manager (for future use)
  Future<List<Geofence>> getAllGeofences() async {
    if (USE_MOCK_DATA) {
      return MockGeofenceData.getMockGeofences();
    }
    
    try {
      final authBox = await Hive.openBox('authBox');
      final token = authBox.get('accessToken', defaultValue: '');
      
      final settingsBox = await Hive.openBox('settingsBox');
      final baseUrl = settingsBox.get('apiBaseUrl', defaultValue: 'https://your-api.com');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/geofences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Geofence.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Error fetching all geofences: $e');
      return [];
    }
  }
  
  // ✅ Create new geofence (for admin panel - future use)
  Future<bool> createGeofence(Geofence geofence) async {
    if (USE_MOCK_DATA) {
      print("📍 MOCK: Geofence created - ${geofence.name}");
      return true;
    }
    
    try {
      final authBox = await Hive.openBox('authBox');
      final token = authBox.get('accessToken', defaultValue: '');
      
      final settingsBox = await Hive.openBox('settingsBox');
      final baseUrl = settingsBox.get('apiBaseUrl', defaultValue: 'https://your-api.com');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/geofences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(geofence.toJson()),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('❌ Error creating geofence: $e');
      return false;
    }
  }
  
  // ✅ Update geofence (for admin panel - future use)
  Future<bool> updateGeofence(Geofence geofence) async {
    if (USE_MOCK_DATA) {
      print("📍 MOCK: Geofence updated - ${geofence.name}");
      return true;
    }
    
    try {
      final authBox = await Hive.openBox('authBox');
      final token = authBox.get('accessToken', defaultValue: '');
      
      final settingsBox = await Hive.openBox('settingsBox');
      final baseUrl = settingsBox.get('apiBaseUrl', defaultValue: 'https://your-api.com');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/geofences/${geofence.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(geofence.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error updating geofence: $e');
      return false;
    }
  }
  
  // ✅ Delete geofence (for admin panel - future use)
  Future<bool> deleteGeofence(String geofenceId) async {
    if (USE_MOCK_DATA) {
      print("📍 MOCK: Geofence deleted - $geofenceId");
      return true;
    }
    
    try {
      final authBox = await Hive.openBox('authBox');
      final token = authBox.get('accessToken', defaultValue: '');
      
      final settingsBox = await Hive.openBox('settingsBox');
      final baseUrl = settingsBox.get('apiBaseUrl', defaultValue: 'https://your-api.com');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/geofences/$geofenceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('❌ Error deleting geofence: $e');
      return false;
    }
  }
}