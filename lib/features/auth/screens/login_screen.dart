import 'package:flutter/material.dart';
import '../../../core/widgets/auth_backdrop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/services/fcm_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please enter email and password');
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Get FCM token before login
      String? fcmToken;
      try {
        fcmToken = await FCMService.getToken();
      } catch (e) {
        debugPrint('FCM token error: $e');
      }
      final response = await ApiService.post('/auth/login', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'userType': 'parent',
        if (fcmToken != null) 'fcmToken': fcmToken,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['data']?['token'] ??
            data['token'] ??
            data['access_token'] ??
            '';
        await TokenStorage.save(token.toString());
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_type', 'parent');

        // FCM token was already sent as part of the /auth/login request
        // above, and the backend saves it there — no separate call needed.
        if (fcmToken != null) {
          await prefs.setString('fcm_token', fcmToken);
        }
        if (mounted) context.go('/home');
      } else {
        _showError(
            response.data?['message'] ?? 'Login failed. Please try again.');
      }
    } on Exception catch (e) {
      _showError('Login failed. Please check your credentials and try again.');
      debugPrint('Login error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: const Color(0xFFFF4B4B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hide the heading while the keyboard is up so the form and Login stay visible.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      body: AuthBackdrop(
        child: AuthSheet(
          children: [
            // One fixed slot (not a conditional spread) so the fields below keep
            // their element/focus when the keyboard opens and this collapses.
            keyboardOpen
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFEC610),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Sign in to track your child's journey",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
            _buildInputLabel('Email Address'),
            const SizedBox(height: 8),
            AuthTextField(
              controller: _emailController,
              hint: 'Enter your email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildInputLabel('Password'),
            const SizedBox(height: 8),
            AuthTextField(
              controller: _passwordController,
              hint: 'Enter your password',
              icon: Icons.lock_outlined,
              obscureText: _obscurePassword,
              suffix: authVisibilityToggle(
                obscured: _obscurePassword,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/forgot-password'),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: Color(0xFFFEC610),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEC610),
                  foregroundColor: const Color(0xFF1B3B69),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B3B69),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/register'),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFFFEC610),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
    );
  }
}
