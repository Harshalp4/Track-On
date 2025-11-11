import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:track_on/core/endpoints/base_url.dart';
import 'package:track_on/feature/auth/domain/services/secure_storage_service.dart';

Future<void> registeredFaceForDevice(int personId, String deviceKey) async {
  final url = Uri.parse(BaseUrl.registeredFaceForDevice);

  try {
    final token = await SecureStorageService.getAccessToken();

    final response = await http.post(
      url,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'personId': personId,
        'deviceKey': deviceKey,
      }),
    );

    if (response.statusCode == 200) {
      print('✅ DeviceSyncFlag successfully updated.');
    } else {
      print('❌ Failed to update DeviceSyncFlag: ${response.body}');
    }
  } catch (e) {
    print('🚫 Error setting DeviceSyncFlag: $e');
  }
}
