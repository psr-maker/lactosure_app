import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/services/admin_services/adminservice.dart';

class FaceEnrollment extends StatefulWidget {
  final int userId;
  final String userName;

  const FaceEnrollment({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<FaceEnrollment> createState() => _FaceEnrollmentState();
}

class _FaceEnrollmentState extends State<FaceEnrollment> {
  File? faceImage;
  bool _isLoading = false;
  bool isEnrolled = false;

  final AdminService _faceService = AdminService();

  Future<void> _startFaceEnrollment() async {
    try {
      final picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        faceImage = File(image.path);
        _isLoading = true;
      });

      // 🔥 CALL BACKEND API
      bool success = await _faceService.registerFace(
        image: faceImage!,
        userId: widget.userId,
      );

      setState(() {
        _isLoading = false;
        isEnrolled = success;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? "Face Registered Successfully" : "Registration Failed",
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Face Enrollment"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 50),

              Text(
                isEnrolled ? "Face Enrolled" : "Face Not Enrolled",
              ),

              const Text("Please register employee face"),

              const SizedBox(height: 30),

              /// FACE PREVIEW
              Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey),
                ),
                child: faceImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.face, size: 90, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No Face Captured"),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(faceImage!, fit: BoxFit.cover),
                      ),
              ),

              const SizedBox(height: 50),

              CustomButton(
                text: isEnrolled ? "Re-Register" : "Register",
                onPressed: _startFaceEnrollment,
                isLoading: _isLoading,
                buttonclr: Colors.orange,
                txtclr: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}