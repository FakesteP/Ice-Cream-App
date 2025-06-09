import 'package:flutter/material.dart';
import 'package:icecreamapp/models/order_model.dart';
import 'package:icecreamapp/models/product_model.dart';
import 'package:icecreamapp/services/product_service.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  final ProductService _productService = ProductService();
  Product? _product;
  bool _isLoadingProduct = false;
  @override
  void initState() {
    super.initState();

    // Debug total price issue
    print('🔍 OrderCard Debug:');
    print('  - Order ID: ${widget.order.id}');
    print('  - Total Price: ${widget.order.totalPrice}');
    print('  - Total Price Type: ${widget.order.totalPrice.runtimeType}');
    print('  - Product ID: ${widget.order.productId}');
    print('  - Quantity: ${widget.order.quantity}');
    print(
        '  - Product from backend join: ${widget.order.product?.name ?? 'null'}');
    print(
        '  - Product imageUrl from backend join: ${widget.order.product?.imageUrl ?? 'null'}');

    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    // First priority: Use product data from backend join if available
    if (widget.order.product != null) {
      setState(() {
        _product = widget.order.product;
      });
      return;
    }

    // Second priority: Fetch using productId
    if (widget.order.productId != null && widget.order.productId! > 0) {
      setState(() {
        _isLoadingProduct = true;
      });
      try {
        final product =
            await _productService.getProductById(widget.order.productId!);

        if (mounted) {
          setState(() {
            _product = product;
            _isLoadingProduct = false;
          });
        }
      } catch (e) {
        print('Error loading product details: $e');
        if (mounted) {
          setState(() {
            _isLoadingProduct = false;
          });
        }
      }
    } else {
      // No valid product ID
      setState(() {
        _isLoadingProduct = false;
      });
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orangeAccent;
      case 'processed':
        return Colors.blueAccent;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'processed':
        return Icons.local_shipping;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building OrderCard for Order #${widget.order.id}');
    print('   Total Price Value: ${widget.order.totalPrice}');

    // Handle totalPrice display with better error checking
    String totalPriceString;
    if (widget.order.totalPrice > 0) {
      totalPriceString = NumberFormat.currency(
              locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(widget.order.totalPrice);
    } else {
      totalPriceString = 'Rp 0 (Check data)';
      print(
          '⚠️ WARNING: Total price is 0 or negative: ${widget.order.totalPrice}');
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.blue[50] ?? Colors.blue.shade50,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header with Order ID and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue[400] ?? Colors.blue.shade400,
                                Colors.purple[400] ?? Colors.purple.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Order #${widget.order.id}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(widget.order.status),
                            _getStatusColor(widget.order.status)
                                .withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(widget.order.status)
                                .withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStatusIcon(widget.order.status),
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            widget.order.status.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Product Section with Image
                _buildProductSection(),

                const SizedBox(height: 16),

                // Order Details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.shopping_cart,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              const Text('Quantity:',
                                  style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          Text('${widget.order.quantity}',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attach_money,
                                  size: 16, color: Colors.green[600]),
                              const SizedBox(width: 8),
                              const Text('Total:',
                                  style: TextStyle(fontSize: 14)),
                            ],
                          ),
                          Text(totalPriceString,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: widget.order.totalPrice > 0
                                      ? Colors.green[600]
                                      : Colors.red[600])),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Order Date
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Ordered: ${_formatDateTime(widget.order.tanggalDibuat)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    // Use same priority logic: backend join first, then async loaded product
    Product? displayProduct = widget.order.product ?? _product;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.pink[50] ?? Colors.pink.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.pink[100] ?? Colors.pink.shade100),
      ),
      child: Row(
        children: [
          // Product Image with better debugging
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildProductImage(),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isLoadingProduct && displayProduct == null)
                  Row(
                    children: const [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading product...',
                          style: TextStyle(
                              fontSize: 13, fontStyle: FontStyle.italic)),
                    ],
                  )
                else if (displayProduct != null) ...[
                  Text(
                    displayProduct.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(
                            locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                        .format(displayProduct.price),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.pink[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (displayProduct.description != null &&
                      displayProduct.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      displayProduct.description!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ] else
                  Text(
                    'Product not found',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    // Debug image loading    print('🖼️ Building product image for Order #${widget.order.id}');
    print('   Loading: $_isLoadingProduct');
    print('   Product from _product: ${_product?.name ?? 'null'}');
    print(
        '   Product from order.product: ${widget.order.product?.name ?? 'null'}');
    print('   Image URL from _product: ${_product?.imageUrl ?? 'null'}');
    print(
        '   Image URL from order.product: ${widget.order.product?.imageUrl ?? 'null'}');

    // Priority 1: Use product data from backend join if available
    Product? displayProduct = widget.order.product ?? _product;

    if (_isLoadingProduct && displayProduct == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey[100]!, Colors.grey[200]!],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } // Simple approach like ProductCard - directly use imageUrl if available
    if (displayProduct?.imageUrl != null &&
        displayProduct!.imageUrl!.isNotEmpty) {
      print('   🌐 Loading Image.network: ${displayProduct.imageUrl}');

      return Image.network(
        displayProduct.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ Image.network ERROR for ${displayProduct.imageUrl}: $error');
          return Container(
            color: Colors.grey[200],
            child: Icon(Icons.icecream_outlined,
                size: 30, color: Colors.grey[400]),
          );
        },
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) {
            print('✅ Image.network SUCCESS: ${displayProduct.imageUrl}');
            return child;
          }
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
      );
    } // Fallback icon when no image URL
    print('   📷 Using fallback icon (no image URL)');
    return Container(
      color: Colors.pink[100],
      child: Icon(Icons.icecream, size: 30, color: Colors.pink[300]),
    );
  }
}
