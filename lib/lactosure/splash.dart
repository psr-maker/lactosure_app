import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/token_check.dart';
import 'package:lactosure_connect_app/lactosure/admin/adminscren.dart';
import 'package:lactosure_connect_app/lactosure/screens/authen/login.dart';
import 'package:lactosure_connect_app/lactosure/screens/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
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
            MaterialPageRoute(builder: (_) => const AdminScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Dashboardhome()),
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
