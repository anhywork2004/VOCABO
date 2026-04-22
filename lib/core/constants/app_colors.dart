import 'package:flutter/material.dart';

class AppColors {

  static const primary = Color(0xff1E88E5);
  static const secondary = Color(0xff64B5F6);
  static const third = Color(0xff42A5F5);
  static const gradient = LinearGradient(
    colors: [
      Color(0xff42A5F5),
      Color(0xff1E88E5),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

}