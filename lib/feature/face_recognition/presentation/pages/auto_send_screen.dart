import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AutoSendScreen extends StatefulWidget {
  @override
  _AutoSendScreenState createState() => _AutoSendScreenState();
}

class _AutoSendScreenState extends State<AutoSendScreen> {
  late StreamSubscription internetSubscription;

  @override
  void initState() {
    super.initState();

    internetSubscription = InternetConnectionChecker.createInstance().onStatusChange.listen((status) {
      final hasInternet = status == InternetConnectionStatus.connected;
      if (hasInternet) {
        sendDataToApi();
      }
    });
  }

  @override
  void dispose() {
    internetSubscription.cancel();
    super.dispose();
  }

  Future<void> sendDataToApi() async {
    final isDeviceConnected = await InternetConnectionChecker.createInstance().hasConnection;

    if (!isDeviceConnected) {
      print('🚫 No working internet connection. Skipping request.');
      return;
    }

    try {
      final url = Uri.parse('https://cims-trackon-api.azurewebsites.net/api/services/app/Timelogs/GetTimeLog');
      final request = http.MultipartRequest('POST', url);

      request.fields['searchScore'] = '0.5';
      request.fields['ip'] = '192.168.0.101';
      request.fields['deviceKey'] = 'A1B2C3D4E5F6G7H8';
      request.fields['type'] = 'face_2';
      request.fields['token'] = 'ABCDEF1234567890XYZ';
      request.fields['imagePath'] = 'https://bit2skyfrstoragenew.blob.core.windows.net/facecontainer/Stranger_xyz';
      request.fields['mask'] = '0';
      request.fields['livenessScore'] = '0.3';
      request.fields['imgBase64'] = '';
      request.fields['personId'] = '999';
      request.fields['time'] = '1720454875620';
      request.fields['timeStamp'] = '2024-07-08T12:07:55.620Z';
      request.fields['deviceId'] = '1';
      request.fields['facilityId'] = '2';

      final response = await request.send();

      final respStr = await response.stream.bytesToString();
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Success: $respStr');
      } else {
        print('❌ Failed: ${response.statusCode}');
        print('Response: $respStr');
      }
    } catch (e) {
      print('❗ Unexpected network error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Auto API Trigger")),
      body: Center(child: Text("Waiting for internet to auto-send data...")),
    );
  }
}
