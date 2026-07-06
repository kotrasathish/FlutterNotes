import 'package:flutter/material.dart';

typedef CloseDialog = void Function();

CloseDialog showLoadingDialog({
  required BuildContext context,
  required String text
  }) {
   final alert = AlertDialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 10),
        Text(text, style: const TextStyle(color: Colors.white)),
      ],
    )
   );
   showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => alert,
   );
   return () {
    Navigator.of(context, rootNavigator: true).pop();
   };
}
