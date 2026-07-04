import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lactosure_connect_app/constant/global/system_info.dart';
import 'package:lactosure_connect_app/constant/loadingflw.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/services/dashboardservice.dart';

class EasyCorrection extends StatefulWidget {
  final BluetoothDevice device;
  final int uid;
  const EasyCorrection({super.key, required this.device, required this.uid});

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
  List<int> responseBuffer = [];
  Timer? _idleTimer;
  Completer<List<int>>? frameCompleter;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    initBle();
  }

  Future<void> initBle() async {
    List<BluetoothService> services = await widget.device.discoverServices();

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse) {
          writeCharacteristic = characteristic;
        }

        if (characteristic.properties.notify) {
          notifyCharacteristic = characteristic;

          await characteristic.setNotifyValue(true);

          notifySubscription = characteristic.onValueReceived.listen(_onData);
        }
      }
    }
  }

  void _onData(List<int> data) {
    if (data.isEmpty) return;

    debugPrint("RAW => $data");

    responseBuffer.addAll(data);
    buffer.addAll(data);

    _resetIdleTimer();

    _tryParseFrames();
  }

  void _tryParseFrames() {
    List<int>? frame;

    while ((frame = extractFrame(buffer)) != null) {
      debugPrint("FRAME => $frame");

      // DO NOT complete here
      _handleFrame(frame!);
    }
  }

  void _handleFrame(List<int> frame) {
    responseBuffer.addAll(frame);
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();

    _idleTimer = Timer(const Duration(milliseconds: 300), () {
      if (frameCompleter != null && !frameCompleter!.isCompleted) {
        debugPrint("FINAL RESPONSE => $responseBuffer");

        frameCompleter!.complete(List.from(responseBuffer));

        responseBuffer.clear();
        buffer.clear();
      }
    });
  }

  List<int>? extractFrame(List<int> buffer) {
    // resync start byte
    while (buffer.isNotEmpty && buffer[0] != 0x40) {
      buffer.removeAt(0);
    }

    if (buffer.length < 2) return null;

    int payloadLength = buffer[1];
    int totalLength = payloadLength + 2;
    debugPrint("Need $totalLength bytes, currently ${buffer.length}");
    if (totalLength > 300) {
      buffer.removeAt(0);
      return null;
    }

    if (buffer.length < totalLength) return null;

    final frame = buffer.sublist(0, totalLength);
    buffer.removeRange(0, totalLength);

    return frame;
  }

  Future<List<int>> sendCommand(List<int> command) async {
    if (writeCharacteristic == null) {
      throw Exception("Write characteristic not found");
    }

    // Clear previous response data
    buffer.clear();

    // Cancel previous timer
    _idleTimer?.cancel();

    frameCompleter = Completer<List<int>>();

    await writeCharacteristic!.write(command, withoutResponse: false);

    debugPrint("SENT => ${command.map((e) => e.toRadixString(16)).join(' ')}");

    return await frameCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException("Device response timeout");
      },
    );
  }

  Future<void> onSavePressed() async {
    if (!mounted) return;
    setState(() {
      isSaving = true;
    });

    try {
      if (writeCharacteristic == null || notifyCharacteristic == null) {
        CustomSnackbar.show(
          context: context,
          message: "BLE connection not ready. Please try again.",
          isError: true,
        );
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

      await writeCharacteristic!.write(
        hex("40 04 01 0A 00 4F"),
        withoutResponse: false,
      );
      print("🥶🥶🥶Exit calib");
      await Future.delayed(const Duration(seconds: 1));

      await DashboardService.saveCorrectionMethod(
        uid: widget.uid,
        corrMethod: "Easy Correction",
        channel: selectedChannel,
        sId: systemInfo.societyId,
        mId: systemInfo.machineId,
        model: systemInfo.model,
        dongleId: systemInfo.dongleId,
        fat: double.tryParse(fatController.text),
        snf: double.tryParse(snfController.text),
        clr: null,
        prt: null,
        temp: null,
        wtr: null,
      );

      CustomSnackbar.show(
        context: context,
        message: "Easy correction saved successfully",
        isError: false,
      );
    } catch (e, s) {
      print("❌ ERROR: $e");
      print(s);
      CustomSnackbar.show(
        context: context,
        message: "Error saving correction: ${e.toString()}",
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
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
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),

        _buildChannelSelector(),

        const SizedBox(height: 20),
        Text(
          "Selected Channel Type : $selectedChannel",
          style: Theme.of(context).textTheme.headlineLarge,
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
                backgroundColor: Theme.of(context).colorScheme.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: isSaving ? null : onSavePressed,
              child: isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: RotatingFlower(),
                    )
                  : Text(
                      "Save",
                      style: Theme.of(context).textTheme.headlineLarge,
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
      dropdownColor: Theme.of(context).colorScheme.primary,

      style: Theme.of(context).textTheme.headlineLarge,

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
      style: Theme.of(context).textTheme.headlineLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.onPrimary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
