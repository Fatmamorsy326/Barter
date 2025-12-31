import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/widgets/unread_messages_badge.dart';
import 'package:barter/core/widgets/login_required_sheet.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/features/account/account_screen.dart';
import 'package:barter/features/chat/chat_list_screen.dart';
import 'package:barter/features/home/home_screen.dart';
import 'package:barter/features/my_listing/my_listing_screen.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;
  late Animation<double> _fabScaleAnimation;

  final List<Widget> _screens = const [
    HomeScreen(),
    ChatListScreen(),
    MyListingsScreen(),
    AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNavBar(context),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      margin: REdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: ColorsManager.cardFor(context),
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.shadowFor(context),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: Padding(
          padding: REdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                outlinedIcon: Icons.home_outlined,
                label: AppLocalizations.of(context)!.home,
              ),
              // Chat item with UnreadMessagesBadge
              _buildChatNavItem(context),
              // Spacer for FAB
              SizedBox(width: 60.w),
              _buildNavItem(
                index: 2,
                icon: Icons.inventory_2_rounded,
                outlinedIcon: Icons.inventory_2_outlined,
                label: AppLocalizations.of(context)!.my_listing,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.person_rounded,
                outlinedIcon: Icons.person_outline_rounded,
                label: AppLocalizations.of(context)!.account,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatNavItem(BuildContext context) {
    final isSelected = _currentIndex == 1;
    
    return GestureDetector(
      onTap: () => _onTap(1),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: REdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    ColorsManager.gradientStart,
                    ColorsManager.gradientEnd,
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UnreadMessagesBadge(
              child: Icon(
                isSelected ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
                color: isSelected ? Colors.white : ColorsManager.textSecondaryFor(context),
                size: 22.sp,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 6.w),
              Text(
                AppLocalizations.of(context)!.chat,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData outlinedIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: REdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    ColorsManager.gradientStart,
                    ColorsManager.gradientEnd,
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? icon : outlinedIcon,
              color: isSelected ? Colors.white : ColorsManager.textSecondaryFor(context),
              size: 22.sp,
            ),
            if (isSelected) ...[
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return GestureDetector(
      onTapDown: (_) => _fabController.forward(),
      onTapUp: (_) {
        _fabController.reverse();
        _createItem();
      },
      onTapCancel: () => _fabController.reverse(),
      child: AnimatedBuilder(
        animation: _fabScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 56.w,
          height: 56.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ColorsManager.gradientStart,
                ColorsManager.gradientEnd,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ColorsManager.purple.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 28.sp,
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    if (index != 0 && FirebaseService.currentUser == null) {
      String feature = '';
      switch (index) {
        case 1:
          feature = AppLocalizations.of(context)!.chat;
          break;
        case 2:
          feature = AppLocalizations.of(context)!.my_listing;
          break;
        case 3:
          feature = AppLocalizations.of(context)!.account;
          break;
      }
      LoginRequiredSheet.show(context, feature);
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _createItem() {
    if (FirebaseService.currentUser == null) {
      LoginRequiredSheet.show(context, 'Add Item');
    } else {
      Navigator.pushNamed(context, Routes.addItem);
    }
  }
}