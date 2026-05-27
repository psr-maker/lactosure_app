import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/token_check.dart';
import 'package:lactosure_connect_app/lactosure/authen/login.dart';
import 'package:lactosure_connect_app/lactosure/screens/admin/admin.dart';
import 'package:lactosure_connect_app/lactosure/screens/home.dart';

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

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    checkLogin();
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
      if (email != null &&
          email.toLowerCase() == "directorbugstest404@gmail.com") {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const Adminpage(),
          ),
        );

      } else {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const Corrections(),
          ),
        );
      }

    } else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    }

  } catch (e) {

    print("Splash Error: $e");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
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
      backgroundColor: const Color.fromARGB(255, 31, 26, 75),
      body: Center(
        child: RotationTransition(
          turns: _controller,
          child: Image.asset(
            'assets/flower.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}