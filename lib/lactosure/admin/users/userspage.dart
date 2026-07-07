import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/lactosure/admin/face/face_register.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/services/authen_service.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> allUsers = [];

  List<dynamic> filteredUsers = [];

  bool isLoading = true;
  bool isSearching = false;
  String selectedFilter = "All";
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
      CustomSnackbar.show(
        context: context,
        message: e.toString(),
        isError: true,
      );
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
      CustomSnackbar.show(
        context: context,
        message: "User Approved",
        isError: false,
      );
      loadUsers();
    }
  }

  Future<void> rejectUser(int id) async {
    bool success = await AuthService.rejectUser(id);
    if (success) {
      CustomSnackbar.show(
        context: context,
        message: "User Rejected",
        isError: false,
      );
    }
  }

  Future<void> deleteUser(int id) async {
    bool success = await AuthService.deleteUser(id);

    if (success) {
      CustomSnackbar.show(
        context: context,
        message: "User deleted successfully",
        isError: false,
      );

      loadUsers();
    } else {
      CustomSnackbar.show(
        context: context,
        message: "Failed to delete user",
        isError: true,
      );
    }
  }

  List<dynamic> getFilteredUsers() {
    List<dynamic> users = List.from(allUsers);

    // Search
    if (searchController.text.isNotEmpty) {
      final query = searchController.text.toLowerCase();

      users = users.where((user) {
        return (user["name"] ?? "").toString().toLowerCase().contains(query) ||
            (user["email"] ?? "").toString().toLowerCase().contains(query);
      }).toList();
    }

    // Status Filter
    if (selectedFilter == "Active") {
      users = users.where((u) => u["status"] == true).toList();
    } else if (selectedFilter == "Pending") {
      users = users.where((u) => u["status"] == false).toList();
    }

    return users;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1000;

        return Scaffold(
          appBar: widget.showAppBar ? _buildAppBar(isDesktop) : null,

          body: isLoading
              ? const Center(child: RotatingFlower())
              : isDesktop
              ? buildDesktopList(getFilteredUsers())
              : TabBarView(
                  controller: tabController,
                  children: [
                    buildList(getApproved(), "approved"),
                    buildList(getPending(), "pending"),
                  ],
                ),
        );
      },
    );
  }

  Widget userCard(dynamic user, String type) {
    final bool isApproved = user["status"] == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: isApproved
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.background,
            width: 4,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Name + Face Enrollment Icon
            Row(
              children: [
                Expanded(
                  child: Text(
                    user["name"] ?? "",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),

                /// Show only for approved users
                if (isApproved)
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FaceEnrollment(
                            userId: user["uId"],
                            userName: user["name"] ?? "",
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.tag_faces_sharp,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 5),

            /// Email
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.background,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user["email"] ?? "",
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),

            /// Approve / Reject Buttons for Pending Users
            if (type == "pending") ...[
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => approveUser(user["uId"]),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text("Approve"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => rejectUser(user["uId"]),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text("Reject"),
                    ),
                  ),
                ],
              ),
            ],
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
          final user = list[index];

          return Dismissible(
            key: ValueKey(user["uId"]),

            direction: DismissDirection.endToStart,

            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 30,
              ),
            ),

            confirmDismiss: (direction) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      title: Text(
                        "Delete User",
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      content: Text(
                        "Are you sure you want to delete ${user["name"]}?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(
                            "Cancel",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            "Delete",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            },

            onDismissed: (direction) {
              deleteUser(user["uId"]);
            },

            child: userCard(user, type),
          );
        },
      ),
    );
  }

  Widget buildDesktopList(List<dynamic> users) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          /// Top Bar
          Row(
            children: [
              Text(
                "All Users",
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const Spacer(),

              SizedBox(
                width: 250,
                child: TextField(
                  controller: searchController,
                  style: Theme.of(context).textTheme.titleMedium,
                  decoration: InputDecoration(
                    hintText: "Search users",
                    hintStyle: Theme.of(context).textTheme.titleMedium,
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),

              const SizedBox(width: 20),

              DropdownButton<String>(
                value: selectedFilter,
                dropdownColor: Theme.of(context).colorScheme.primary,
                items: const [
                  DropdownMenuItem(value: "All", child: Text("All")),
                  DropdownMenuItem(value: "Active", child: Text("Active")),
                  DropdownMenuItem(value: "Pending", child: Text("Pending")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedFilter = value!;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    "Name",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Text(
                    "Email",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Text(
                    "Status",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Text(
                    "Face",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Text(
                    "Action",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return desktopRow(users[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget desktopRow(dynamic user) {
    final bool approved = user["status"] == true;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: Text(user["name"] ?? "")),

          Expanded(
            flex: 2,
            child: Text(user["email"] ?? "", overflow: TextOverflow.ellipsis),
          ),

          Expanded(
            child: Text(
              approved ? "Active" : "Pending",
              style: TextStyle(
                color: approved ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: approved
                ? IconButton(
                    icon: const Icon(Icons.tag_faces),
                    color: Colors.blue,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FaceEnrollment(
                            userId: user["uId"],
                            userName: user["name"],
                          ),
                        ),
                      );
                    },
                  )
                : const Text("-"),
          ),

          Expanded(
            flex: 2,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  deleteUser(user["uId"]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDesktop) {
    return AppBar(
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

      actions: isDesktop
          ? []
          : [
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

      bottom: isDesktop
          ? null
          : TabBar(
              controller: tabController,
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSecondary,
              indicatorColor: Theme.of(context).colorScheme.onPrimary,
              indicatorWeight: 3,
              labelStyle: Theme.of(context).textTheme.titleMedium,
              unselectedLabelStyle: Theme.of(context).textTheme.titleMedium,

              tabs: const [
                Tab(text: "Approved"),
                Tab(text: "Pending"),
              ],
            ),
    );
  }
}
