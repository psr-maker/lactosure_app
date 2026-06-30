import 'dart:async';
import 'package:lactosure_connect_app/constant/global/ble_session.dart';
import 'package:lactosure_connect_app/constant/global/system_info.dart';
import 'package:lactosure_connect_app/lactosure/screens/dashboard/home.dart';
import 'package:lactosure_connect_app/services/adminservice.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  List<ScanResult> scanResults = [];
  StreamSubscription? scanSubscription;
  List allowedDevices = [];
  bool _isConnecting = false;
  String? _connectingMac;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await loadAllowedDevices();
    await startScan();
  }

  Future<void> loadMachineDetails() async {
    final machineData = await AdminService.getMachines();
    final societyData = await AdminService.getSocieties();

    String bleMachineId = systemInfo.machineId;
    String bleModel = systemInfo.model;

    final matchedMachines = machineData.cast<Map<String, dynamic>>().where((m) {
      return m["machineCode"].toString().trim() == bleMachineId.trim() &&
          m["machineType"].toString().trim().toUpperCase() ==
              bleModel.trim().toUpperCase();
    }).toList();

    if (matchedMachines.isEmpty) {
      print("❌ Machine not found");
      return;
    }

    final machine = matchedMachines.first;

    // Get SID from machine
    final int sid = machine["sid"];

    // Find society using SID
    final matchedSociety = societyData.cast<Map<String, dynamic>>().where((s) {
      return s["sid"] == sid;
    }).toList();

    if (matchedSociety.isEmpty) {
      print("❌ Society not found");
      return;
    }

    final society = matchedSociety.first;

    // Save values
    systemInfo.machineId = machine["machineCode"].toString();
    systemInfo.model = machine["machineType"].toString();

    systemInfo.societyId = society["societyCode"].toString();
    systemInfo.societyName = society["sName"].toString();

    print("Machine : ${systemInfo.machineId}");
    print("Model   : ${systemInfo.model}");
    print("SID     : $sid");
    print("Society Code : ${systemInfo.societyId}");
    print("Society Name : ${systemInfo.societyName}");
  }

  Future<void> loadAllowedDevices() async {
    allowedDevices = await AdminService.getDevices();
  }

  Future<void> startScan() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;

    if (state != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();

      state = await FlutterBluePlus.adapterState.first;

      if (state != BluetoothAdapterState.on) {
        if (!mounted) return;

        CustomSnackbar.show(
          context: context,
          message: "Please turn on Bluetooth",
          isError: true,
        );
        return;
      }
    }

    scanResults.clear();

    scanSubscription?.cancel();

    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _connectingMac = device.remoteId.str;
    });
    try {
      String normalizeMac(String mac) => mac
          .replaceAll(":", "")
          .replaceAll("-", "")
          .replaceAll(" ", "")
          .trim()
          .toUpperCase();

      final matchedDevice = allowedDevices.cast<Map>().firstWhere(
        (d) =>
            normalizeMac(d["macAddress"].toString()) ==
            normalizeMac(device.remoteId.str),
        orElse: () => {},
      );
      if (matchedDevice.isEmpty) {
        CustomSnackbar.show(
          context: context,
          message: "Unauthorized Device",
          isError: true,
        );
        return;
      }

      if (matchedDevice["isActive"] != true) {
        CustomSnackbar.show(
          context: context,
          message: "Device is inactive",
          isError: true,
        );
        return;
      }

      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
      );

      connectedDevice = device;

      // Listen for disconnect
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          connectedDevice = null;
        }
      });

      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? writeCharacteristic;
      BluetoothCharacteristic? notifyCharacteristic;
      Completer<List<int>> responseCompleter = Completer<List<int>>();
      List<int> buffer = [];

      // Find characteristics
      for (final service in services) {
        print("SERVICE : ${service.uuid}");

        for (final c in service.characteristics) {
          print(
            "CHAR : ${c.uuid}"
            " write=${c.properties.write}"
            " writeNR=${c.properties.writeWithoutResponse}"
            " notify=${c.properties.notify}"
            " indicate=${c.properties.indicate}"
            " read=${c.properties.read}",
          );

          if (c.properties.write || c.properties.writeWithoutResponse) {
            writeCharacteristic = c;
          }

          if (c.properties.notify || c.properties.indicate) {
            notifyCharacteristic = c;
          }
        }
      }

      if (writeCharacteristic == null) {
        throw Exception("No write characteristic found");
      }

      if (notifyCharacteristic == null) {
        throw Exception("No notify characteristic found");
      }

      // Enable notifications
      await notifyCharacteristic.setNotifyValue(true);

      // Give the device time to enable notifications
      await Future.delayed(const Duration(seconds: 3));

      // Listen for response
      notifyCharacteristic.lastValueStream.listen((data) {
        if (data.isEmpty) return;

        buffer.addAll(data);

        String hex = buffer
            .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(' ');

        print("📩 RESPONSE : $hex");

        // Complete on first packet received
        if (!responseCompleter.isCompleted) {
          responseCompleter.complete(List.from(buffer));
        }
      });

      // Login command
      List<int> command = [0x40, 0x04, 0x55, 0x00, 0x00];
      command.add(calculateLRC(command));

      await writeCharacteristic.write(
        command,
        withoutResponse: writeCharacteristic.properties.writeWithoutResponse,
      );

      print(
        "📤 SENT : ${command.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
      );

      // Wait for response
      List<int> response = await responseCompleter.future.timeout(
        const Duration(seconds: 10),
      );

      print("✅ FINAL RESPONSE : $response");
      parseSystemInfo(response);
      await loadMachineDetails();
      connectedDevice = device;

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          connectedDevice = null;
        }
      });

      if (!mounted) return;

      CustomSnackbar.show(
        context: context,
        message: "${device.platformName} Connected",
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Dashboardhome()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("Connection Error: $e");

      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: "Connection Failed\n$e",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingMac = null;
        });
      }
    }
  }

  int calculateLRC(List<int> bytes) {
    int xor = 0;
    for (var b in bytes) {
      xor ^= b;
    }
    return xor & 0xFF;
  }

  void parseSystemInfo(List<int> frame) {
    if (frame.length < 17) return;

    // Machine ID (1 byte)
    int machineNo = frame[4];

    // Dongle ID (2 bytes)
    int dongleId = (frame[10] << 8) | frame[11];

    // Model
    String model = readString(frame, 12, 5);

    systemInfo.machineId = "A${machineNo.toString().padLeft(5, '0')}";
    systemInfo.dongleId = dongleId.toString();
    systemInfo.model = model;

    print("Machine ID : ${systemInfo.machineId}");
    print("Dongle ID  : ${systemInfo.dongleId}");
    print("Model      : ${systemInfo.model}");
  }

  // Unsigned 16-bit
  int readUInt16(List<int> frame, int index) {
    return (frame[index] << 8) | frame[index + 1];
  }

  // Signed 16-bit
  int readInt16(List<int> frame, int index) {
    int value = (frame[index] << 8) | frame[index + 1];

    if ((value & 0x8000) != 0) {
      value -= 0x10000;
    }

    return value;
  }

  // Unsigned 32-bit
  int readUInt32(List<int> frame, int index) {
    return (frame[index] << 24) |
        (frame[index + 1] << 16) |
        (frame[index + 2] << 8) |
        frame[index + 3];
  }

  // Convert bytes to ASCII
  String readString(List<int> frame, int index, int length) {
    return String.fromCharCodes(
      frame.sublist(index, index + length),
    ).replaceAll('\u0000', '').trim();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: const Text("BLE Scanner"),
        actions: [
          IconButton(onPressed: startScan, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: scanResults.isEmpty
            ? const Center(child: RotatingFlower())
            : ListView.separated(
                itemCount: scanResults.length,
                separatorBuilder: (_, __) => SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final device = scanResults[index].device;

                  return Row(
                    children: [
                      const Icon(
                        Icons.bluetooth,
                        color: Colors.orange,
                        size: 28,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.platformName.isEmpty
                                  ? "Unknown Device"
                                  : device.platformName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              device.remoteId.str,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isConnecting
                            ? null
                            : () => connectDevice(device),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.orange),
                          ),
                        ),
                        child:
                            _isConnecting &&
                                _connectingMac == device.remoteId.str
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: RotatingFlower(),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    "Connect",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class SystemInfo {
  final String machineId;
  final String model;
  final String dongleId;

  const SystemInfo({
    required this.machineId,
    required this.model,
    required this.dongleId,
  });
}
