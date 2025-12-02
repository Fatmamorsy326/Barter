// import 'package:barter/core/resources/colors_manager.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class CustomDropDownButton extends StatelessWidget {
//   CustomDropDownButton({super.key,required this.selectedValue,required this.list,this.onChange});
//   List<String> list;
//   String selectedValue;
//   void Function(String?)? onChange;
//
//   @override
//   Widget build(BuildContext context) {
//     return  Container(
//       padding: REdgeInsets.symmetric(horizontal:16 ,vertical: 10),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20.r),
//         border: Border.all(
//           color: ColorsManager.blue,
//           width: 1.w,
//         )
//       ),
//       child: DropdownButton(
//         onChanged: onChange,
//         items: list.map((String value) {
//           return DropdownMenuItem<String>(
//             value: value,
//             child: Text(value,style: GoogleFonts.inter(fontWeight: FontWeight.w700,fontSize: 20.sp,color:ColorsManager.blue ),
//             ),
//           );
//         }).toList(),
//         style: GoogleFonts.inter(fontWeight: FontWeight.w700,fontSize: 20.sp,color:ColorsManager.blue ),
//         value: selectedValue,
//         isExpanded: true,
//         icon:  Icon(
//           Icons.arrow_drop_down,
//           color: ColorsManager.blue,
//           size: 50,
//         ),
//         underline: SizedBox(),
//       ),
//     );
//   }
// }
