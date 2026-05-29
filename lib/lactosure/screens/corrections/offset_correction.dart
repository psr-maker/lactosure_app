import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OffsetCorrection extends StatefulWidget {
  final BluetoothDevice device;

  const OffsetCorrection({super.key, required this.device});

  @override
  State<OffsetCorrection> createState() => _OffsetCorrectionState();
}

class _OffsetCorrectionState extends State<OffsetCorrection> {
  final TextEditingController societyIdController = TextEditingController();
  final TextEditingController machineIdController = TextEditingController();
  final TextEditingController machineTypeController = TextEditingController();

  /// Offset Controllers
  final TextEditingController fatController = TextEditingController();
  final TextEditingController snfController = TextEditingController();
  final TextEditingController clrController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController tempController = TextEditingController();
  final TextEditingController waterController = TextEditingController();
  int selectedTab = 0;
  String selectedChannel = "CH1";
  final List<String> channels = ["CH1", "CH2", "CH3"];
  BluetoothCharacteristic? writeCharacteristic;
  BluetoothCharacteristic? notifyCharacteristic;
  StreamSubscription<List<int>>? notifySubscription;
  Completer<List<int>>? responseCompleter;
  List<int> buffer = [];
  Completer<List<int>>? frameCompleter;
  List<int>? lastReadFrame;
  Map<String, double> lastReadValues = {};

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

  List<int> hex(String s) =>
      s.split(' ').map((e) => int.parse(e, radix: 16)).toList();

  int calculateLRC(List<int> bytes) {
    int xor = 0;
    for (var b in bytes) {
      xor ^= b;
    }
    return xor & 0xFF;
  }

  Future<List<int>> sendCommand(List<int> command) async {
    frameCompleter = Completer<List<int>>();

    await writeCharacteristic!.write(command, withoutResponse: false);

    debugPrint("SENT => ${command.map((e) => e.toRadixString(16)).join(' ')}");

    return frameCompleter!.future.timeout(const Duration(seconds: 8));
  }

  Future<void> readChannelValues() async {
    try {
      buffer.clear();

      int channel = 0;

      if (selectedChannel == "CH1") {
        channel = 0;
      } else if (selectedChannel == "CH2") {
        channel = 1;
      } else {
        channel = 2;
      }

      // LOGIN
      debugPrint("LOGIN...");

      final loginResp = await sendCommand(hex("40 04 06 00 00 42"));

      debugPrint("LOGIN RESP => $loginResp");

      await Future.delayed(const Duration(seconds: 3));

      // READ CMD
      int address = 34 + (channel * 70);

      int high = (address >> 8) & 0xFF;
      int low = address & 0xFF;

      List<int> cmd = [0x40, 0x06, 0xFA, 0xA1, high, low, 0x0C];

      int lrc = calculateLRC(cmd);

      cmd.add(lrc);

      debugPrint("READ CMD => $cmd");

      buffer.clear();

      final readResp = await sendCommand(cmd);

      debugPrint("READ RESP => $readResp");

      parseOffsetResponse(readResp);

      await Future.delayed(const Duration(seconds: 3));

      // LOGOUT
      debugPrint("LOGOUT...");

      final logoutResp = await sendCommand(hex("40 04 D1 00 00 95"));

      debugPrint("LOGOUT RESP => $logoutResp");
    } catch (e) {
      debugPrint("ERROR => $e");
    }
  }

