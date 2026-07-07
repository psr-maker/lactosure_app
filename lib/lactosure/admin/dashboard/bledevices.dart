import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/services/adminservice.dart';

class Bledevice extends StatefulWidget {
  final bool showAppBar;

  const Bledevice({super.key, this.showAppBar = true});

  @override
  State<Bledevice> createState() => _BledeviceState();
}

class _BledeviceState extends State<Bledevice> {
  List devices = [];
  List filteredDevices = [];

  bool isLoading = true;
  bool isSearching = false;
  final bleNameController = TextEditingController();

  final macController = TextEditingController();

  bool isActive = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDevices();
  }

  Future<void> loadDevices() async {
    setState(() => isLoading = true);

    try {
      final data = await AdminService.getDevices();

      setState(() {
        devices = data;
        filteredDevices = data;
      });
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() => isLoading = false);
  }

  void searchDevice(String value) {
    final query = value.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        filteredDevices = List.from(devices);
        return;
      }

      filteredDevices = devices.where((device) {
        final bleName = (device["bleName"] ?? "").toString().toLowerCase();

        final macAddress = (device["macAddress"] ?? "")
            .toString()
            .toLowerCase();

        return bleName.contains(query) || macAddress.contains(query);
      }).toList();
    });
  }

  void _showAddDeviceDialog() {
    final bleNameController = TextEditingController();
    final macController = TextEditingController();

    bool status = true;
    final borderColor = Theme.of(context).colorScheme.background;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: Text(
                "Add BLE Device",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: bleNameController,
                      style: Theme.of(context).textTheme.headlineLarge,
                      decoration: InputDecoration(
                        hintText: "BLE Name",
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
                    const SizedBox(height: 10),
                    TextField(
                      controller: macController,
                      style: Theme.of(context).textTheme.headlineLarge,
                      decoration: InputDecoration(
                        hintText: "MAC Address",
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
                      value: status,
                      activeColor: Theme.of(context).colorScheme.tertiary,
                      inactiveThumbColor: Theme.of(context).colorScheme.error,
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
                    final result = await AdminService.addDevice(
                      bleName: bleNameController.text.trim(),
                      macAddress: macController.text.trim(),
                      isActive: status,
                    );

                    if (result["success"] == true) {
                      Navigator.pop(context);
                      loadDevices();
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDeviceDialog(Map device) {
    final bleNameController = TextEditingController(text: device["bleName"]);

    final macController = TextEditingController(text: device["macAddress"]);

    bool status = device["isActive"];
    final borderColor = Theme.of(context).colorScheme.background;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: Text(
                "Edit Device",
                style: Theme.of(context).textTheme.displaySmall,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: bleNameController,
                      style: Theme.of(context).textTheme.headlineLarge,
                      decoration: InputDecoration(
                        labelText: "BLE Name",
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
                    TextField(
                      controller: macController,
                      style: Theme.of(context).textTheme.headlineLarge,
                      decoration: InputDecoration(
                        labelText: "MAC Address",
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
                  child: const Text("Cancel"),
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
                    final result = await AdminService.updateDevice(
                      id: device["id"],
                      bleName: bleNameController.text.trim(),
                      macAddress: macController.text.trim(),
                      isActive: status,
                    );

                    if (result["success"] == true) {
                      Navigator.pop(context);
                      loadDevices();
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

  @override
  Widget build(BuildContext context) {
    final totalDevices = devices.length;
    final activeDevices = devices.where((e) => e["isActive"] == true).length;
    final inactiveDevices = devices.where((e) => e["isActive"] == false).length;

    // Dashboard View
    if (!widget.showAppBar) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "All BLE Devices",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),

                  const Spacer(),

                  SizedBox(
                    width: 250,
                    child: TextField(
                      controller: searchController,
                      style: Theme.of(context).textTheme.titleMedium,
                      decoration: InputDecoration(
                        hintText: "Search Society",
                        hintStyle: Theme.of(context).textTheme.titleMedium,
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: searchDevice,
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
                    onPressed: _showAddDeviceDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Add BLE Device"),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              // Total Card Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Total",
                      totalDevices.toString(),
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      "Active",
                      activeDevices.toString(),
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      "Inactive",
                      inactiveDevices.toString(),
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                "BLE Devices List",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        "BLE Name",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),

                    Expanded(
                      flex: 1,
                      child: Text(
                        "MAC Address",
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
                  itemCount: filteredDevices.length,
                  itemBuilder: (context, index) {
                    return desktopRow(filteredDevices[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile View
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: isSearching
            ? TextField(
                controller: searchController,
                style: Theme.of(context).textTheme.titleMedium,
                onChanged: searchDevice,
                decoration: InputDecoration(
                  hintText: "Search users...",
                  hintStyle: Theme.of(context).textTheme.titleMedium,
                  border: InputBorder.none,
                ),
              )
            : const Text("BLE Devices"),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                searchController.clear();
                filteredDevices = devices;
              });
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Total",
                    totalDevices.toString(),
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    "Active",
                    activeDevices.toString(),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    "Inactive",
                    inactiveDevices.toString(),
                    Colors.red,
                  ),
                ),
              ],
            ),
            // Search
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showAddDeviceDialog,
                child: Text(
                  "+ Add Devices",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),

            // Device List
            Expanded(
              child: isLoading
                  ? const Center(child: RotatingFlower())
                  : ListView.builder(
                      itemCount: filteredDevices.length,
                      itemBuilder: (context, index) {
                        final device = filteredDevices[index];

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
                                  color: (device["isActive"] ?? false)
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
                                  device["bleName"]
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),

                              title: Text(
                                device["bleName"] ?? "",
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineLarge,

                                overflow: TextOverflow.ellipsis,
                              ),

                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 5),
                                  Text(
                                    device["macAddress"] ?? "",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    (device["isActive"] ?? false)
                                        ? "Active"
                                        : "Inactive",
                                    style: TextStyle(
                                      color: (device["isActive"] ?? false)
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
                                  if (value == "edit") {
                                    _showEditDeviceDialog(device);
                                  }

                                  if (value == "delete") {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        title: const Text(
                                          "Delete Device",
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: const Text(
                                          "Are you sure? You want to delete this Device",
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
                                            child: const Text("Delete"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm != true) {
                                      return;
                                    }

                                    final result =
                                        await AdminService.deleteDevice(
                                          device["id"],
                                        );

                                    if (result["success"] == true) {
                                      loadDevices();
                                    }
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
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.onSecondary),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget desktopRow(dynamic device) {
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
          Expanded(child: Text(device["bleName"] ?? "")),

          Expanded(
            child: Text(
              device["macAddress"]?.toString() ?? "",
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            child: Text(
              device["isActive"] == true ? "Active" : "Inactive",
              style: TextStyle(
                color: device["isActive"] == true
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
              onPressed: () => _showEditDeviceDialog(device),
            ),
          ),

          Expanded(
            flex: 2,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      title: const Text(
                        "Delete Device",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        "Are you sure? You want to delete this Device",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
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

                  if (confirm != true) {
                    return;
                  }

                  final result = await AdminService.deleteDevice(device["id"]);

                  if (result["success"] == true) {
                    loadDevices();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
