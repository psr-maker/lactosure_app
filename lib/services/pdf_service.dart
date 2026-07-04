import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateCorrectionReport({
    required String name,
    required String email,
    required String society,
    required String machineId,
    required String model,
    required String dongleId,
    required List<dynamic> history,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              "LACTOSURE CONNECT",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 5),

          pw.Center(
            child: pw.Text(
              "Correction Method Report",
              style: const pw.TextStyle(fontSize: 16),
            ),
          ),

          pw.Divider(),

          pw.SizedBox(height: 15),

          pw.Text(
            "User Information",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          buildRow("Name", name),
          buildRow("Email", email),

          pw.SizedBox(height: 20),

          pw.Text(
            "System Identifiers",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          buildRow("Society", society),
          buildRow("Machine ID", machineId),
          buildRow("Model", model),
          buildRow("Dongle ID", dongleId),

          pw.SizedBox(height: 25),

          pw.Text(
            "Correction History",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            border: pw.TableBorder.all(),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey700,
            ),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headers: const [
              "Correction Method",
              "Channel",
              "Date",
              "SID",
              "MID",
              "Dongle ID",
              "Model",
              "Fat/SNF/CLR",
              "PRT",
              "Temp",
              "WTR",
            ],
            data: history.map((item) {
              final dt = DateTime.parse(item["date"]);

              final date =
                  "${dt.day.toString().padLeft(2, '0')}-"
                  "${dt.month.toString().padLeft(2, '0')}-"
                  "${dt.year}";

              final sid = _formatPdfValue(item["sId"] ?? item["sid"]);
              final mid = _formatPdfValue(item["mId"] ?? item["mid"]);
              final dongleId = _formatPdfValue(item["dongleId"]);
              final model = _formatPdfValue(item["model"]);
              final fat = _formatPdfValue(item["fat"]);
              final snf = _formatPdfValue(item["snf"]);
              final clr = _formatPdfValue(item["clr"]);
              final prt = _formatPdfValue(item["prt"]);
              final temp = _formatPdfValue(item["temp"]);
              final wtr = _formatPdfValue(item["wtr"]);

              return [
                item["corrMethod"] ?? "-",
                item["channel"] ?? "-",
                date,
                sid,
                mid,
                dongleId,
                model,
                "Fat: $fat\nSNF: $snf\nCLR: $clr",
                prt,
                temp,
                wtr,
              ];
            }).toList(),
          ),
        ],
      ),
    );

    /// 🔥 SAVE FILE (OPTIONAL - for internal storage)
    final dir = await _getSaveDirectory();

    final file = File(
      "${dir.path}/Correction_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    try {
      await file.writeAsBytes(await pdf.save());
      print("PDF Saved at: ${file.path}");
    } catch (e) {
      final granted = await _ensureStoragePermission();

      if (!granted) {
        throw Exception("Storage permission denied");
      }

      final retryDir = await _getSaveDirectory();

      final retryFile = File(
        "${retryDir.path}/Correction_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );

      await retryFile.writeAsBytes(await pdf.save());
      print("PDF Saved at: ${retryFile.path}");
    }

    /// 🔥 THIS IS THE SAME AS STAFF REPORT (IMPORTANT)
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: "Correction_Report",
    );
  }

  // ---------------- HELPERS ----------------

  static pw.Widget buildRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              "$title :",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static String _formatPdfValue(dynamic value) {
    if (value == null) return "-";
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  static Future<Directory> _getSaveDirectory() async {
    return Directory("/storage/emulated/0/Download");
  }

  static Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.storage.request();
    if (status.isGranted) return true;

    final manage = await Permission.manageExternalStorage.request();
    return manage.isGranted;
  }
}

