import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/global/token.dart';
import 'package:lactosure_connect_app/lactosure/admin/adminscren.dart';
import 'package:lactosure_connect_app/lactosure/screens/authen/login.dart';
import 'package:lactosure_connect_app/lactosure/screens/dashboard/home.dart';
import 'package:lactosure_connect_app/services/authen_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    try {
      final loggedIn = await TokenCheck.isLoggedIn();

      if (!mounted || _navigated) return;
      _navigated = true;

      if (loggedIn) {
        final email = await TokenCheck.getEmail();

        if (!mounted) return;

        if (email != null && email.toLowerCase().contains("admin")) {
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
        await AuthService.logout();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
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
