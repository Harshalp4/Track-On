// lib/domain/services/mock_geofence_data.dart

import '../models/geofence_model.dart';

class MockGeofenceData {
  // ✅ TESTING MODE: Set to true to always pass location checks
  static const bool ALWAYS_PASS_IN_TEST = false; // Change to true for easy testing
  
  // ✅ Mock geofences - Replace with your actual office locations
  static List<Geofence> getMockGeofences({double? currentLat, double? currentLon}) {
    // ✅ TEST MODE: Create geofence at current location (always pass)
    if (ALWAYS_PASS_IN_TEST && currentLat != null && currentLon != null) {
      print("🧪 TEST MODE: Using current location as geofence center");
      return [getCurrentLocationAsGeofence(currentLat, currentLon)];
    }
    
    // ✅ PRODUCTION MODE: Use actual office/site locations
    return [
      // ========================================
      // Example 1: Main Office
      // ========================================
      Geofence(
        id: 'geo_001',
        name: 'Main Office',
        // 📍 REPLACE THESE WITH YOUR ACTUAL OFFICE COORDINATES
        // To find coordinates: Right-click on Google Maps → Click on coordinates
        centerLatitude: 19.0760,   // Mumbai coordinates (example)
        centerLongitude: 72.8777,
        radiusMeters: 100.0,       // 100 meters radius
        isActive: true,
        assignedEmployeeIds: ['all'], // All employees can use this location
        companyId: 'company_001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      
      // ========================================
      // Example 2: Warehouse
      // ========================================
      Geofence(
        id: 'geo_002',
        name: 'Warehouse - Zone A',
        centerLatitude: 19.0800,   // Replace with actual coordinates
        centerLongitude: 72.8800,
        radiusMeters: 150.0,       // Larger radius for warehouse
        isActive: true,
        assignedEmployeeIds: ['all'],
        companyId: 'company_001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      
      // ========================================
      // Example 3: Store #1
      // ========================================
      Geofence(
        id: 'geo_003',
        name: 'Retail Store #1',
        centerLatitude: 19.0750,   // Replace with actual coordinates
        centerLongitude: 72.8750,
        radiusMeters: 80.0,        // Smaller radius for store
        isActive: true,
        assignedEmployeeIds: ['all'],
        companyId: 'company_001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      
      // ========================================
      // Example 4: Remote Site (Construction/Field)
      // ========================================
      Geofence(
        id: 'geo_004',
        name: 'Construction Site - Project Alpha',
        centerLatitude: 19.0900,   // Replace with actual coordinates
        centerLongitude: 72.9000,
        radiusMeters: 200.0,       // Larger radius for construction site
        isActive: true,
        assignedEmployeeIds: ['all'],
        companyId: 'company_001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      
      // ========================================
      // Add more locations as needed
      // ========================================
    ];
  }
  
  // ✅ For testing: Create a geofence at current location
  static Geofence getCurrentLocationAsGeofence(double lat, double lon) {
    return Geofence(
      id: 'geo_test_current',
      name: 'Current Location (Test Mode)',
      centerLatitude: lat,
      centerLongitude: lon,
      radiusMeters: 1000.0,  // 1km radius - very lenient for testing
      isActive: true,
      assignedEmployeeIds: ['all'],
      companyId: 'company_test',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  // ✅ Helper: Get geofence by ID
  static Geofence? getGeofenceById(String id) {
    try {
      return getMockGeofences().firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // ✅ Helper: Get geofences by company ID
  static List<Geofence> getGeofencesByCompanyId(String companyId) {
    return getMockGeofences().where((g) => g.companyId == companyId).toList();
  }
  
  // ✅ Helper: Get active geofences only
  static List<Geofence> getActiveGeofences() {
    return getMockGeofences().where((g) => g.isActive).toList();
  }
}

// ========================================
// 📝 HOW TO CONFIGURE YOUR LOCATIONS:
// ========================================
// 
// 1. Open Google Maps: https://maps.google.com
// 2. Find your office/site location
// 3. Right-click on the exact spot
// 4. Click on the coordinates (e.g., "19.0760, 72.8777")
// 5. Copy and paste into centerLatitude & centerLongitude above
// 
// 📏 RADIUS RECOMMENDATIONS:
// - Small office: 50-100 meters
// - Large office/campus: 100-200 meters
// - Warehouse: 150-300 meters
// - Construction site: 200-500 meters
// - Outdoor/parking lot: 100-200 meters
// 
// 🧪 TESTING MODES:
// - Set ALWAYS_PASS_IN_TEST = true → Always passes (uses current location)
// - Set ALWAYS_PASS_IN_TEST = false → Uses actual configured locations
// 
// ========================================