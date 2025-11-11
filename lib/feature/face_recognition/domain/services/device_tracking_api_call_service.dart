import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Get local IPv4 address (non-loopback, starting with 192.)
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

Future<String> getDeviceKey() async {
  final settingsBox = Hive.box('settingsBox');
  return settingsBox.get('deviceKey', defaultValue: 'A1B2C3D4E5F6G7H8');
}

class DeviceTrackingService {
  Timer? _timer;

  final String apiUrl;

  DeviceTrackingService({required this.apiUrl});

  void start() {
    _checkInternetAndSend();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
      await _checkInternetAndSend();
    });
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _checkInternetAndSend() async {
    bool isConnected =
        await InternetConnectionChecker.createInstance().hasConnection;
    if (isConnected) {
      print("🌐 Internet available. Sending tracking data...");
      await sendTrackingData();
    } else {
      print("🚫 No internet connection. Skipping tracking.");
    }
  }

  Future<void> sendTrackingData() async {
    try {
      final url = Uri.parse(apiUrl);
      final deviceKey = await getDeviceKey();
      final localIp = await getLocalIpAddress();
      final now = DateTime.now().toUtc();
      final box = await Hive.openBox('faces');
      final personCount = box.length.toString();

     
      final Map<String, String> formData = {
        'deviceKey': deviceKey,
        'IP': localIp,
        'personCount': personCount,
        'faceCount': '0',
        'time': now.millisecondsSinceEpoch.toString(),
        'version': '1.42.0.0', 
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Tracking sent successfully at ${DateTime.now()}');
      } else {
        print('❌ Failed to send tracking: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('🚫 Exception during tracking call: $e');
    }
  }
}
