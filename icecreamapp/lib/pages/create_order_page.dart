import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icecreamapp/models/product_model.dart';
import 'package:icecreamapp/services/order_service.dart';
import 'package:icecreamapp/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CreateOrderPage extends StatefulWidget {
  final Product product;
  final int quantity;

  const CreateOrderPage({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage>
    with TickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  int? _currentUserId;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _particleAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserId();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fadeAnimationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideAnimationController, curve: Curves.easeOut));

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _particleAnimationController, curve: Curves.linear),
    );

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _particleAnimationController.repeat();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _particleAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    print('=== LOADING USER ID ===');
    print('UserId from SharedPreferences: $userId');

    setState(() {
      _currentUserId = userId;
    });

    if (userId == null) {
      print('❌ No userId found - user may not be logged in');
    } else {
      print('✅ UserId loaded: $userId');
    }
  }

  Future<void> _placeOrder() async {
    if (_currentUserId == null) {
      print('❌ No userId available - redirecting to login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please login first to place an order'),
            backgroundColor: Colors.red),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (widget.product.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid product selected'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    print('=== CREATING ORDER ===');
    print('User ID: $_currentUserId');
    print('Product ID: ${widget.product.id}');
    print('Product Name: ${widget.product.name}');
    print('Quantity: ${widget.quantity}');

    final orderData = {
      'userId': _currentUserId,
      'productId': widget.product.id,
      'quantity': widget.quantity,
      'totalPrice': widget.product.price * widget.quantity,
    };

    print('Order data to send: $orderData');

    try {
      final result = await _orderService.createOrder(orderData);

      if (result['success']) {
        final order = result['order'];
        print('✅ Order created successfully');
        print('Order ID: ${order.id}');
        print('Order userId: ${order.userId} (expected: $_currentUserId)');
        print(
            'Order productId: ${order.productId} (expected: ${widget.product.id})');

        await _notificationService.showNotification(
          order.id,
          '🍦 Order Successful!',
          'Your order for ${widget.product.name} (x${widget.quantity}) has been placed.',
          'order_id_${order.id}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Order placed successfully!'),
                backgroundColor: Colors.green),
          );
          int count = 0;
          Navigator.popUntil(context, (route) {
            return count++ == 2;
          });
        }
      } else {
        print('❌ Order creation failed: ${result['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to place order: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      print('❌ Order creation exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final totalPrice = widget.product.price * widget.quantity;
    final priceString =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
            .format(widget.product.price);
    final totalPriceString =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
            .format(totalPrice);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink[50]!,
              Colors.purple[50]!,
              Colors.blue[50]!,
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
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Modern App Bar
                      _buildModernAppBar(),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Product Card
                              _buildProductCard(priceString, totalPriceString),

                              const SizedBox(height: 40),

                              // Action Button
                              _buildActionButton(),

                              const SizedBox(height: 16),

                              if (_currentUserId == null && !_isLoading)
                                _buildLoadingMessage(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
      animation: _particleAnimation,
      builder: (context, child) {
        final progress = (_particleAnimation.value + (random / 100)) % 1.0;
        final top = size.height * progress;

        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: 0.06 + (0.12 * (1 - progress)),
            child: Container(
              width: 3 + (random % 2),
              height: 3 + (random % 2),
              decoration: BoxDecoration(
                color: index.isEven ? Colors.pink[300] : Colors.purple[300],
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.pink[400]!.withOpacity(0.9),
            Colors.purple[400]!.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                ).createShader(bounds),
                child: const Text(
                  'Confirm Your Order',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(String priceString, String totalPriceString) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 3,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Title
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.pink[600]!, Colors.purple[600]!],
              ).createShader(bounds),
              child: Text(
                widget.product.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Product Image
            if (widget.product.imageUrl != null &&
                widget.product.imageUrl!.isNotEmpty)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.product.imageUrl!,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.pink[100]!, Colors.purple[100]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.icecream,
                            size: 60, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Order Details
            _buildOrderDetail(
                'Price per item', priceString, Icons.attach_money),
            const SizedBox(height: 12),
            _buildOrderDetail(
                'Quantity', widget.quantity.toString(), Icons.shopping_cart),

            const SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink[200]!, Colors.purple[200]!],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Total Price
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink[50]!, Colors.purple[50]!],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.pink[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Price:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    totalPriceString,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.pink[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink[100]!, Colors.purple[100]!],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.pink[600], size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _currentUserId == null || _isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                _placeOrder();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.payment, size: 24),
        label: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _currentUserId == null || _isLoading
                  ? [Colors.grey[400]!, Colors.grey[500]!]
                  : [Colors.pink[400]!, Colors.pink[600]!, Colors.purple[500]!],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _currentUserId == null || _isLoading
                ? null
                : [
                    BoxShadow(
                      color: Colors.pink[300]!.withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              _isLoading ? 'Placing Order...' : 'Place Order',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange[200]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              "Loading user data...",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
