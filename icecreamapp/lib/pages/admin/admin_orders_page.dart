import 'package:flutter/material.dart';
import 'package:icecreamapp/services/order_service.dart';
import 'package:icecreamapp/services/product_service.dart';
import 'package:icecreamapp/models/order_model.dart';
import 'package:icecreamapp/models/product_model.dart';
import 'package:intl/intl.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({Key? key}) : super(key: key);

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage>
    with TickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadOrders();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orders = await _orderService.getOrders();
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load orders: ${e.toString()}';
        });
        _showSnackBar('Error loading orders: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[400] : Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<Order> get _filteredOrders {
    try {
      if (_selectedFilter == 'all') return _orders;
      return _orders.where((order) {
        return order.status?.toLowerCase() == _selectedFilter;
      }).toList();
    } catch (e) {
      print('Error filtering orders: $e');
      return [];
    }
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    if (!mounted) return;

    try {
      // Handle different possible ID field names and types
      String? orderId;

      // Try different possible ID field names
      if (order.id != null) {
        orderId = order.id.toString();
      } else {
        // If order.id is null, check if there's another ID field
        // You might need to adjust this based on your Order model
        print('Warning: Order ID is null for order: $order');
        _showSnackBar('Invalid order ID', isError: true);
        return;
      }

      if (orderId.isEmpty) {
        _showSnackBar('Invalid order ID', isError: true);
        return;
      }

      print('Updating order $orderId to status: $newStatus');
      final int? orderIdInt = int.tryParse(orderId);
      if (orderIdInt == null) {
        _showSnackBar('Invalid order ID type', isError: true);
        return;
      }
      final result =
          await _orderService.updateOrderStatus(orderIdInt, newStatus);
      if (mounted) {
        if (result['success'] == true) {
          await _loadOrders();
          _showSnackBar('Order status updated successfully');
        } else {
          _showSnackBar(
              'Failed to update order: ${result['message'] ?? 'Unknown error'}',
              isError: true);
        }
      }
    } catch (e) {
      print('Error updating order status: $e');
      if (mounted) {
        _showSnackBar('Error updating order: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink[50] ?? Colors.pink.shade50,
              Colors.purple[50] ?? Colors.purple.shade50,
              Colors.blue[50] ?? Colors.blue.shade50,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(12, (index) => _buildParticle(index, size)),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildFilterSection(),
                    Expanded(
                      child: _buildContent(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticle(int index, Size size) {
    final random = (index * 1234567) % 100;
    final left = (random / 100) * size.width;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        final progress = (_fadeAnimation.value + (random / 100)) % 1.0;
        final top = size.height * progress;

        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: 0.05 + (0.1 * (1 - progress)),
            child: Container(
              width: 3 + (random % 2),
              height: 3 + (random % 2),
              decoration: BoxDecoration(
                color: index.isEven
                    ? (Colors.pink[300] ?? Colors.pink.shade300)
                    : (Colors.purple[300] ?? Colors.purple.shade300),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[400] ?? Colors.blue.shade400,
            Colors.purple[400] ?? Colors.purple.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.list_alt, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Orders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Monitor and update order status',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadOrders,
              tooltip: 'Refresh Orders',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.blue[50] ?? Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue[400] ?? Colors.blue.shade400,
                      Colors.blue[600] ?? Colors.blue.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.filter_list,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filter Orders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', Colors.grey),
                _buildFilterChip('Pending', 'pending', Colors.orange),
                _buildFilterChip('Processed', 'processed', Colors.blue),
                _buildFilterChip('Completed', 'completed', Colors.green),
                _buildFilterChip('Cancelled', 'cancelled', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, MaterialColor color) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [
                  color[400] ?? color.shade400,
                  color[600] ?? color.shade600,
                ])
              : null,
          color: isSelected ? null : (color[50] ?? color.shade50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color[200] ?? color.shade200),
        ),
        child: InkWell(
          onTap: () {
            if (mounted) {
              setState(() {
                _selectedFilter = value;
              });
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : (color[700] ?? color.shade700),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: Colors.blue[400],
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          try {
            final order = _filteredOrders[index];
            return AdminOrderCard(
              order: order,
              onStatusChange: _updateOrderStatus,
            );
          } catch (e) {
            print('Error building order card at index $index: $e');
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              color: Colors.blue[400],
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading orders...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child:
                const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue[100] ?? Colors.blue.shade100,
                  Colors.purple[100] ?? Colors.purple.shade100,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _selectedFilter == 'all'
                ? 'No Orders Found'
                : 'No ${_selectedFilter.toUpperCase()} Orders',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedFilter == 'all'
                ? 'No orders have been placed yet'
                : 'No orders with ${_selectedFilter} status found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AdminOrderCard extends StatefulWidget {
  final Order order;
  final Function(Order, String) onStatusChange;

  const AdminOrderCard({
    Key? key,
    required this.order,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  State<AdminOrderCard> createState() => _AdminOrderCardState();
}

class _AdminOrderCardState extends State<AdminOrderCard> {
  final ProductService _productService = ProductService();
  Product? _product;
  bool _isLoadingProduct = true;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      if (widget.order.productId != null) {
        final product =
            await _productService.getProductById(widget.order.productId!);
        if (mounted) {
          setState(() {
            _product = product;
            _isLoadingProduct = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingProduct = false;
          });
        }
      }
    } catch (e) {
      print('Error loading product details: $e');
      if (mounted) {
        setState(() {
          _isLoadingProduct = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.blue[50] ?? Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${widget.order.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (_product != null)
                      Text(
                        _product!.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 44, top: 4),
            child: _buildStatusBadge(widget.order.status ?? 'unknown'),
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[50] ?? Colors.grey.shade50,
                    Colors.blue[25] ?? Colors.blue.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image and Details Section
                  _buildProductSection(),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  _buildInfoRow('User ID', '${widget.order.userId ?? 'N/A'}',
                      Icons.person),
                  _buildInfoRow('Product ID',
                      '${widget.order.productId ?? 'N/A'}', Icons.icecream),
                  _buildInfoRow('Quantity', '${widget.order.quantity}',
                      Icons.shopping_cart),
                  _buildInfoRow(
                    'Total Price',
                    _formatCurrency(widget.order.totalPrice),
                    Icons.attach_money,
                  ),
                  _buildInfoRow(
                      'Created',
                      _formatDateTime(widget.order.tanggalDibuat),
                      Icons.schedule),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green[400] ?? Colors.green.shade400,
                              Colors.green[600] ?? Colors.green.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.update,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Update Status:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      _buildStatusButton(context, 'pending', Colors.orange),
                      _buildStatusButton(context, 'processed', Colors.blue),
                      _buildStatusButton(context, 'completed', Colors.green),
                      _buildStatusButton(context, 'cancelled', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.pink[50] ?? Colors.pink.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink[100] ?? Colors.pink.shade100),
      ),
      child: Row(
        children: [
          // Product Image with enhanced debugging
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildAdminProductImage(),
            ),
          ),
          const SizedBox(width: 16),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.icecream, size: 18, color: Colors.pink[400]),
                    const SizedBox(width: 8),
                    const Text(
                      'Product Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isLoadingProduct)
                  const Text(
                    'Loading product details...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  )
                else if (_product != null) ...[
                  Text(
                    _product!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(_product!.price),
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.pink[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_product!.description != null &&
                      _product!.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _product!.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Debug info for image URL
                  if (_product!.imageUrl != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'IMG: ${_product!.imageUrl!.length > 40 ? '${_product!.imageUrl!.substring(0, 40)}...' : _product!.imageUrl!}',
                        style: const TextStyle(
                            fontSize: 8, fontFamily: 'monospace'),
                      ),
                    ),
                ] else
                  Text(
                    'Product not found',
                    style: TextStyle(
                      fontSize: 14,
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

  Widget _buildAdminProductImage() {
    // Debug image loading
    print('🖼️ Admin: Building product image for Order #${widget.order.id}');
    print('   Loading: $_isLoadingProduct');
    print('   Product: ${_product?.name ?? 'null'}');
    print('   Image URL: ${_product?.imageUrl ?? 'null'}');

    if (_isLoadingProduct) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_product?.imageUrl != null && _product!.imageUrl!.isNotEmpty) {
      print('   Admin: Attempting to load: ${_product!.imageUrl}');
      return Image.network(
        _product!.imageUrl!,
        fit: BoxFit.cover,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        errorBuilder: (context, error, stackTrace) {
          print('❌ Admin: Image load error for ${_product!.imageUrl}: $error');
          return Container(
            color: Colors.red[100],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 25, color: Colors.red[400]),
                const SizedBox(height: 4),
                Text(
                  'Load Error',
                  style: TextStyle(fontSize: 10, color: Colors.red[600]),
                ),
              ],
            ),
          );
        },
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) {
            print('✅ Admin: Image loaded successfully: ${_product!.imageUrl}');
            return child;
          }
          print(
              '⏳ Admin: Loading progress: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes ?? 'unknown'}');
          return Container(
            color: Colors.blue[50],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue[400],
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }

    // Fallback icon
    print('   Admin: Using fallback icon (no image URL)');
    return Container(
      color: Colors.pink[100],
      child: Icon(Icons.icecream, size: 40, color: Colors.pink[300]),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
      BuildContext context, String status, MaterialColor color) {
    final isCurrentStatus =
        (widget.order.status?.toLowerCase() ?? '') == status;
    return Container(
      decoration: BoxDecoration(
        gradient: isCurrentStatus
            ? LinearGradient(colors: [
                Colors.grey[400] ?? Colors.grey.shade400,
                Colors.grey[600] ?? Colors.grey.shade600,
              ])
            : LinearGradient(colors: [
                color[400] ?? color.shade400,
                color[600] ?? color.shade600,
              ]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isCurrentStatus ? Colors.grey : color).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isCurrentStatus
            ? null
            : () => widget.onStatusChange(widget.order, status),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          status.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[400] ?? Colors.orange.shade400;
      case 'processed':
        return Colors.blue[400] ?? Colors.blue.shade400;
      case 'completed':
        return Colors.green[400] ?? Colors.green.shade400;
      case 'cancelled':
        return Colors.red[400] ?? Colors.red.shade400;
      default:
        return Colors.grey[400] ?? Colors.grey.shade400;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    try {
      if (dateTime == null) return 'N/A';
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid Date';
    }
  }

  String _formatCurrency(double? amount) {
    try {
      if (amount == null) return 'Rp 0';
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(amount);
    } catch (e) {
      print('Error formatting currency: $e');
      return 'Rp ${amount ?? 0}';
    }
  }
}
