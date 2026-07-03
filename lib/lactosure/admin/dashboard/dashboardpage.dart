import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/lactosure/admin/dashboard/bledevices.dart';
import 'package:lactosure_connect_app/lactosure/admin/dashboard/settings.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/services/dashboardservice.dart';
import 'package:lactosure_connect_app/services/pdf_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? dashboard;
  bool isLoading = true;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final data = await DashboardService.getDashboard();
    setState(() {
      dashboard = data;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _pieData => [
    {
      "title": "Society",
      "value": dashboard!["totalSocieties"],
      "color": Colors.blue,
    },
    {
      "title": "Machine",
      "value": dashboard!["totalMachines"],
      "color": Colors.green,
    },
    {
      "title": "Models",
      "value": dashboard!["totalMachineTypes"],
      "color": Colors.orange,
    },
    {
      "title": "BLE Device",
      "value": dashboard!["totalBleDevices"],
      "color": Colors.purple,
    },
  ];

  List<PieChartSectionData> _pieSections() {
    return List.generate(_pieData.length, (i) {
      final item = _pieData[i];
      final isTouched = i == touchedIndex;

      return PieChartSectionData(
        color: item["color"],
        value: (item["value"] as num).toDouble(),
        title: item["value"].toString(),
        radius: isTouched ? 80 : 65,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    });
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: RotatingFlower());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              if (dashboard == null) return;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: RotatingFlower()),
              );
              await AdminPdfService.generateAdminReport(dashboard: dashboard!);

              if (context.mounted) {
                Navigator.of(context).pop();

                CustomSnackbar.show(
                  context: context,
                  message: "PDF downloaded successfully",
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Bledevice()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Settings()),
              );
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadDashboard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _statCard(
                    "Users",
                    dashboard!["totalUsers"].toString(),
                    Icons.people,
                  ),

                  _statCard(
                    "Societies",
                    dashboard!["totalSocieties"].toString(),
                    Icons.business,
                  ),

                  _statCard(
                    "Machines",
                    dashboard!["totalMachines"].toString(),
                    Icons.precision_manufacturing,
                  ),

                  _statCard(
                    "Models",
                    dashboard!["totalMachineTypes"].toString(),
                    Icons.category,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                "Top Societies",
                style: Theme.of(context).textTheme.displaySmall,
              ),

              const SizedBox(height: 10),

              Card(
                color: Theme.of(context).colorScheme.primary,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: (dashboard!["topSocieties"] as List).length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = dashboard!["topSocieties"][index];

                    return ListTile(
                      leading: CircleAvatar(child: Text("${index + 1}")),
                      title: Text(
                        item["societyName"],
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      subtitle: Text(
                       item["societyId"],
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      trailing: Text(
                        "${item["activeMachineCount"]} Machines",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "System Overview",
                style: Theme.of(context).textTheme.displaySmall,
              ),

              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (touchedIndex != -1) _buildDetails(),
                
                    const SizedBox(height: 20),
                
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: _pieData.map((item) {
                        return _legendItem(
                          context,
                          item["color"] as Color,
                          item["title"] as String,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 50,
                          sectionsSpace: 3,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    response == null ||
                                    response.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }

                                touchedIndex = response
                                    .touchedSection!
                                    .touchedSectionIndex;
                              });
                            },
                          ),
                          sections: _pieSections(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 25, color: Theme.of(context).colorScheme.secondary),

          const SizedBox(height: 10),

          Text(value, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    switch (touchedIndex) {
      case 0:
        return _detailCard(
          "Societies",
          dashboard!["totalSocieties"],
          dashboard!["activeSocieties"],
          dashboard!["inactiveSocieties"],
        );

      case 1:
        return _detailCard(
          "Machines",
          dashboard!["totalMachines"],
          dashboard!["activeMachines"],
          dashboard!["inactiveMachines"],
        );

      case 2:
        return _detailCard(
          "Models",
          dashboard!["totalMachineTypes"],
          dashboard!["activeMachineTypes"],
          dashboard!["inactiveMachineTypes"],
        );

      case 3:
        return _detailCard(
          "BLE Devices",
          dashboard!["totalBleDevices"],
          dashboard!["activeBleDevices"],
          dashboard!["inactiveBleDevices"],
        );

      default:
        return Container();
    }
  }

  Widget _detailCard(String title, int total, int? active, int? inactive) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),

            const Divider(),

            Text(
              "Total : $total",
              style: Theme.of(context).textTheme.titleMedium,
            ),

            if (active != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Active : $active",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),

            if (inactive != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Inactive : $inactive",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
