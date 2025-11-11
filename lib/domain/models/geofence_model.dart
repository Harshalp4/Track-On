class Geofence {
  final String id;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final bool isActive;
  final List<String> assignedEmployeeIds;
  final String companyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Geofence({
    required this.id,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    required this.isActive,
    required this.assignedEmployeeIds,
    required this.companyId,
    required this.createdAt,
    required this.updatedAt,
  });

  // ✅ From JSON (from API response)
  factory Geofence.fromJson(Map<String, dynamic> json) {
    return Geofence(
      id: json['id'],
      name: json['name'],
      centerLatitude: json['centerLatitude'],
      centerLongitude: json['centerLongitude'],
      radiusMeters: json['radiusMeters'],
      isActive: json['isActive'],
      assignedEmployeeIds: List<String>.from(json['assignedEmployeeIds']),
      companyId: json['companyId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // ✅ To JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'radiusMeters': radiusMeters,
      'isActive': isActive,
      'assignedEmployeeIds': assignedEmployeeIds,
      'companyId': companyId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

   static List<Geofence> getMockGeofences() {
    return [
      // Example 1: Main Office
      Geofence(
        id: 'geo_001',
        name: 'Main Office',
        centerLatitude: 19.2183,  // ✅ REPLACE with your office latitude
        centerLongitude: 72.9781, // ✅ REPLACE with your office longitude
        radiusMeters: 100.0,      // 100 meters radius
        isActive: true,
        assignedEmployeeIds: ['all'], // All employees can use this
        companyId: 'company_001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      
      // Example 2: Warehouse
      Geofence(
        id: 'geo_002',
        name: 'Warehouse',
        centerLatitude: 19.2200,  // ✅ REPLACE with your warehouse location
        centerLongitude: 72.9800,
        radiusMeters: 150.0,
        isActive: true,
        assignedEmployeeIds: ['all'],
        companyId: 'company_001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      
      // Example 3: Store #1
      Geofence(
        id: 'geo_003',
        name: 'Store #1',
        centerLatitude: 19.2150,  // ✅ REPLACE
        centerLongitude: 72.9750,
        radiusMeters: 80.0,
        isActive: true,
        assignedEmployeeIds: ['all'],
        companyId: 'company_001',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
  
  // ✅ For testing: Get current device location as a geofence (always pass)
  static Geofence getCurrentLocationAsGeofence(double lat, double lon) {
    return Geofence(
      id: 'geo_current',
      name: 'Current Location (Test)',
      centerLatitude: lat,
      centerLongitude: lon,
      radiusMeters: 500.0, // Large radius so you always pass
      isActive: true,
      assignedEmployeeIds: ['all'],
      companyId: 'company_001',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

// ✅ Location verification result
class LocationVerificationResult {
  final bool isValid;
  final Geofence? geofence;
  final double? distanceFromCenter;
  final double? accuracy;
  final String? reason;
  final Geofence? nearestGeofence;

  LocationVerificationResult({
    required this.isValid,
    this.geofence,
    this.distanceFromCenter,
    this.accuracy,
    this.reason,
    this.nearestGeofence,
  });
}