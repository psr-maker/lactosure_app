import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/services/authen_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> allUsers = [];

  List<dynamic> filteredUsers = [];

  bool isLoading = true;
  bool isSearching = false;

  late TabController tabController;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      final users = await AuthService.getAllUsers();

      setState(() {
        allUsers = users;
        filteredUsers = users;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void filterSearch(String value) {
    setState(() {
      filteredUsers = allUsers
          .where(
            (u) =>
                u["name"].toString().toLowerCase().contains(
                  value.toLowerCase(),
                ) ||
                u["email"].toString().toLowerCase().contains(
                  value.toLowerCase(),
                ),
          )
          .toList();
    });
  }

  List<dynamic> getPending() =>
      filteredUsers.where((u) => u["status"] == false).toList();

  List<dynamic> getApproved() =>
      filteredUsers.where((u) => u["status"] == true).toList();

  Future<void> approveUser(int id) async {
    bool success = await AuthService.approveUser(id);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User Approved")));
      loadUsers();
    }
  }

  Future<void> rejectUser(int id) async {
    bool success = await AuthService.rejectUser(id);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User Rejected")));
      loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                style: Theme.of(context).textTheme.titleMedium,
                onChanged: filterSearch,
                decoration: InputDecoration(
                  hintText: "Search users...",
                  hintStyle: Theme.of(context).textTheme.titleMedium,
                  border: InputBorder.none,
                ),
              )
            : const Text("Users"),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                searchController.clear();
                filteredUsers = allUsers;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          labelColor: Theme.of(context).colorScheme.onPrimary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSecondary,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          indicatorWeight: 3,
          labelStyle: Theme.of(context).textTheme.titleMedium,
          unselectedLabelStyle: Theme.of(context).textTheme.titleMedium,

          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Approved"),
          ],
        ),
      ),

      body: isLoading
          ? const Center(child: RotatingFlower())
          : TabBarView(
              controller: tabController,
              children: [
                buildList(getPending(), "pending"),
                buildList(getApproved(), "approved"),
              ],
            ),
    );
  }

  Widget userCard(dynamic user, String type) {
    final bool isApproved = user["status"] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: isApproved ? Colors.green : Colors.orange,
            width: 6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user["name"] ?? "",
              style: Theme.of(context).textTheme.headlineLarge,
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    user["email"] ?? "",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (type == "pending") ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => approveUser(user["uId"]),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text("Approve"),
                  ),

                  const SizedBox(width: 8),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => rejectUser(user["uId"]),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Reject"),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildList(List list, String type) {
    return RefreshIndicator(
      onRefresh: loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return userCard(list[index], type);
        },
      ),
    );
  }
}
