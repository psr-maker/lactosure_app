

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lactosure_connect_app/constant/api_url.dart';

class AdmdashboardService {
  static const String baseUrl = Api.baseUrl;

static Future<Map<String, dynamic>> getDashboard() async {
  final response = await http.get(
    Uri.parse('$baseUrl/AdmDashboard/dashboard'),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }

  throw Exception("Failed to load dashboard");
}
}
