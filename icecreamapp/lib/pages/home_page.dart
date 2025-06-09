import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icecreamapp/pages/status_page.dart';
import 'package:icecreamapp/services/auth_service.dart';
import 'package:icecreamapp/models/user_model.dart';
import 'package:icecreamapp/pages/catalog_page.dart';
import 'package:icecreamapp/pages/order_history_page.dart';
import 'package:icecreamapp/pages/stores_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // --- Existing state variables ---
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;

  final TextEditingController _currencyAmountController =
      TextEditingController();
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _convertedAmount = 0.0;
  Map<String, dynamic> _exchangeRates = {};
  DateTime? _ratesLastUpdated;

  // --- New animation controllers for modern theme ---
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _particleAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _particleAnimation;

  final List<Map<String, String>> _currencies = [
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fadeAnimationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideAnimationController, curve: Curves.easeOutCubic));

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
    _currencyAmountController.dispose();
    super.dispose();
  }

  // --- Fungsi yang Dikonsolidasi ---
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Jalankan semua proses loading secara bersamaan
      await Future.wait([
        _loadCurrentUser(),
        _fetchExchangeRates(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          // Error occurred during loading
        });
      }
      print("Error loading initial data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    _currentUser = await _authService.getCurrentUser();
  }

  // --- Logika Currency yang Disatukan ---
  Future<void> _fetchExchangeRates() async {
    const String baseCurrency = 'USD';
    final Uri apiUrl =
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$baseCurrency');

    try {
      final response = await http.get(apiUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _exchangeRates = data['rates'];
        _ratesLastUpdated = DateTime.now();
      } else {
        throw Exception('Failed to load rates from API');
      }
    } catch (e) {
      print("API fetch failed, using static rates. Error: $e");
      _useStaticRates();
    }
  }

  void _useStaticRates() {
    _exchangeRates = {
      'USD': 1.0,
      'IDR': 16250.7,
      'EUR': 0.92,
      'JPY': 157.3,
      'SGD': 1.35,
      'MYR': 4.70,
    };
    _ratesLastUpdated = null;
  }

  void _convertCurrency() {
    if (_currencyAmountController.text.isEmpty || _exchangeRates.isEmpty) {
      if (mounted) setState(() => _convertedAmount = 0.0);
      return;
    }

    try {
      final double amount =
          double.parse(_currencyAmountController.text.replaceAll(',', ''));
      final double fromRate = _exchangeRates[_fromCurrency]?.toDouble() ?? 1.0;
      final double toRate = _exchangeRates[_toCurrency]?.toDouble() ?? 1.0;
      final double result = (amount / fromRate) * toRate;

      if (mounted) setState(() => _convertedAmount = result);
    } catch (e) {
      print('Error converting currency: $e');
      if (mounted) setState(() => _convertedAmount = 0.0);
    }
  }

  String _formatCurrency(double amount, String currencyCode) {
    final currency = _currencies.firstWhere(
      (c) => c['code'] == currencyCode,
      orElse: () => {'symbol': '$currencyCode '},
    );
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '${currency['symbol']} ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
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
            // Animated background particles (same as login)
            ...List.generate(15, (index) => _buildParticle(index, size)),

            // Main content
            _isLoading ? _buildLoadingShimmer() : _buildMainContent(),
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
            opacity: 0.08 + (0.15 * (1 - progress)),
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

  Widget _buildLoadingShimmer() {
    return SafeArea(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 60),
            Container(width: 200, height: 32, color: Colors.white),
            const SizedBox(height: 8),
            Container(width: double.infinity, height: 20, color: Colors.white),
            const SizedBox(height: 40),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: List.generate(
                  4,
                  (index) => Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      )),
            ),
            const SizedBox(height: 30),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: CustomScrollView(
        slivers: [
          _buildModernSliverAppBar(),
          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 24),
              _buildAnimatedSection(_buildQuickActions()),
              const SizedBox(height: 24),
              _buildAnimatedSection(_buildFeaturedSection()),
              const SizedBox(height: 24),
              _buildAnimatedSection(_buildToolsSection()),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildModernSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.pink[400]!.withOpacity(0.9),
                Colors.purple[400]!.withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Colors.white70],
                        ).createShader(bounds),
                        child: Text(
                          _currentUser != null
                              ? 'Hello, ${_currentUser!.username}!'
                              : 'Hello, Guest!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'What sweet treat are you looking for today?',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSection(Widget child) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: child,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.pink[600]!, Colors.purple[600]!],
            ).createShader(bounds),
            child: const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildModernActionCard(
              icon: Icons.icecream_outlined,
              title: 'View Catalog',
              color: Colors.orange,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CatalogPage()));
              },
            ),
            _buildModernActionCard(
              icon: Icons.history_outlined,
              title: 'Order History',
              color: Colors.lightBlue,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OrderHistoryPage()));
              },
            ),
            _buildModernActionCard(
              icon: Icons.store_mall_directory_outlined,
              title: 'Find Stores',
              color: Colors.green,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StoresPage()));
              },
            ),
            _buildModernActionCard(
              icon: Icons.rate_review_outlined,
              title: 'Feedback',
              color: Colors.purple,
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StatusPage()));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernActionCard({
    required IconData icon,
    required String title,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 2,
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 0.2,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.pink[600]!, Colors.purple[600]!],
            ).createShader(bounds),
            child: const Text(
              'Special Offer',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 3,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.pink[400]!,
                    Colors.purple[400]!,
                    Colors.blue[400]!,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative elements
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.icecream,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Choco Berry Blast!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "20% discount for new flavor. Limited time only!",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.pink[600]!, Colors.purple[600]!],
            ).createShader(bounds),
            child: const Text(
              'Handy Tools',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _showCurrencyConverter();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green[100]!, Colors.green[200]!],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.currency_exchange,
                        size: 28, color: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Currency Converter',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 0.2,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Check live exchange rates',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCurrencyConverter() {
    if (mounted) {
      setState(() {
        _fromCurrency = 'IDR';
        _toCurrency = 'USD';
        _currencyAmountController.text = '50000';
      });
    }
    _convertCurrency();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void swapCurrencies() {
              setModalState(() {
                final temp = _fromCurrency;
                _fromCurrency = _toCurrency;
                _toCurrency = temp;
              });
              _convertCurrency();
            }

            void updateState(VoidCallback fn) {
              setModalState(fn);
              _convertCurrency();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.pink[600]!, Colors.purple[600]!],
                          ).createShader(bounds),
                          child: const Text(
                            'Currency Converter',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_ratesLastUpdated != null)
                      Text(
                        'Live rates updated: ${DateFormat.yMd().add_jm().format(_ratesLastUpdated!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )
                    else
                      Text(
                        'Using offline cached rates',
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange[700]),
                      ),
                    const SizedBox(height: 32),

                    // Enhanced form fields (same style as login)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _currencyAmountController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (value) => _convertCurrency(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            decoration: InputDecoration(
                              prefixText:
                                  '${_currencies.firstWhere((c) => c['code'] == _fromCurrency)['symbol']} ',
                              prefixStyle: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                              hintText: '0',
                              border: InputBorder.none,
                            ),
                          ),
                          _buildCurrencyDropdown(
                            value: _fromCurrency,
                            onChanged: (val) =>
                                updateState(() => _fromCurrency = val!),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.pink[400]!,
                                      Colors.purple[400]!
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.swap_vert,
                                    color: Colors.white),
                              ),
                              onPressed: swapCurrencies,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green[50]!, Colors.green[100]!],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatCurrency(_convertedAmount, _toCurrency),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.green,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          _buildCurrencyDropdown(
                            value: _toCurrency,
                            onChanged: (val) =>
                                updateState(() => _toCurrency = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrencyDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      underline: Container(),
      items: _currencies.map((currency) {
        return DropdownMenuItem<String>(
          value: currency['code'],
          child: Text(
            '${currency['code']} - ${currency['name']}',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
