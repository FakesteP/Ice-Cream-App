import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icecreamapp/models/product_model.dart';
import 'api_service.dart';

class ProductService {
  Future<List<Product>> getProducts() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/products'),
      headers: await ApiService.getHeaders(useAuth: false), // Endpoint publik
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Product> products =
          body.map((dynamic item) => Product.fromJson(item)).toList();
      return products;
    } else {
      throw Exception('Failed to load products: ${response.body}');
    }
  }

  // Add this method to get product name by ID
  Future<String> getProductNameById(int productId) async {
    try {
      // Add validation for productId
      if (productId <= 0) {
        print('❌ ProductService: Invalid productId: $productId');
        throw Exception('Invalid product ID');
      }

      print('🔍 ProductService: Fetching product name for ID: $productId');
      print('🔗 API URL: ${ApiService.baseUrl}/products/$productId');

      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/products/$productId'),
            headers: await ApiService.getHeaders(
                useAuth: false), // Use same headers as getProducts
          )
          .timeout(const Duration(seconds: 10));

      print('📡 ProductService Response Status: ${response.statusCode}');
      print('📡 ProductService Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        print('📋 Parsed response data: $responseData');
        print('📋 Response data type: ${responseData.runtimeType}');

        // Handle different possible response structures
        String productName;

        if (responseData is Map<String, dynamic>) {
          final Map<String, dynamic> data = responseData;

          if (data.containsKey('data') && data['data'] != null) {
            final productData = data['data'];
            print('📦 Product data from "data" field: $productData');
            productName = productData['name']?.toString() ?? 'Unknown Product';
          } else if (data.containsKey('name')) {
            print('📦 Product data direct access: $data');
            productName = data['name']?.toString() ?? 'Unknown Product';
          } else {
            print('❌ Product name not found in response structure');
            print('📋 Available keys: ${data.keys.toList()}');
            throw Exception('Product name not found in response');
          }
        } else if (responseData is List) {
          print('📋 Response is a list, taking first item');
          if (responseData.isNotEmpty &&
              responseData.first is Map<String, dynamic>) {
            final Map<String, dynamic> data = responseData.first;
            productName = data['name']?.toString() ?? 'Unknown Product';
          } else {
            throw Exception('Invalid list response structure');
          }
        } else {
          throw Exception(
              'Unexpected response format: ${responseData.runtimeType}');
        }

        print('✅ ProductService: Product name found: $productName');
        return productName;
      } else if (response.statusCode == 404) {
        print('❌ ProductService: Product not found with ID: $productId');
        throw Exception('Product not found');
      } else {
        print('❌ ProductService: Server error: ${response.statusCode}');
        print('❌ Error response body: ${response.body}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ProductService Error in getProductNameById: $e');
      print('❌ Error type: ${e.runtimeType}');

      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout - please try again');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('Network error - check your connection');
      } else if (e.toString().contains('Invalid product ID')) {
        throw Exception('Invalid product ID: $productId');
      }
      rethrow;
    }
  }

  Future<Product> getProductById(int id) async {
    try {
      print('🔍 Fetching full product details for ID: $id');

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/products/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('📡 getProductById Response Status: ${response.statusCode}');
      print('📡 getProductById Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // Handle different response structures
        Map<String, dynamic> productData;
        if (jsonData.containsKey('data') && jsonData['data'] != null) {
          productData = jsonData['data'];
        } else if (jsonData.containsKey('id')) {
          productData = jsonData;
        } else {
          throw Exception('Invalid response structure');
        }

        final product = Product.fromJson(productData);
        print('✅ Successfully parsed product: ${product.name}');
        return product;
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in getProductById: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createProduct(
      Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/products'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode(productData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'product': Product.fromJson(jsonDecode(response.body)),
          'message': 'Product created successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateProduct(
      int id, Map<String, dynamic> productData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/products/$id'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode(productData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'product': Product.fromJson(jsonDecode(response.body)),
          'message': 'Product updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/products/$id'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Successfully deleted
        return;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete product');
      }
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Alternative method that returns success/failure status
  Future<Map<String, dynamic>> deleteProductWithStatus(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/products/$id'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Product deleted successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
