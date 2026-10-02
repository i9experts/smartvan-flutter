import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/tracking/screens/parent_tracking_screen.dart';
import '../../features/kids/screens/kids_screen.dart';
import '../../features/kids/screens/add_kid_screen.dart';
import '../../features/alerts/screens/alerts_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../../features/fees/screens/payment_history_screen.dart';
import '../../features/chat/chat_api.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/chat/screens/conversations_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
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
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ResetPasswordScreen(
          email: extra['email'] as String,
          otp: extra['otp'] as String,
        );
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => const TrackingScreen(),
    ),
    GoRoute(
      path: '/kids',
      builder: (context, state) => const KidsScreen(),
    ),
    GoRoute(
      path: '/add-kid',
      builder: (context, state) => const AddKidScreen(),
    ),
    GoRoute(
      path: '/alerts',
      builder: (context, state) => const AlertsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/payment-history',
      builder: (context, state) => const PaymentHistoryScreen(),
    ),
    GoRoute(
      path: '/chats',
      builder: (context, state) => const ConversationsScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) =>
          ChatScreen(conversation: state.extra as Conversation),
    ),
  ],
);