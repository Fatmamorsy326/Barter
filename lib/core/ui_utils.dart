import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
abstract class UiUtils{
  static void showLoading(BuildContext context,bool dismissible ){
    showCupertinoDialog(barrierDismissible: dismissible,
        context: context,
        builder: (context)=>PopScope(canPop:dismissible ,
          child: CupertinoAlertDialog(content:  Column(
            mainAxisSize: MainAxisSize.min,
            children: [Center(child: CircularProgressIndicator())],
          ),),
        ));
  }

  static void hideDialog(BuildContext context) {
    Navigator.pop(context);
  }


  static void showToastMessage(String message, Color bgColor) {
    Fluttertoast.showToast(msg: message,textColor: Colors.white,
        backgroundColor:bgColor );
  }
}