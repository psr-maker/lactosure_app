import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/services/admin_services/adminservice.dart';

class SocietyPage extends StatefulWidget {
  const SocietyPage({super.key});

  @override
  State<SocietyPage> createState() => _SocietyPageState();
}

class _SocietyPageState extends State<SocietyPage> {
  List societies = [];
  List filteredSocieties = [];
  bool isSearching = false;
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadSocieties();
  }

  Future<void> loadSocieties() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await AdminService.getSocieties();

      setState(() {
        societies = data;
        filteredSocieties = data;
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  void searchSociety(String value) {
    setState(() {
      filteredSocieties = societies.where((society) {
        final name = society["sName"].toString().toLowerCase();

        final code = society["scode"].toString().toLowerCase();

        return name.contains(value.toLowerCase()) ||
            code.contains(value.toLowerCase());
      }).toList();
    });
  }

  void _showEditSocietyDialog(Map society) {
    final TextEditingController nameController = TextEditingController(
      text: society["sName"],
    );

    bool status = society["status"];
    final borderColor = Theme.of(context).colorScheme.background;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.secondary,

              title: Text(
                "Edit Society",
                style: Theme.of(context).textTheme.displaySmall,
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ID (READ ONLY)
                    TextField(
                      controller: TextEditingController(
                        text: society["societyCode"].toString(),
                      ),
                      style: Theme.of(context).textTheme.headlineLarge,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Society ID",
                        labelStyle: Theme.of(context).textTheme.titleMedium,
                        filled: true,
                        fillColor: Colors.transparent,

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 0.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.5,
                          ),
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // NAME (EDITABLE)
                    TextField(
                      controller: nameController,
                      style: Theme.of(context).textTheme.headlineLarge,
                      decoration: InputDecoration(
                        labelText: "Society Name",
                        labelStyle: Theme.of(context).textTheme.titleMedium,
                        filled: true,
                        fillColor: Colors.transparent,

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 0.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.5,
                          ),
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    SwitchListTile(
                      title: Text(
                        status ? "Active" : "Inactive",
                        style: TextStyle(
                          color: status
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      activeColor: Theme.of(context).colorScheme.tertiary,
                      inactiveThumbColor: Theme.of(context).colorScheme.error,
                      value: status,
                      onChanged: (value) {
                        setState(() {
                          status = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.background,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final result = await AdminService.updateSociety(
                      id: society["sid"],
                      sName: nameController.text,
                      status: status,
                    );

                    if (result["success"] == true) {
                      setState(() {
                        society["sName"] = nameController.text;
                        society["status"] = status;
                      });

                      Navigator.pop(context);
                      await loadSocieties();
                    }
                  },
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddSocietyDialog() {
    final societyIdController = TextEditingController();
    final societyNameController = TextEditingController();
    final borderColor = Theme.of(context).colorScheme.background;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          title: Text(
            "Add Society",
            style: Theme.of(context).textTheme.displaySmall,
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: societyIdController,
                  style: Theme.of(context).textTheme.headlineLarge,
                  decoration: InputDecoration(
                    hintText: "Society ID",
                    hintStyle: Theme.of(context).textTheme.titleMedium,

                    filled: true,
                    fillColor: Colors.transparent,

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: borderColor, width: 0.5),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: borderColor, width: 1.5),
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: societyNameController,
                  style: Theme.of(context).textTheme.headlineLarge,
                  decoration: InputDecoration(
                    hintText: "Society Name",
                    hintStyle: Theme.of(context).textTheme.titleMedium,

                    filled: true,
                    fillColor: Colors.transparent,

                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: borderColor, width: 0.5),
                    ),

                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: borderColor, width: 1.5),
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.background,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (societyIdController.text.trim().isEmpty ||
                    societyNameController.text.trim().isEmpty) {
                  return;
                }

                final result = await AdminService.addSociety(
                  societyCode: societyIdController.text.trim(),
                  societyName: societyNameController.text.trim(),
                );

                if (result["success"] == true) {
                  Navigator.pop(context);

                  await loadSocieties();
                } else {}
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSocieties = societies.length;

    final activeSocieties = societies.where((s) => s["status"] == true).length;

    final inactiveSocieties = societies
        .where((s) => s["status"] == false)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                style: Theme.of(context).textTheme.titleMedium,
                onChanged: searchSociety,
                decoration: InputDecoration(
                  hintText: "Search users...",
                  hintStyle: Theme.of(context).textTheme.titleMedium,
                  border: InputBorder.none,
                ),
              )
            : const Text("Societies"),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                searchController.clear();
                filteredSocieties = societies;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Total",
                    totalSocieties.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    "Active",
                    activeSocieties.toString(),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    "Inactive",
                    inactiveSocieties.toString(),
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showAddSocietyDialog,
                child: Text(
                  "+ Add Society",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),

            Expanded(
              child: isLoading
                  ? const Center(child: RotatingFlower())
                  : ListView.builder(
                      itemCount: filteredSocieties.length,
                      itemBuilder: (context, index) {
                        final society = filteredSocieties[index];

                        return Card(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border(
                                left: BorderSide(
                                  color: society["status"]
                                      ? Theme.of(context).colorScheme.tertiary
                                      : Theme.of(context).colorScheme.error,
                                  width: 6,
                                ),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.background,
                                child: Text(
                                  society["sName"].toString().trim().isNotEmpty
                                      ? society["sName"][0].toUpperCase()
                                      : "?",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),

                              title: Text(
                                society["sName"] ?? "",
                                style: Theme.of(context).textTheme.displaySmall,

                                overflow: TextOverflow.ellipsis,
                              ),

                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  Text(
                                    "Society ID • ${society["societyCode"]}",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    society["status"] ? "Active" : "Inactive",
                                    style: TextStyle(
                                      color: society["status"]
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.tertiary
                                          : Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                              trailing: PopupMenuButton(
                                iconColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondary,

                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: "edit",
                                    child: Text("Edit"),
                                  ),
                                  PopupMenuItem(
                                    value: "delete",
                                    child: Text("Delete"),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == "delete") {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          "Delete Society",
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: const Text(
                                          "If you delete this society, all machines under this society will also be deleted permanently.\n\nDo you want to continue?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text("Cancel"),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                              foregroundColor: Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed != true) return;

                                    final result =
                                        await AdminService.deleteSociety(
                                          society["sid"],
                                        );

                                    if (result["success"] == true) {
                                      await loadSocieties();
                                    }
                                  }

                                  if (value == "edit") {
                                    _showEditSocietyDialog(society);
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSecondary),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
