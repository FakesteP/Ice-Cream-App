import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math' as math;

class ShakeDetectorPage extends StatefulWidget {
  const ShakeDetectorPage({super.key});

  @override
  State<ShakeDetectorPage> createState() => _ShakeDetectorPageState();
}

class _ShakeDetectorPageState extends State<ShakeDetectorPage>
    with TickerProviderStateMixin {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  int _shakeCount = 0;
  bool _isShaking = false;
  double _shakeThreshold = 15.0;
  List<String> _availableFlavors = [
    'Vanilla',
    'Chocolate',
    'Strawberry',
    'Mint'
  ];
  List<String> _mixedFlavors = [];

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _particleAnimationController;
  late AnimationController _mixingAnimationController;
  late AnimationController _shakeAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _mixingAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeAccelerometer();
  }

  void _setupAnimations() {
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

    _mixingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
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

    _mixingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _mixingAnimationController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
          parent: _shakeAnimationController, curve: Curves.elasticOut),
    );

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
    _particleAnimationController.repeat();
  }

  void _initializeAccelerometer() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      double magnitude = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (magnitude > _shakeThreshold) {
        _onShakeDetected();
      }
    });
  }

  void _onShakeDetected() {
    if (!_isShaking) {
      setState(() {
        _isShaking = true;
        _shakeCount++;
      });

      _shakeAnimationController.forward().then((_) {
        _shakeAnimationController.reverse();
      });

      if (_shakeCount % 3 == 0 && _availableFlavors.isNotEmpty) {
        _addRandomFlavor();
      }

      Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _isShaking = false;
        });
      });
    }
  }

  void _addRandomFlavor() {
    if (_availableFlavors.isNotEmpty) {
      final randomIndex = math.Random().nextInt(_availableFlavors.length);
      final selectedFlavor = _availableFlavors[randomIndex];

      setState(() {
        _mixedFlavors.add(selectedFlavor);
        _availableFlavors.removeAt(randomIndex);
      });

      _mixingAnimationController.forward().then((_) {
        _mixingAnimationController.reverse();
      });
    }
  }

  void _resetMix() {
    setState(() {
      _shakeCount = 0;
      _mixedFlavors.clear();
      _availableFlavors = ['Vanilla', 'Chocolate', 'Strawberry', 'Mint'];
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();

    // Dispose all animation controllers
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _particleAnimationController.dispose();
    _mixingAnimationController.dispose();
    _shakeAnimationController.dispose();

    super.dispose();
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
            ...List.generate(15, (index) => _buildParticle(index, size)),

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
                            children: [
                              // Instructions Card
                              _buildInstructionsCard(),

                              const SizedBox(height: 20),

                              // Shake Counter
                              _buildShakeCounter(),

                              const SizedBox(height: 30),

                              // Ice cream bowl animation
                              _buildIceCreamBowl(),

                              const SizedBox(height: 30),

                              // Mixed flavors display
                              if (_mixedFlavors.isNotEmpty)
                                _buildMixedFlavors(),

                              const SizedBox(height: 30),

                              // Control buttons
                              _buildControlButtons(),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.vibration, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                ).createShader(bounds),
                child: const Text(
                  'Shake to Mix Flavors',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _resetMix();
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
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
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink[100]!, Colors.purple[100]!],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.vibration, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.pink[600]!, Colors.purple[600]!],
              ).createShader(bounds),
              child: const Text(
                'Shake your phone to mix ice cream flavors!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Every 3 shakes adds a new flavor',
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

  Widget _buildShakeCounter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: Text(
                    _shakeCount.toString(),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _isShaking ? Colors.pink[600] : Colors.grey[700],
                    ),
                  ),
                );
              },
            ),
            Text(
              'Shakes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIceCreamBowl() {
    return AnimatedBuilder(
      animation: _mixingAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_mixingAnimation.value * 0.1),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Colors.pink[200]!, Colors.purple[200]!],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bowl
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!, width: 3),
                  ),
                ),
                // Ice cream scoops based on mixed flavors
                if (_mixedFlavors.isNotEmpty) ..._buildIceCreamScoops(),
                if (_mixedFlavors.isEmpty)
                  Text(
                    'Empty Bowl\nShake to add flavors!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMixedFlavors() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.pink[600]!, Colors.purple[600]!],
              ).createShader(bounds),
              child: const Text(
                'Your Mixed Flavors:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _mixedFlavors
                  .map((flavor) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getFlavorColor(flavor),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getFlavorColor(flavor).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          flavor,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Reset',
            Icons.refresh,
            Colors.grey[600]!,
            _resetMix,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            'Order',
            Icons.shopping_cart,
            _mixedFlavors.isNotEmpty ? Colors.pink[600]! : Colors.grey[400]!,
            _mixedFlavors.isNotEmpty
                ? () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                  'Order placed: ${_mixedFlavors.join(", ")} ice cream!'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback? onPressed) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          shadowColor: color.withOpacity(0.3),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildIceCreamScoops() {
    List<Widget> scoops = [];
    for (int i = 0; i < _mixedFlavors.length && i < 3; i++) {
      scoops.add(
        Positioned(
          top: 40 + (i * 15.0),
          child: Container(
            width: 60 - (i * 5),
            height: 60 - (i * 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getFlavorColor(_mixedFlavors[i]),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return scoops;
  }

  Color _getFlavorColor(String flavor) {
    switch (flavor) {
      case 'Vanilla':
        return Colors.yellow[200]!;
      case 'Chocolate':
        return Colors.brown[400]!;
      case 'Strawberry':
        return Colors.pink[300]!;
      case 'Mint':
        return Colors.green[300]!;
      default:
        return Colors.grey[300]!;
    }
  }
}
