import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';

import 'package:lactosure_connect_app/services/adminservice.dart';

class MachinePage extends StatefulWidget {
  final String searchText;

  const MachinePage({super.key, required this.searchText});

  @override
  State<MachinePage> createState() => _MachinePageState();
}

class _MachinePageState extends State<MachinePage> {
  List machines = [];
  List societies = [];
  List machineTypes = [];

  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    try {
      final machineData = await AdminService.getMachines();
      final societyData = await AdminService.getSocieties();
      final machineTypeData = await AdminService.getMachineTypes();

      setState(() {
        machines = machineData;
        societies = societyData;
        machineTypes = machineTypeData;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showAddMachineDialog() {
    final machineCodeController = TextEditingController();

    int? selectedSociety;
    int? selectedMachineType;
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
                "Add Machine",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Machine ID
                    TextField(
                      controller: machineCodeController,
                      style: Theme.of(context).textTheme.headlineLarge,
                      decoration: InputDecoration(
                        hintText: "Machine ID",
                        hintStyle: Theme.of(context).textTheme.titleMedium,

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

                    const SizedBox(height: 12),

                    /// Society Dropdown
                    DropdownButtonFormField<int>(
                      value: selectedSociety,
                      dropdownColor: Theme.of(context).colorScheme.primary,
                      style: Theme.of(context).textTheme.titleMedium,
                      decoration: InputDecoration(
                        labelText: "Select Society",
                        labelStyle: Theme.of(context).textTheme.titleMedium,

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      iconEnabledColor: Theme.of(context).colorScheme.onPrimary,
                      items: societies.map<DropdownMenuItem<int>>((s) {
                        return DropdownMenuItem<int>(
                          value: s["sid"],
                          child: Text(
                            s["sName"],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSociety = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    /// Machine Type Dropdown
                    DropdownButtonFormField<int>(
                      value: selectedMachineType,
                      dropdownColor: Theme.of(context).colorScheme.primary,
                      style: Theme.of(context).textTheme.titleMedium,
                      decoration: InputDecoration(
                        labelText: "Select Machine Type",
                        labelStyle: Theme.of(context).textTheme.titleMedium,

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      iconEnabledColor: Theme.of(context).colorScheme.onPrimary,
                      items: machineTypes.map<DropdownMenuItem<int>>((m) {
                        return DropdownMenuItem<int>(
                          value: m["mtid"],
                          child: Text(
                            m["mType"],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMachineType = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    /// Status Switch
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
                    if (machineCodeController.text.isEmpty ||
                        selectedSociety == null ||
                        selectedMachineType == null) {
                      return;
                    }

                    final result = await AdminService.addMachine(
                      machineCode: machineCodeController.text.trim(),
                      sid: selectedSociety!,
                      mtid: selectedMachineType!,
                      status: status,
                    );

                    if (result["success"] == true) {
                      Navigator.pop(context);
                      await loadData();
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

  void _showEditMachineDialog(Map item) {
    int selectedSociety = item["sid"];
    int selectedMachineType = item["mtid"];
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
                "Edit Machine",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: TextEditingController(
                        text: item["machineCode"],
                      ),
                      readOnly: true,
                      style: Theme.of(context).textTheme.headlineLarge,
                      decoration: InputDecoration(
                        labelText: "Machine ID",
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

                    DropdownButtonFormField<int>(
                      value: selectedSociety,
                      dropdownColor: Theme.of(context).colorScheme.primary,
                      decoration: InputDecoration(
                        labelText: "Society",
                        labelStyle: Theme.of(context).textTheme.titleMedium,

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: societies.map<DropdownMenuItem<int>>((s) {
                        return DropdownMenuItem<int>(
                          value: s["sid"],
                          child: Text(
                            s["sName"],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSociety = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<int>(
                      value: selectedMachineType,
                      dropdownColor: Theme.of(context).colorScheme.primary,
                      style: Theme.of(context).textTheme.titleMedium,
                      decoration: InputDecoration(
                        labelText: "Machine Type",
                        labelStyle: Theme.of(context).textTheme.titleMedium,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.5,
                          ),
                        ),

                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: borderColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: machineTypes.map<DropdownMenuItem<int>>((m) {
                        return DropdownMenuItem<int>(
                          value: m["mtid"],
                          child: Text(
                            m["mType"],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedMachineType = value!;
                        });
                      },
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
                        setDialogState(() {
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
                    final result = await AdminService.updateMachine(
                      id: item["mid"],
                      sid: selectedSociety,
                      mtid: selectedMachineType,
                      status: status,
                    );

                    if (result["success"] == true) {
                      Navigator.pop(context);
                      await loadData();
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

  Future<void> _deleteMachine(Map item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          "Delete Machine",
          style: TextStyle(
            fontSize: 15,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete '${item["machineCode"]}' ?",
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

    if (confirm != true) return;

    final result = await AdminService.deleteMachine(item["mid"]);

    if (result["success"] == true) {
      await loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = machines.length;

    final active = machines.where((e) => e["status"] == true).length;

    final inactive = machines.where((e) => e["status"] == false).length;
    final filteredMachines = machines.where((m) {
      return m["machineCode"].toString().toLowerCase().contains(
            widget.searchText.toLowerCase(),
          ) ||
          m["societyName"].toString().toLowerCase().contains(
            widget.searchText.toLowerCase(),
          ) ||
          m["machineType"].toString().toLowerCase().contains(
            widget.searchText.toLowerCase(),
          );
    }).toList();
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          SizedBox(height: 10),

          /// COUNTS
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
              onPressed: _showAddMachineDialog,
              child: Text(
                "+ Add Machine",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: RotatingFlower())
                : ListView.builder(
                    itemCount: filteredMachines.length,
                    itemBuilder: (context, index) {
                      final item = filteredMachines[index];

                      return Card(
                        color: Theme.of(context).colorScheme.primary,
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
                                color: item["status"]
                                    ? Theme.of(context).colorScheme.tertiary
                                    : Theme.of(context).colorScheme.error,
                                width: 4,
                              ),
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.background,
                              child: Text(
                                item["machineCode"].toString()[0].toUpperCase(),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            title: Text(
                              item["machineCode"],
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5),
                                Text(
                                  item["machineType"],
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item["societyName"],
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item["status"] ? "Active" : "Inactive",
                                  style: TextStyle(
                                    color: item["status"]
                                        ? Theme.of(context).colorScheme.tertiary
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
                              color: Theme.of(context).colorScheme.onSecondary,
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: "edit",
                                  child: Text("Edit"),
                                ),
                                PopupMenuItem(
                                  value: "delete",
                                  child: Text("Delete"),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == "edit") {
                                  _showEditMachineDialog(item);
                                }

                                if (value == "delete") {
                                  _deleteMachine(item);
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
}
