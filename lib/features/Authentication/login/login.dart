import 'package:barter/core/resources/colors_manager.dart';
import 'package:barter/core/resources/images_manager.dart';
import 'package:barter/core/routes_manager/routes.dart';
import 'package:barter/core/ui_utils.dart';
import 'package:barter/core/widgets/custom_text_button.dart';
import 'package:barter/features/Authentication/validation.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'package:barter/model/login_request.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool  isSecurePassword=true;
  GlobalKey<FormState> loginFormKey =GlobalKey<FormState>();
  late TextEditingController emailController;
  late TextEditingController passwordController;

  void togglePasswordVisibility(){
    isSecurePassword=!isSecurePassword;
    setState(() {

    });
  }
  @override
  void initState() {
    emailController=TextEditingController();
    passwordController=TextEditingController();
    super.initState();
  }
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return   Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        padding:REdgeInsets.only(left: 16,right: 16, bottom: MediaQuery.of(context).viewInsets.bottom,top: 47.h) ,
        child: Form(
          key: loginFormKey,
          child: Column(
            children: [
              Image.asset(ImagesManager.barter,height: 180.h,),
              Text(AppLocalizations.of(context)!.exchange_and_discover_easily,textAlign: TextAlign.center,style: GoogleFonts.inter(
                  fontWeight:FontWeight.w500 ,
                  fontSize:20.sp ,
                  color: ColorsManager.grey,
              ),),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomTextButton(text: AppLocalizations.of(context)!.forget_password, onTap: (){}),
                ],
              ),
              SizedBox(height: 16.h,),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: (){
                    login();
                  }, child: Text(AppLocalizations.of(context)!.login))),
              SizedBox(height: 16.h,),
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      endIndent: 16.w,
                      indent:26.w ,
                      thickness: 1.h,
                      color: ColorsManager.grey,
                    ),
                  ),
                  Text(AppLocalizations.of(context)!.or,style: GoogleFonts.inter(
                      fontWeight:FontWeight.w500 ,
                      fontSize:20.sp ,
                      color: ColorsManager.grey
                  ),),
                  Expanded(
                    child: Divider(
                      endIndent: 26.w,
                      indent:16.w ,
                      thickness: 1.h,
                      color: ColorsManager.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h,),
              OutlinedButton(onPressed: (){}, child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(ImagesManager.google,width: 20.h,),
                  Text(AppLocalizations.of(context)!.login_with_google,style: GoogleFonts.inter(
                      fontWeight:FontWeight.w500 ,
                      fontSize:20.sp ,
                      color: ColorsManager.purple
                  ),)
                ],
              )),
              SizedBox(height: 16.h,),
              OutlinedButton(onPressed: (){}, child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.continue_as_guest,style: GoogleFonts.inter(
                      fontWeight:FontWeight.w500 ,
                      fontSize:20.sp ,
                      color: ColorsManager.purple
                  ),)
                ],
              )),
              SizedBox(height: 16.h,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.dont_have_account,style: Theme.of(context).textTheme.bodySmall,),
                  CustomTextButton(text:AppLocalizations.of(context)!.create_account,onTap:(){
                    Navigator.pushReplacementNamed(context, Routes.register);
                  } ,),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }

  Future<void> login() async {
    if(loginFormKey.currentState?.validate()==false)return;
    try {
      UiUtils.showLoading(context,false);
      UserCredential userCredential = await FirebaseService.login(LoginRequest(
          email: emailController.text, password: passwordController.text));
      UiUtils.hideDialog(context);
      UiUtils.showToastMessage("Logged_In successfully", Colors.green);
      Navigator.pushReplacementNamed(context, Routes.mainLayout);
    } on FirebaseAuthException catch(e){
      UiUtils.hideDialog(context);
      UiUtils.showToastMessage(e.code, Colors.red);
    }
    catch(e){
      UiUtils.hideDialog(context);
      UiUtils.showToastMessage("failed to login", Colors.red);
    }
  }
}
