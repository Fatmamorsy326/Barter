abstract class Validation {
static String? emailValidation(String? email){
  final RegExp regex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  if(email==null || email.trim().isEmpty){
    return "Email is required";
  }
  else if(!regex.hasMatch(email)){
    return "Email not valid";
  }
  return null;
}
static String? passwordValidation(String? password){
  final RegExp regex = RegExp(
    r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
  );
  if(password==null || password.trim().isEmpty){
    return "password is required";
  }
  else if(password.trim().length<8){
    return "password should be at least 8";
  }
  else if(!regex.hasMatch(password)){
    return "The password must contain an uppercase letter,a lowercase letter and a number";
  }
  return null;
}
static String? nameValidation(String? name){
  if(name==null || name.trim().isEmpty){
    return "password is required";
  }
  else if(name.trim().length<3){
    return "name should be at least 3 char";
  }
  return null;
}
static String? rePasswordValidation(String? rePassword ,String? password){
  if(rePassword==null || rePassword.trim().isEmpty){
    return "Re-password is required";
  }
  else if(rePassword != password){
    return "password does not match";
  }
  return null;
}
}