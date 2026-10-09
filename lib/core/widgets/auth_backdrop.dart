import 'package:flutter/material.dart';

/// Night-time van/school photo behind the top of the screen with a navy
/// overlay, shared by the auth screens.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final photoHeight = MediaQuery.sizeOf(context).height * 0.56;
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0B1B3F)),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: photoHeight,
          child: Image.asset(
            'assets/images/login_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: photoHeight,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x660B1B3F), Color(0x000B1B3F), Color(0x000B1B3F), Color(0xFF0B1B3F)],
                stops: [0, 0.3, 0.9, 1],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
