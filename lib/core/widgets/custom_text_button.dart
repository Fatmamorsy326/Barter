import 'package:barter/core/resources/colors_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextButton extends StatelessWidget {
  String text;
  VoidCallback onTap;
  CustomTextButton({super.key,required this.text,required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        onTap();
      },
      child: Text(text,style: GoogleFonts.inter(fontSize: 16.sp,fontWeight: FontWeight.w700,color: ColorsManager.purple,decorationColor: ColorsManager.purple,fontStyle: FontStyle.italic),),
    );
  }
}
