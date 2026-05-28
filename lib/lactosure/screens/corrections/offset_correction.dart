import 'package:flutter/material.dart';

class OffsetCorrection extends StatefulWidget {
  const OffsetCorrection({super.key});

  @override
  State<OffsetCorrection> createState() => _OffsetCorrectionState();
}

class _OffsetCorrectionState extends State<OffsetCorrection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OffSet Corrections")),
      body: Column(children: [Center(child: Text("data"))]),
    );
  }
}
