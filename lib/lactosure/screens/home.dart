import 'package:flutter/material.dart';
import 'package:lactosure_connect_app/lactosure/screens/corrections/offset_correction.dart';

class Corrections extends StatefulWidget {
  const Corrections({super.key});

  @override
  State<Corrections> createState() => _CorrectionsState();
}

class _CorrectionsState extends State<Corrections> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Corrections")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OffsetCorrection(),
                    ),
                  );
                },
                child: const Text("Correction"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
