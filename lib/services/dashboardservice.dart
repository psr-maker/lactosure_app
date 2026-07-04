import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lactosure_connect_app/constant/api_url.dart';

class DashboardService {
  static const String baseUrl = Api.baseUrl;

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl/Dashboard/dashboard'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load dashboard");
  }

  static Future<bool> saveCorrectionMethod({
    required int uid,
    String? sId,
    String? mId,
    required String? model,
    required String? dongleId,
    required double? fat,
    required double? snf,
    required double? clr,
    required double? prt,
    required double? temp,
    required double? wtr,
    required String corrMethod,
    required String channel,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/Dashboard/CorrMethodSave"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "uId": uid,
          "sId": sId,
          "mId": mId,
          "model": model,
          "dongleId": dongleId,
          "fat": fat,
          "snf": snf,
          "clr": clr,
          "prt": prt,
          "temp": temp,
          "wtr": wtr,
          "corrMethod": corrMethod,
          "channel": channel,
        }),
      );

      print("SAVE METHOD STATUS : ${response.statusCode}");
      print("SAVE METHOD BODY   : ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("SAVE METHOD ERROR : $e");
      return false;
    }
  }

  static Future<List<dynamic>> getCorrMethodHistory(int uid) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/Dashboard/GetCorrMethodHistory/$uid"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["success"] == true) {
          return json["data"] as List<dynamic>;
        }

        return [];
      } else {
        print("GET HISTORY FAILED: ${response.statusCode}");
        print(response.body);
        return [];
      }
    } catch (e) {
      print("GET HISTORY ERROR: $e");
      return [];
    }
  }
}
