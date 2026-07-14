import 'package:flutter/material.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2B6B), Color(0xFF2D4099)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.go('/login'),
                    ),
                    const Text(
                      'Forgot Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Lock icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_outlined,
                  size: 45,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reset Password',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email to receive\na password reset OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 32),
              // Bottom card
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Enter your registered email',
                            hintStyle: const TextStyle(
                              color: Color(0xFF8A94A6),
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF1B2B6B),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFEAECF0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFEAECF0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Color(0xFF1B2B6B), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Send OTP Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B2B6B),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
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
                        const SizedBox(height: 24),
                        // Info box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2B6B).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF1B2B6B),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'We will send a 6-digit OTP to your registered email address. Please check your inbox.',
                                  style: TextStyle(
                                    color: Color(0xFF1B2B6B),
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Back to login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Remember your password? ',
                              style: TextStyle(
                                color: Color(0xFF8A94A6),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Color(0xFF1B2B6B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}