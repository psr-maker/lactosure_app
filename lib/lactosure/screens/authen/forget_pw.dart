import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/lactosure/screens/authen/forget_otp.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_textfield.dart';
import 'package:lactosure_connect_app/services/authen_service.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final emailController = TextEditingController();

  final formKey = GlobalKey<FormState>();
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
              key: formKey,

              child: Column(
                children: [
                  const SizedBox(height: 120),

                  const Text(
                    "Forgot Password",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    "Enter your registered email",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),

                  const SizedBox(height: 50),

                  CustomTextField(
                    hintText: "Enter Email",
                    prefixIcon: Icons.email,
                    controller: emailController,

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter email";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 40),

                  CustomButton(
                    text: "Send OTP",

                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                        });

                        final result = await AuthService.forgotPasswordSendOtp(
                          emailController.text,
                        );

                        setState(() {
                          _isLoading = false;
                        });

                        if (result["success"]) {
                          CustomSnackbar.show(
                            context: context,
                            message: result["message"],
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ForgetOtp(email: emailController.text),
                            ),
                          );
                        } else {
                          CustomSnackbar.show(
                            context: context,
                            message: result["message"],
                            isError: true,
                          );
                        }
                      }
                    },

                    buttonclr: const Color.fromARGB(255, 255, 157, 10),
                    txtclr: Colors.white,
                    isLoading: _isLoading,
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
