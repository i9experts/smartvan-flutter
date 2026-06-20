import 'package:flutter/material.dart';
class OtpScreen extends StatelessWidget {
  final String phone;
  final bool isRegistration;
  const OtpScreen({super.key, required this.phone, required this.isRegistration});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('OTP Screen')));
}