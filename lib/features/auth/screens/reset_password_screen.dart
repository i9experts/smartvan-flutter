import 'package:flutter/material.dart';
import '../../../core/widgets/auth_backdrop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_service.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String otp;
  final String userType;
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
    this.userType = 'parent',
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/auth/reset-password', {
        'email': widget.email,
        'otp': widget.otp,
        'userType': widget.userType,
        'newPassword': _passwordController.text,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          context.go('/login');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password reset successful! Please login.'),
              backgroundColor: const Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        // ApiService treats any 4xx as a normal (non-throwing) response, so
        // an expired OTP would otherwise just reset the spinner with no
        // explanation.
        final message = response.data is Map
            ? (response.data['message'] ?? 'Reset failed. Try again.')
            : 'Reset failed. Try again.';
        _showError(message.toString());
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Reset failed. Try again.';
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
                  icon: Icons.lock_outlined,
                  title: 'Create New Password',
                  subtitle:
                      'Your new password must be\ndifferent from the previous one',
                ),
                Text(
                  'New Password',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _passwordController,
                  hint: 'Enter new password',
                  icon: Icons.lock_outlined,
                  obscureText: _obscurePassword,
                  suffix: authVisibilityToggle(
                    obscured: _obscurePassword,
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Confirm Password',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _confirmPasswordController,
                  hint: 'Confirm new password',
                  icon: Icons.lock_outlined,
                  obscureText: _obscureConfirm,
                  suffix: authVisibilityToggle(
                    obscured: _obscureConfirm,
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
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
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                  ),
                ),
              ],
            ),
            AuthTopBar(
              title: 'Reset Password',
              onBack: () => context.go('/login'),
            ),
          ],
        ),
      ),
    );
  }
}
