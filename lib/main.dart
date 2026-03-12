import 'package:flutter/material.dart';
import 'screens/auth/password/change_password_screen.dart';
import 'screens/home_screen.dart';  
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/confirmed_screen.dart';
import 'screens/auth/how_screen.dart';
import 'screens/auth/permissions_screen.dart';
import 'screens/trust_contacts/add_trust_contact_screen.dart';
import 'screens/trust_contacts/add_contact_screen.dart';
import 'screens/trust_contacts/contact_added_screen.dart';
import 'screens/auth/password/forgot_password_screen.dart';
import 'screens/auth/password/verification_screen.dart';

void main() => runApp(const VoxGuardApp());

class VoxGuardApp extends StatelessWidget {
  const VoxGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/confirmed': (context) => const ConfirmedScreen(),
        '/how_safe': (context) => const HowWeKeepSafeScreen(),
        '/permissions': (context) => const PermissionsScreen(),
        '/trust_contacts': (context) => const AddTrustedContactsScreen(),
        '/add_contact': (context) => const AddContactScreen(),
        '/contact_added': (context) => const ContactAddedScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/verification': (context) => const VerificationScreen(),
        '/home': (context) => const HomeScreen(),
        '/change_password': (context) => const ChangePasswordScreen(),
      },
    );
  }
}
