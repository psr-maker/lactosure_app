import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:http/http.dart' as http;
import 'package:lactosure_connect_app/lactosure/screens/corrections/easy_correction.dart';
import 'package:lactosure_connect_app/lactosure/widgets/custom_button.dart';
import 'package:lactosure_connect_app/services/admin_services/adminservice.dart';
import 'package:lactosure_connect_app/services/corr_history_model.dart';

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
  String formattedDate = "";
  Map<String, double> lastReadValues = {};
  Map<String, double> finalWrittenValues = {};
  final String apiBaseUrl = 'https://lactosure.azurewebsites.net';
  bool canSend = false;
  List<int> responseBuffer = [];
  Timer? _idleTimer;

  String? selectedSocietyId;
  String? selectedMachineId;
  String? selectedMachineType;
  bool isLoading = true;

  List<dynamic> machines = [];
  List<dynamic> societies = [];
  List<dynamic> machineTypes = [];
  @override
  void initState() {
    super.initState();
    initBle();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);

    try {
      final machineData = await AdminService.getMachines();
      final societyData = await AdminService.getSocieties();
      final machineTypeData = await AdminService.getMachineTypes();

      setState(() {
        machines = machineData;
        societies = societyData;
        machineTypes = machineTypeData;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void validateSendButton() {
    bool fieldsFilled =
        selectedSocietyId != null &&
        selectedMachineId != null &&
        selectedMachineType != null;

    setState(() {
      canSend = fieldsFilled && lastReadValues.isNotEmpty;
    });
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

  List<int> hex(String s) =>
      s.split(' ').map((e) => int.parse(e, radix: 16)).toList();

  int calculateLRC(List<int> bytes) {
    int xor = 0;
    for (var b in bytes) {
      xor ^= b;
    }
    return xor & 0xFF;
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
    validateSendButton();
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
    finalWrittenValues = {
      'fat': fat,
      'snf': snf,
      'clr': clr,
      'temp': temp,
      'protein': protein,
      'water': water,
    };
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
      await Future.delayed(const Duration(milliseconds: 300));
      await updateMachineCorrection();

      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: "Offset values written successfully",
        );
      }
    } catch (e) {
      debugPrint("WRITE ERROR => $e");

      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: "Write failed: $e",
          isError: true,
        );
      }
    }
  }

  Future<void> updateMachineCorrection() async {
    try {
      print("\n☁️ UPDATING CLOUD WITH CORRECTIONS...");

      String society = selectedSocietyId ?? "";
      String machineId = selectedMachineId ?? "";
      String model = selectedMachineType ?? "";

      if (society.isEmpty || machineId.isEmpty || model.isEmpty) {
        print("❌ Missing required fields");
        CustomSnackbar.show(
          context: context,
          message: "Please enter Society ID, Machine ID and Model",
          isError: true,
        );

        return;
      }

      Map<String, dynamic> payload = {
        'SocietyID': society,
        'MachineId': machineId,
        'MachineType': model,

        // CHANNEL 1
        'ch1': selectedChannel == "CH1" ? "1" : null,
        'fat1': selectedChannel == "CH1" ? finalWrittenValues['fat'] : null,
        'snf1': selectedChannel == "CH1" ? finalWrittenValues['snf'] : null,
        'clr1': selectedChannel == "CH1" ? finalWrittenValues['clr'] : null,
        't1': selectedChannel == "CH1" ? finalWrittenValues['temp'] : null,
        'w1': selectedChannel == "CH1" ? finalWrittenValues['water'] : null,
        'p1': selectedChannel == "CH1" ? finalWrittenValues['protein'] : null,

        // CHANNEL 2
        'ch2': selectedChannel == "CH2" ? "2" : null,
        'fat2': selectedChannel == "CH2" ? finalWrittenValues['fat'] : null,
        'snf2': selectedChannel == "CH2" ? finalWrittenValues['snf'] : null,
        'clr2': selectedChannel == "CH2" ? finalWrittenValues['clr'] : null,
        't2': selectedChannel == "CH2" ? finalWrittenValues['temp'] : null,
        'w2': selectedChannel == "CH2" ? finalWrittenValues['water'] : null,
        'p2': selectedChannel == "CH2" ? finalWrittenValues['protein'] : null,

        // CHANNEL 3
        'ch3': selectedChannel == "CH3" ? "3" : null,
        'fat3': selectedChannel == "CH3" ? finalWrittenValues['fat'] : null,
        'snf3': selectedChannel == "CH3" ? finalWrittenValues['snf'] : null,
        'clr3': selectedChannel == "CH3" ? finalWrittenValues['clr'] : null,
        't3': selectedChannel == "CH3" ? finalWrittenValues['temp'] : null,
        'w3': selectedChannel == "CH3" ? finalWrittenValues['water'] : null,
        'p3': selectedChannel == "CH3" ? finalWrittenValues['protein'] : null,

        'Timestamp': DateTime.now().toIso8601String(),
      };

      print("Selected Channel => $selectedChannel");
      print("Final Written Values => $finalWrittenValues");

      print("Payload =>");
      print(const JsonEncoder.withIndent('  ').convert(payload));

      final response = await http.post(
        Uri.parse(
          '$apiBaseUrl/api/MachineCorrection/GetLatestMachineCorrection',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print("📦 STATUS CODE: ${response.statusCode}");
      print("📦 RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ CLOUD UPDATE SUCCESSFUL");

        CustomSnackbar.show(
          context: context,
          message: "Correction Saved Successfully",
        );
      } else {
        print("❌ CLOUD UPDATE FAILED");

        CustomSnackbar.show(
          context: context,
          message: "Failed: ${response.statusCode}",
          isError: true,
        );
      }
    } catch (e) {
      print("❌ CLOUD UPDATE ERROR: $e");

      CustomSnackbar.show(
        context: context,
        message: "Error: $e",
        isError: true,
      );
    }
  }

  Future<List<CorrectionHistory>> fetchCorrectionHistory() async {
    try {
      String society = selectedSocietyId ?? "";
      String machineId = selectedMachineId ?? "";
      String model = selectedMachineType ?? "";

      final uri =
          Uri.parse(
            '$apiBaseUrl/api/MachineCorrection/GetCorrectionByDetails',
          ).replace(
            queryParameters: {
              'SocietyID': society,
              'MachineID': machineId,
              'MachineType': model,
            },
          );

      print("📥 FETCHING HISTORY...");
      print(uri);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("data.....🤠🤠🤠🤠");
        print(data);

        if (data is List) {
          return data.map((e) => CorrectionHistory.fromJson(e)).toList();
        }

        return [];
      } else {
        print("❌ HISTORY FETCH FAILED: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ HISTORY ERROR: $e");
      return [];
    }
  }

  Future<void> showHistoryDialog() async {
    List<CorrectionHistory> history = await fetchCorrectionHistory();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Correction History",
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.cancel_sharp,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: history.isEmpty
                      ? const Center(child: Text("No History Found"))
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (context, index) {
                            final item = history[index];
                            try {
                              DateTime dt = DateTime.parse(item.backupDateTime);

                              formattedDate =
                                  "${dt.day.toString().padLeft(2, '0')}-"
                                  "${dt.month.toString().padLeft(2, '0')}-"
                                  "${dt.year}  "
                                  "${dt.hour.toString().padLeft(2, '0')}:"
                                  "${dt.minute.toString().padLeft(2, '0')}";
                            } catch (e) {
                              formattedDate = item.backupDateTime;
                            }
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Channel ${item.ch1 ?? item.ch2 ?? item.ch3 ?? '-'}",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Date: $formattedDate",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      _historyChip(
                                        "Fat",
                                        item.fat1 ??
                                            item.fat2 ??
                                            item.fat3 ??
                                            "0",
                                      ),
                                      _historyChip(
                                        "SNF",
                                        item.snf1 ??
                                            item.snf2 ??
                                            item.snf3 ??
                                            "0",
                                      ),
                                      _historyChip(
                                        "CLR",
                                        item.clr1 ??
                                            item.clr2 ??
                                            item.clr3 ??
                                            "0",
                                      ),
                                      _historyChip(
                                        "Temp",
                                        item.t1 ?? item.t2 ?? item.t3 ?? "0",
                                      ),
                                      _historyChip(
                                        "Protein",
                                        item.p1 ?? item.p2 ?? item.p3 ?? "0",
                                      ),
                                      _historyChip(
                                        "Water",
                                        item.w1 ?? item.w2 ?? item.w3 ?? "0",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Machine Settings'),
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
                            ? Theme.of(context).colorScheme.onTertiary
                            : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Common Offsets',
                          style: Theme.of(context).textTheme.headlineLarge,
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
                            ? Theme.of(context).colorScheme.onTertiary
                            : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Easy Corrections',
                          style: Theme.of(context).textTheme.headlineLarge,
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
                  Text(
                    'Corrections',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  IconButton(
                    onPressed: () async {
                      await showHistoryDialog();
                    },
                    icon: Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.background,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildCommonCard(),
              const SizedBox(height: 25),
              Text(
                "Selected Channel Type : $selectedChannel",
                style: Theme.of(context).textTheme.headlineLarge,
              ),

              const SizedBox(height: 20),
              _buildOffsetFields(),
              const SizedBox(height: 50),
              _submitButton(),
            ]
            /// Easy Correction UI
            else ...[
              EasyCorrection(device: widget.device),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommonCard() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedSocietyId,
                dropdownColor: Theme.of(context).colorScheme.primary,
                style: Theme.of(context).textTheme.headlineLarge,
                decoration: _dropdownDecoration("Society"),
                items: societies.map<DropdownMenuItem<String>>((society) {
                  return DropdownMenuItem<String>(
                    value: society["societyCode"].toString(),
                    child: Text(
                      society["societyCode"].toString(),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSocietyId = value;
                  });
                  validateSendButton();
                },
              ),
            ),
            SizedBox(width: 5),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedMachineId,
                dropdownColor: Theme.of(context).colorScheme.primary,
                style: Theme.of(context).textTheme.headlineLarge,
                decoration: _dropdownDecoration("Machine"),
                items: machines.map<DropdownMenuItem<String>>((machine) {
                  return DropdownMenuItem<String>(
                    value: machine["machineCode"].toString(),
                    child: Text(
                      machine["machineCode"].toString(),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMachineId = value;
                  });
                  validateSendButton();
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        DropdownButtonFormField<String>(
          value: selectedMachineType,
          dropdownColor: Theme.of(context).colorScheme.primary,
          style: Theme.of(context).textTheme.headlineLarge,
          decoration: _dropdownDecoration("Model"),
          items: machineTypes.map<DropdownMenuItem<String>>((type) {
            return DropdownMenuItem<String>(
              value: type["mType"].toString(),
              child: Text(
                type["mType"].toString(),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedMachineType = value;
            });
            validateSendButton();
          },
        ),
        const SizedBox(height: 15),
        DropdownButtonFormField<String>(
          value: selectedChannel,
          dropdownColor: Theme.of(context).colorScheme.primary,
          style: Theme.of(context).textTheme.headlineLarge,
          decoration: _dropdownDecoration("Channel"),
          items: channels.map((channel) {
            return DropdownMenuItem<String>(
              value: channel,
              child: Text(channel),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedChannel = value!;
            });
          },
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),
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
      style: Theme.of(context).textTheme.headlineMedium,
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
              backgroundColor: canSend
                  ? Theme.of(context).colorScheme.background
                  : Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: canSend ? sendOffsetValues : null,
            child: Text(
              'Send',
              style: TextStyle(
                color: canSend ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        TextButton(
          onPressed: readChannelValues,
          child: Text('Read', style: Theme.of(context).textTheme.headlineLarge),
        ),
      ],
    );
  }

  Widget _historyChip(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        "$title : $value",
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
