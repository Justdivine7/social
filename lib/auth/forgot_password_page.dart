import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return "Please enter a valid email address";
    }
    if (!email.contains('@') || !email.contains('.')) {
      return "Please enter a valid email address";
    }
    return null;
  }

  bool isLoading = false;

  Future passwordReset() async {
    try {
      setState(() {
        isLoading = true;
      });
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      setState(() {
        isLoading = true;
      });
      // Fluttertoast.showToast(msg: 'Password reset link sent! Check your mail');
      setState(() {
        isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Fluttertoast.showToast(msg: 'Email is not registeres');
      } else {
        print(e.toString());

        // Fluttertoast.showToast(msg: e.message.toString());
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: Colors.grey[50],

      appBar: AppBar(
 forceMaterialTransparency: true,
         elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
              'Enter your email and we will send you a password reset link'),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: TextFormField(
              controller: _emailController,
              validator: validateEmail,
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.white,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.deepPurple,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.grey[200],
                filled: true,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          isLoading
              ? const CircularProgressIndicator()
              : MaterialButton(
                  onPressed: passwordReset,
                  color: Colors.deepPurple[200],
                  child: const Text('Reset Pasword'),
                )
        ],
      ),
    );
  }
}
