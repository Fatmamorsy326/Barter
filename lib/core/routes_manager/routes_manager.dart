import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/features/Authentication/login/login.dart';
import 'package:barter/features/Authentication/register/register.dart';
import 'package:barter/features/exchange/exchange_detail_screen.dart';
import 'package:barter/features/exchange/exchange_screen.dart';
import 'package:barter/features/exchange/propose_exchange_screen.dart';
import 'package:barter/features/item_detail_screen/item_detail_screen.dart';
import 'package:barter/features/main_layout/main_layout.dart';
import 'package:barter/features/add_item/add_item_screen.dart';
import 'package:barter/features/chat/chat_detail_screen.dart';
import 'package:barter/features/account/edit_profile_screen.dart';
import 'package:barter/features/account/settings_screen.dart';
import 'package:barter/features/account/owner_profile_screen.dart';
import 'package:barter/features/account/reviews_screen.dart';
import 'package:barter/features/saved_items/saved_items_screen.dart';
import 'package:barter/features/Authentication/otp/otp_verification_screen.dart';
import 'package:barter/features/splash/splash_screen.dart';
import 'package:barter/features/onboarding/onboarding_screen.dart';
import 'package:barter/features/notifications/notifications_screen.dart';
import 'package:barter/model/item_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoutesManager {
  static Route? router(RouteSettings settings) {
    switch (settings.name) {
      // Splash Route
      case Routes.splash:
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        );

      // Onboarding Route
      case Routes.onboarding:
        return MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        );

      // Auth Routes
      case Routes.login:
        return CupertinoPageRoute(
          builder: (context) => const Login(),
        );

      case Routes.register:
        return CupertinoPageRoute(
          builder: (context) => const Register(),
        );

      // Main Layout
      case Routes.mainLayout:
        return CupertinoPageRoute(
          builder: (context) => const MainLayout(),
        );

      // Item Detail - receives ItemModel as argument
      case Routes.itemDetail:
        final item = settings.arguments as ItemModel;
        return CupertinoPageRoute(
          builder: (context) => ItemDetailScreen(item: item),
        );

      // Add Item
      case Routes.addItem:
        return CupertinoPageRoute(
          builder: (context) => const AddItemScreen(),
        );

      // Edit Item - receives ItemModel as argument
      case Routes.editItem:
        final item = settings.arguments as ItemModel;
        return CupertinoPageRoute(
          builder: (context) => AddItemScreen(itemToEdit: item),
        );

      // Chat Detail - receives chatId as argument
      case Routes.chatDetail:
        final chatId = settings.arguments as String;
        return CupertinoPageRoute(
          builder: (context) => ChatDetailScreen(chatId: chatId),
        );

      // Edit Profile
      case Routes.editProfile:
        return CupertinoPageRoute(
          builder: (context) => const EditProfileScreen(),
        );

      // Settings
      case Routes.settings:
        return CupertinoPageRoute(
          builder: (context) => const SettingsScreen(),
        );

      // Owner Profile - receives ownerId as argument
      case Routes.ownerProfile:
        final ownerId = settings.arguments as String;
        return CupertinoPageRoute(
          builder: (context) => OwnerProfileScreen(ownerId: ownerId),
        );

      // Saved Items
      case Routes.savedItems:
        return CupertinoPageRoute(
          builder: (context) => const SavedItemsScreen(),
        );
      case Routes.proposeExchange:
        if (settings.arguments is ItemModel) {
          return MaterialPageRoute(
            builder: (_) => ProposeExchangeScreen(
              requestedItem: settings.arguments as ItemModel,
            ),
          );
        }
        return unDefinedRoute();

      case Routes.exchangesList:
        return MaterialPageRoute(
          builder: (_) => const ExchangesScreen(),
        );

      case Routes.exchangeDetail:
        if (settings.arguments is String) {
          return MaterialPageRoute(
            builder: (_) => ExchangeDetailScreen(
              exchangeId: settings.arguments as String,
            ),
          );
        }
        return unDefinedRoute();

      case Routes.notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
        );

      case Routes.otpVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return CupertinoPageRoute(
          builder: (context) => OtpVerificationScreen(
            uid: args['uid'],
            email: args['email'],
          ),
        );

      case Routes.reviews:
        final args = settings.arguments as Map<String, dynamic>;
        return CupertinoPageRoute(
          builder: (context) => ReviewsScreen(
            userId: args['userId'],
            userName: args['userName'],
            averageRating: args['averageRating'],
            reviewCount: args['reviewCount'],
          ),
        );

      default:
        return unDefinedRoute();
    }
  }

  static Route<dynamic> unDefinedRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Not Found')),
        body: const Center(child: Text('Route not found')),
      ),
    );
  }
}