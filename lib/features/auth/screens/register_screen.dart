import 'package:flutter/material.dart';
import '../../../core/widgets/auth_backdrop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import '../../../core/network/api_service.dart';
import '../../../core/widgets/html_asset_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => _openDoc('Terms & Conditions', 'terms_conditions');
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => _openDoc('Privacy Policy', 'privacy_policy');

  void _openDoc(String title, String file) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            HtmlAssetScreen(title: title, assetPath: 'assets/html/$file.html'),
      ),
    );
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _nameController.dispose();
    _schoolNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_nameController.text.isEmpty ||
        _schoolNameController.text.trim().isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    if (!_agreedToTerms) {
      _showError('Please agree to the Terms & Conditions');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.post('/auth/registeruser', {
        'fullname': _nameController.text.trim(),
        'schoolName': _schoolNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNo': _phoneController.text.trim(),
        'password': _passwordController.text,
        'userType': 'parent',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          context.go('/otp', extra: {
            'phone': _emailController.text.trim(),
            'isRegistration': true,
            'userType': 'parent',
          });
        }
      } else {
        // ApiService treats any 4xx as a normal (non-throwing) response, so
        // a validation failure (e.g. duplicate email) would otherwise just
        // reset the spinner with no explanation at all.
        final message = response.data is Map
            ? (response.data['message'] ?? 'Registration failed. Try again.')
            : 'Registration failed. Try again.';
        _showError(message.toString());
      }
    } on DioException catch (e) {
      final message =
          e.response?.data?['message'] ?? 'Registration failed. Try again.';
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

  // Natural (scale 1) height of the form: 6 fields with label + gaps, the
  // terms row, button and sign-in link. Used to pick a scale that fits.
  static double _formHeight(double s) {
    final fieldH =
        s >= 1 ? 56.0 : 2 * 16 * s + 1.6 * 14 * (s < 0.85 ? 0.85 : s);
    final labelH = 20 * s;
    final field = labelH + 8 * s + fieldH + 16 * s;
    return 6 * field + 48 * s + 8 * s + 52 * s + 16 * s + 22 * s + 16;
  }

  /// Largest scale (down to 0.5) at which the whole form fits the screen
  /// without scrolling.
  double _fitScale(BuildContext context) {
    final mq = MediaQuery.of(context);
    // size excludes the keyboard, so the layout doesn't jump when it opens.
    final avail = mq.size.height - mq.padding.top - mq.padding.bottom - 56 - 24;
    for (var s = 1.0; s > 0.5; s -= 0.05) {
      if (_formHeight(s) <= avail) return s;
    }
    return 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final s = _fitScale(context);
    final gap = 16 * s;
    return Scaffold(
      body: AuthBackdrop(
        child: Stack(
          children: [
            AuthSheet(
              topPadding: 24,
              bottomPadding: 8,
              children: [
                // Full Name
                _buildLabel(s, 'Full Name'),
                SizedBox(height: 8 * s),
                _buildTextField(
                  s,
                  controller: _nameController,
                  hint: 'Enter your full name',
                  icon: Icons.person_outlined,
                  keyboardType: TextInputType.name,
                ),
                SizedBox(height: gap),

                // School Name
                _buildLabel(s, 'School Name'),
                SizedBox(height: 8 * s),
                _buildTextField(
                  s,
                  controller: _schoolNameController,
                  hint: "Your child's school name",
                  icon: Icons.school_outlined,
                  keyboardType: TextInputType.name,
                ),
                SizedBox(height: gap),

                // Email
                _buildLabel(s, 'Email Address'),
                SizedBox(height: 8 * s),
                _buildTextField(
                  s,
                  controller: _emailController,
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: gap),

                // Phone
                _buildLabel(s, 'Phone Number'),
                SizedBox(height: 8 * s),
                _buildTextField(
                  s,
                  controller: _phoneController,
                  hint: 'Enter your phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: gap),

                // Password
                _buildLabel(s, 'Password'),
                SizedBox(height: 8 * s),
                _buildPasswordField(
                  s,
                  controller: _passwordController,
                  hint: 'Create a password',
                  obscure: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                SizedBox(height: gap),

                // Confirm Password
                _buildLabel(s, 'Confirm Password'),
                SizedBox(height: 8 * s),
                _buildPasswordField(
                  s,
                  controller: _confirmPasswordController,
                  hint: 'Confirm your password',
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                SizedBox(height: 8 * s),

                // Terms & Conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (val) =>
                          setState(() => _agreedToTerms = val ?? false),
                      activeColor: const Color(0xFFFEC610),
                      checkColor: const Color(0xFF1B3B69),
                      side: const BorderSide(color: Colors.white70, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: TextSpan(
                            text: 'I agree to the ',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms & Conditions',
                                recognizer: _termsTap,
                                style: const TextStyle(
                                  color: Color(0xFFFEC610),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFFFEC610),
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                recognizer: _privacyTap,
                                style: const TextStyle(
                                  color: Color(0xFFFEC610),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFFFEC610),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: gap),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 52 * s,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEC610),
                      foregroundColor: const Color(0xFF1B3B69),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                  ),
                ),
                SizedBox(height: gap),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Color(0xFFFEC610),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.go('/login'),
                    ),
                    const Text(
                      'Create Account',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(double s, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13 * (s < 0.85 ? 0.85 : s),
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildTextField(
    double s, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AuthTextField(
      controller: controller,
      hint: hint,
      icon: icon,
      keyboardType: keyboardType,
      scale: s,
    );
  }

  Widget _buildPasswordField(
    double s, {
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return AuthTextField(
      controller: controller,
      hint: hint,
      icon: Icons.lock_outlined,
      obscureText: obscure,
      scale: s,
      suffix: authVisibilityToggle(
        obscured: obscure,
        onPressed: onToggle,
        compact: s < 1,
      ),
    );
  }
}
