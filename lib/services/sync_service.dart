import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:lactosure_connect_app/database/database_helper.dart';
import 'package:lactosure_connect_app/models/correction_model.dart';

class SyncService {
  static const String apiBaseUrl = "https://lactosure.azurewebsites.net";

  /// Upload all pending corrections
  static Future<bool> syncCorrections() async {
    final pending = await DatabaseHelper.instance.getPendingCorrections();

    if (pending.isEmpty) {
      return true;
    }

    bool allSuccess = true;

    for (final item in pending) {
      bool success = await uploadCorrection(item);

      if (success) {
       await DatabaseHelper.instance.deleteCorrection(item.id!);
      } else {
        allSuccess = false;
      }
    }

    return allSuccess;
  }

  static Future<bool> uploadCorrection(CorrectionModel item) async {
    try {
      Map<String, dynamic> payload = {
        "SocietyID": item.societyId,
        "MachineId": item.machineId,
        "MachineType": item.machineType,

        // CH1
        "ch1": item.channel == "CH1" ? "1" : null,
        "fat1": item.channel == "CH1" ? item.fat : null,
        "snf1": item.channel == "CH1" ? item.snf : null,
        "clr1": item.channel == "CH1" ? item.clr : null,
        "p1": item.channel == "CH1" ? item.protein : null,
        "t1": item.channel == "CH1" ? item.temp : null,
        "w1": item.channel == "CH1" ? item.water : null,

        // CH2
        "ch2": item.channel == "CH2" ? "2" : null,
        "fat2": item.channel == "CH2" ? item.fat : null,
        "snf2": item.channel == "CH2" ? item.snf : null,
        "clr2": item.channel == "CH2" ? item.clr : null,
        "p2": item.channel == "CH2" ? item.protein : null,
        "t2": item.channel == "CH2" ? item.temp : null,
        "w2": item.channel == "CH2" ? item.water : null,

        // CH3
        "ch3": item.channel == "CH3" ? "3" : null,
        "fat3": item.channel == "CH3" ? item.fat : null,
        "snf3": item.channel == "CH3" ? item.snf : null,
        "clr3": item.channel == "CH3" ? item.clr : null,
        "p3": item.channel == "CH3" ? item.protein : null,
        "t3": item.channel == "CH3" ? item.temp : null,
        "w3": item.channel == "CH3" ? item.water : null,

        "Timestamp": item.createdAt,
      };

      print("Uploading...");
      print(const JsonEncoder.withIndent("  ").convert(payload));

      final response = await http.post(
        Uri.parse(
          "$apiBaseUrl/api/MachineCorrection/GetLatestMachineCorrection",
        ),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print(response.statusCode);
      print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
