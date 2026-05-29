import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/lactosure/screens/home.dart';
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

      if (!mounted) return;
      CustomSnackbar.show(
        context: context,
        message: "${device.platformName} Connected",
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Corrections(device: device)),
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
      // backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        // backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "BLE Scanner",
          style: const TextStyle(
            color: Color.fromARGB(255, 14, 4, 109),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: startScan,
            icon: const Icon(
              Icons.refresh,
              color: Color.fromARGB(255, 14, 4, 109),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: scanResults.isEmpty
            ? const Center(child: RotatingFlower())
            : ListView.builder(
                itemCount: scanResults.length,
                itemBuilder: (context, index) {
                  final device = scanResults[index].device;

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.bluetooth),
                      title: Text(
                        device.platformName.isEmpty
                            ? "Unknown Device"
                            : device.platformName,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 14, 102, 58),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        device.remoteId.str,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => connectDevice(device),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "Connect",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
