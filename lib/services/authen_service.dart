import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:lactosure_connect_app/constant/api_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String url = Api.baseUrl;
  static const String _tokenKey = "auth_token";
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$url/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );

      print(response.body);

      Map<String, dynamic> data = {};

      // prevent unexpected end of input
      if (response.body.isNotEmpty) {
        data = safeJsonDecode(response.body);
      }

      if (response.statusCode == 200) {
        return {"success": true, "message": data["message"] ?? "Success"};
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Something went wrong",
        };
      }
    } catch (e) {
      print(e);

      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$url/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "otp": otp}),
      );

      final data = safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "message": data["message"]};
      } else {
        return {"success": false, "message": data["message"]};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> resendOtp({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse("$url/auth/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(email),
      );

      final data = safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {"success": true, "message": data["message"]};
      } else {
        return {"success": false, "message": data["message"]};
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
  ) async {
    try {
      final eurl = Uri.parse("$url/auth/login");

      final response = await http.post(
        eurl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = safeJsonDecode(response.body);

      // DEBUG
      print(data);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        String userEmail =
            data["user"]?["email"] ?? data["user"]?["Email"] ?? "";

        // Save token
        // await prefs.setString("token", data["token"] ?? "");
        await _storage.write(key: _tokenKey, value: data["token"] ?? "");
        // Save email
        await prefs.setString("email", userEmail);

        return {
          "success": true,
          "email": userEmail,
          "message": data["message"] ?? "",
        };
      }

      return {"success": false, "message": data["message"] ?? "Login failed"};
    } catch (e) {
      print("LOGIN ERROR: $e");

      return {"success": false, "message": e.toString()};
    }
  }

  static Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$url/auth/all-users'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return safeJsonDecode(response.body);
    } else {
      throw Exception("Failed to load users");
    }
  }

  static Future<bool> approveUser(int id) async {
    final response = await http.put(
      Uri.parse('$url/auth/approve-user/$id'),
      headers: {"Content-Type": "application/json"},
    );

    return response.statusCode == 200;
  }

  static Future<bool> rejectUser(int id) async {
    final response = await http.delete(
      Uri.parse('$url/auth/reject-user/$id'),
      headers: {"Content-Type": "application/json"},
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> forgotPasswordSendOtp(
    String email,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$url/auth/forgot-password-send-otp'),

        headers: {"Content-Type": "application/json"},
        body: jsonEncode(email),
      );

      final data = safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"] ?? "OTP sent successfully",
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Failed to send OTP",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Something went wrong"};
    }
  }

  static Future<Map<String, dynamic>> forgotPasswordVerifyOtp(
    String email,
    String otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$url/auth/forgot-password-verify-otp'),

        headers: {"Content-Type": "application/json"},

        body: jsonEncode({"email": email, "otp": otp}),
      );

      final data = safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"] ?? "OTP verified successfully",
        };
      } else {
        return {"success": false, "message": data["message"] ?? "Invalid OTP"};
      }
    } catch (e) {
      return {"success": false, "message": "Something went wrong"};
    }
  }

  static Future<Map<String, dynamic>> changePassword(
    String email,
    String password,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$url/auth/change-password'),

        headers: {"Content-Type": "application/json"},

        body: jsonEncode({"email": email, "password": password}),
      );

      final data = safeJsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"] ?? "Password updated successfully",
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Failed to update password",
        };
      }
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }
}

dynamic safeJsonDecode(String body) {
  try {
    if (body.isEmpty) return null;

    // prevent HTML responses
    if (body.trim().startsWith('<')) {
      throw Exception("Server returned HTML instead of JSON");
    }

    return jsonDecode(body);
  } catch (e) {
    print("JSON ERROR: $body");
    throw Exception("Invalid server response");
  }
}
