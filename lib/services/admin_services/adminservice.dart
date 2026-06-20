import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lactosure_connect_app/constant/api_url.dart';

class AdminService {
  static const String baseUrl = Api.baseUrl;

  //Society

  static Future<Map<String, dynamic>> addSociety({
    required String societyCode,
    required String societyName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/add-society'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "societyCode": societyCode,
          "sName": societyName,
          "status": true,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<List<dynamic>> getSocieties() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/societies'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      throw Exception('Failed to load societies');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<Map<String, dynamic>> updateSociety({
    required int id,
    required String sName,
    required bool status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/society/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sName': sName, 'status': status}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteSociety(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/society/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  //Machine
  static Future<List<dynamic>> getMachines() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/machines'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load machines");
  }

  static Future<Map<String, dynamic>> addMachine({
    required String machineCode,
    required int sid,
    required int mtid,
    required bool status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/add-machine'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "machineCode": machineCode,
        "sid": sid,
        "mtid": mtid,
        "status": status,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateMachine({
    required int id,
    required int sid,
    required int mtid,
    required bool status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/machine/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"sid": sid, "mtid": mtid, "status": status}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteMachine(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/admin/machine/$id'));

    return jsonDecode(response.body);
  }

  //Machine Type
  static Future<List<dynamic>> getMachineTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/machine-types'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed");
  }

  static Future<Map<String, dynamic>> addMachineType({
    required String mType,
    required bool status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/add-machine-type'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mType": mType, "status": status}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateMachineType({
    required int id,
    required String mType,
    required bool status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/machine-type/$id'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"mType": mType, "status": status}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteMachineType(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/machine-type/$id'),
    );

    return jsonDecode(response.body);
  }

  // Ble Devices

  static Future<List<dynamic>> getDevices() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/get-alldevices'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Failed to load devices");
  }

  static Future<Map<String, dynamic>> addDevice({
    required String bleName,
    required String macAddress,
    required bool isActive,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/add-devices'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "bleName": bleName,
        "macAddress": macAddress,
        "isActive": isActive,
      }),
    );

    return {
      "success": response.statusCode == 200,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> updateDevice({
    required int id,
    required String bleName,
    required String macAddress,
    required bool isActive,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/admin/update-device/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "bleName": bleName,
        "macAddress": macAddress,
        "isActive": isActive,
      }),
    );

    return {
      "success": response.statusCode == 200,
      "data": jsonDecode(response.body),
    };
  }

  static Future<Map<String, dynamic>> deleteDevice(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/admin/delete-devices/$id"));

    return {"success": response.statusCode == 200};
  }
}
