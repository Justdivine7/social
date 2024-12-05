import 'package:chat_test/auth/login_page.dart';
import 'package:chat_test/auth/register_page.dart';
 import 'package:flutter/widgets.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  bool showLoginPage = true;
  void toggleLoginOrRegisterPage(){
    setState(() {
      showLoginPage =!showLoginPage;
    });
  }
  @override
  Widget build(BuildContext context) {
if(showLoginPage){
return LoginPage(onTap: toggleLoginOrRegisterPage);
}else{
  return RegisterPage(onTap: toggleLoginOrRegisterPage);
}
   }
}