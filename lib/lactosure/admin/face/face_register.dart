import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/services/faceservice.dart';

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
  bool loadingFace = true;

  int? faceId;

  bool status = false;

  String? faceBase64;
  final Faceservice _faceService = Faceservice();

  @override
  void initState() {
    super.initState();
    loadFace();
  }

  Future<void> loadFace() async {
    final data = await _faceService.getFaceDetails(widget.userId);

    if (data != null) {
      faceId = data["id"];
      status = data["status"];
      faceBase64 = data["faceImage"];
      isEnrolled = true;
    } else {
      isEnrolled = false;
    }

    setState(() {
      loadingFace = false;
    });
  }

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingFace) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios),
          ),
          title: const Text("Face Enrollment"),
        ),
        body: const Center(child: RotatingFlower()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Face Enrollment"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            /// Enrollment Status
            Center(
              child: Text(
                isEnrolled ? "✅ Face Registered" : "❌ Face Not Registered",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isEnrolled
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),

            if (!isEnrolled) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Please register the employee's face.",
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 20),

            /// Toggle (Only if face already enrolled)
            if (isEnrolled)
              SwitchListTile(
                value: status,
                title: Text(
                  status
                      ? "Disable face authentication during user login"
                      : "Enable face authentication during user login",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                onChanged: (value) async {
                  bool ok = await _faceService.changeFaceStatus(
                    widget.userId,
                    value,
                  );

                  if (ok) {
                    setState(() {
                      status = value;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to update status.")),
                    );
                  }
                },
              ),

            const SizedBox(height: 30),

            /// Face Preview
            Center(
              child: Container(
                height: 250,
                width: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                child: faceImage != null
                    ? Image.file(faceImage!, fit: BoxFit.cover)
                    : faceBase64 != null
                    ? Image.memory(base64Decode(faceBase64!), fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            size: 90,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "No Face Captured",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 40),

            /// Register Button
            Center(
              child: CustomButton(
                text: isEnrolled ? "Re-Register" : "Register Face",
                onPressed: _startFaceEnrollment,
                isLoading: _isLoading,
                buttonclr: Theme.of(context).colorScheme.background,
                txtclr: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
