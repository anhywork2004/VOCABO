import 'package:flutter/material.dart';

import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/auth/forgot_password_screen.dart';
import '../views/auth/otp_verification_screen.dart';
import '../views/auth/user_info_screen.dart';
import '../views/calendar/CalendarScreen.dart';
import '../views/add/add_screen.dart';
import '../views/notification/notification_screen.dart';
import '../views/home/home_screen.dart';
import '../views/settings/setting_screen.dart';
import '../views/admin/admin_screen.dart';

class AppRoutes {
  static const String login = "/login";
  static const String register = "/register";
  static const String forgot = "/forgot";
  static const String otp = "/otp";
  static const String userInfo = "/user-info";
  static const String home = "/home";
  static const String admin = "/admin";
  static const String settings = "/settings";
  static const String calendar = "/calendar";
  static const String add = "/add";
  static const String notification = "/notification";

  static final Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgot: (context) => const ForgotPasswordScreen(),
    otp: (context) => OtpVerificationScreen(email: ""),
    userInfo: (context) => const UserInfoScreen(),
    calendar: (context) => CalendarScreen(),
    add: (context) => AddScreen(),
    notification: (context) => NotificationScreen(),
    home: (context) => const HomeScreen(),
    settings: (context) => SettingScreen(),
    admin: (context) => const AdminScreen(),
  };
}
