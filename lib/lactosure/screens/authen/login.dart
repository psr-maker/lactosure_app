import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/lactosure/admin/adminscren.dart';
import 'package:lactosure_connect_app/lactosure/admin/face/verify_face.dart';
import 'package:lactosure_connect_app/lactosure/screens/authen/forget_pw.dart';
import 'package:lactosure_connect_app/lactosure/screens/authen/register.dart';
import 'package:lactosure_connect_app/lactosure/screens/dashboard/home.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_textfield.dart';
import 'package:lactosure_connect_app/services/faceservice.dart';
import 'package:lactosure_connect_app/services/authen_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 25, 83),
              Color.fromARGB(255, 55, 61, 71),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 70),

                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Login to continue",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 50),

                  /// EMAIL
                  CustomTextField(
                    hintText: "Email",
                    prefixIcon: Icons.email,
                    controller: emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter your Email";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  /// PASSWORD
                  CustomTextField(
                    hintText: "Password",
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    controller: passwordController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter your Password";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  /// FORGOT PASSWORD
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgetPassword(),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 255, 157, 10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// LOGIN BUTTON
                  CustomButton(
                    text: "Login",
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                        });
                        final result = await AuthService.loginUser(
                          emailController.text,
                          passwordController.text,
                        );
                        setState(() {
                          _isLoading = false;
                        });
                        if (result["success"]) {
                          String email = result["email"];

                          // Admin
                          if (email.toLowerCase() == "admin") {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminScreen(),
                              ),
                            );
                          }
                          // User
                          else {
                            // final face = await Faceservice.getFaceStatus();

                            // if (!mounted) return;

                            // if (face["status"] == true) {
                            //   Navigator.pushReplacement(
                            //     context,
                            //     MaterialPageRoute(
                            //       builder: (_) => const FaceLoginPage(),
                            //     ),
                            //   );
                            // } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Dashboardhome(),
                              ),
                            );
                          }
                          //}
                        } else {
                          CustomSnackbar.show(
                            context: context,
                            message: result["message"],
                            isError: true,
                          );
                        }
                      }
                    },
                    isLoading: _isLoading,
                    buttonclr: const Color.fromARGB(255, 255, 157, 10),
                    txtclr: Colors.white,
                  ),

                  const SizedBox(height: 25),

                  /// REGISTER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.white),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterUser(),
                            ),
                          );
                        },
                        child: const Text(
                          "Register",
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 157, 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
