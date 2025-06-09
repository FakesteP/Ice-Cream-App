import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icecreamapp/pages/home_page.dart';
import 'package:icecreamapp/pages/catalog_page.dart';
import 'package:icecreamapp/pages/stores_page.dart';
import 'package:icecreamapp/pages/profile_page.dart';
import 'package:icecreamapp/pages/order_history_page.dart';
import 'package:icecreamapp/pages/shake_detector_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;

  // Animation controllers - nullable initially
  AnimationController? _fadeAnimationController;
  AnimationController? _slideAnimationController;
  AnimationController? _particleAnimationController;

  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _particleAnimation;

  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    CatalogPage(),
    StoresPage(),
    OrderHistoryPage(),
    ShakeDetectorPage(),
    ProfilePage(),
  ];

  static const List<String> _appBarTitles = <String>[
    "Scoopin'",
    'Our Ice Creams',
    'Store Locations',
    'My Orders',
    'Shake to Mix',
    'My Profile',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    try {
      _fadeAnimationController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );

      _slideAnimationController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );

      _particleAnimationController = AnimationController(
        duration: const Duration(seconds: 4),
        vsync: this,
      );

      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fadeAnimationController!,
          curve: Curves.easeInOut,
        ),
      );

      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideAnimationController!,
        curve: Curves.easeOut,
      ));

      _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _particleAnimationController!,
          curve: Curves.linear,
        ),
      );

      // Start animations after initialization
      _fadeAnimationController?.forward();
      _slideAnimationController?.forward();
      _particleAnimationController?.repeat();
    } catch (e) {
      print('Error initializing animations: $e');
    }
  }

  @override
  void dispose() {
    _fadeAnimationController?.dispose();
    _slideAnimationController?.dispose();
    _particleAnimationController?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();

    setState(() {
      _selectedIndex = index;
    });

    // Restart page transition animation safely
    _slideAnimationController?.reset();
    _slideAnimationController?.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Check if animations are initialized
    if (_fadeAnimation == null ||
        _slideAnimation == null ||
        _particleAnimation == null) {
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
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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
            // Animated background particles (only if animation is ready)
            if (_particleAnimation != null)
              ...List.generate(12, (index) => _buildParticle(index, size)),

            // Main content with custom app bar
            SafeArea(
              child: Column(
                children: [
                  // Modern App Bar
                  _buildModernAppBar(),

                  // Page Content with reduced bottom padding for navbar
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          bottom: 0), // Reduced from 100 to 80
                      child: _fadeAnimation != null && _slideAnimation != null
                          ? FadeTransition(
                              opacity: _fadeAnimation!,
                              child: SlideTransition(
                                position: _slideAnimation!,
                                child: _widgetOptions.elementAt(_selectedIndex),
                              ),
                            )
                          : _widgetOptions.elementAt(_selectedIndex),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Use extendBody and proper bottomNavigationBar instead of Positioned
      extendBody: true,
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildParticle(int index, Size size) {
    final random = (index * 1234567) % 100;
    final left = (random / 100) * size.width;

    return AnimatedBuilder(
      animation: _particleAnimation!,
      builder: (context, child) {
        final progress = (_particleAnimation!.value + (random / 100)) % 1.0;
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
            // App icon/logo - Option 1: Use Image.asset for custom logo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/icon/app_icon.jpeg', // Your custom logo
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to icon if image not found
                    return const Icon(
                      Icons.icecream_outlined,
                      color: Colors.white,
                      size: 24,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Title with gradient text
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.white70],
                ).createShader(bounds),
                child: Text(
                  _appBarTitles[_selectedIndex],
                  style: const TextStyle(
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

  Widget _buildModernBottomNav() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(16, 0, 16, 20), // Increased bottom margin
      height: 70, // Set explicit height
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.pink[600],
          unselectedItemColor: Colors.grey[500],
          selectedFontSize: 11, // Slightly smaller font
          unselectedFontSize: 10,
          iconSize: 22, // Slightly smaller icons
          items: [
            _buildNavItem(Icons.home_outlined, Icons.home, 'Home'),
            _buildNavItem(Icons.icecream_outlined, Icons.icecream, 'Catalog'),
            _buildNavItem(Icons.store_mall_directory_outlined,
                Icons.store_mall_directory, 'Stores'),
            _buildNavItem(
                Icons.receipt_long_outlined, Icons.receipt_long, 'Orders'),
            _buildNavItem(Icons.vibration_outlined, Icons.vibration, 'Shake'),
            _buildNavItem(Icons.person_outline, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
      IconData outlinedIcon, IconData filledIcon, String label) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6), // Reduced padding
        decoration: _selectedIndex == _getItemIndex(label)
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink[100]!, Colors.purple[100]!],
                ),
                borderRadius: BorderRadius.circular(10), // Smaller radius
              )
            : null,
        child: Icon(
          _selectedIndex == _getItemIndex(label) ? filledIcon : outlinedIcon,
        ),
      ),
      label: label,
    );
  }

  int _getItemIndex(String label) {
    switch (label) {
      case 'Home':
        return 0;
      case 'Catalog':
        return 1;
      case 'Stores':
        return 2;
      case 'Orders':
        return 3;
      case 'Shake':
        return 4;
      case 'Profile':
        return 5;
      default:
        return 0;
    }
  }
}
