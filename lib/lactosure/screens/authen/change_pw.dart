import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/lactosure/screens/authen/login.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_textfield.dart';
import 'package:lactosure_connect_app/services/authen_service.dart';

class ChangePassword extends StatefulWidget {
  final String email;
  const ChangePassword({super.key, required this.email});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

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
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Form(
            key: formKey,

            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 120),

                  const Text(
                    "Change Password",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 50),

                  CustomTextField(
                    hintText: "New Password",
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    controller: newPasswordController,

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter new password";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  CustomTextField(
                    hintText: "Confirm Password",
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    controller: confirmPasswordController,

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Confirm password";
                      }

                      if (value != newPasswordController.text) {
                        return "Password not match";
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 40),

                  CustomButton(
                    text: "Save",

                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          _isLoading = true;
                        });

                        final result = await AuthService.changePassword(
                          widget.email,
                          newPasswordController.text,
                        );

                        setState(() {
                          _isLoading = false;
                        });

                        if (result["success"]) {
                          CustomSnackbar.show(
                            context: context,
                            message: result["message"],
                          );

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPage()),
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
