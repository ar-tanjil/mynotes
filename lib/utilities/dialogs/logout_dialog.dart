import 'package:flutter/widgets.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<bool> showLogutDialog(
  BuildContext context,
) {
  return showGenericDialog(
    context: context,
    title: "Log Out",
    content: "Are you sure you want to log out?",
    optionBuilder: () => {
      'Cancle': false,
      'Log Out': true,
    },
  ).then(
    (value) => value ?? false,
  );
}
