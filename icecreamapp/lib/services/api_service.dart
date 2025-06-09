import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      "https://api-ice-cream-1061342868557.us-central1.run.app";

  static Future<Map<String, String>> getHeaders({bool useAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (useAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static String get frankfurterApiUrl => "https://api.frankfurter.dev/v1";
}
