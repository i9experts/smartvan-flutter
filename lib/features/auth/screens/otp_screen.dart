import 'package:flutter/material.dart';
import '../../../core/widgets/auth_backdrop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_service.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final bool isRegistration;
  final String userType;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.isRegistration,
    this.userType = 'parent',
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _otpCode = '';
  bool _isLoading = false;
  bool _isResending = false;
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Stream.periodic(const Duration(seconds: 1), (i) => i).take(60).listen((_) {
      if (mounted) {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      _showError('Please enter the complete 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final endpoint =
          widget.isRegistration ? '/auth/verifyOtp' : '/auth/verifyOtpForgot';

      final response = await ApiService.post(endpoint, {
        'email': widget.phone,
        'otp': _otpCode,
        'userType': widget.userType,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          if (widget.isRegistration) {
            final data = response.data;
            final token = data['data']?['token'] ??
                data['token'] ??
                data['access_token'] ??
                '';
            await TokenStorage.save(token.toString());
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_type', 'parent');
            if (mounted) context.go('/home');
          } else {
            context.go('/reset-password', extra: {
              'email': widget.phone,
              'otp': _otpCode,
              'userType': widget.userType,
            });
          }
        }
      } else {
        // ApiService treats any 4xx as a normal (non-throwing) response, so
        // a wrong/expired OTP would otherwise just reset the spinner with
        // no explanation and no way to tell the code was rejected.
        final message = response.data is Map
            ? (response.data['message'] ?? 'Invalid OTP. Try again.')
            : 'Invalid OTP. Try again.';
        _showError(message.toString());
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Invalid OTP. Try again.';
      _showError(message.toString());
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0) return;
    setState(() => _isResending = true);

    try {
      final resendEndpoint = widget.isRegistration
          ? '/auth/resend-otp'
          : '/auth/resend-otp-reset-password';

      final response = await ApiService.post(resendEndpoint, {
        'email': widget.phone,
        'userType': widget.userType,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _resendSeconds = 60);
        _startTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('OTP resent successfully!'),
              backgroundColor: const Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Failed to resend OTP. Try again.')
            : 'Failed to resend OTP. Try again.';
        _showError(message.toString());
      }
    } catch (e) {
      _showError('Failed to resend OTP. Try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
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
                AuthHeader(
                  icon: Icons.message_outlined,
                  title: 'OTP Verification',
                  subtitle: 'Enter the 6-digit code sent to\n${widget.phone}',
                ),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  onChanged: (val) => setState(() => _otpCode = val),
                  onCompleted: (val) => setState(() => _otpCode = val),
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  backgroundColor: Colors.transparent,
                  cursorColor: const Color(0xFFFEC610),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 54,
                    fieldWidth: 46,
                    borderWidth: 1.2,
                    activeFillColor: Colors.transparent,
                    inactiveFillColor: Colors.transparent,
                    selectedFillColor: Colors.transparent,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white38,
                    selectedColor: const Color(0xFFFEC610),
                  ),
                  enableActiveFill: true,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
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
                            'Verify OTP',
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
                      "Didn't receive the code? ",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    GestureDetector(
                      onTap: _resendSeconds == 0 ? _resendOtp : null,
                      child: _isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFEC610),
                              ),
                            )
                          : Text(
                              _resendSeconds > 0
                                  ? 'Resend in ${_resendSeconds}s'
                                  : 'Resend OTP',
                              style: TextStyle(
                                color: _resendSeconds > 0
                                    ? Colors.white54
                                    : const Color(0xFFFEC610),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const AuthInfoBox(
                  text:
                      'The OTP is valid for 10 minutes. Please do not share it with anyone.',
                ),
              ],
            ),
            AuthTopBar(
              title: 'Verify OTP',
              onBack: () => context.go('/register'),
            ),
          ],
        ),
      ),
    );
  }
}
