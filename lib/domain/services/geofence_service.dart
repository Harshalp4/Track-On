import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/geofence_model.dart';

class GeofenceService {
  // ✅ Calculate distance between two GPS points (Haversine formula)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // distance in meters
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // ✅ Check if location is inside geofence
  bool isInsideGeofence(
    double latitude,
    double longitude,
    Geofence geofence,
  ) {
    double distance = calculateDistance(
      latitude,
      longitude,
      geofence.centerLatitude,
      geofence.centerLongitude,
    );

    return distance <= geofence.radiusMeters;
  }

  // ✅ Find nearest geofence from a list
  Geofence? findNearestGeofence(
    double latitude,
    double longitude,
    List<Geofence> geofences,
  ) {
    if (geofences.isEmpty) return null;

    Geofence nearest = geofences.first;
    double minDistance = calculateDistance(
      latitude,
      longitude,
      nearest.centerLatitude,
      nearest.centerLongitude,
    );

    for (var fence in geofences.skip(1)) {
      double distance = calculateDistance(
        latitude,
        longitude,
        fence.centerLatitude,
        fence.centerLongitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = fence;
      }
    }

    return nearest;
  }

  // ✅ Verify location against assigned geofences
  LocationVerificationResult verifyLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    required List<Geofence> assignedGeofences,
  }) {
    for (var fence in assignedGeofences) {
      if (!fence.isActive) continue;

      double distance = calculateDistance(
        latitude,
        longitude,
        fence.centerLatitude,
        fence.centerLongitude,
      );

      if (distance <= fence.radiusMeters) {
        return LocationVerificationResult(
          isValid: true,
          geofence: fence,
          distanceFromCenter: distance,
          accuracy: accuracy,
        );
      }
    }

    // Not inside any geofence
    Geofence? nearest = findNearestGeofence(
      latitude,
      longitude,
      assignedGeofences,
    );

    return LocationVerificationResult(
      isValid: false,
      nearestGeofence: nearest,
      distanceFromCenter: nearest != null
          ? calculateDistance(
              latitude,
              longitude,
              nearest.centerLatitude,
              nearest.centerLongitude,
            )
          : null,
      reason: "Outside authorized location",
    );
  }

  // ✅ Get current device location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      // Get location
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
    } catch (e) {
      print("❌ Location error: $e");
      return null;
    }
  }

  // ✅ Check for GPS spoofing (velocity check)
  bool detectSpoofing({
    required Position currentPosition,
    required Position? lastPosition,
  }) {
    if (lastPosition == null) return false;

    double distance = calculateDistance(
      lastPosition.latitude,
      lastPosition.longitude,
      currentPosition.latitude,
      currentPosition.longitude,
    );

    int timeDiff = currentPosition.timestamp
        .difference(lastPosition.timestamp)
        .inSeconds;

    if (timeDiff == 0) return false;

    // Calculate velocity (m/s)
    double velocity = distance / timeDiff;

    // Flag if faster than 30 m/s (108 km/h)
    return velocity > 30;
  }
}