import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/lactosure/admin/dashboard/dashboardpage.dart';
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

  final List<Widget> pages = const [
    DashboardPage(),
    UsersPage(),
    SocietyPage(),
    MachineMaster(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        backgroundColor: Theme.of(context).colorScheme.primary,
        selectedItemColor: Theme.of(context).colorScheme.onPrimary,
        unselectedItemColor: Theme.of(context).colorScheme.onSecondary,
        unselectedFontSize: 12,
        selectedFontSize: 15,
        selectedIconTheme: IconThemeData(size: 15),
        unselectedIconTheme: IconThemeData(size: 12),
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() { 
            selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Society'),
          BottomNavigationBarItem(
            icon: Icon(Icons.precision_manufacturing),
            label: 'Machine',
          ),
        ],
      ),
    );
  }
}
