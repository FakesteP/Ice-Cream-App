import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icecreamapp/models/user_model.dart';
import 'api_service.dart';

class UserService {
  Future<List<User>> getUsers() async {
    print('=== GET USERS FOR ADMIN ===');

    try {
      // Try different endpoints for getting users
      final endpoints = [
        '${ApiService.baseUrl}/admin/users',
        '${ApiService.baseUrl}/users',
        '${ApiService.baseUrl}/api/users',
      ];

      for (String endpoint in endpoints) {
        print('Trying users endpoint: $endpoint');

        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: await ApiService.getHeaders(),
          );

          print('Users response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final responseBody = response.body;
            print('Users response body: $responseBody');

            if (responseBody.isEmpty) {
              return [];
            }

            final dynamic decodedBody = jsonDecode(responseBody);
            List<dynamic> usersList;

            if (decodedBody is List) {
              usersList = decodedBody;
            } else if (decodedBody is Map) {
              usersList = decodedBody['data'] ??
                  decodedBody['users'] ??
                  decodedBody['results'] ??
                  [];
            } else {
              usersList = [];
            }

            print('Found ${usersList.length} users');

            List<User> users =
                usersList.map((item) => User.fromJson(item)).toList();
            return users;
          }
        } catch (e) {
          print('Error with users endpoint $endpoint: $e');
          continue;
        }
      }

      throw Exception('No working endpoint found for users');
    } catch (e) {
      print('Error in getUsers: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  Future<User> getUserById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/users/$id'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load user: $e');
    }
  }

  Future<User> updateUser(int id, Map<String, dynamic> userData) async {
    // userData bisa berisi 'username', 'email', 'password'
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/users/$id'),
      headers: await ApiService.getHeaders(),
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  // Fungsi createUser, deleteUser biasanya untuk Admin.

  // Profile Photo Methods
  Future<Map<String, dynamic>> uploadProfilePhoto(
      int userId, String base64Image, String mimeType) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/users/$userId/profile-photo'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'base64Image': base64Image,
          'mimeType': mimeType,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload profile photo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  Future<String?> getProfilePhoto(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/users/$userId/profile-photo'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['imageData']; // Returns data:image/type;base64,xxx format
      } else if (response.statusCode == 404) {
        return null; // No profile photo found
      } else {
        throw Exception('Failed to get profile photo: ${response.body}');
      }
    } catch (e) {
      print('Error getting profile photo: $e');
      return null;
    }
  }

  Future<bool> deleteProfilePhoto(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/users/$userId/profile-photo'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete profile photo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete profile photo: $e');
    }
  }

  // Get user with profile photo
  Future<User> getUserWithProfilePhoto(int id) async {
    try {
      // Get basic user data
      final user = await getUserById(id);

      // Get profile photo
      final profilePhotoBase64 = await getProfilePhoto(id);

      // Return user with profile photo data
      return User(
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
        name: user.name,
        profilePhotoBase64: profilePhotoBase64,
        profilePhotoType: profilePhotoBase64 != null
            ? _extractMimeType(profilePhotoBase64)
            : null,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      );
    } catch (e) {
      throw Exception('Failed to load user with profile photo: $e');
    }
  }

  String? _extractMimeType(String base64Data) {
    // Extract MIME type from data:image/type;base64,xxx format
    if (base64Data.startsWith('data:')) {
      final match = RegExp(r'data:([^;]+);base64,').firstMatch(base64Data);
      return match?.group(1);
    }
    return null;
  }
}
