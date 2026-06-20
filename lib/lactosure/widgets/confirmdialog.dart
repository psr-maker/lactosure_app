import 'package:flutter/material.dart';
Future<bool?> showConfirmDialog(
  BuildContext context,
  String action,
  String entitytype,
) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Center(
          child: Text(
            "$action Confirmation",
            style: TextStyle(
              fontSize: 18,
              color: const Color.fromARGB(255, 25, 77, 38),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Text("Are you sure you want to $action this $entitytype?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              action,
              style: TextStyle(
                color: action == "Approve"
                    ? const Color.fromARGB(255, 25, 77, 38)
                    : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      );
    },
  );
}
