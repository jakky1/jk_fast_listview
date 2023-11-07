import 'package:flutter/material.dart';

Future<int?> showIntInputDialog(BuildContext context, String title) async {
  String? input = await showInputDialog(context, title);
  if (input == null) return null;
  return int.tryParse(input);
}

Future<String?> showInputDialog(BuildContext context, String title) async {
  String? input;
  return await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) => input = value,
              onSubmitted: (value) {
                Navigator.pop(context, input);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, input);
                  },
                  child: const Text("OK"),
                ),
                TextButton(
                  onPressed: () {
                    input = null;
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
