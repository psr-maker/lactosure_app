import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/services/adminservice.dart';

class MachineTypePage extends StatefulWidget {
  final String searchText;
  final bool showAppBar;

  const MachineTypePage({
    super.key,
    required this.searchText,
    this.showAppBar = true,
  });

  @override
  State<MachineTypePage> createState() => _MachineTypePageState();
}

class _MachineTypePageState extends State<MachineTypePage> {
  List machineTypes = [];
  List filteredMachineTypes = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    loadMachineTypes();
  }

  Future<void> loadMachineTypes() async {
    setState(() => isLoading = true);

    try {
      final data = await AdminService.getMachineTypes();

      setState(() {
        machineTypes = data;
        filteredMachineTypes = data;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showAddMachineTypeDialog() {
    final controller = TextEditingController();
    bool status = true;
    final borderColor = Theme.of(context).colorScheme.background;
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: Text(
                "Add Machine Type",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: Theme.of(context).textTheme.headlineLarge,
                    decoration: InputDecoration(
                      hintText: "Machine Type",
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
                  const SizedBox(height: 10),
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
                      setDialogState(() {
                        status = value;
                      });
                    },
                  ),
                ],
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
                    final result = await AdminService.addMachineType(
                      mType: controller.text,
                      status: status,
                    );

                    if (result["success"] == true) {
                      Navigator.pop(context);
                      await loadMachineTypes();
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMachineTypeDialog(Map item) {
    final controller = TextEditingController(text: item["mType"]);

    bool status = item["status"];
    final borderColor = Theme.of(context).colorScheme.background;
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.primary,

              title: Text(
                "Edit Machine Type",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: Theme.of(context).textTheme.headlineLarge,

                    decoration: InputDecoration(
                      labelText: "Machine Type",
                      labelStyle: Theme.of(context).textTheme.titleMedium,
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
                  const SizedBox(height: 10),
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
                      setDialogState(() {
                        status = value;
                      });
                    },
                  ),
                ],
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
                    final result = await AdminService.updateMachineType(
                      id: item["mtid"],
                      mType: controller.text,
                      status: status,
                    );

                    if (result["success"] == true) {
                      Navigator.pop(context);
                      await loadMachineTypes();
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

  Future<void> _deleteMachineType(Map item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          "Delete Machine Type",
          style: TextStyle(
            fontSize: 15,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this machine type?",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await AdminService.deleteMachineType(item["mtid"]);

      if (result["success"] == true) {
        await loadMachineTypes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = machineTypes.length;
    final active = machineTypes.where((e) => e["status"] == true).length;
    final inactive = machineTypes.where((e) => e["status"] == false).length;
    final filteredMachineTypes = machineTypes.where((m) {
      return m["mType"].toString().toLowerCase().contains(
        widget.searchText.toLowerCase(),
      );
    }).toList();

    // Dashboard View
    if (!widget.showAppBar) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "All Machines Model",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),

                const Spacer(),
                SizedBox(
                  width: 250,
                  child: TextField(
                    onChanged: (value) {},
                    style: Theme.of(context).textTheme.titleMedium,
                    decoration: InputDecoration(
                      hintText: "Search Models",
                      hintStyle: Theme.of(context).textTheme.titleMedium,
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.background,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 15,
                    ),
                  ),
                  onPressed: _showAddMachineTypeDialog,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Model"),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Total Card Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard("Total", total.toString(), Colors.blue),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    "Active",
                    active.toString(),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    "Inactive",
                    inactive.toString(),
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              "Model List",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 15),

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
                      "Machine Type",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      "Society",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),

                  Expanded(
                    flex: 1,
                    child: Text(
                      "Edit",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),

                  Expanded(
                    flex: 1,
                    child: Text(
                      "Delete",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                itemCount: filteredMachineTypes.length,
                itemBuilder: (context, index) {
                  return desktopRow(filteredMachineTypes[index]);
                },
              ),
            ),
          ],
        ),
      );
    }

    // Mobile View
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _buildStatCard("Total", total.toString(), Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  "Active",
                  active.toString(),
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  "Inactive",
                  inactive.toString(),
                  Colors.red,
                ),
              ),
            ],
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showAddMachineTypeDialog,
              child: Text(
                "+ Add Machine Type",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: RotatingFlower())
                : ListView.builder(
                    itemCount: filteredMachineTypes.length,
                    itemBuilder: (context, index) {
                      final item = filteredMachineTypes[index];

                      return Card(
                        color: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.background,

                            child: Text(item["mType"][0].toUpperCase()),
                          ),
                          title: Text(
                            item["mType"],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            item["status"] ? "Active" : "Inactive",
                            style: TextStyle(
                              color: item["status"]
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          trailing: PopupMenuButton(
                            iconColor: Theme.of(context).colorScheme.onPrimary,
                            color: Theme.of(context).colorScheme.onSecondary,
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: "edit", child: Text("Edit")),
                              PopupMenuItem(
                                value: "delete",
                                child: Text("Delete"),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == "edit") {
                                _showEditMachineTypeDialog(item);
                              }

                              if (value == "delete") {
                                _deleteMachineType(item);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSecondary),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 5),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget desktopRow(dynamic model) {
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
          Expanded(
            child: Text(
              model["mType"]?.toString() ?? "",
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            child: Text(
              model["status"] == true ? "Active" : "Inactive",
              style: TextStyle(
                color: model["status"] == true
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.onTertiary,
              ),
              onPressed: () => _showEditMachineTypeDialog(model),
            ),
          ),

          Expanded(
            flex: 2,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteMachineType(model),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