class AdminPdfService {
  static Future<void> generateAdminReport({
    required Map<String, dynamic> dashboard,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              "LACTOSURE CONNECT",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.Divider(),

          pw.SizedBox(height: 20),

          pw.Text(
            "Summary",
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 15),

          buildRow("Total Users", dashboard["totalUsers"].toString()),
          buildRow("Total Societies", dashboard["totalSocieties"].toString()),
          buildRow("Total Machines", dashboard["totalMachines"].toString()),
          buildRow("Total Models", dashboard["totalMachineTypes"].toString()),
          buildRow(
            "Total BLE Devices",
            dashboard["totalBleDevices"].toString(),
          ),
          pw.SizedBox(height: 25),

          pw.Text(
            "Users",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headers: const ["Name", "Email", "Status"],

            data: (dashboard["users"] as List).map((u) {
              return [
                u["name"],
                u["email"],
                u["status"] ? "Active" : "Inactive",
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 25),

          pw.Text(
            "Societies",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headers: const ["Code", "Society", "Status"],

            data: (dashboard["societies"] as List).map((s) {
              return [
                s["societyCode"],
                s["sName"],
                s["status"] ? "Active" : "Inactive",
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 25),

          pw.Text(
            "Machines",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headers: const ["Machine", "Society", "Model", "Status"],

            data: (dashboard["machines"] as List).map((m) {
              return [
                m["machineCode"],
                m["society"],
                m["machineType"],
                m["status"] ? "Active" : "Inactive",
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 25),

          pw.Text(
            "Machine Types",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: const ["Model", "Status"],

            data: (dashboard["machineTypes"] as List).map((m) {
              return [m["mType"], m["status"] ? "Active" : "Inactive"];
            }).toList(),
          ),
          pw.SizedBox(height: 25),

          pw.Text(
            "BLE Devices",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Table.fromTextArray(
            headers: const ["BLE Name", "MAC Address", "Status"],

            data: (dashboard["bleDevices"] as List).map((b) {
              return [
                b["bleName"],
                b["macAddress"],
                b["isActive"] ? "Active" : "Inactive",
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 25),

          pw.Text(
            "Correction History",
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),

          ..._buildCorrectionHistory(dashboard["correctionMethods"]),
        ],
      ),
    );
    final dir = await _getSaveDirectory();

    final file = File(
      "${dir.path}/Admin_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );

    try {
      await file.writeAsBytes(await pdf.save());
    } catch (e) {
      final granted = await _ensureStoragePermission();

      if (!granted) {
        throw Exception("Storage permission denied");
      }

      final retryDir = await _getSaveDirectory();

      final retryFile = File(
        "${retryDir.path}/Admin_Report_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );

      await retryFile.writeAsBytes(await pdf.save());
    }

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: "Admin_Report",
    );
  }

  // ---------------- HELPERS ----------------

  static pw.Widget buildRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              "$title :",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  static Future<Directory> _getSaveDirectory() async {
    return Directory("/storage/emulated/0/Download");
  }

  static Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.storage.request();
    if (status.isGranted) return true;

    final manage = await Permission.manageExternalStorage.request();
    return manage.isGranted;
  }

  static String _formatPdfValue(dynamic value) {
    if (value == null) return "-";
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  static List<pw.Widget> _buildCorrectionHistory(List<dynamic> history) {
    final Map<String, List<dynamic>> grouped = {};

    for (final item in history) {
      final user = item["userName"] ?? "Unknown User";
      grouped.putIfAbsent(user, () => []);
      grouped[user]!.add(item);
    }

    final List<pw.Widget> widgets = [];

    grouped.forEach((user, list) {
      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 20),

            pw.Text(
              user,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 8),

            pw.Table.fromTextArray(
              border: pw.TableBorder.all(),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey700,
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              headers: const [
                "Method",
                "Channel",
                "Date",
                "SID",
                "MID",
                "Dongle ID",
                "Model",
                "Fat/SNF/CLR",
                "PRT",
                "Temp",
                "WTR",
              ],
              data: list.map((e) {
                final dt = DateTime.parse(e["date"]);

                final date =
                    "${dt.day.toString().padLeft(2, '0')}-"
                    "${dt.month.toString().padLeft(2, '0')}-"
                    "${dt.year}";

                final sid = _formatPdfValue(e["sId"] ?? e["sid"]);
                final mid = _formatPdfValue(e["mId"] ?? e["mid"]);
                final dongleId = _formatPdfValue(e["dongleId"]);
                final model = _formatPdfValue(e["model"]);
                final fat = _formatPdfValue(e["fat"]);
                final snf = _formatPdfValue(e["snf"]);
                final clr = _formatPdfValue(e["clr"]);
                final prt = _formatPdfValue(e["prt"]);
                final temp = _formatPdfValue(e["temp"]);
                final wtr = _formatPdfValue(e["wtr"]);

                return [
                  e["corrMethod"] ?? "-",
                  e["channel"] ?? "-",
                  date,
                  sid,
                  mid,
                  dongleId,
                  model,
                  "Fat: $fat\nSNF: $snf\nCLR: $clr",
                  prt,
                  temp,
                  wtr,
                ];
              }).toList(),
            ),
          ],
        ),
      );
    });

    return widgets;
  }
}
