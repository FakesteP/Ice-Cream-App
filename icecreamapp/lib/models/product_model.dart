class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    print('=== PARSING PRODUCT JSON ===');
    print('Raw JSON: $json');
    print('Available keys: ${json.keys.toList()}');

    try {
      // Parse ID with multiple field name options
      int parsedId = 0;
      if (json['id'] != null) {
        parsedId = json['id'] is int
            ? json['id']
            : int.tryParse(json['id'].toString()) ?? 0;
      } else if (json['product_id'] != null) {
        parsedId = json['product_id'] is int
            ? json['product_id']
            : int.tryParse(json['product_id'].toString()) ?? 0;
      } else if (json['productId'] != null) {
        parsedId = json['productId'] is int
            ? json['productId']
            : int.tryParse(json['productId'].toString()) ?? 0;
      }

      // Parse name with multiple field name options and better validation
      String parsedName = '';

      // Try different field names
      List<String> nameFields = [
        'name',
        'product_name',
        'productName',
        'title',
        'nama'
      ];
      for (String field in nameFields) {
        if (json[field] != null) {
          String candidateName = json[field].toString().trim();
          if (candidateName.isNotEmpty &&
              candidateName.toLowerCase() != 'null' &&
              candidateName.toLowerCase() != 'undefined') {
            parsedName = candidateName;
            print('✅ Found valid name in field "$field": "$parsedName"');
            break;
          }
        }
      }

      // If still no valid name found, use fallback
      if (parsedName.isEmpty) {
        parsedName = 'Ice Cream Product #$parsedId';
        print('⚠️  Using fallback name: "$parsedName"');
      }

      // Parse description
      String? parsedDescription;
      if (json['description'] != null &&
          json['description'].toString().trim().isNotEmpty) {
        parsedDescription = json['description'].toString().trim();
      } else if (json['product_description'] != null &&
          json['product_description'].toString().trim().isNotEmpty) {
        parsedDescription = json['product_description'].toString().trim();
      }

      // Parse price with multiple field name options
      double parsedPrice = 0.0;
      if (json['price'] != null) {
        parsedPrice = _parseDouble(json['price']);
      } else if (json['product_price'] != null) {
        parsedPrice = _parseDouble(json['product_price']);
      } else if (json['unitPrice'] != null) {
        parsedPrice = _parseDouble(json['unitPrice']);
      } else if (json['harga'] != null) {
        parsedPrice = _parseDouble(json['harga']);
      }

      // Parse stock
      int parsedStock = 0;
      if (json['stock'] != null) {
        parsedStock = json['stock'] is int
            ? json['stock']
            : int.tryParse(json['stock'].toString()) ?? 0;
      } else if (json['quantity'] != null) {
        parsedStock = json['quantity'] is int
            ? json['quantity']
            : int.tryParse(json['quantity'].toString()) ?? 0;
      } else if (json['available_stock'] != null) {
        parsedStock = json['available_stock'] is int
            ? json['available_stock']
            : int.tryParse(json['available_stock'].toString()) ?? 0;
      } else if (json['stok'] != null) {
        parsedStock = json['stok'] is int
            ? json['stok']
            : int.tryParse(json['stok'].toString()) ?? 0;
      }

      // Parse image URL
      String? parsedImageUrl;
      List<String> imageFields = [
        'imageUrl',
        'image_url',
        'image',
        'foto',
        'gambar'
      ];
      for (String field in imageFields) {
        if (json[field] != null && json[field].toString().trim().isNotEmpty) {
          parsedImageUrl = json[field].toString().trim();
          break;
        }
      }

      print('=== FINAL PARSED PRODUCT VALUES ===');
      print('✅ id: $parsedId');
      print('✅ name: "$parsedName"');
      print('✅ description: "$parsedDescription"');
      print('✅ price: $parsedPrice');
      print('✅ stock: $parsedStock');
      print('✅ imageUrl: "$parsedImageUrl"');

      final product = Product(
        id: parsedId,
        name: parsedName,
        description: parsedDescription,
        price: parsedPrice,
        stock: parsedStock,
        imageUrl: parsedImageUrl,
      );

      print(
          '🎉 Created product successfully: id=${product.id}, name="${product.name}", price=${product.price}');
      return product;
    } catch (e) {
      print('❌ Error parsing product: $e');
      print('JSON was: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value is double) {
      return value;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
