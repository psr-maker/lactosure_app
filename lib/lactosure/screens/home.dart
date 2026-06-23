import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/constant/global/ble_session.dart';
import 'package:lactosure_connect_app/lactosure/admin/face/verify_face.dart';
import 'package:lactosure_connect_app/lactosure/screens/corrections/offset_correction.dart';
import 'package:lactosure_connect_app/lactosure/screens/scanner.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';

class Dashboardhome extends StatefulWidget {
  const Dashboardhome({super.key});

  @override
  State<Dashboardhome> createState() => _DashboardhomeState();
}

class _DashboardhomeState extends State<Dashboardhome> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text(
          "Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaceLoginPage()),
              );
            },
            icon: Icon(Icons.qr_code_scanner_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (connectedDevice != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bluetooth_connected,
                      color: Colors.green,
                      size: 25,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            connectedDevice!.platformName.isEmpty
                                ? "Unknown Device"
                                : connectedDevice!.platformName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            connectedDevice!.remoteId.str,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 150,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (connectedDevice == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No device connected")),
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
                  child: const Text("Correction"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