  void parseOffsetResponse(List<int> frame) {
    debugPrint(
      "PARSE FRAME => ${frame.map((e) => e.toRadixString(16)).join(' ')}",
    );

    lastReadFrame = frame;

    if (frame.length < 16) {
      debugPrint("Invalid frame length");
      return;
    }

    if (frame[0] != 0x40 || frame[2] != 0xA1) {
      debugPrint("Invalid response");
      return;
    }

    int readInt16(int high, int low) {
      int value = (high << 8) | low;

      if ((value & 0x8000) != 0) {
        value = value - 0x10000;
      }

      return value;
    }

    double getVal(int index) {
      return readInt16(frame[index], frame[index + 1]) / 100.0;
    }

    double fat = getVal(3);
    double protein = getVal(5);
    double snf = getVal(7);
    double temp = getVal(9);
    double water = getVal(11);
    double clr = getVal(13);

    lastReadValues = {
      "fat": fat,
      "protein": protein,
      "snf": snf,
      "temp": temp,
      "water": water,
      "clr": clr,
    };

    debugPrint("FAT => $fat");
    debugPrint("PROTEIN => $protein");
    debugPrint("SNF => $snf");
    debugPrint("TEMP => $temp");
    debugPrint("WATER => $water");
    debugPrint("CLR => $clr");

    setState(() {
      fatController.text = fat.toStringAsFixed(2);

      snfController.text = snf.toStringAsFixed(2);

      clrController.text = clr.toStringAsFixed(2);

      proteinController.text = protein.toStringAsFixed(2);

      tempController.text = temp.toStringAsFixed(2);

      waterController.text = water.toStringAsFixed(2);
    });
  }

  List<int> buildWriteCommand(int channel) {
    int address = 34 + (channel * 70);

    int high = (address >> 8) & 0xFF;
    int low = address & 0xFF;

    // USER ENTERED CORRECTIONS
    double fatCorrection = double.tryParse(fatController.text.trim()) ?? 0.0;

    double proteinCorrection =
        double.tryParse(proteinController.text.trim()) ?? 0.0;

    double snfCorrection = double.tryParse(snfController.text.trim()) ?? 0.0;

    double tempCorrection = double.tryParse(tempController.text.trim()) ?? 0.0;

    double waterCorrection =
        double.tryParse(waterController.text.trim()) ?? 0.0;

    double clrCorrection = double.tryParse(clrController.text.trim()) ?? 0.0;

    // OLD VALUES FROM MACHINE
    double oldFat = lastReadValues["fat"] ?? 0.0;
    double oldProtein = lastReadValues["protein"] ?? 0.0;
    double oldSnf = lastReadValues["snf"] ?? 0.0;
    double oldTemp = lastReadValues["temp"] ?? 0.0;
    double oldWater = lastReadValues["water"] ?? 0.0;
    double oldClr = lastReadValues["clr"] ?? 0.0;

    // FINAL VALUES
    double fat = calculateFinalValue(
      field: "FAT",
      oldVal: oldFat,
      input: fatCorrection,
    );

    double protein = calculateFinalValue(
      field: "PROTEIN",
      oldVal: oldProtein,
      input: proteinCorrection,
    );

    double snf = calculateFinalValue(
      field: "SNF",
      oldVal: oldSnf,
      input: snfCorrection,
    );

    double temp = calculateFinalValue(
      field: "TEMP",
      oldVal: oldTemp,
      input: tempCorrection,
    );

    double water = calculateFinalValue(
      field: "WATER",
      oldVal: oldWater,
      input: waterCorrection,
    );

    double clr = calculateFinalValue(
      field: "CLR",
      oldVal: oldClr,
      input: clrCorrection,
    );

    List<int> toBytes(double value) {
      int v = (value * 100).round();

      if (v < 0) {
        v = 0x10000 + v;
      }

      return [(v >> 8) & 0xFF, v & 0xFF];
    }

    List<int> cmd = [
      0x40,
      0x12,
      0xFA,
      0xA0,
      high,
      low,
      0x0C,

      ...toBytes(fat),
      ...toBytes(protein),
      ...toBytes(snf),
      ...toBytes(temp),
      ...toBytes(water),
      ...toBytes(clr),
    ];

    int lrc = calculateLRC(cmd);

    cmd.add(lrc);

    debugPrint(
      "FINAL VALUES => "
      "FAT:$fat "
      "PROTEIN:$protein "
      "SNF:$snf "
      "TEMP:$temp "
      "WATER:$water "
      "CLR:$clr",
    );

    debugPrint(
      "WRITE CMD => ${cmd.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}",
    );

    return cmd;
  }

