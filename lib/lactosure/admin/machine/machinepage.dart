import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/lactosure/admin/machine/machine.dart';
import 'package:lactosure_connect_app/lactosure/admin/machine/mtype.dart';

class MachineMaster extends StatefulWidget {
  const MachineMaster({super.key});

  @override
  State<MachineMaster> createState() => _MachineMasterState();
}

class _MachineMasterState extends State<MachineMaster>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String title = "Machine";
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  String searchText = "";
  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.index == 0) {
        setState(() {
          title = "Machine";
        });
      } else {
        setState(() {
          title = "Machine Type";
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: Theme.of(context).textTheme.titleMedium,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
              )
            : Text(title),

        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;

                if (!isSearching) {
                  searchController.clear();

                  searchText = "";
                }
              });
            },
          ),
        ],

        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor:Theme.of(context).colorScheme.onSecondary,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          indicatorWeight: 3,
          labelStyle: Theme.of(context).textTheme.titleMedium,
          unselectedLabelStyle: Theme.of(context).textTheme.titleMedium,
          tabs: const [
            Tab(text: "Machine"),
            Tab(text: "Machine Type"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MachinePage(searchText: searchText),
          MachineTypePage(searchText: searchText),
        ],
      ),
    );
  }
}
