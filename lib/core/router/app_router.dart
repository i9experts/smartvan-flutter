import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/tracking/screens/tracking_screen.dart';
import '../../features/kids/screens/kids_screen.dart';
import '../../features/kids/screens/add_kid_screen.dart';
import '../../features/alerts/screens/alerts_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return OtpScreen(
          phone: extra['phone'],
          isRegistration: extra['isRegistration'] ?? true,
        );
      },
    ),
    GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/tracking', builder: (context, state) => const TrackingScreen()),
    GoRoute(path: '/kids', builder: (context, state) => const KidsScreen()),
    GoRoute(path: '/add-kid', builder: (context, state) => const AddKidScreen()),
    GoRoute(path: '/alerts', builder: (context, state) => const AlertsScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
  ],
);