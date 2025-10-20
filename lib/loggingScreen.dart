// loggingScreen.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'home.dart'; // Import HomeScreen for navigation

class LoggingScreen extends StatefulWidget {
  const LoggingScreen({super.key});

  @override
  State<LoggingScreen> createState() => _LoggingScreenState();
}

class _LoggingScreenState extends State<LoggingScreen> with TickerProviderStateMixin {
  // --------------------------------------
  // STATE VARIABLES
  // --------------------------------------
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _backgroundController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _showUsernameError = false;
  bool _showPasswordError = false;

  // --------------------------------------
  // INITIALIZATION AND DISPOSAL
  // --------------------------------------
  @override
  void initState() {
    super.initState();
    // Setup background animation for dynamic gradient shift
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    // Setup glow animation for icons and buttons
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _backgroundController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // --------------------------------------
  // UI WIDGETS
  // --------------------------------------
  /// Builds an animated, eye-catching gradient background
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        final double value = _backgroundController.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[700]!.withOpacity(0.8 + value * 0.2),
                Colors.indigo[600]!.withOpacity(0.7 + value * 0.1),
                Colors.purple[400]!.withOpacity(0.6 + value * 0.1),
                Colors.blue[400]!.withOpacity(0.9 + value * 0.1),
              ],
              stops: [0.0, 0.4, 0.7, 1.0],
              transform: GradientRotation(value * 2 * pi),
            ),
          ),
        );
      },
    );
  }

  /// Builds the heading with icon
  Widget _buildHeading() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_rounded,
            color: Colors.blue[50],
            size: 36,
            shadows: [
              Shadow(
                color: Colors.blueAccent.withOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
          const SizedBox(width: 12),
          Text(
            'Smart Assistant',
            style: TextStyle(
              color: Colors.blue[50],
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: Colors.blueAccent.withOpacity(0.5),
                  blurRadius: 10,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the login form with glassmorphic fields and fancy icons
  Widget _buildLoginForm() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.blue[900]!.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Username field with fancy icon and glow
            _buildInputField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.person_outline_rounded,
              error: _showUsernameError,
            ),
            const SizedBox(height: 24),
            // Password field with fancy icon and glow
            _buildInputField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              error: _showPasswordError,
            ),
            const SizedBox(height: 32),
            // Login button with neumorphic design and animation
            _buildLoginButton(),
            const SizedBox(height: 16),
            // Guest login with subtle animation
            _buildGuestLoginButton(),
            const SizedBox(height: 16),
            // Sign-up link with fancy underline
            _buildSignUpLink(),
          ],
        ),
      ),
    );
  }

  /// Builds a glassmorphic input field with animated glow icon
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    required bool error,
  }) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(_glowAnimation.value * 0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.blue[50]?.withOpacity(0.9)),
              prefixIcon: Icon(
                icon,
                color: Colors.blue[50]?.withOpacity(_glowAnimation.value),
                size: 28,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: error ? Colors.redAccent : Colors.blueAccent.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.blue[50]!.withOpacity(_glowAnimation.value),
                  width: 2,
                ),
              ),
              errorText: error ? 'This field is required' : null,
              errorStyle: const TextStyle(color: Colors.redAccent),
            ),
            style: TextStyle(color: Colors.blue[50]),
          ),
        );
      },
    );
  }

  /// Builds the login button with animated gradient and glow
  Widget _buildLoginButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue[700]!.withOpacity(_glowAnimation.value * 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _showUsernameError = _usernameController.text.trim().isEmpty;
                _showPasswordError = _passwordController.text.trim().isEmpty;
              });
              // Dummy login: Navigate regardless
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                alignment: Alignment.center,
                constraints: const BoxConstraints(maxHeight: 52),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.login_rounded, size: 22, color: Colors.blue[50]),
                    const SizedBox(width: 8),
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue[50],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the guest login button with subtle glow
  Widget _buildGuestLoginButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return TextButton.icon(
          onPressed: () {
            // Clear fields and navigate
            _usernameController.clear();
            _passwordController.clear();
            setState(() {
              _showUsernameError = false;
              _showPasswordError = false;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
          icon: Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.blue[50]?.withOpacity(_glowAnimation.value),
            size: 20,
          ),
          label: Text(
            'Guest Login',
            style: TextStyle(
              color: Colors.blue[50],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
    );
  }

  /// Builds the sign-up link with animated underline
  Widget _buildSignUpLink() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-up feature coming soon!')),
        );
      },
      child: Text(
        'New user? Sign up here',
        style: TextStyle(
          color: Colors.blue[100],
          fontSize: 14,
          decoration: TextDecoration.underline,
          decorationColor: Colors.blueAccent.withOpacity(0.7),
          decorationThickness: 2,
        ),
      ),
    );
  }

  // --------------------------------------
  // MAIN UI BUILD
  // --------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          // Main content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Heading with icon
                  _buildHeading(),
                  // Login form
                  _buildLoginForm(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}