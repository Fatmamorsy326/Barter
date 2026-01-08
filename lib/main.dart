 import 'package:barter/configration/theme/theme_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/routes_manager/routes_manager.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/firebase_options.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/providers/local_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firestore settings (Persistence)
  FirebaseService.initializeFirestore();

  runApp(const BarterApp());
}

class BarterApp extends StatelessWidget {
  const BarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, child) {
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp(
                title: 'Barter',
                debugShowCheckedModeBanner: false,

                // Theme - now uses ThemeProvider
                theme: ThemeManager.lightTheme,
                darkTheme: ThemeManager.darkTheme,
                themeMode: themeProvider.themeMode,

                // Localization - Uses provider's locale
                locale: localeProvider.locale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', ''), // English
                  Locale('ar', ''), // Arabic
                ],

                // Routes
                initialRoute: Routes.splash,
                onGenerateRoute: RoutesManager.router,
              );
            },
          );
        },
      ),
    );
  }
}