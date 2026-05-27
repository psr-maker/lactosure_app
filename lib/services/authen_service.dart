import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lactosure_connect_app/constant/api_url.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String url = Api.baseUrl;
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
        data = jsonDecode(response.body);
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

      final data = jsonDecode(response.body);

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

      final data = jsonDecode(response.body);

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

      final data = jsonDecode(response.body);

      // DEBUG
      print(data);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        String userEmail =
            data["user"]?["email"] ?? data["user"]?["Email"] ?? "";

        // Save token
        await prefs.setString("token", data["token"] ?? "");

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

  // ================= GET ALL USERS =================
  static Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$url/auth/all-users'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load users");
    }
  }

  // ================= APPROVE USER =================
  static Future<bool> approveUser(int id) async {
    final response = await http.put(
      Uri.parse('$url/auth/approve-user/$id'),
      headers: {"Content-Type": "application/json"},
    );

    return response.statusCode == 200;
  }

  // ================= REJECT USER =================
  static Future<bool> rejectUser(int id) async {
    final response = await http.delete(
      Uri.parse('$url/auth/reject-user/$id'),
      headers: {"Content-Type": "application/json"},
    );

    return response.statusCode == 200;
  }

  // ================= SEND FORGOT OTP =================
  static Future<bool> forgotPasswordSendOtp(String email) async {
    final response = await http.post(
      Uri.parse('$url/auth/forgot-password-send-otp'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(email),
    );

    return response.statusCode == 200;
  }

  // ================= VERIFY FORGOT OTP =================
  static Future<bool> forgotPasswordVerifyOtp(
    String email,
    String otp,
  ) async {
    final response = await http.post(
      Uri.parse('$url/auth/forgot-password-verify-otp'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "otp": otp,
      }),
    );

    return response.statusCode == 200;
  }

  // ================= CHANGE PASSWORD =================
  static Future<bool> changePassword(
    String email,
    String password,
  ) async {
    final response = await http.put(
      Uri.parse('$url/auth/change-password'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    return response.statusCode == 200;
  }
}
