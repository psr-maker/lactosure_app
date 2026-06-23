import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lactosure_connect_app/services/admin_services/adminservice.dart';

class FaceLoginPage extends StatefulWidget {

  const FaceLoginPage({super.key});

  @override
  State<FaceLoginPage> createState() => _FaceLoginPageState();
}

class _FaceLoginPageState extends State<FaceLoginPage> {
  File? image;
  bool isLoading = false;
  String result = "";

  final AdminService _service = AdminService();

  Future<void> scanFace() async {
    final picker = ImagePicker();

    final XFile? picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      image = File(picked.path);
      isLoading = true;
      result = "";
    });

    final res = await _service.verifyFace(
      image: image!,
    );

    setState(() {
      isLoading = false;
      result = res["match"] == true
          ? "✅ FACE VERIFIED (Score: ${res["score"]})"
          : "❌ FACE NOT MATCHED";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Face Login")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(image!, height: 220),
              ),

            const SizedBox(height: 20),

            Text(
              result,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : scanFace,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Scan Face"),
            ),
          ],
        ),
      ),
    );
  }
}