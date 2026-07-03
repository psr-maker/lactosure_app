import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lactosure_connect_app/constant/global/ble_session.dart';
import 'package:lactosure_connect_app/constant/global/system_info.dart';
import 'package:lactosure_connect_app/constant/global/token.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/lactosure/admin/dashboard/settings.dart';
import 'package:lactosure_connect_app/lactosure/screens/corrections/offset_correction.dart';
import 'package:lactosure_connect_app/lactosure/screens/dashboard/method_history.dart';
import 'package:lactosure_connect_app/lactosure/screens/dashboard/scanner.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/services/dashboardservice.dart';
import 'package:lactosure_connect_app/services/pdf_service.dart';

class Dashboardhome extends StatefulWidget {
  const Dashboardhome({super.key});

  @override
  State<Dashboardhome> createState() => _DashboardhomeState();
}

class _DashboardhomeState extends State<Dashboardhome> {
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;
  StreamSubscription<List<int>>? notifySubscription;
  BluetoothCharacteristic? readCharacteristic;
  List<dynamic> correctionHistory = [];
  List<int> buffer = [];
  Completer<List<int>>? frameCompleter;
  int currentCount = 0;
  String userName = "";
  int? userId;
  String email = "";
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      await initBle();
      await loadUser();
    });
  }

  Future<void> initBle() async {
    if (connectedDevice == null) {
      debugPrint("No BLE device connected");
      return;
    }

    final ready = await _ensureBleCharacteristics();
    if (!ready) {
      debugPrint("Required BLE characteristics not found");
      return;
    }

    debugPrint(
      "Selected WRITE char: ${writeCharacteristic?.uuid} "
      "(write=${writeCharacteristic?.properties.write} "
      "writeNR=${writeCharacteristic?.properties.writeWithoutResponse})",
    );
    debugPrint(
      "Selected NOTIFY char: ${notifyCharacteristic?.uuid} "
      "(notify=${notifyCharacteristic?.properties.notify} "
      "indicate=${notifyCharacteristic?.properties.indicate})",
    );

    if (!(notifyCharacteristic?.properties.notify == true ||
        notifyCharacteristic?.properties.indicate == true)) {
      debugPrint(
        "Selected notify characteristic does not support notify/indicate",
      );
    }

    final canNotify =
        notifyCharacteristic?.properties.notify == true ||
        notifyCharacteristic?.properties.indicate == true;

    if (canNotify) {
      await notifyCharacteristic!.setNotifyValue(true);
      debugPrint("✅ Notify Enabled");
      _setupNotifyListener();
    } else if (readCharacteristic != null) {
      debugPrint(
        "❕ Notify not supported, using read fallback from ${readCharacteristic!.uuid}",
      );
    } else {
      debugPrint("❌ No notify or read response characteristic available");
    }

    connectionSubscription = connectedDevice!.connectionState.listen((state) {
      debugPrint("BLE STATE : $state");

      if (state == BluetoothConnectionState.disconnected) {
        connectedDevice = null;
        writeCharacteristic = null;
        notifyCharacteristic = null;

        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _setupNotifyListener() {
    notifySubscription?.cancel();

    notifySubscription = notifyCharacteristic!.lastValueStream.listen((data) {
      if (data.isEmpty) return;

      debugPrint(
        "📩 RESPONSE : ${data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
      );

      if (data.length == 6 &&
          frameCompleter != null &&
          !frameCompleter!.isCompleted) {
        frameCompleter!.complete(List<int>.from(data));
      }
    });
  }

  Future<bool> _ensureBleCharacteristics() async {
    if (connectedDevice == null) return false;

    if (writeCharacteristic != null && notifyCharacteristic != null) {
      return true;
    }

    final services = await connectedDevice!.discoverServices();
    BluetoothCharacteristic? foundWrite;
    BluetoothCharacteristic? foundNotify;

    for (final service in services) {
      debugPrint("SERVICE: ${service.uuid}");
      for (final characteristic in service.characteristics) {
        debugPrint(
          "CHAR: ${characteristic.uuid} "
          "write=${characteristic.properties.write} "
          "writeNR=${characteristic.properties.writeWithoutResponse} "
          "notify=${characteristic.properties.notify} "
          "indicate=${characteristic.properties.indicate} "
          "read=${characteristic.properties.read}",
        );

        if (foundWrite == null &&
            (characteristic.properties.write ||
                characteristic.properties.writeWithoutResponse)) {
          foundWrite = characteristic;
        }

        if (foundNotify == null &&
            (characteristic.properties.notify ||
                characteristic.properties.indicate)) {
          foundNotify = characteristic;
        }
      }
    }

    if (foundWrite != null) {
      writeCharacteristic = foundWrite;
    }

    if (foundNotify != null) {
      notifyCharacteristic = foundNotify;
    }

    if (notifyCharacteristic == null &&
        writeCharacteristic != null &&
        writeCharacteristic!.properties.notify) {
      notifyCharacteristic = writeCharacteristic;
    }

    if (writeCharacteristic == null &&
        notifyCharacteristic != null &&
        notifyCharacteristic!.properties.write) {
      writeCharacteristic = notifyCharacteristic;
    }

    if (readCharacteristic == null) {
      if (writeCharacteristic != null && writeCharacteristic!.properties.read) {
        readCharacteristic = writeCharacteristic;
      } else if (notifyCharacteristic != null &&
          notifyCharacteristic!.properties.read) {
        readCharacteristic = notifyCharacteristic;
      }
    }

    debugPrint(
      "Resolved BLE chars: write=${writeCharacteristic?.uuid} "
      "notify=${notifyCharacteristic?.uuid} "
      "read=${readCharacteristic?.uuid}",
    );

    return writeCharacteristic != null &&
        (notifyCharacteristic != null || readCharacteristic != null);
  }

  Future<List<int>> sendCommand(List<int> command) async {
    if (writeCharacteristic == null) {
      throw Exception("❌ No writable characteristic found");
    }

    buffer.clear();
    final completer = Completer<List<int>>();
    frameCompleter = completer;

    final useNR = writeCharacteristic!.properties.writeWithoutResponse;

    final canNotify =
        notifyCharacteristic?.properties.notify == true ||
        notifyCharacteristic?.properties.indicate == true;

    await writeCharacteristic!.write(command, withoutResponse: useNR);
    debugPrint("Waiting for response...");
    debugPrint(
      "📤 SENT => ${command.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );

    if (canNotify) {
      try {
        return await completer.future.timeout(const Duration(seconds: 10));
      } on TimeoutException {
        if (buffer.length >= 6 &&
            buffer[0] == 0x40 &&
            buffer[1] == 0x04 &&
            buffer[2] == 0x77) {
          debugPrint("✅ Using received response from buffer.");

          return buffer.sublist(0, 6);
        }

        throw TimeoutException("Device timeout");
      }
    }

    if (readCharacteristic != null) {
      return await _pollReadResponse(
        const Duration(seconds: 10),
        pollDelay: const Duration(milliseconds: 300),
      );
    }

    throw TimeoutException("Device timeout");
  }

  Future<List<int>> _pollReadResponse(
    Duration timeout, {
    required Duration pollDelay,
  }) async {
    if (readCharacteristic == null) {
      throw Exception("No readable characteristic available for fallback");
    }

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      try {
        final readData = await readCharacteristic!.read();
        if (readData.isNotEmpty) {
          debugPrint(
            "📥 READ FALLBACK => ${readData.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
          );
          return readData;
        }
      } catch (e) {
        debugPrint("Read fallback attempt failed: $e");
      }

      await Future.delayed(pollDelay);
    }

    throw TimeoutException("Device read fallback timeout");
  }

  Future<void> readCurrentCount() async {
    try {
      // Command without LRC
      List<int> cmd = [0x40, 0x04, 0x66, 0xA1, 0x00];

      // Add LRC
      cmd.add(calculateLRC(cmd));

      final response = await sendCommand(cmd);

      debugPrint("COUNT RESPONSE => $response");

      // Expected:
      // 40 04 77 A1 03 LRC

      if (response.length >= 6 &&
          response[0] == 0x40 &&
          response[1] == 0x04 &&
          response[2] == 0x77 &&
          response[3] == 0xA1) {
        currentCount = response[4];

        debugPrint("Current Count = $currentCount");
      } else {
        throw Exception("Invalid response");
      }
    } catch (e) {
      debugPrint("READ COUNT ERROR: $e");
    }
  }

  Future<bool> writeCurrentCount(int count) async {
    List<int> cmd = [0x40, 0x04, 0x66, 0xA1, count];
    cmd.add(calculateLRC(cmd));

    try {
      final response = await sendCommand(cmd);

      return response.length >= 6 &&
          response[0] == 0x40 &&
          response[1] == 0x04 &&
          response[2] == 0x77 &&
          response[3] == 0xA0;
    } on TimeoutException {
      // Device may have disconnected after sending ACK.
      if (connectedDevice == null) {
        debugPrint("Device already disconnected. Treating as success.");
        _cleanupBleSession();
        return true;
      }

      final state = await connectedDevice!.connectionState.first;

      if (state == BluetoothConnectionState.disconnected) {
        debugPrint("Device disconnected after write. Treating as success.");
        _cleanupBleSession();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint("WRITE COUNT ERROR => $e");
      return false;
    }
  }

  void _cleanupBleSession() {
    connectedDevice = null;
    writeCharacteristic = null;
    notifyCharacteristic = null;
    if (mounted) {
      setState(() {});
    }
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
                    currentCount.toString(),
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
                      onPressed: () async {
                        if (countController.text.isEmpty) {
                          return;
                        }

                        int count = int.parse(countController.text);

                        bool success = await writeCurrentCount(count);

                        if (!mounted) return;

                        if (success) {
                          Navigator.pop(context);
                          await disconnectDevice(showSnackbar: false);

                          CustomSnackbar.show(
                            context: context,
                            message: "Count reset successfully and device disconnected",
                          );
                        } else {
                          CustomSnackbar.show(
                            context: context,
                            message: "Count reset failed",
                            isError: true,
                          );
                        }
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

  Future<void> loadUser() async {
    userName = await TokenCheck.getUserName() ?? "";
    userId = await TokenCheck.getUserId();
    email = await TokenCheck.getEmail() ?? "";
    if (userId != null) {
      await loadCorrectionHistory();
    }
    setState(() {});
  }

  Future<void> disconnectDevice({bool showSnackbar = true}) async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
    }

    _cleanupBleSession();

    if (showSnackbar) {
      CustomSnackbar.show(
        context: context,
        message: "Device Disconnected",
        isError: true,
      );
    }
  }

  Future<void> loadCorrectionHistory() async {
    correctionHistory = await DashboardService.getCorrMethodHistory(userId!);

    setState(() {});
  }

  @override
  void dispose() {
    notifySubscription?.cancel();
    connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latestThree = correctionHistory.take(3).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: connectedDevice != null
                ? Icon(
                    Icons.bluetooth_connected,
                    color: Color.fromARGB(255, 7, 218, 218),
                  )
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
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: RotatingFlower()),
              );

              try {
                await PdfService.generateCorrectionReport(
                  name: userName,
                  email: email,
                  society:
                      "${systemInfo.societyId} - ${systemInfo.societyName}",
                  machineId: systemInfo.machineId,
                  model: systemInfo.model,
                  dongleId: systemInfo.dongleId,
                  history: correctionHistory,
                );

                if (context.mounted) {
                  Navigator.of(context).pop(); // Close loading dialog

                  CustomSnackbar.show(
                    context: context,
                    message: "PDF downloaded successfully",
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close loading dialog

                  CustomSnackbar.show(
                    context: context,
                    message: e.toString(),
                    isError: true,
                  );
                }
              }
            },
          ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await loadCorrectionHistory();
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        child: Icon(
                          Icons.person,
                          size: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Name : ${userName.isEmpty ? "-" : userName}",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),

                            const SizedBox(height: 5),

                            Text(
                              "Email : ${email.isEmpty ? "-" : email}",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                          Expanded(
                            child: _buildInfoItem(
                              "Society",
                              systemInfo.societyName.isEmpty
                                  ? "-"
                                  : " ${systemInfo.societyId} - ${systemInfo.societyName}",
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildInfoItem(
                              "Machine Id",
                              systemInfo.machineId.isEmpty
                                  ? "-"
                                  : systemInfo.machineId,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoItem(
                              "Model",
                              systemInfo.model.isEmpty ? "-" : systemInfo.model,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildInfoItem(
                              "Dongle Id",
                              systemInfo.dongleId.isEmpty
                                  ? "-"
                                  : systemInfo.dongleId,
                            ),
                          ),
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
                            CustomSnackbar.show(
                              context: context,
                              message: "No device connected",
                              isError: true,
                            );
                            return;
                          }

                          if (userId == null) {
                            CustomSnackbar.show(
                              context: context,
                              message: "User ID not loaded",
                              isError: true,
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OffsetCorrection(
                                device: connectedDevice!,
                                uid: userId!,
                              ),
                            ),
                          );
                        },
                        child: _buildActionCard(
                          title: "Correction",
                          icon: Icons.sticky_note_2_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          //   await readCurrentCount();
                          if (connectedDevice == null) {
                            CustomSnackbar.show(
                              context: context,
                              message: "No device connected",
                              isError: true,
                            );
                            return;
                          }
                          _showCountDialog(context);
                        },
                        child: _buildActionCard(
                          title: "Count",
                          icon: Icons.av_timer_rounded,
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
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CorrMethodHistory(uid: userId!),
                          ),
                        );
                      },
                      child: Text(
                        "View All",
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: latestThree.length,
                  itemBuilder: (context, index) {
                    final item = latestThree[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["corrMethod"],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),

                            const SizedBox(height: 8),

                            Text(
                              "Channel : ${item["channel"]}",
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
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
      height: 90,
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
