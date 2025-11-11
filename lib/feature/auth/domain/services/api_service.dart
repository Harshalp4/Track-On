import 'package:http/http.dart' as http;
import '../../../../core/endpoints/base_url.dart';
import 'secure_storage_service.dart';

class ApiService {
  final String baseUrl = BaseUrl as String;

  Future<http.Response?> getRequest(String endpoint) async {
    String? token = await SecureStorageService.getAccessToken();
    if (token == null) return null;

    final url = Uri.parse("$baseUrl$endpoint");

    return await http.get(url, headers: {"Authorization": "Bearer $token"});
  }
}
