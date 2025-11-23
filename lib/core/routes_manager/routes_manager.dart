
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/features/Authentication/login/login.dart';
import 'package:barter/features/Authentication/register/register.dart';
import 'package:barter/features/item_detail_screen/item_detail_screen.dart';
import 'package:barter/features/main_layout/main_layout.dart';
import 'package:barter/features/add_item/add_item_screen.dart';
import 'package:barter/features/chat/chat_detail_screen.dart';
import 'package:barter/features/account/edit_profile_screen.dart';
import 'package:barter/features/account/settings_screen.dart';
import 'package:barter/features/account/owner_profile_screen.dart';
import 'package:barter/features/saved_items/saved_items_screen.dart';
import 'package:barter/model/item_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoutesManager {
  static Route? router(RouteSettings settings) {
    switch (settings.name) {
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

    // Default - Unknown route
      default:
        return CupertinoPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}