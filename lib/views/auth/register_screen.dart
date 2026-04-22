import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../auth/user_info_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {

    if (!formKey.currentState!.validate()) return;

    try {

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if(credential.user != null){

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => UserInfoScreen(),
          ),
        );

      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Register"),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(

          padding: const EdgeInsets.all(20),

          child: Form(

            key: formKey,

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                const SizedBox(height: 20),

                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                CustomTextField(
                  hint: "Email",
                  controller: emailController,
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  hint: "Password",
                  controller: passwordController,
                  isPassword: true,
                ),

                const SizedBox(height: 30),

                CustomButton(
                  text: "Register",
                  onTap: register,
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Already have an account? Login"),
                )

              ],
            ),
          ),
        ),
      ),
    );
  }
}