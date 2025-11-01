import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/features/Authentication/login/login.dart';
import 'package:barter/features/Authentication/register/register.dart';
import 'package:barter/features/main_layout/main_layout.dart';
import 'package:flutter/cupertino.dart';

class RoutesManager {


  static Route? router(RouteSettings settings){
    switch(settings.name){

      case Routes.login:{
        return CupertinoPageRoute(builder: (context)=> Login());
      }
      case Routes.register:{
        return CupertinoPageRoute(builder: (context)=> Register());
      }
      case Routes.mainLayout:{
        return CupertinoPageRoute(builder: (context)=> MainLayout());
      }
    }
  }
}