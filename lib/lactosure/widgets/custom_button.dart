import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color buttonclr;
  final Color txtclr;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.buttonclr,
    required this.txtclr,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      height: 45,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonclr,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 25,
                height: 25,
                child: RotatingFlower()
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: txtclr,
                ),
              ),
      ),
    );
  }
}

class CustomSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    bool isError = false,
  }) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: isError ? Colors.red : Color.fromARGB(255, 255, 157, 10),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error : Icons.check_circle,
                  color: Colors.white,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}
