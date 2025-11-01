import 'package:barter/core/prefs_manager/prefs_manager.dart';
import 'package:flutter/material.dart';

class ConfigProvider extends ChangeNotifier {
  ThemeMode currentTheme= PrefsManager.getTheme() ?? ThemeMode.light;
  String currentLanguage=PrefsManager.getLanguage()?? "en";
  void changeTheme(ThemeMode newTheme){
    if(currentTheme==newTheme)return;
    currentTheme=newTheme;
    PrefsManager.setMode(currentTheme);
    notifyListeners();
  }
  void toggleTheme(){
    if(currentTheme==ThemeMode.light){
      currentTheme=ThemeMode.dark;
    }
    else{
      currentTheme=ThemeMode.light;
    }
    PrefsManager.setMode(currentTheme);
    notifyListeners();
  }
  bool get isDark => currentTheme==ThemeMode.dark;
  void changeLanguage(String newLanguage){
    if(currentLanguage==newLanguage)return;
    currentLanguage=newLanguage;
    PrefsManager.setLanguage(currentLanguage);
    notifyListeners();
  }
  void toggleLanguage(){
    if(currentLanguage=="en"){
      currentLanguage="ar";
    }
    else{
      currentLanguage="en";
    }
    PrefsManager.setLanguage(currentLanguage);
    notifyListeners();
  }
  bool get isEn => currentLanguage=="en";
}