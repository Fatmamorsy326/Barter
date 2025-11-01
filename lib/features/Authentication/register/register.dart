
import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/resources/images_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/routes_manager/routes_manager.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/core/widgets/custom_text_button.dart';
import 'package:barter/features/Authentication/validation.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/register_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';


class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {

  bool  isSecurePassword=true;
  bool  isSecureRePassword=true;
  GlobalKey<FormState> regFormKey =GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController rePasswordController;

  void togglePasswordVisibility(){
    isSecurePassword=!isSecurePassword;
    setState(() {

    });
  }
  void toggleRePasswordVisibility(){
    isSecureRePassword=!isSecureRePassword;
    setState(() {

    });
  }
  @override
  void initState() {
    nameController=TextEditingController();
    emailController=TextEditingController();
    passwordController=TextEditingController();
    rePasswordController=TextEditingController();
    super.initState();
  }
@override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    rePasswordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
       resizeToAvoidBottomInset: false,
       body: SingleChildScrollView(
         padding:REdgeInsets.only(top:47.h,left: 16,right: 16, bottom: MediaQuery.of(context).viewInsets.bottom) ,
         child: Form(
           key: regFormKey,
           child: Column(
             children: [
               Image.asset(ImagesManager.barter,height: 180,),
               Text(AppLocalizations.of(context)!.exchange_and_discover_easily,textAlign: TextAlign.center,style: GoogleFonts.inter(
                 fontWeight:FontWeight.w500 ,
                 fontSize:20.sp ,
                 color: ColorsManager.grey,
               ),),
               SizedBox(
                 height: 24.h,
               ),
               TextFormField(
                 controller: nameController,
                 validator: Validation.nameValidation,
                 keyboardType: TextInputType.name,
                 decoration: InputDecoration(
                   prefixIcon: Icon(Icons.person),
                   labelText: AppLocalizations.of(context)!.name,
                 ),
               ),
               SizedBox(height: 16.h,),
               TextFormField(
                 controller: emailController,
                 validator: Validation.emailValidation,
                 keyboardType: TextInputType.emailAddress,
                 decoration: InputDecoration(
                   prefixIcon: Icon(Icons.email),
                   labelText: AppLocalizations.of(context)!.email,
                 ),
               ),
               SizedBox(height: 16.h,),
               TextFormField(
                 controller: passwordController,
                 validator: Validation.passwordValidation,
                 obscureText: isSecurePassword,
                 keyboardType: TextInputType.visiblePassword,
                 decoration: InputDecoration(
                   prefixIcon: Icon(Icons.lock),
                   labelText: AppLocalizations.of(context)!.password,
                   suffixIcon: IconButton(icon: isSecurePassword?Icon(Icons.visibility_off):Icon(Icons.visibility), onPressed: () {
                     togglePasswordVisibility();
                   },),
                 ),
               ),
               SizedBox(height: 16.h,),
               TextFormField(
                 validator: (value) {
                   return Validation.rePasswordValidation(rePasswordController.text, passwordController.text);
                 },
                 controller: rePasswordController,
                 keyboardType: TextInputType.visiblePassword,
                 obscureText: isSecureRePassword,
                 decoration: InputDecoration(
                   prefixIcon: Icon(Icons.lock),
                   labelText: AppLocalizations.of(context)!.re_password,
                   suffixIcon: IconButton(icon: isSecureRePassword?Icon(Icons.visibility_off):Icon(Icons.visibility), onPressed: () {
                     toggleRePasswordVisibility();
                   },),
                 ),
               ),
               SizedBox(height: 16.h,),
               SizedBox(
                 width: double.infinity,
                   child: ElevatedButton(onPressed: (){
                     createAccount();
                   }, child: Text(AppLocalizations.of(context)!.create_account))),
               SizedBox(height: 16.h,),
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Text(AppLocalizations.of(context)!.already_have_account,style: Theme.of(context).textTheme.bodySmall,),
                   CustomTextButton(text:AppLocalizations.of(context)!.login,onTap:(){
                     Navigator.pushReplacementNamed(context, Routes.login);
                   } ,),
                 ],
               ),
             ],
           ),
         ),
       ),
    );
  }

  Future<void> createAccount() async {
    if(regFormKey.currentState?.validate()==false){
      return;
    }
    try{
      UiUtils.showLoading(context, false);
      //get object from firebaseAuth

      UserCredential userCredential = await  FirebaseService.register(RegisterRequest(email:emailController.text, password:passwordController.text));

      UiUtils.showToastMessage("Successfully Registration", Colors.green);
      UiUtils.hideDialog(context);
      Navigator.pushReplacementNamed(context, Routes.login);
    }

    on FirebaseAuthException catch(e){
      UiUtils.hideDialog(context);
      UiUtils.showToastMessage(e.code, Colors.red);
    } catch (e) {
      UiUtils.hideDialog(context);
      UiUtils.showToastMessage("Failed to register", Colors.red);
    }

  }
}
