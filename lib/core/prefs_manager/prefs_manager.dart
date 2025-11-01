import 'package:barter/core/resources/constant_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsManager {
  static late SharedPreferences prefs;
  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
  }
  static void setLanguage(String language){
    prefs.setString(ConstantManager.savedLanguage, language);
  }
  static void setMode(ThemeMode themeMode) {
    String savedTheme = themeMode == ThemeMode.light ? "Light" :"Dark";
    prefs.setString(ConstantManager.savedTheme, savedTheme);
  }
  static String? getLanguage(){
    return prefs.getString(ConstantManager.savedLanguage);
  }
  static ThemeMode? getTheme(){
    String? theme=prefs.getString(ConstantManager.savedTheme);
    if(theme=="Light"){
      return ThemeMode.light;
    }else if(theme=="Dark"){
      return ThemeMode.dark;
    }
    return null;
  }
}