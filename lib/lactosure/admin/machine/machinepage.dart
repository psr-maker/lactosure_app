import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/lactosure/admin/machine/machine.dart';
import 'package:lactosure_connect_app/lactosure/admin/machine/mtype.dart';

class MachineMaster extends StatefulWidget {
  const MachineMaster({super.key, this.showAppBar = true});

  final bool showAppBar;

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
    final tabBar = TabBar(
      controller: _tabController,
      labelColor: Theme.of(context).colorScheme.onPrimary,
      unselectedLabelColor: Theme.of(context).colorScheme.onSecondary,
      indicatorColor: Theme.of(context).colorScheme.onPrimary,
      indicatorWeight: 3,
      labelStyle: Theme.of(context).textTheme.titleMedium,
      unselectedLabelStyle: Theme.of(context).textTheme.titleMedium,
      tabs: const [
        Tab(text: "Machine"),
        Tab(text: "Machine Type"),
      ],
    );

    // Dashboard View
    if (!widget.showAppBar) {
      return Scaffold(
        body: Column(
          children: [
            // TabBar
            Container(
              color: Theme.of(context).colorScheme.primary,
              child: tabBar,
            ),
            // TabBar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  MachinePage(searchText: searchText, showAppBar: widget.showAppBar),
                  MachineTypePage(searchText: searchText, showAppBar: widget.showAppBar),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile View
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: tabBar,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MachinePage(searchText: searchText, showAppBar: widget.showAppBar),
          MachineTypePage(searchText: searchText, showAppBar: widget.showAppBar),
        ],
      ),
    );
  }
}
