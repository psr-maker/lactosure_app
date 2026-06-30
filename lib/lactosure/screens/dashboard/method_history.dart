import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/services/dashboardservice.dart';

class CorrMethodHistory extends StatefulWidget {
  final int uid;

  const CorrMethodHistory({super.key, required this.uid});

  @override
  State<CorrMethodHistory> createState() => _CorrMethodHistoryState();
}

class _CorrMethodHistoryState extends State<CorrMethodHistory> {
  List<dynamic> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    history = await DashboardService.getCorrMethodHistory(widget.uid);

    setState(() {
      isLoading = false;
    });
  }

  String formatDate(String date) {
    final dt = DateTime.parse(date);

    return "${dt.day.toString().padLeft(2, '0')}-"
        "${dt.month.toString().padLeft(2, '0')}-"
        "${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
        title: const Text("Correction Method History"),
      ),
      body: isLoading
          ? const Center(child: RotatingFlower())
          : history.isEmpty
          ? const Center(child: Text("No History Found"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];

                return Container(
                  margin: EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Correction Method : ${item["corrMethod"]}",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Channel : ${item["channel"]}",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Date : ${formatDate(item["date"])}",
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
