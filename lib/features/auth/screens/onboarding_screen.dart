import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Welcome to Smart Van',
      'subtitle': 'Safe, Smart, and Stress-Free Rides for Your Child',
      'description':
          'We make school transportation stress-free for parents and safe for students. With real-time tracking and trained, trusted drivers, you\'ll always know your child is in good hands.',
      'image': 'assets/images/onboarding1.png',
    },
    {
      'title': 'Safe Rides, Every Day',
      'subtitle': 'Your Child\'s Safety, Our Priority',
      'description':
          'We provide trusted and secure transportation for students, ensuring peace of mind for parents every single day.',
      'image': 'assets/images/onboarding2.png',
    },
    {
      'title': 'Real-Time Tracking',
      'subtitle': 'Know Where They Are, Anytime',
      'description':
          'Track your child\'s ride in real-time, so you\'re always informed and never left wondering.',
      'image': 'assets/images/onboarding3.png',
    },
    {
      'title': 'Trained, Caring Drivers',
      'subtitle': 'Qualified Drivers Who Care',
      'description':
          'All of our drivers are background-checked, professionally trained, and committed to providing a safe, friendly journey for every child.',
      'image': 'assets/images/onboarding4.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final textHeight = 190 * MediaQuery.textScalerOf(context).scale(1);
    return Scaffold(
      backgroundColor: const Color(0xFF1B3B69),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen photo; only the text below swipes.
          Image.asset(
            'assets/images/login_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) =>
                const ColoredBox(color: Color(0xFF1B3B69)),
          ),
          // Gradient behind the text and buttons so they stay readable.
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x001B3B69),
                    Color(0xE61B3B69),
                    Color(0xFF1B3B69)
                  ],
                  stops: [0, 0.3, 0.6],
                ),
              ),
              padding: EdgeInsets.fromLTRB(24, 64, 24, 8 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: textHeight,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemCount: _slides.length,
                      itemBuilder: (context, index) =>
                          _buildSlideText(_slides[index]),
                    ),
                  ),
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFFFEC610)
                              : Colors.white30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEC610),
                        foregroundColor: const Color(0xFF1B3B69),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Log in or create an account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideText(Map<String, String> slide) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slide['title']!,
            style: const TextStyle(
              color: Color(0xFFFEC610),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            slide['subtitle']!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            slide['description']!,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontFamily: 'Poppins',
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
