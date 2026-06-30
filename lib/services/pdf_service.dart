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
            headers: const ["Correction Method", "Channel", "Date"],
            data: history.map((item) {
              final dt = DateTime.parse(item["date"]);

              final date =
                  "${dt.day.toString().padLeft(2, '0')}-"
                  "${dt.month.toString().padLeft(2, '0')}-"
                  "${dt.year}";

              return [item["corrMethod"] ?? "-", item["channel"] ?? "-", date];
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
