import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icecreamapp/models/order_model.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderService {
  // Cache untuk order yang baru dibuat
  static final Map<int, Map<String, dynamic>> _orderCache = {};

  // Method to sanitize order data from backend
  Map<String, dynamic> _sanitizeOrderData(Map<String, dynamic> item) {
    print('🧹 Sanitizing order data: $item');

    // Map database field names to model field names
    return {
      'id': item['id'],
      'userid': item['userid'], // Keep database field name
      'userId': item['userid'] ?? item['userId'], // Map to camelCase
      'productid': item['productid'], // Keep database field name
      'productId': item['productid'] ?? item['productId'], // Map to camelCase
      'quantity': item['quantity'] ?? 1,
      'totalprice': item['totalprice'], // Keep database field name
      'totalPrice': item['totalprice'] ?? item['totalPrice'], // Map to camelCase
      'status': item['status'] ?? 'pending',
      'tanggal_dibuat': item['tanggal_dibuat'],
      'tanggal_diperbarui': item['tanggal_diperbarui'],
      'product': item['product'], // Include joined product data
    };
  }

  // Get all orders (Admin only)
  Future<List<Order>> getOrders() async {
    print('=== ADMIN: GET ALL ORDERS ===');

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/orders'),
        headers: await ApiService.getHeaders(),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        List<Order> orders = [];
        for (var item in data) {
          try {
            final sanitizedItem = _sanitizeOrderData(item);
            final order = Order.fromJson(sanitizedItem);
            orders.add(order);
            print('✅ Admin order parsed - ID: ${order.id}, ProductID: ${order.productId}');
          } catch (e) {
            print('❌ Error parsing admin order: $e');
            continue;
          }
        }

        print('Successfully parsed ${orders.length} admin orders');
        return orders;
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getOrders: $e');
      throw Exception('Failed to load orders: $e');
    }
  }

  // Get orders by user ID
  Future<List<Order>> getOrdersByUserId(int userId) async {
    print('=== GET ORDERS BY USER ID: $userId ===');

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/orders/user/$userId'),
        headers: await ApiService.getHeaders(),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        List<Order> orders = [];
        for (var item in data) {
          try {
            final sanitizedItem = _sanitizeOrderData(item);
            // Ensure userId is set correctly
            sanitizedItem['userId'] = userId;

            final order = Order.fromJson(sanitizedItem);
            orders.add(order);
            print('✅ User order parsed - ID: ${order.id}, ProductID: ${order.productId}, UserID: ${order.userId}');
          } catch (e) {
            print('❌ Error parsing user order: $e');
            continue;
          }
        }

        print('Successfully parsed ${orders.length} user orders');
        return orders;
      } else {
        throw Exception('Failed to load user orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getOrdersByUserId: $e');
      throw Exception('Failed to load user orders: $e');
    }
  }

  // Get single order by ID
  Future<Order> getOrderById(int id) async {
    print('=== GET ORDER BY ID: $id ===');

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/orders/$id'),
        headers: await ApiService.getHeaders(),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final sanitizedItem = _sanitizeOrderData(data);
        return Order.fromJson(sanitizedItem);
      } else {
        throw Exception('Failed to load order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getOrderById: $e');
      rethrow;
    }
  }

  // Create new order
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    print('=== CREATE ORDER ===');
    print('Input data: $orderData');

    try {
      // Get userId from SharedPreferences if not provided
      final prefs = await SharedPreferences.getInstance();
      final userId = orderData['userId'] ?? prefs.getInt('userId');
      final productId = orderData['productId'];

      // Validate required fields
      if (userId == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      if (productId == null || productId <= 0) {
        return {'success': false, 'message': 'Invalid product ID'};
      }

      final completeOrderData = {
        'userId': userId,
        'productId': productId,
        'quantity': orderData['quantity'] ?? 1,
        'totalPrice': orderData['totalPrice'] ?? 0.0,
        'status': 'pending',
      };

      print('Sending order data: $completeOrderData');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/orders'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode(completeOrderData),
      );

      print('Create response status: ${response.statusCode}');
      print('Create response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final sanitizedItem = _sanitizeOrderData(responseData);
        final order = Order.fromJson(sanitizedItem);

        print('✅ Order created successfully - ID: ${order.id}');

        return {
          'success': true,
          'order': order,
          'message': 'Order created successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to create order',
        };
      }
    } catch (e) {
      print('Error in createOrder: $e');
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Update order
  Future<Order> updateOrder(int id, Order order) async {
    print('=== UPDATE ORDER: $id ===');

    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/orders/$id'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode(order.toJson()),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final sanitizedItem = _sanitizeOrderData(responseData);
        return Order.fromJson(sanitizedItem);
      } else {
        throw Exception('Failed to update order: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateOrder: $e');
      rethrow;
    }
  }

  // Update order status (Admin only)
  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String newStatus) async {
    print('=== UPDATE ORDER STATUS: $orderId -> $newStatus ===');

    try {
      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/orders/$orderId/status'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({'status': newStatus}),
      );

      print('Update status response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Order status updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update order status',
        };
      }
    } catch (e) {
      print('Error in updateOrderStatus: $e');
      return {
        'success': false,
        'message': 'Error updating order status: $e',
      };
    }
  }

  // Delete order
  Future<bool> deleteOrder(int id) async {
    print('=== DELETE ORDER: $id ===');

    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/orders/$id'),
        headers: await ApiService.getHeaders(),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error in deleteOrder: $e');
      return false;
    }
  }

  // Clear old cache entries
  static void clearOldCache() {
    final now = DateTime.now();
    _orderCache.removeWhere((key, value) {
      if (value['createdAt'] != null) {
        final createdAt = DateTime.parse(value['createdAt']);
        return now.difference(createdAt).inHours > 1;
      }
      return true;
    });
  }
}
