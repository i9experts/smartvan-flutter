import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2B6B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_bus, size: 120, color: Colors.white),
              const SizedBox(height: 32),
              const Text(
                'Track Your Child\'s\nSchool Van',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Real-time GPS tracking, instant alerts\nand safe transportation for your kids',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  foregroundColor: const Color(0xFF1B2B6B),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Get Started',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins')),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text(
                  'Create New Account',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}