import 'package:fluent_ui/fluent_ui.dart';
import 'package:quickalert/quickalert.dart';

import 'globals.dart';

abstract class Dialogs {
  static Future<void> errorDialog({
    required String message,
  }) =>
      QuickAlert.show(
        context: Globals.context,
        type: QuickAlertType.error,
        text: message,
        title: 'Fehler',
        barrierDismissible: true,
        width: 400,
      );

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

  static Future<bool> confirmDialog({
    required String title,
    required String message,
  }) async {
    dynamic result = await QuickAlert.show(
      context: Globals.context,
      type: QuickAlertType.confirm,
      text: message,
      title: title,
      barrierDismissible: true,
      width: 400,
      cancelBtnText: 'Abbrechen',
      confirmBtnText: 'Bestätigen',
      onConfirmBtnTap: () => Navigator.of(Globals.context).pop(true),
      onCancelBtnTap: () => Navigator.of(Globals.context).pop(false),
    );

    return result == true;
  }
}
