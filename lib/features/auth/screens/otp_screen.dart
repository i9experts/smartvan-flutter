import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:dio/dio.dart';
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
      final endpoint = widget.isRegistration
          ? '/auth/verifyOtp'
          : '/auth/verifyOtpForgot';

      final response = await ApiService.post(endpoint, {
        'email': widget.phone,
        'otp': _otpCode,
        'userType': widget.userType,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          if (widget.isRegistration) {
            context.go('/login');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Account verified! Please login.'),
                backgroundColor: const Color(0xFF27AE60),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else {
            context.go('/reset-password', extra: {
              'email': widget.phone,
              'otp': _otpCode,
              'userType': widget.userType,
            });
          }
        }
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

      await ApiService.post(resendEndpoint, {
        'email': widget.phone,
        'userType': widget.userType,
      });

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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => context.go('/register'),
                    ),
                    const Text(
                      'Verify OTP',
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
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.message_outlined,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'OTP Verification',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to\n${widget.phone}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 32),
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
                      children: [
                        const SizedBox(height: 24),
                        PinCodeTextField(
                          appContext: context,
                          length: 6,
                          onChanged: (val) => setState(() => _otpCode = val),
                          onCompleted: (val) => setState(() => _otpCode = val),
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.fade,
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 56,
                            fieldWidth: 48,
                            activeFillColor: Colors.white,
                            inactiveFillColor: Colors.white,
                            selectedFillColor: Colors.white,
                            activeColor: const Color(0xFF1B2B6B),
                            inactiveColor: const Color(0xFFEAECF0),
                            selectedColor: const Color(0xFF1B2B6B),
                          ),
                          enableActiveFill: true,
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2B6B),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOtp,
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
                                    'Verify OTP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Didn't receive the code? ",
                              style: TextStyle(
                                color: Color(0xFF8A94A6),
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
                                        color: Color(0xFF1B2B6B),
                                      ),
                                    )
                                  : Text(
                                      _resendSeconds > 0
                                          ? 'Resend in ${_resendSeconds}s'
                                          : 'Resend OTP',
                                      style: TextStyle(
                                        color: _resendSeconds > 0
                                            ? const Color(0xFF8A94A6)
                                            : const Color(0xFF1B2B6B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B2B6B).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF1B2B6B),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'The OTP is valid for 10 minutes. Please do not share it with anyone.',
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