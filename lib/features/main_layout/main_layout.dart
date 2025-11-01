import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/features/Authentication/login/login.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  List<Widget> taps=[
    Scaffold(backgroundColor: Colors.white,),
    Scaffold(backgroundColor: Colors.pink,),
    Scaffold(backgroundColor: Colors.pink,),
    Scaffold(backgroundColor: Colors.pink,),
  ];
  int currentIndex=0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: taps[currentIndex],
      bottomNavigationBar:BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(currentIndex!=0?Icons.home_outlined:Icons.home),label: AppLocalizations.of(context)!.home),
          BottomNavigationBarItem(icon: Icon(currentIndex!=1?Icons.chat_bubble_outline:Icons.chat_bubble),label: AppLocalizations.of(context)!.chat),
          BottomNavigationBarItem(icon: Icon(currentIndex!=2?Icons.featured_play_list_outlined:Icons.featured_play_list_rounded),label: AppLocalizations.of(context)!.my_listing),
          BottomNavigationBarItem(icon: Icon(currentIndex!=3?Icons.person_2_outlined:Icons.person_2_rounded),label: AppLocalizations.of(context)!.account),
        ],
        currentIndex: currentIndex,
        onTap: _onTap,
        elevation: 10,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createEvent,
        child: Icon(Icons.add_circle_outline_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
  void _onTap(int index){
    setState(() {
      currentIndex=index;
    });
  }

  void _createEvent() {

  }
}
