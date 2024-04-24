import 'package:fluent_ui/fluent_ui.dart';
import 'package:quickalert/quickalert.dart';

import 'globals.dart';

abstract class Dialogs {
  static void errorDialog({
    required String title,
    required String message,
  }) {
    QuickAlert.show(
      context: Globals.context,
      type: QuickAlertType.error,
      text: message,
      title: title,
      barrierDismissible: true,
      width: 400,
    );
  }

  static void loadingDialog({
    required String title,
    required String message,
  }) {
    QuickAlert.show(
      context: Globals.context,
      type: QuickAlertType.loading,
      text: message,
      title: title,
      barrierDismissible: false,
      width: 400,
      disableBackBtn: true,
      showConfirmBtn: false,
      showCancelBtn: false,
    );
  }
}
