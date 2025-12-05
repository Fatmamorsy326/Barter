import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Find Unique Items',
      description: 'Discover hidden gems and unique items in your local community.',
      icon: Icons.search_rounded,
      color: const Color(0xFF6C63FF),
    ),
    OnboardingItem(
      title: 'Propose Exchange',
      description: 'Offer your items in exchange for what you want. No money needed!',
      icon: Icons.swap_horizontal_circle_rounded,
      color: const Color(0xFFFF6584),
    ),
    OnboardingItem(
      title: 'Chat & Meet',
      description: 'Connect with owners, chat securely, and arrange the exchange.',
      icon: Icons.chat_bubble_rounded,
      color: const Color(0xFF4ECDC4),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.backgroundFor(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return _buildPage(_items[index]);
                },
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingItem item) {
    return Padding(
      padding: REdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: REdgeInsets.all(40),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 100.sp,
              color: item.color,
            ),
          ),
          SizedBox(height: 48.h),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: ColorsManager.textFor(context),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              color: ColorsManager.textSecondaryFor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: REdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Indicators
          Row(
            children: List.generate(
              _items.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: REdgeInsets.only(right: 8),
                height: 8.h,
                width: _currentPage == index ? 24.w : 8.w,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? ColorsManager.purpleFor(context)
                      : ColorsManager.purpleFor(context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),

          // Button
          ElevatedButton(
            onPressed: () {
              if (_currentPage == _items.length - 1) {
                _completeOnboarding();
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorsManager.purpleFor(context),
              foregroundColor: Colors.white,
              padding: REdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            child: Row(
              children: [
                Text(
                  _currentPage == _items.length - 1 ? 'Get Started' : 'Next',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                if (_currentPage != _items.length - 1) ...[
                  SizedBox(width: 8.w),
                  Icon(Icons.arrow_forward_rounded, size: 20.sp),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
