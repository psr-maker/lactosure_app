import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/services/authen_service.dart';

class Adminpage extends StatefulWidget {
  const Adminpage({super.key});

  @override
  State<Adminpage> createState() => _AdminpageState();
}

class _AdminpageState extends State<Adminpage> {
  List<dynamic> pendingUsers = [];
  List<dynamic> approvedUsers = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  // ================= LOAD USERS =================
  Future<void> loadUsers() async {
    try {
      final users = await AuthService.getAllUsers();

      pendingUsers =
          users.where((user) => user["status"] == false).toList();

      approvedUsers =
          users.where((user) => user["status"] == true).toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // ================= APPROVE USER =================
  Future<void> approveUser(int id) async {
    bool success = await AuthService.approveUser(id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User Approved")),
      );

      loadUsers();
    }
  }

  // ================= REJECT USER =================
  Future<void> rejectUser(int id) async {
    bool success = await AuthService.rejectUser(id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User Rejected")),
      );

      loadUsers();
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadUsers,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ================= PENDING USERS =================
                    const Text(
                      "Pending Users",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    pendingUsers.isEmpty
                        ? const Text("No Pending Users")
                        : ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: pendingUsers.length,
                            itemBuilder: (context, index) {
                              final user = pendingUsers[index];

                              return Card(
                                child: ListTile(
                                  title: Text(user["name"]),
                                  subtitle: Text(user["email"]),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [

                                      // APPROVE BUTTON
                                      ElevatedButton(
                                        onPressed: () {
                                          approveUser(user["uId"]);
                                        },
                                        child: const Text("Approve"),
                                      ),

                                      const SizedBox(width: 10),

                                      // REJECT BUTTON
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () {
                                          rejectUser(user["uId"]);
                                        },
                                        child: const Text("Reject"),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                    const SizedBox(height: 30),

                    // ================= APPROVED USERS =================
                    const Text(
                      "Approved Users",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    approvedUsers.isEmpty
                        ? const Text("No Approved Users")
                        : ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: approvedUsers.length,
                            itemBuilder: (context, index) {
                              final user = approvedUsers[index];

                              return Card(
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.verified,
                                    color: Colors.green,
                                  ),
                                  title: Text(user["name"]),
                                  subtitle: Text(user["email"]),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}