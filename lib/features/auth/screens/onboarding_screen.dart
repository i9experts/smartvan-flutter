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
  String _selectedLanguage = 'English US';

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

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Choose Your Preferred Language',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                    fontFamily: 'Poppins',
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Color(0xFF8A94A6)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLanguageOption('🇺🇸', 'English USA'),
            _buildLanguageOption('🇹🇷', 'Turkish'),
            _buildLanguageOption('🇵🇰', 'اردو'),
            _buildLanguageOption('🇸🇦', 'العربية'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String flag, String language) {
    final isSelected = _selectedLanguage == language;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedLanguage = language);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B2B6B).withOpacity(0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected
                      ? const Color(0xFF1B2B6B)
                      : const Color(0xFF1A1A2E),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF1B2B6B), size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return _buildSlide(slide);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(Map<String, String> slide) {
    return Column(
      children: [
        // Top image area
        Expanded(
          flex: 4,
          child: Stack(
            children: [
              // Background image or color
              Container(
                width: double.infinity,
                color: const Color(0xFFE8F0FF),
                child: _buildSlideImage(slide['image']!),
              ),
              // Language selector at top
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: _showLanguageSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEAECF0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🇺🇸', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            _selectedLanguage,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              color: Color(0xFF1A1A2E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down,
                              size: 16, color: Color(0xFF8A94A6)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom navy section
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B2B6B), Color(0xFF2D4099)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  slide['title']!,
                  style: const TextStyle(
                    color: Color(0xFFFFB800),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
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
                // Description
                Text(
                  slide['description']!,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    height: 1.6,
                  ),
                ),
                const Spacer(),

                // Dot indicators
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
                            ? const Color(0xFFFFB800)
                            : Colors.white30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Log in button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB800),
                      foregroundColor: const Color(0xFF1B2B6B),
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
                const SizedBox(height: 12),

                // Skip button
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
    );
  }

  Widget _buildSlideImage(String imagePath) {
    // Use placeholder icons since we don't have the actual photos
    final icons = [
      Icons.directions_bus_filled,
      Icons.child_care,
      Icons.location_on,
      Icons.person,
    ];
    final colors = [
      const Color(0xFF1B2B6B),
      const Color(0xFF27AE60),
      const Color(0xFFFFB800),
      const Color(0xFF1B2B6B),
    ];
    final index = _slides.indexWhere((s) => s['image'] == imagePath);
    return Center(
      child: Icon(
        icons[index >= 0 ? index : 0],
        size: 120,
        color: colors[index >= 0 ? index : 0].withOpacity(0.3),
      ),
    );
  }
}