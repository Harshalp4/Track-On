import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:track_on/core/ML/RecognizerV2.dart';
import 'package:track_on/core/endpoints/base_url.dart';
import 'package:track_on/feature/auth/domain/services/secure_storage_service.dart';
import 'package:track_on/feature/face_recognition/domain/services/registered_face_for_device.dart';

Future<void> fetchNewFaceForDevice(int deviceId, RecognizerV2 recognizer) async {
  final settingsBox = await Hive.openBox('settingsBox');
  final String? deviceKey = settingsBox.get('deviceKey');

  if (deviceKey == null || deviceKey.isEmpty) {
    print('🚫 No device key found in Hive settingsBox.');
    return;
  }
  final url = Uri.parse('${BaseUrl.getNewFaceForDevice}$deviceKey');

  try {
    final token = await SecureStorageService.getAccessToken();

    if (token == null) {
      print('🚫 No access token found. User might not be logged in.');
      return;
    }

    final response = await http.get(
      url,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("📥 Response code: ${response.statusCode}");

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['success'] == true && jsonResponse['result'] != null) {
        final faceData = jsonResponse['result'];

        final int? personId = faceData['personId'];
        final int? deviceId = faceData['deviceId'];
        final String? imagePath = faceData['imagePath'];
        final String? base64 = faceData['base64'];
        final String? userName = faceData['userName'];
        final String? email = faceData['email'];
        final String? phone = faceData['phone'];

        print('🧑 Person ID: $personId');
        print('📱 Device ID: $deviceId');
        print('🖼️ Image Path: $imagePath');
        print('👤 Username: $userName');

        if (base64 != null && base64.isNotEmpty && userName != null) {
          final bytes = base64Decode(base64);

          // Check if face with this name already exists
          await recognizer.loadRegisteredFaces();
          if (recognizer.registered.containsKey(userName)) {
            print('⚠️ Face with name "$userName" already exists. Skipping registration.');
            return;
          }

          await recognizer.registerFetchedFace(
            imageBytes: bytes,
            name: userName,
            email: email ?? '',
            phone: phone ?? '',
            employeeId: personId?.toString() ?? '',
            facilityId: '',
          );

          print('✅ Successfully registered face from API: $userName');

          // Call backend to update DeviceSyncFlag
          if (personId != null && deviceId != null) {
            await registeredFaceForDevice(personId, deviceKey);
          }
        } else {
          print('⚠️ Invalid or missing image data.');
        }
      } else {
        print('⚠️ No face data found or API returned null.');
      }
    } else {
      print('❌ API request failed: ${response.statusCode}');
      print('Body: ${response.body}');
    }
  } catch (e) {
    print('🚫 Error fetching face data: $e');
  }
}

Future<String?> getDeviceIdFromServer() async {
  try {
    final settingsBox = await Hive.openBox('settingsBox');
    final String? deviceKey = settingsBox.get('deviceKey');

    if (deviceKey == null || deviceKey.isEmpty) {
      print("🚫 No device key found in Hive.");
      return null;
    }

    final token = await SecureStorageService.getAccessToken();
    if (token == null) {
      print("🚫 No access token found.");
      return null;
    }

    final url = Uri.parse('${BaseUrl.getDeviceIdFromKey}?deviceKey=$deviceKey');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['result'] != null) {
        final deviceId = data['result'].toString();
        print("📟 Device ID from server: $deviceId");
        return deviceId;
      } else {
        print("⚠️ No deviceId found in response.");
      }
    } else {
      print("❌ Failed to fetch deviceId: ${response.statusCode}");
      print("Response: ${response.body}");
    }
  } catch (e) {
    print("⚠️ Error fetching deviceId: $e");
  }
  return null;
}