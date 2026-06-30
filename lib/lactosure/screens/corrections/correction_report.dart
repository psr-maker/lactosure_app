import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/database/database_helper.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/models/correction_model.dart';
import 'package:lactosure_connect_app/services/network_service.dart';
import 'package:lactosure_connect_app/services/sync_service.dart';

class CorrectionReport extends StatefulWidget {
  const CorrectionReport({super.key});

  @override
  State<CorrectionReport> createState() => _CorrectionReportState();
}

class _CorrectionReportState extends State<CorrectionReport> {
  List<CorrectionModel> corrections = [];

  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    loadCorrections();
  }

  Future<void> loadCorrections() async {
    final data = await DatabaseHelper.instance.getPendingCorrections();

    setState(() {
      corrections = data;
      isLoading = false;
    });
  }

  Future<void> syncCorrections() async {
    bool internet = await NetworkService.hasInternet();

    if (!internet) {
      CustomSnackbar.show(
        context: context,
        message: "No InterNet",
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    bool success = await SyncService.syncCorrections();

    await loadCorrections();

    setState(() {
      isLoading = false;
    });

    if (success) {
      CustomSnackbar.show(
        context: context,
        message: "All offline records uploaded successfully",
        isError: false,
      );
    } else {
      CustomSnackbar.show(
        context: context,
        message: "Some records failed to upload",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Correction Report"),
        actions: [
          IconButton(onPressed: syncCorrections, icon: const Icon(Icons.sync)),
        ],
      ),
      body: isLoading
          ? const Center(child: RotatingFlower())
          : corrections.isEmpty
          ? const Center(
              child: Text(
                "No Pending Offline Reports",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(15),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    border: TableBorder.all(
                      color: Theme.of(context).colorScheme.onPrimary,
                      width: 1,
                    ),

                    headingRowColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.primary,
                    ),

                    headingTextStyle: Theme.of(context).textTheme.bodyMedium,
                    dataTextStyle: Theme.of(context).textTheme.titleMedium,

                    columnSpacing: 20,
                    horizontalMargin: 12,
                    dataRowHeight: 55,
                    headingRowHeight: 50,
                    columns: const [
                      DataColumn(label: Text("ID")),
                      DataColumn(label: Text("Type")),
                      DataColumn(label: Text("Society")),
                      DataColumn(label: Text("Machine")),
                      DataColumn(label: Text("Model")),
                      DataColumn(label: Text("Channel")),
                      DataColumn(label: Text("Fat")),
                      DataColumn(label: Text("SNF")),
                      DataColumn(label: Text("CLR")),
                      DataColumn(label: Text("Protein")),
                      DataColumn(label: Text("Temp")),
                      DataColumn(label: Text("Water")),
                      DataColumn(label: Text("Created")),
                      DataColumn(label: Text("Status")),
                    ],
                    rows: corrections.map((item) {
                      return DataRow(
                        cells: [
                          DataCell(Text("${item.id}")),
                          DataCell(Text(item.correctionType)),
                          DataCell(Text(item.societyId ?? "")),
                          DataCell(Text(item.machineId ?? "")),
                          DataCell(Text(item.machineType ?? "")),
                          DataCell(Text(item.channel)),
                          DataCell(Text("${item.fat ?? ""}")),
                          DataCell(Text("${item.snf ?? ""}")),
                          DataCell(Text("${item.clr ?? ""}")),
                          DataCell(Text("${item.protein ?? ""}")),
                          DataCell(Text("${item.temp ?? ""}")),
                          DataCell(Text("${item.water ?? ""}")),
                          DataCell(Text(item.createdAt)),
                          DataCell(
                            Row(
                              children: const [
                                Icon(
                                  Icons.cloud_off,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  "Pending",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
    );
  }
}
