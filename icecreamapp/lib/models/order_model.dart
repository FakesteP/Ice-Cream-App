import 'package:icecreamapp/models/product_model.dart';
import 'package:icecreamapp/models/user_model.dart';

class Order {
  final int id;
  final int? userId;
  final int? productId;
  final int quantity;
  final double total;
  final String status;
  final DateTime? tanggalDibuat;
  final DateTime? tanggalDiperbarui;
  final User? user;
  final Product? product;

  Order({
    required this.id,
    this.userId,
    this.productId,
    required this.quantity,
    required this.total,
    required this.status,
    this.tanggalDibuat,
    this.tanggalDiperbarui,
    this.user,
    this.product,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    print('🔍 Order.fromJson - Raw JSON keys: ${json.keys.toList()}');
    // CRITICAL: Handle productId field mapping with priority order
    int? productId;
    // Check in order of preference: productId -> productid -> product_id
    if (json['productId'] != null) {
      productId = json['productId'] as int?;
      print('✅ Found productId (camelCase): $productId');
    } else if (json['productid'] != null) {
      productId = json['productid'] as int?;
      print('✅ Found productid (database lowercase): $productId');
    } else if (json['product_id'] != null) {
      productId = json['product_id'] as int?;
      print('✅ Found product_id (snake_case): $productId');
    } else {
      print('❌ CRITICAL: No productId field found!');
      print(
          'Available fields: ${json.keys.where((k) => k.toLowerCase().contains('product')).toList()}');
      print('Full JSON: $json');
    }
    // Handle userId mapping
    int? userId;
    if (json['userId'] != null) {
      userId = json['userId'] as int?;
      print('✅ Found userId (camelCase): $userId');
    } else if (json['userid'] != null) {
      userId = json['userid'] as int?;
      print('✅ Found userid (database lowercase): $userId');
    } else if (json['user_id'] != null) {
      userId = json['user_id'] as int?;
      print('✅ Found user_id (snake_case): $userId');
    }
    // Handle totalPrice mapping
    double totalPrice = 0.0;
    if (json['totalPrice'] != null) {
      totalPrice = (json['totalPrice'] as num?)?.toDouble() ?? 0.0;
      print('✅ Found totalPrice (camelCase): $totalPrice');
    } else if (json['totalprice'] != null) {
      totalPrice = (json['totalprice'] as num?)?.toDouble() ?? 0.0;
      print('✅ Found totalprice (database lowercase): $totalPrice');
    } else if (json['total_price'] != null) {
      totalPrice = (json['total_price'] as num?)?.toDouble() ?? 0.0;
      print('✅ Found total_price (snake_case): $totalPrice');
    }
    // Handle date field variations
    DateTime? tanggalDibuat;
    final dateFields = [
      'tanggal_dibuat',
      'tanggalDibuat',
      'created_at',
      'createdAt'
    ];
    for (String field in dateFields) {
      if (json[field] != null) {
        try {
          tanggalDibuat = DateTime.parse(json[field] as String);
          print('✅ Found date in field "$field": $tanggalDibuat');
          break;
        } catch (e) {
          print('❌ Error parsing date from field "$field": ${json[field]}');
        }
      }
    }

    final order = Order(
      id: json['id'] ?? '',
      userId: userId,
      productId: productId,
      quantity: json['quantity'] as int? ?? 1,
      total: totalPrice,
      status: json['status'] as String? ?? 'pending',
      tanggalDibuat: tanggalDibuat ?? DateTime.now(),
      product: json['product'] != null
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );

    print('=== PARSED VALUES ===');
    print('ID: ${order.id}');
    print('User ID: ${order.userId}');
    print('Product ID: ${order.productId}');
    print('Total Price: ${order.total}');
    print(
        '✅ Order created: ID=${order.id}, UserID=${order.userId}, ProductID=${order.productId}');

    return order;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic dateTimeValue) {
    if (dateTimeValue == null) return null;

    try {
      if (dateTimeValue is String) {
        return DateTime.parse(dateTimeValue);
      } else if (dateTimeValue is int) {
        // Handle timestamp in milliseconds
        return DateTime.fromMillisecondsSinceEpoch(dateTimeValue);
      }
      return null;
    } catch (e) {
      print('Error parsing datetime: $e for value: $dateTimeValue');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'productId': productId,
      'quantity': quantity,
      'totalPrice': total,
    };
  }

  // Getter for display purposes
  String get createdAt {
    if (tanggalDibuat != null) {
      return tanggalDibuat!.toString();
    }
    return 'Unknown date';
  }

  // Getter for total amount (alias)
  double get totalAmount => total;

  // Getter for totalPrice (for backward compatibility)
  double get totalPrice => total;
}
