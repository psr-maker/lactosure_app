import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/lactosure/admin/dashboard/bledevices.dart';
import 'package:lactosure_connect_app/lactosure/admin/dashboard/dashboardpage.dart';
import 'package:lactosure_connect_app/lactosure/admin/dashboard/settings.dart';
import 'package:lactosure_connect_app/lactosure/admin/machine/machinepage.dart';
import 'package:lactosure_connect_app/lactosure/admin/society/societypage.dart';
import 'package:lactosure_connect_app/lactosure/admin/users/userspage.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int selectedIndex = 0;

  bool get isMobile => MediaQuery.of(context).size.width < 600;

  List<Widget> get desktopPages {
    return [
      DashboardPage(showAppBar: false),
      UsersPage(showAppBar: false),
      SocietyPage(showAppBar: false),
      MachineMaster(showAppBar: false),
      Bledevice(showAppBar: false),
    ];
  }

  List<Widget> get mobilePages {
    return [
      DashboardPage(showAppBar: true),
      UsersPage(showAppBar: true),
      SocietyPage(showAppBar: true),
      MachineMaster(showAppBar: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = isMobile ? mobilePages : desktopPages;

    // Prevent invalid index
    if (selectedIndex >= pages.length) {
      selectedIndex = 0;
    }

    return Scaffold(
      appBar: isMobile
          ? null
          : AppBar(
              title: const Text("Admin Dashboard"),
              centerTitle: false,
              actions: [
                _buildTopNavItem("Dashboard", 0),
                const SizedBox(width: 15),

                _buildTopNavItem("Users", 1),
                const SizedBox(width: 15),

                _buildTopNavItem("Society", 2),
                const SizedBox(width: 15),

                _buildTopNavItem("Machine", 3),
                const SizedBox(width: 15),

                // Desktop Only
                _buildTopNavItem("BLE", 4),
                const SizedBox(width: 15),

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

      body: IndexedStack(index: selectedIndex, children: pages),

      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: selectedIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).colorScheme.primary,
              selectedItemColor: Theme.of(context).colorScheme.onPrimary,
              unselectedItemColor: Theme.of(context).colorScheme.onSecondary,

              onTap: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },

              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: "Dashboard",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: "Users",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.groups),
                  label: "Society",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.precision_manufacturing),
                  label: "Machine",
                ),
              ],
            )
          : null,
    );
  }

 Widget _buildTopNavItem(String label, int index) {
  final bool isSelected = selectedIndex == index;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Color.fromARGB(255, 7, 218, 218)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
}