  double calculateFinalValue({
    required String field,
    required double oldVal,
    required double input,
  }) {
    // SAME VALUE -> DON'T CHANGE
    if ((input - oldVal).abs() < 0.001) {
      debugPrint(
        "🔄 $field: INPUT=$input equals OLD=$oldVal, keeping old value",
      );

      return oldVal;
    }

    // APPLY CORRECTION
    double finalVal = oldVal + input;

    debugPrint("✏️ $field: OLD=$oldVal + INPUT=$input = FINAL=$finalVal");

    return finalVal;
  }

  Future<void> sendOffsetValues() async {
    try {
      buffer.clear();

      int channel = 0;

      if (selectedChannel == "CH1") {
        channel = 0;
      } else if (selectedChannel == "CH2") {
        channel = 1;
      } else {
        channel = 2;
      }

      /// LOGIN
      debugPrint("LOGIN...");

      final loginResp = await sendCommand(hex("40 04 06 00 00 42"));

      debugPrint("LOGIN RESP => $loginResp");

      await Future.delayed(const Duration(seconds: 3));

      /// BUILD WRITE COMMAND
      List<int> cmd = buildWriteCommand(channel);

      buffer.clear();

      /// WRITE
      final writeResp = await sendCommand(cmd);

      debugPrint("WRITE RESP => $writeResp");

      await Future.delayed(const Duration(seconds: 3));

      /// LOGOUT
      debugPrint("LOGOUT...");

      final logoutResp = await sendCommand(hex("40 04 D1 00 00 95"));

      debugPrint("LOGOUT RESP => $logoutResp");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Offset values written successfully")),
        );
      }
    } catch (e) {
      debugPrint("WRITE ERROR => $e");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Write failed: $e")));
      }
    }
  }

  @override
  void dispose() {
    notifySubscription?.cancel();

    societyIdController.dispose();
    machineIdController.dispose();
    machineTypeController.dispose();

    fatController.dispose();
    snfController.dispose();
    clrController.dispose();
    proteinController.dispose();
    tempController.dispose();
    waterController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Machine Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTab = 0;
                      });
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: selectedTab == 0
                            ? const Color.fromARGB(255, 16, 134, 109)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Common Offsets',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTab = 1;
                      });
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: selectedTab == 1
                            ? const Color.fromARGB(255, 16, 134, 109)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Easy Corrections',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            if (selectedTab == 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Corrections',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {},
                    icon: const Icon(Icons.history, color: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildCommonCard(),
              const SizedBox(height: 25),
              Text(
                "Selected Channel Type : $selectedChannel",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),
              _buildOffsetFields(),
              const SizedBox(height: 50),
              _submitButton(),
            ],

            /// Easy Correction UI
            if (selectedTab == 1) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Center(
                  child: Text(
                    "Easy Correction Selected",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommonCard() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: societyIdController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              labelText: "Society Id",
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
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: machineIdController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              labelText: "Machine Id",
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
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: machineTypeController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              labelText: "Machine Type",
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
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedChannel,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Channel',
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
            items: channels.map((channel) {
              return DropdownMenuItem(value: channel, child: Text(channel));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedChannel = value!;
              });
            },
          ),
        ),
      ],
    );
  }

  /// Offset TextFields
  Widget _buildOffsetFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildTextField("FAT", fatController)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("SNF", snfController)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("CLR", clrController)),
          ],
        ),

        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(child: _buildTextField("PROTEIN", proteinController)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("TEMP", tempController)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("WATER", waterController)),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
    );
  }

  Widget _submitButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 100,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: sendOffsetValues,
            child: const Text(
              'Send',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        TextButton(
          onPressed: readChannelValues,
          child: const Text(
            'Read',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
