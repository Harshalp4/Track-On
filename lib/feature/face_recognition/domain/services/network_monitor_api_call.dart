import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:track_on/core/endpoints/base_url.dart';
import 'package:track_on/feature/face_recognition/domain/services/fetch_new_face_from_device.dart';
import 'package:track_on/feature/face_recognition/domain/services/liveness_detector_service.dart';

final LivenessDetectionService livenessService = LivenessDetectionService();

Future<String> getLocalIpAddress() async {
  try {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 &&
            !addr.isLoopback &&
            addr.address.startsWith('192.')) {
          return addr.address;
        }
      }
    }
  } catch (e) {
    print("Error getting IP address: $e");
  }
  return 'Unknown';
}

// Get device key from Hive
Future<String> getDeviceKey() async {
  final settingsBox = Hive.box('settingsBox');
  return settingsBox.get('deviceKey', defaultValue: 'A1B2C3D4E5F6G7H8');
}

// Get facility ID from Hive
Future<String> getFacilityId() async {
  final settingsBox = Hive.box('settingsBox');
  return settingsBox.get('facilityId', defaultValue: '1');
}

void monitorAndSend() {
  InternetConnectionChecker.createInstance().onStatusChange.listen((status) {
    if (status == InternetConnectionStatus.connected) {
      print("🌐 Internet available. Sending data...");
      sendDataToApi(type: 'null', faceImage: null, employeeId: '');
    } else {
      print("🚫 Internet lost.");
    }
  });
}

Future<void> sendDataToApi({
  required String type,
  required Uint8List? faceImage,
  required String employeeId,
}) async {
  final isDeviceConnected =
      await InternetConnectionChecker.createInstance().hasConnection;

  if (!isDeviceConnected) {
    print('🚫 No working internet connection. Skipping request.');
    return;
  }

  try {
    final url = Uri.parse(BaseUrl.getTimeLog);
    final request = http.MultipartRequest('POST', url);
    final localIp = await getLocalIpAddress();
    final deviceKey = await getDeviceKey();
    final facilityId = await getFacilityId();
    final deviceId = await getDeviceIdFromServer() ?? '';
    DateTime now = DateTime.now().toUtc();

    // Encode face image if available
    String base64Image = (faceImage != null && faceImage.isNotEmpty)
        ? 'data:image/jpeg;base64,${base64Encode(faceImage)}'
        : '';

    // Set request fields
    request.fields['searchScore'] = '0.5';
    request.fields['ip'] = localIp;
    request.fields['deviceKey'] = deviceKey;
    request.fields['type'] = type;
    request.fields['token'] = 'ABCDEF1234567890XYZ';
    request.fields['imagePath'] =
        'https://bit2skyfrstoragenew.blob.core.windows.net/facecontainer/Stranger_xyz';
    request.fields['mask'] = '0';
    request.fields['livenessScore'] = '0.8';
    request.fields['imgBase64'] = base64Image;
    request.fields['personId'] = employeeId; // <-- Use dynamic employee ID
    request.fields['time'] = now.millisecondsSinceEpoch.toString();
    request.fields['timeStamp'] = now.toIso8601String();
    request.fields['deviceId'] = deviceId;
    // request.fields['facilityId'] = facilityId;

    print('🧑 Person ID in timelogs: $employeeId');

    // Send request
    final response = await request.send();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final respStr = await response.stream.bytesToString();
      print('✅ Success: $respStr');
    } else {
      final respStr = await response.stream.bytesToString();
      print('❌ Failed: ${response.statusCode}');
      print('Response: $respStr');
    }
  } catch (e) {
    print('❗ Unexpected network error: $e');
  }
}
