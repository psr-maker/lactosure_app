import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/lactosure/screens/dashboard/home.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/services/faceservice.dart';

class FaceLoginPage extends StatefulWidget {
  const FaceLoginPage({super.key});

  @override
  State<FaceLoginPage> createState() => _FaceLoginPageState();
}

class _FaceLoginPageState extends State<FaceLoginPage> {
  File? image;
  bool isLoading = false;
  String result = "";
  Color resultColor = Colors.transparent;
  File? capturedImage;
  CameraController? controller;
  final Faceservice _service = Faceservice();
  @override
  void initState() {
    super.initState();
    initCamera();
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();

    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    controller = CameraController(frontCamera, ResolutionPreset.high);

    await controller!.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> scanFace() async {
    if (controller == null || !controller!.value.isInitialized) return;

    setState(() {
      isLoading = true;
      result = "";
    });

    final XFile file = await controller!.takePicture();
    capturedImage = File(file.path);

    setState(() {});

    final res = await _service.verifyFace(image: capturedImage!);

    // final bool match = res["match"] == true;
    // final double score = (res["score"] as num).toDouble();

    // setState(() {
    //   isLoading = false;

    //   if (match) {
    //     result = "✅ Face Verified : ${score.toStringAsFixed(2)}";
    //     resultColor = Theme.of(context).colorScheme.tertiary;
    //   } else {
    //     result = "❌ Face Not Matched : ${score.toStringAsFixed(2)}";
    //     resultColor = Theme.of(context).colorScheme.error;
    //   }
    // });
    final bool match = res["match"] == true;
    final double score = (res["score"] as num).toDouble();

    setState(() {
      isLoading = false;

      if (match) {
        result = "✅ Face Verified : ${score.toStringAsFixed(2)}";
        resultColor = Theme.of(context).colorScheme.tertiary;
      } else {
        result = "❌ Face Not Matched : ${score.toStringAsFixed(2)}";
        resultColor = Theme.of(context).colorScheme.error;
      }
    });

    if (match) {
      // Wait 2 seconds so the user can see the success message.
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Dashboardhome()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                const SizedBox(height: 20),

                Text(
                  "Face Login",
                  style: Theme.of(context).textTheme.displayMedium,
                ),

                const SizedBox(height: 15),

                Text(
                  "Align your face inside the frame",
                  style: Theme.of(context).textTheme.labelLarge,
                ),

                const SizedBox(height: 40),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.cyanAccent, width: 4),
                      ),
                    ),

                    ClipOval(
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: capturedImage != null
                            ? Image.file(capturedImage!, fit: BoxFit.cover)
                            : (controller != null &&
                                  controller!.value.isInitialized)
                            ? CameraPreview(controller!)
                            : const Center(child: RotatingFlower()),
                      ),
                    ),

                    if (isLoading)
                      const SizedBox(
                        width: 280,
                        height: 280,
                        child: CircularProgressIndicator(
                          strokeWidth: 5,
                          color: Colors.cyanAccent,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 40),

                Center(
                  child: CustomButton(
                    text: isLoading ? "" : "Scan My Face",
                    onPressed: isLoading ? null : scanFace,
                    buttonclr: Theme.of(context).colorScheme.background,
                    txtclr: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: isLoading
                      ? Text(
                          "Verifying your face...",
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      : result.isNotEmpty
                      ? Text(
                          result,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: resultColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
