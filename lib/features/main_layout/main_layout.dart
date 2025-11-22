import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
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

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ChatListScreen(),
    MyListingsScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ColorsManager.purple,
        unselectedItemColor: ColorsManager.grey,
        elevation: 10,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 0 ? Icons.home : Icons.home_outlined,
            ),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 1 ? Icons.chat_bubble : Icons.chat_bubble_outline,
            ),
            label: AppLocalizations.of(context)!.chat,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 2
                  ? Icons.featured_play_list_rounded
                  : Icons.featured_play_list_outlined,
            ),
            label: AppLocalizations.of(context)!.my_listing,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _currentIndex == 3 ? Icons.person_2_rounded : Icons.person_2_outlined,
            ),
            label: AppLocalizations.of(context)!.account,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createItem,
        backgroundColor: ColorsManager.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _createItem() {
    Navigator.pushNamed(context, Routes.addItem);
  }
}