import 'dart:async';
import 'package:lactosure_connect_app/constant/global/ble_session.dart';
import 'package:lactosure_connect_app/lactosure/screens/home.dart';
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

  @override
  void initState() {
    super.initState();
    startScan();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> startScan() async {
    // Request permissions
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // Check bluetooth state
    BluetoothAdapterState state = await FlutterBluePlus.adapterState.first;

    if (state != BluetoothAdapterState.on) {
      // Ask user to turn on bluetooth
      await FlutterBluePlus.turnOn();

      // Recheck state
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
    try {
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
      );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          "BLE Scanner",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: startScan,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
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
                        onPressed: () => connectDevice(device),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.orange),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 16),
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
