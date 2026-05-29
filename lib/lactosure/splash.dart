import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/token_check.dart';
import 'package:lactosure_connect_app/lactosure/screens/authen/login.dart';
import 'package:lactosure_connect_app/lactosure/admin/admin.dart';
import 'package:lactosure_connect_app/lactosure/screens/scanner.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      checkLogin();
    });
  }

  void checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    try {
      bool loggedIn = await TokenCheck.isLoggedIn();

      if (!mounted) return;

      if (loggedIn) {
        String? email = await TokenCheck.getEmail();

        if (!mounted) return;

        // Admin
        if (email != null && email.toLowerCase() == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Adminpage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ScannerPage()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      print("Splash Error: $e");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/psrlogo.png',
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
