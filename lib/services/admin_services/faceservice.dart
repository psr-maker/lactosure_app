import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:lactosure_connect_app/constant/api_url.dart';
import 'package:lactosure_connect_app/services/authen_service.dart';

class Faceservice {
  static const String baseUrl = Api.baseUrl;

  // Face Register

  Future<bool> registerFace({required File image, required int userId}) async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/face/register"),
      );

      request.fields["userId"] = userId.toString();

      request.files.add(await http.MultipartFile.fromPath("file", image.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("REGISTER RESPONSE: $responseBody");
      print("REGISTER code: ${response.statusCode}");

      return response.statusCode == 200;
    } catch (e) {
      print("Register Error: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>> verifyFace({required File image}) async {
    try {
      final token = await AuthService.getToken();

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/face/face-verify"),
      );

      request.headers["Authorization"] = "Bearer $token";

      request.files.add(await http.MultipartFile.fromPath("file", image.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("VERIFY STATUS: ${response.statusCode}");
      print("VERIFY RESPONSE: $responseBody");

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      }

      return {"match": false, "message": responseBody};
    } catch (e) {
      print("VERIFY ERROR: $e");

      return {"match": false, "message": e.toString()};
    }
  }

  Future<Map<String, dynamic>?> getFaceDetails(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/face/face-details/$userId"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  Future<bool> changeFaceStatus(int id, bool status) async {
    final response = await http.put(
      Uri.parse("$baseUrl/face/face-status/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": status}),
    );

    print(response.statusCode);
    print(response.body);

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getFaceStatus() async {
    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/face/face-statuscheck"),
      headers: {"Authorization": "Bearer $token"},
    );

    return jsonDecode(response.body);
  }
}
