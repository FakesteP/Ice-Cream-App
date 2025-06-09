import 'package:flutter/material.dart';
import 'package:icecreamapp/models/product_model.dart';
import 'package:icecreamapp/services/product_service.dart';
import 'package:icecreamapp/pages/create_order_page.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ProductService _productService = ProductService();
  late Future<Product> _productFuture;
  int _quantity = 1;

  // Currency converter variables
  String _selectedCurrency = 'IDR';
  double _convertedPrice = 0.0;
  bool _isCurrencyLoading = false;
  Map<String, dynamic> _exchangeRates = {};

  final List<Map<String, String>> _currencies = [
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM'},
  ];

  @override
  void initState() {
    super.initState();
    _productFuture = _loadProductWithRetry();
    _fetchExchangeRates();
  }

  Future<Product> _loadProductWithRetry() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        print(
            'Attempting to load product ${widget.productId}, try ${retryCount + 1}');
        final product = await _productService.getProductById(widget.productId);
        print('Successfully loaded product: ${product.name}');
        return product;
      } catch (e) {
        retryCount++;
        print('Failed to load product, attempt $retryCount: $e');

        if (retryCount >= maxRetries) {
          print('Max retries reached, throwing error');
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(Duration(seconds: retryCount));
      }
    }

    throw Exception('Failed to load product after $maxRetries attempts');
  }

  Future<void> _fetchExchangeRates() async {
    setState(() {
      _isCurrencyLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/IDR'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _exchangeRates = data['rates'];
        });
        // Trigger conversion after rates are loaded
        _productFuture.then((product) {
          _convertPrice(product.price);
        });
      } else {
        _useStaticRates();
      }
    } catch (e) {
      _useStaticRates();
    } finally {
      setState(() {
        _isCurrencyLoading = false;
      });
    }
  }

  void _useStaticRates() {
    setState(() {
      _exchangeRates = {
        'USD': 0.000067,
        'EUR': 0.000062,
        'GBP': 0.000053,
        'JPY': 0.0098,
        'SGD': 0.000090,
        'MYR': 0.00031,
        'IDR': 1.0,
      };
    });
    // Trigger conversion after static rates are set
    _productFuture.then((product) {
      _convertPrice(product.price);
    });
  }

  void _convertPrice(double originalPrice) {
    if (_exchangeRates.isEmpty) return;

    setState(() {
      if (_selectedCurrency == 'IDR') {
        _convertedPrice = originalPrice;
      } else {
        double rate = _exchangeRates[_selectedCurrency] ?? 1.0;
        _convertedPrice = originalPrice * rate;
      }
    });
  }

  String _formatCurrency(double amount, String currencyCode) {
    final currency = _currencies.firstWhere(
      (c) => c['code'] == currencyCode,
      orElse: () => {'symbol': currencyCode},
    );

    final formatter = NumberFormat('#,##0.00');
    return '${currency['symbol']} ${formatter.format(amount)}';
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _navigateToCreateOrder() async {
    print('=== NAVIGATE TO CREATE ORDER ===');
    print('Product ID: ${widget.productId}');
    print('Selected quantity: $_quantity');

    // Verify user is logged in before proceeding
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final token = prefs.getString('token');

    print('=== USER VERIFICATION ===');
    print('User ID from prefs: $userId');
    print('Token exists: ${token != null}');

    if (userId == null || token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first to place an order'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    // Get the current product data
    if (_productFuture != null) {
      try {
        final product = await _productFuture!;
        print('=== PRODUCT DATA FOR ORDER ===');
        print('Product ID: ${product.id}');
        print('Product Name: ${product.name}');
        print('Product Price: ${product.price}');
        print('Product Stock: ${product.stock}');
        print('Selected Quantity: $_quantity');

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateOrderPage(
                product: product,
                quantity: _quantity,
              ),
            ),
          );
        }
      } catch (e) {
        print('Error getting product for order: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading product: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ice Cream Details'),
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load product',
                    style: TextStyle(fontSize: 18, color: Colors.red[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _productFuture = _loadProductWithRetry();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Product not found.'));
          }

          final product = snapshot.data!;

          // Ensure conversion happens when both product and exchange rates are available
          if (_exchangeRates.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_convertedPrice == 0.0 || _selectedCurrency == 'IDR') {
                _convertPrice(product.price);
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Product Image
                if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                  Image.network(
                    product.imageUrl!,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 300,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image,
                          size: 100, color: Colors.grey[400]),
                    ),
                  )
                else
                  Container(
                    height: 300,
                    color: Colors.pink[100],
                    child: Icon(Icons.icecream,
                        size: 150, color: Colors.pink[300]),
                  ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        product.name,
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColorDark),
                      ),
                      const SizedBox(height: 12),

                      // Price Section with Currency Converter
                      Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Price',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: _selectedCurrency,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCurrency = newValue!;
                                      });
                                      _convertPrice(product.price);
                                    },
                                    items: _currencies.map((currency) {
                                      return DropdownMenuItem<String>(
                                        value: currency['code'],
                                        child: Text(
                                            '${currency['symbol']} ${currency['code']}'),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_isCurrencyLoading)
                                const Center(child: CircularProgressIndicator())
                              else
                                Text(
                                  _selectedCurrency == 'IDR'
                                      ? NumberFormat.currency(
                                              locale: 'id_ID',
                                              symbol: 'Rp ',
                                              decimalDigits: 0)
                                          .format(product.price)
                                      : _formatCurrency(
                                          _convertedPrice, _selectedCurrency),
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (_selectedCurrency != 'IDR' &&
                                  !_isCurrencyLoading)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Original: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(product.price)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Description
                      Text(
                        product.description ?? 'No description available.',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey[700], height: 1.5),
                      ),
                      const SizedBox(height: 10),

                      // Stock Information
                      Text(
                        'Stock: ${product.stock > 0 ? product.stock : "Out of Stock"}',
                        style: TextStyle(
                          fontSize: 16,
                          color: product.stock > 0
                              ? Colors.green[700]
                              : Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Quantity Selector and Order Button
                      if (product.stock > 0) ...[
                        // Quantity Selector
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Quantity',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                      onPressed: _decrementQuantity,
                                      iconSize: 30,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color:
                                                Theme.of(context).primaryColor),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$_quantity',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      onPressed: _incrementQuantity,
                                      iconSize: 30,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Total Price
                                Text(
                                  'Total: ${_selectedCurrency == 'IDR' ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(product.price * _quantity) : _formatCurrency((_convertedPrice > 0 ? _convertedPrice : product.price * (_exchangeRates[_selectedCurrency] ?? 1.0)) * _quantity, _selectedCurrency)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Add to Order Button
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.shopping_cart_checkout),
                            label: const Text('Add to Order'),
                            onPressed: () {
                              _navigateToCreateOrder();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 15),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Out of Stock Message
                        Card(
                          elevation: 2,
                          color: Colors.red[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    color: Colors.red[700]),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    "Currently Out of Stock",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
