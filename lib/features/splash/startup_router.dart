import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartupRouter extends StatefulWidget {
  const StartupRouter({super.key});

  @override
  State<StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<StartupRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goNext());
  }

  Future<void> _goNext() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

    if (!mounted) return;

    if (!onboardingSeen) {
      Navigator.pushReplacementNamed(context, Routes.onboarding);
      return;
    }

    final user = FirebaseService.currentUser;
    Navigator.pushReplacementNamed(
      context,
      user != null ? Routes.mainLayout : Routes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nothing rendered => native splash disappears as soon as first frame is ready
    return const Scaffold(body: SizedBox.shrink());
  }
}
