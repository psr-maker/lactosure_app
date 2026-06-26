import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lactosure_connect_app/constant/global/ble_session.dart';
import 'package:lactosure_connect_app/lactosure/admin/dashboard/settings.dart';
import 'package:lactosure_connect_app/lactosure/screens/corrections/offset_correction.dart';
import 'package:lactosure_connect_app/lactosure/screens/scanner.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';

class Dashboardhome extends StatefulWidget {
  const Dashboardhome({super.key});

  @override
  State<Dashboardhome> createState() => _DashboardhomeState();
}

class _DashboardhomeState extends State<Dashboardhome> {
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? notifyCharacteristic;
  StreamSubscription<List<int>>? notifySubscription;
  List<int> buffer = [];
  Completer<List<int>>? frameCompleter;
  @override
  void initState() {
    super.initState();
    initBle();
  }

  Future<void> initBle() async {
    if (connectedDevice == null) {
      debugPrint("❌ No BLE device connected");
      return;
    }

    List<BluetoothService> services = await connectedDevice!.discoverServices();

    for (final service in services) {
      debugPrint("SERVICE: ${service.uuid}");

      for (final c in service.characteristics) {
        debugPrint(
          "CHAR: ${c.uuid} | "
          "write=${c.properties.write} | "
          "writeNR=${c.properties.writeWithoutResponse} | "
          "read=${c.properties.read} | "
          "notify=${c.properties.notify} | "
          "indicate=${c.properties.indicate}",
        );

        // ✅ WRITE CHARACTERISTIC (fix)
        if (c.properties.write || c.properties.writeWithoutResponse) {
          writeCharacteristic = c;
          debugPrint("✅ WRITE FOUND: ${c.uuid}");
        }

        // ✅ NOTIFY CHARACTERISTIC (response)
        if (c.properties.notify || c.properties.indicate) {
          notifyCharacteristic = c;

          await c.setNotifyValue(true);
          notifySubscription = c.lastValueStream.listen((data) {
            final hexData = data
                .map((e) => e.toRadixString(16).padLeft(2, '0'))
                .join(' ');

            debugPrint("📩 NOTIFY => $hexData");

            buffer.addAll(data);

            // 🔥 VALIDATE FRAME BEFORE COMPLETING
            if (_isValidResponse(buffer)) {
              if (frameCompleter != null && !frameCompleter!.isCompleted) {
                frameCompleter!.complete(List.from(buffer));
              }
            }
          });

          debugPrint("✅ NOTIFY ENABLED: ${c.uuid}");
        }
      }
    }

    if (writeCharacteristic == null) {
      debugPrint("❌ NO WRITE CHARACTERISTIC FOUND!");
    }
  }

  bool _isValidResponse(List<int> data) {
    if (data.length < 6) return false;

    return data[0] == 0x40 && data[1] == 0x04;
  }

  Future<List<int>> sendCommand(List<int> command) async {
    if (writeCharacteristic == null) {
      throw Exception("❌ No writable characteristic found");
    }

    buffer.clear();
    frameCompleter = Completer<List<int>>();

    final useNR = writeCharacteristic!.properties.writeWithoutResponse;

    await writeCharacteristic!.write(command, withoutResponse: useNR);

    debugPrint(
      "📤 SENT => ${command.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );

    return await frameCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException("Device timeout"),
    );
  }

  List<int> hex(String s) =>
      s.split(' ').map((e) => int.parse(e, radix: 16)).toList();

  int calculateLRC(List<int> bytes) {
    int xor = 0;
    for (var b in bytes) {
      xor ^= b;
    }
    return xor & 0xFF;
  }

  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();

      connectedDevice = null;

      if (mounted) {
        setState(() {});
      }
      CustomSnackbar.show(
        context: context,
        message: "Device Disconnected",
        isError: true,
      );
    }
  }

  void _showCountDialog(BuildContext context) {
    final countController = TextEditingController();
    final borderColor = Theme.of(context).colorScheme.background;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "System Response",
                  style: Theme.of(context).textTheme.labelLarge,
                ),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    "CURRENT COUNT",
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    "3",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  "Enter Count",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: countController,
                  keyboardType: TextInputType.number,
                  style: Theme.of(context).textTheme.bodySmall,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),

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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: SizedBox(
                    width: 100,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        String count = countController.text.trim();

                        print("Send Count: $count");

                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        "Send",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: connectedDevice != null
                ? Icon(Icons.bluetooth_connected, color: Colors.white)
                : Icon(Icons.bluetooth_disabled, color: Colors.white60),
            onPressed: () async {
              if (connectedDevice != null) {
                await disconnectDevice();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScannerPage()),
                ).then((_) {
                  if (mounted) setState(() {});
                });
              }
            },
          ),
          IconButton(onPressed: () {}, icon: Icon(Icons.download)),

          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Settings()),
              );
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (connectedDevice != null)
                Row(
                  children: [
                    Icon(
                      Icons.bluetooth_connected,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: 25,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        connectedDevice!.platformName.isEmpty
                            ? "Unknown Device"
                            : connectedDevice!.platformName,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SYSTEM IDENTIFIERS",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(child: _buildInfoItem("Society Id", "S-100")),
                        const SizedBox(width: 20),
                        Expanded(child: _buildInfoItem("Machine Id", "M-100")),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem("Model", "LSE-SVPWTPQ-12AH"),
                        ),
                        const SizedBox(width: 20),
                        Expanded(child: _buildInfoItem("Dongle Id", "123dygy")),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (connectedDevice == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("No device connected"),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OffsetCorrection(device: connectedDevice!),
                          ),
                        );
                      },
                      child: _buildActionCard(
                        title: "Correction",
                        icon: Icons.done_outline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showCountDialog(context),
                      child: _buildActionCard(
                        title: "Count",
                        icon: Icons.adjust_sharp,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Correction History",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text(
                    "View All",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.headlineLarge),
      ],
    );
  }

  Widget _buildActionCard({required String title, required IconData icon}) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 25, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
