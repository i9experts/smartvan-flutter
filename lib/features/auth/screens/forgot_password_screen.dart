import 'package:flutter/material.dart';
import '../../../core/widgets/auth_backdrop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_service.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/auth/forgot-password', {
        'email': _emailController.text.trim(),
        'userType': 'parent',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          context.go('/otp', extra: {
            'phone': _emailController.text.trim(),
            'isRegistration': false,
            'userType': 'parent',
          });
        }
      } else {
        // ApiService treats any 4xx as a normal (non-throwing) response, so
        // e.g. "no account with this email" would otherwise just reset the
        // spinner with no explanation.
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to send OTP. Try again.')
            : 'Failed to send OTP. Try again.';
        _showError(message.toString());
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Failed to send OTP. Try again.';
      _showError(message.toString());
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF4B4B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackdrop(
        child: Stack(
          children: [
            AuthSheet(
              children: [
                const AuthHeader(
                  icon: Icons.lock_reset_outlined,
                  title: 'Reset Password',
                  subtitle: 'Enter your email to receive\na password reset OTP',
                ),
                Text(
                  'Email Address',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _emailController,
                  hint: 'Enter your registered email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEC610),
                      foregroundColor: const Color(0xFF1B3B69),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                            'Send Reset OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const AuthInfoBox(
                  text:
                      'We will send a 6-digit OTP to your registered email address. Please check your inbox.',
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Remember your password? ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        'Sign In',
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
            AuthTopBar(
              title: 'Forgot Password',
              onBack: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
