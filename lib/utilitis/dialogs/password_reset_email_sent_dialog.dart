import 'package:flutter/material.dart';
import 'package:mynotesflutter/utilitis/dialogs/generic_dialog.dart';

Future <void> showPasswordResetEmailSentDialog(BuildContext context) {
  return showGenericDialog(
    context: context,
    title: 'Password Reset',
    content: 'We have sent you an email with a link to reset your password.',
    optionsBuilder: () => {
      'OK': null,
    },
  );
}