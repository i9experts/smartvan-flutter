import 'package:flutter/material.dart';

/// Night-time van/school photo with a navy overlay, shared by the auth screens.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0B1B3F)),
        Image.asset(
          'assets/images/login_bg.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x330B1B3F), Color(0xCC0B1B3F)],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

