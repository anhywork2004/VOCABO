import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {

  final String hint;
  final TextEditingController controller;
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.hint,
    required this.controller,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {

    return TextField(

      controller: controller,

      obscureText: isPassword,

      decoration: InputDecoration(

        hintText: hint,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
      ),
    );
  }
}