import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class EasyCorrection extends StatefulWidget {
  final BluetoothDevice device;

  const EasyCorrection({super.key, required this.device});

  @override
  State<EasyCorrection> createState() => _EasyCorrectionState();
}

class _EasyCorrectionState extends State<EasyCorrection> {
  final TextEditingController fatController = TextEditingController();
  final TextEditingController snfController = TextEditingController();

  String selectedChannel = "CH1";

  final List<String> channels = ["CH1", "CH2", "CH3"];

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
    List<BluetoothService> services = await widget.device.discoverServices();

    for (BluetoothService service in services) {
      for (BluetoothCharacteristic characteristic in service.characteristics) {
        // WRITE CHARACTERISTIC
        if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          writeCharacteristic = characteristic;
        }

        // NOTIFY CHARACTERISTIC
        if (characteristic.properties.notify) {
          notifyCharacteristic = characteristic;

          await characteristic.setNotifyValue(true);

          notifySubscription = notifyCharacteristic!.lastValueStream.listen((
            data,
          ) {
            if (data.isEmpty) return;

            debugPrint("RAW => $data");

            buffer.addAll(data);

            final frame = extractFrame(buffer);

            if (frame != null) {
              debugPrint(
                "FRAME => ${frame.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
              );

              if (frameCompleter != null && !frameCompleter!.isCompleted) {
                frameCompleter!.complete(frame);
              }
            }
          });
        }
      }
    }
  }

  List<int>? extractFrame(List<int> buffer) {
    if (buffer.length < 3) return null;

    if (buffer[0] != 0x40) {
      buffer.removeAt(0);
      return null;
    }

    int payloadLength = buffer[1];

    int totalLength = payloadLength + 2;

    if (buffer.length < totalLength) {
      return null;
    }

    List<int> frame = buffer.sublist(0, totalLength);

    // REMOVE USED FRAME
    buffer.removeRange(0, totalLength);

    return frame;
  }

  Future<List<int>> sendCommand(List<int> command) async {
    frameCompleter = Completer<List<int>>();

    await writeCharacteristic!.write(command, withoutResponse: false);

    debugPrint("SENT => ${command.map((e) => e.toRadixString(16)).join(' ')}");

    return frameCompleter!.future.timeout(const Duration(seconds: 8));
  }

  Future<void> onSavePressed() async {
    try {
      if (writeCharacteristic == null || notifyCharacteristic == null) {
        print("❌ BLE not ready");
        return;
      }
      buffer.clear();

      int channel = 0;

      if (selectedChannel == "CH1") {
        channel = 0;
      } else if (selectedChannel == "CH2") {
        channel = 1;
      } else {
        channel = 2;
      }

      // Start calibration
      final startResp = await sendCommand(hex("40 04 04 01 00 41"));
      print("🤠🤠🤠Start calib");
      print(startResp);

      await Future.delayed(const Duration(seconds: 3));
      // Read values
      double fat = double.tryParse(fatController.text) ?? 0.0;

      double snf = double.tryParse(snfController.text) ?? 0.0;

      // Build calibration command
      List<int> calibrationCmd = buildCalibrationCommand(
        channel: channel,
        fat: fat,
        snf: snf,
      );

      // Send calibration command
      final calibcmd = await sendCommand(calibrationCmd);
      print("😎😎😎Send calib");
      print(calibcmd);

      await Future.delayed(const Duration(seconds: 3));

      // End calibration

      final endCmd = await sendCommand(hex("40 04 04 00 00 40"));
      print("🍭🍭🍭End calib");
      print(endCmd);

      await Future.delayed(const Duration(seconds: 3));

      // Exit

      final exitCmd = await sendCommand(hex("40 04 01 0A 00 4F"));
      print("🥶🥶🥶Exit calib");
      print(exitCmd);

      await Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      print("👍👍👍");
    }
  }

  List<int> buildCalibrationCommand({
    required int channel,
    required double fat,
    required double snf,
  }) {
    int fatValue = (fat * 100).round();
    int snfValue = (snf * 100).round();
    List<int> cmd = [
      0x40,
      0x0C,
      0x30,
      channel,
      0x00,
      (fatValue >> 8) & 0xFF,
      fatValue & 0xFF,
      (snfValue >> 8) & 0xFF,
      snfValue & 0xFF,
      0x00,
      0x00,
      0x00,
      0x00,
    ];
    int xor = calculateXor(cmd);
    cmd.add(xor);
    print(
      '📤 CALIBRATION CMD : '
      "${cmd.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ').toUpperCase()}",
    );
    return cmd;
  }

  List<int> hex(String s) {
    return s.split(' ').map((e) => int.parse(e, radix: 16)).toList();
  }

  int calculateXor(List<int> bytes) {
    int xor = 0;
    for (var b in bytes) {
      xor ^= b;
    }
    return xor & 0xFF;
  }

  @override
  void dispose() {
    fatController.dispose();
    snfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          "Select Channel",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),

        _buildChannelSelector(),

        const SizedBox(height: 20),
        Text(
          "Selected Channel Type : $selectedChannel",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(child: _buildTextField("FAT", fatController)),

            const SizedBox(width: 15),

            Expanded(child: _buildTextField("SNF", snfController)),
          ],
        ),

        const SizedBox(height: 100),

        Center(
          child: SizedBox(
            width: 100,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: onSavePressed,
              child: const Text(
                "Save",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelSelector() {
    return DropdownButtonFormField<String>(
      value: selectedChannel,
      dropdownColor: const Color(0xFF1E293B),

      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),

      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF1E293B),

        prefixIcon: const Icon(
          Icons.settings_input_component,
          color: Colors.orange,
          size: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),

      items: channels.map((channel) {
        return DropdownMenuItem(value: channel, child: Text(channel));
      }).toList(),

      onChanged: (value) {
        setState(() {
          selectedChannel = value!;
        });
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
    );
  }
}
