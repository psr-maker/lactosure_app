import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lactosure_connect_app/lactosure/screens/authen/login.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/services/authen_service.dart';

class OtpVerify extends StatefulWidget {
  final String email;

  const OtpVerify({super.key, required this.email});

  @override
  State<OtpVerify> createState() => _OtpVerifyState();
}

class _OtpVerifyState extends State<OtpVerify> {
  List<TextEditingController> controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  int secondsRemaining = 300;

  Timer? timer;

  int resendCount = 0;
  int maxResend = 3;

  bool canResend = true;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer?.cancel();

    setState(() {
      secondsRemaining = 300;
      canResend = false;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      if (secondsRemaining > 0) {
        setState(() {
          secondsRemaining--;
        });
      } else {
        t.cancel();

        setState(() {
          canResend = resendCount < maxResend;
        });
      }
    });
  }

  String get timerText {
    int minutes = secondsRemaining ~/ 60;
    int seconds = secondsRemaining % 60;

    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  Future<void> verifyOtp() async {
    String otp = controllers.map((e) => e.text).join();

    if (otp.length != 6) {
      CustomSnackbar.show(
        context: context,
        message: "Enter complete OTP",
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService.verifyOtp(email: widget.email, otp: otp);

    setState(() {
      _isLoading = false;
    });

    if (result["success"]) {
      CustomSnackbar.show(context: context, message: result["message"]);

      Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage()));
    } else {
      CustomSnackbar.show(
        context: context,
        message: result["message"],
        isError: true,
      );
    }
  }

  Future<void> resendOtp() async {
    final response = await AuthService.resendOtp(email: widget.email);

    if (response["success"]) {
      setState(() {
        resendCount = response["resendCount"] ?? 0;
      });

      startTimer();

      CustomSnackbar.show(context: context, message: "OTP resent successfully");
    } else {
      CustomSnackbar.show(
        context: context,
        message: response["message"],
        isError: true,
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();

    for (var controller in controllers) {
      controller.dispose();
    }

    super.dispose();
  }

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
            child: Column(
              children: [
                const SizedBox(height: 80),

                const Text(
                  "OTP Verification",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  "A 6 digit OTP has been sent to\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                /// OTP BOXES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 50,
                      height: 60,
                      child: TextField(
                        controller: controllers[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),

                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            FocusScope.of(context).nextFocus();
                          }

                          if (value.isEmpty && index > 0) {
                            FocusScope.of(context).previousFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// TIMER
                Text(
                  timerText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),

                const SizedBox(height: 20),

                /// RESEND OTP
                TextButton(
                  onPressed: canResend
                      ? () {
                          resendOtp();
                        }
                      : null,

                  child: Text(
                    canResend ? "Resend OTP" : "Resend available after timer",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// VERIFY BUTTON
                CustomButton(
                  text: "Verify OTP",
                  isLoading: _isLoading,
                  onPressed: verifyOtp,
                  buttonclr: const Color.fromARGB(255, 255, 157, 10),
                  txtclr: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
