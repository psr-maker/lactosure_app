import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/lactosure/admin/dashboard/bledevices.dart';
import 'package:lactosure_connect_app/lactosure/admin/dashboard/settings.dart';
import 'package:lactosure_connect_app/services/dashboardservice.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? dashboard;
  bool isLoading = true;
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
                    "Machine Types",
                    dashboard!["totalMachineTypes"].toString(),
                    Icons.category,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text("Active Societies"),
                        trailing: Text(
                          dashboard!["activeSocieties"].toString(),
                        ),
                      ),

                      ListTile(
                        title: Text("Inactive Societies"),
                        trailing: Text(
                          dashboard!["inactiveSocieties"].toString(),
                        ),
                      ),

                      Divider(),

                      ListTile(
                        title: Text("Active Machines"),
                        trailing: Text(dashboard!["activeMachines"].toString()),
                      ),

                      ListTile(
                        title: Text("Inactive Machines"),
                        trailing: Text(
                          dashboard!["inactiveMachines"].toString(),
                        ),
                      ),
                    ],
                  ),
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
          Icon(
            icon,
            size: 25,
            color: Theme.of(context).colorScheme.onSecondary,
          ),

          const SizedBox(height: 10),

          Text(value, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
