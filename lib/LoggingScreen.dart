// LoggingScreen.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'HomeScreen.dart';
import 'user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late AnimationController _backgroundController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  bool _showUsernameError = false;
  bool _showPasswordError = false;
  bool _isSignUp = false;

  final UserService _userService = UserService();

  // --------------------------------------
  // INITIALIZATION AND DISPOSAL
  // --------------------------------------
  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

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
    _emailController.dispose();
    _phoneController.dispose();
    _backgroundController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // --------------------------------------
  // ANIMATED BACKGROUND
  // --------------------------------------
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
              stops: const [0.0, 0.4, 0.7, 1.0],
              transform: GradientRotation(value * 2 * pi),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------
  // HEADING WITH ICON
  // --------------------------------------
  Widget _buildHeading() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_rounded,
            color: Colors.white,
            size: 40,
            shadows: const [
              Shadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          const SizedBox(width: 16),
          Text(
            'Smart Assistant',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: const [
                Shadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------
  // INPUT FIELD
  // --------------------------------------
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    required bool error,
    bool isOptional = false,
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: Icon(
                icon,
                color: Colors.white.withOpacity(_glowAnimation.value),
                size: 28,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: error ? Colors.redAccent : Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white.withOpacity(_glowAnimation.value), width: 2),
              ),
              errorText: error && !isOptional ? 'This field is required' : null,
              errorStyle: const TextStyle(color: Colors.redAccent),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------
  // LOGIN / SIGNUP FORM
  // --------------------------------------
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
            _buildInputField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.person_outline_rounded,
              error: _showUsernameError,
            ),
            const SizedBox(height: 24),
            _buildInputField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: true,
              error: _showPasswordError,
            ),
            const SizedBox(height: 24),
            if (_isSignUp) ...[
              _buildInputField(
                controller: _emailController,
                label: 'Email (optional)',
                icon: Icons.email_outlined,
                error: false,
                isOptional: true,
              ),
              const SizedBox(height: 24),
              _buildInputField(
                controller: _phoneController,
                label: 'Phone (optional)',
                icon: Icons.phone_outlined,
                error: false,
                isOptional: true,
              ),
              const SizedBox(height: 24),
            ],
            _buildActionButton(),
            const SizedBox(height: 16),
            _buildToggleLink(),
            const SizedBox(height: 16),
            _buildGuestLoginButton(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------
  // ACTION BUTTON (Login / Sign Up)
  // --------------------------------------
  Widget _buildActionButton() {
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
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[500]!]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                alignment: Alignment.center,
                constraints: const BoxConstraints(minHeight: 52),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isSignUp ? Icons.person_add : Icons.login_rounded, size: 22, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _isSignUp ? 'Sign Up' : 'Login',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
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

  // --------------------------------------
  // TOGGLE LINK (Login ↔ Sign Up)
  // --------------------------------------
  Widget _buildToggleLink() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSignUp = !_isSignUp;
          _clearErrors();
        });
      },
      child: Text(
        _isSignUp ? 'Already have an account? Login' : 'New user? Sign up here',
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
  // GUEST LOGIN BUTTON
  // --------------------------------------
  Widget _buildGuestLoginButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return TextButton.icon(
          onPressed: () async {
            await _userService.logout();
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          },
          icon: Icon(Icons.person_add_alt_1_rounded, color: Colors.white.withOpacity(_glowAnimation.value), size: 20),
          label: const Text('Guest Login', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        );
      },
    );
  }

  // --------------------------------------
  // LOGIC
  // --------------------------------------
  void _clearErrors() {
    setState(() {
      _showUsernameError = false;
      _showPasswordError = false;
    });
  }

  Future<void> _handleSubmit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _showUsernameError = username.isEmpty;
      _showPasswordError = password.isEmpty;
    });

    if (_showUsernameError || _showPasswordError) return;

    String? error;

    if (_isSignUp) {
      error = await _userService.signUp(
        username: username,
        password: password,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );
      if (error == null) {
        await _userService.login(username: username, password: password);
      }
    } else {
      error = await _userService.login(username: username, password: password);
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', username);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  // --------------------------------------
  // MAIN BUILD
  // --------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeading(),
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
