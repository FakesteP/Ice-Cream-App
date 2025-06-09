import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icecreamapp/services/auth_service.dart';
import 'package:icecreamapp/pages/main_screen.dart';
import 'package:icecreamapp/pages/admin_dashboard.dart';
import 'package:icecreamapp/pages/auth/register_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late AnimationController _logoAnimationController;
  late AnimationController _particleAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Particle animation controller
    _particleAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Setup animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoAnimationController, curve: Curves.elasticOut),
    );

    _logoRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoAnimationController, curve: Curves.easeInOut),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _particleAnimationController, curve: Curves.linear),
    );

    // Start animations
    _animationController.forward();
    _logoAnimationController.forward();
    _particleAnimationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoAnimationController.dispose();
    _particleAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Add haptic feedback
    HapticFeedback.lightImpact();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final result = await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (result['success']) {
          HapticFeedback.mediumImpact();
          final userRole = result['role']?.toString().toLowerCase();

          if (mounted) {
            // Success animation before navigation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Welcome ${userRole == 'admin' ? 'Admin' : 'User'}!'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );

            await Future.delayed(const Duration(milliseconds: 500));

            if (userRole == 'admin') {
              Navigator.pushReplacement(
                context,
                _createPageRoute(const AdminDashboard()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                _createPageRoute(const MainScreen()),
              );
            }
          }
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _errorMessage = result['message'] ?? 'Login failed.';
          });
        }
      } catch (e) {
        HapticFeedback.heavyImpact();
        setState(() {
          _errorMessage = 'Network error occurred. Please try again.';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  PageRoute _createPageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
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
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background particles
              ...List.generate(20, (index) => _buildParticle(index, size)),

              // Main content
              SingleChildScrollView(
                child: Container(
                  height: size.height - MediaQuery.of(context).padding.top,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.08),

                      // Welcome Section with enhanced logo
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            children: [
                              // Enhanced App Logo
                              AnimatedBuilder(
                                animation: Listenable.merge([
                                  _logoScaleAnimation,
                                  _logoRotationAnimation
                                ]),
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _logoScaleAnimation.value,
                                    child: Transform.rotate(
                                      angle: _logoRotationAnimation.value * 0.1,
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.pink[300]!,
                                              Colors.pink[500]!,
                                              Colors.purple[400]!,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.pink[200]!
                                                  .withOpacity(0.6),
                                              blurRadius: 25,
                                              offset: const Offset(0, 15),
                                              spreadRadius: 5,
                                            ),
                                            BoxShadow(
                                              color: Colors.purple[100]!
                                                  .withOpacity(0.4),
                                              blurRadius: 40,
                                              offset: const Offset(0, 5),
                                              spreadRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.icecream_outlined,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 40),

                              // Enhanced Welcome Text
                              ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [
                                    Colors.pink[600]!,
                                    Colors.purple[600]!
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1.0,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sign in to continue your sweet journey',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.06),

                      // Enhanced Form Section
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                                spreadRadius: 5,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Error Message with animation
                                if (_errorMessage != null)
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 300),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Container(
                                          width: double.infinity,
                                          margin:
                                              const EdgeInsets.only(bottom: 24),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.red[50]!,
                                                Colors.red[100]!
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: Colors.red[200]!,
                                                width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.error_outline,
                                                  color: Colors.red[600],
                                                  size: 24),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: TextStyle(
                                                    color: Colors.red[700],
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                // Email Field
                                _buildEnhancedTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  hint: 'Enter your email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Password Field
                                _buildEnhancedTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    icon: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        key: ValueKey(_obscurePassword),
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 32),

                                // Enhanced Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: _isLoading
                                                ? [
                                                    Colors.grey[400]!,
                                                    Colors.grey[500]!
                                                  ]
                                                : [
                                                    Colors.pink[400]!,
                                                    Colors.pink[600]!,
                                                    Colors.purple[500]!
                                                  ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: _isLoading
                                              ? null
                                              : [
                                                  BoxShadow(
                                                    color: Colors.pink[300]!
                                                        .withOpacity(0.5),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                        ),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Colors.white),
                                                  ),
                                                )
                                              : const Text(
                                                  'Sign In',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Enhanced Register Link
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          const RegisterPage(),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        return SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(1.0, 0.0),
                                            end: Offset.zero,
                                          ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeInOut)),
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Colors.pink[500]!,
                                      Colors.purple[500]!
                                    ],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticle(int index, Size size) {
    final random = (index * 1234567) % 100;
    final left = (random / 100) * size.width;
    final duration = 3 + (random % 3);

    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        final progress = (_particleAnimation.value + (random / 100)) % 1.0;
        final top = size.height * progress;

        return Positioned(
          left: left,
          top: top,
          child: Opacity(
            opacity: 0.1 + (0.2 * (1 - progress)),
            child: Container(
              width: 4 + (random % 3),
              height: 4 + (random % 3),
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

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink[100]!, Colors.purple[100]!],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.pink[600],
                size: 20,
              ),
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.pink[400]!, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red[500]!, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            errorStyle: TextStyle(
              color: Colors.red[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}
