import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:track_on/core/endpoints/base_url.dart';
import 'secure_storage_service.dart';

class AuthService {
  Future<bool> login(String username, String password) async {
    final url = Uri.parse(BaseUrl.login);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userNameOrEmailAddress": username,
        "password": password,
        "rememberClient": true
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['result'];
      if (data != null) {
        await SecureStorageService.saveToken(data['accessToken'], data['refreshToken']);
        return true;
      }
    }
    return false;
  }

  Future<bool> isLoggedIn() async {
  String? token = await SecureStorageService.getAccessToken();
  return token != null;
}


  Future<void> logout() async {
    await SecureStorageService.clearTokens();
  }
}
