import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:icecreamapp/models/user_model.dart';
import 'api_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    print('=== AUTH SERVICE LOGIN ===');
    print('Attempting login for email: $email');

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Parsed login response: $responseData');

        final token = responseData['token'];
        final user = responseData['user'];

        if (token != null && user != null) {
          final prefs = await SharedPreferences.getInstance();

          // Store token
          await prefs.setString('token', token);
          print('✅ Stored token');

          // Store user data
          final userId = user['id'] as int; // Direct cast since we expect int
          final userName = user['name'] ?? user['username'] ?? 'Unknown';
          final userEmail = user['email'];
          final userRole = user['role'] ?? 'customer';

          print('=== STORING USER DATA ===');
          print('User ID: $userId');
          print('User Name: $userName');
          print('User Email: $userEmail');
          print('User Role: $userRole');

          // Store all user data
          await prefs.setInt('userId', userId);
          await prefs.setString('userName', userName);
          await prefs.setString('userEmail', userEmail);
          await prefs.setString('userRole', userRole);

          print('✅ All user data stored successfully');

          return {
            'success': true,
            'token': token,
            'user': user,
            'role': userRole,
            'userId': userId,
            'message': 'Login successful',
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid response format',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    print('=== AUTH SERVICE REGISTER DEBUG ===');
    print('Input name: "$name"');
    print('Input email: "$email"');
    print('Input password length: ${password.length}');

    // Prepare registration data with all required fields
    final registrationData = {
      'username': name.trim(), // Backend expects 'username' not 'name'
      'email': email.trim(),
      'password': password,
      'role': 'customer', // Default role for new registrations
    };

    print('=== REGISTRATION DATA TO SEND ===');
    print('Registration data: $registrationData');

    try {
      final headers = await ApiService.getHeaders(
          useAuth: false); // No auth needed for registration
      print('Request headers: $headers');
      print('Request URL: ${ApiService.baseUrl}/auth/register');
      print('Request body JSON: ${jsonEncode(registrationData)}');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/register'),
        headers: headers,
        body: jsonEncode(registrationData),
      );

      print('=== REGISTRATION RESPONSE ===');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Registration successful');
        print('Response data: $responseData');

        return {
          'success': true,
          'message': responseData['message'] ??
              'Registration successful! Please login with your credentials.',
          'user': responseData['user'],
        };
      } else {
        print('❌ Registration failed with status: ${response.statusCode}');

        try {
          final errorData = jsonDecode(response.body);
          print('Error details: $errorData');

          String errorMessage = 'Registration failed.';

          // Handle specific database constraint errors
          if (response.body.contains('username') &&
              response.body.contains('null')) {
            errorMessage = 'Username is required and cannot be empty.';
          } else if (response.body.contains('role') &&
              response.body.contains('null')) {
            errorMessage = 'User role assignment failed. Please try again.';
          } else if (response.body.contains('email') &&
              response.body.contains('unique')) {
            errorMessage =
                'Email already exists. Please use a different email.';
          } else if (response.body.contains('username') &&
              response.body.contains('unique')) {
            errorMessage =
                'Username already exists. Please choose a different name.';
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }

          return {
            'success': false,
            'message': errorMessage,
          };
        } catch (jsonError) {
          print('Error parsing error response: $jsonError');
          return {
            'success': false,
            'message':
                'Registration failed. Please check your input and try again.',
          };
        }
      }
    } catch (e) {
      print('❌ Network/Exception error in register: $e');
      return {
        'success': false,
        'message':
            'Network error occurred. Please check your connection and try again.',
      };
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final userName = prefs.getString('userName');
      final userEmail = prefs.getString('userEmail');
      final userRole = prefs.getString('userRole');

      if (userId != null && userEmail != null && userRole != null) {
        return User(
          id: userId,
          username: userName ?? 'User',
          email: userEmail,
          role: userRole,
        );
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✅ User logged out and all data cleared');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('userId');
    return token != null && userId != null;
  }

  // Update user profile in database
  Future<Map<String, dynamic>> updateUser({
    required int userId,
    String? username,
    String? email,
    String? password,
  }) async {
    print('=== AUTH SERVICE UPDATE USER ===');
    print('Updating user ID: $userId');
    print('New username: $username');
    print('New email: $email');

    try {
      final headers = await ApiService.getHeaders(useAuth: true);

      // Prepare update data - only include non-null fields
      final updateData = <String, dynamic>{};
      if (username != null && username.trim().isNotEmpty) {
        updateData['username'] = username.trim();
      }
      if (email != null && email.trim().isNotEmpty) {
        updateData['email'] = email.trim();
      }
      if (password != null && password.trim().isNotEmpty) {
        updateData['password'] = password.trim();
      }

      print('Update data: $updateData');

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/users/$userId'),
        headers: headers,
        body: jsonEncode(updateData),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Update local storage with new data
        final prefs = await SharedPreferences.getInstance();
        if (username != null) {
          await prefs.setString('userName', username.trim());
        }
        if (email != null) {
          await prefs.setString('userEmail', email.trim());
        }

        print('✅ User profile updated successfully');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      print('Update user error: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get user by ID from database
  Future<User?> getUserById(int userId) async {
    print('=== AUTH SERVICE GET USER BY ID ===');
    print('Fetching user ID: $userId');

    try {
      final headers = await ApiService.getHeaders(useAuth: true);

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/users/$userId'),
        headers: headers,
      );

      print('Get user response status: ${response.statusCode}');
      print('Get user response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return User.fromJson(responseData);
      } else {
        print('Failed to get user: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }
}
