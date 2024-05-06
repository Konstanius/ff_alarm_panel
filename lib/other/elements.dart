import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:panel/other/styles.dart';

abstract class UIElements {
  static Widget rowLeading(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  static Widget rowEditor(TextEditingController controller, String text, {RegExp? validation, bool disabled = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextBox(
        controller: controller,
        placeholder: text,
        readOnly: disabled,
        inputFormatters: [
          if (validation != null) FilteringTextInputFormatter.allow(validation),
        ],
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }

  static Widget divider(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Container(margin: const EdgeInsets.only(right: 8.0), height: 2, color: Colors.blue)),
          Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
          Expanded(child: Container(margin: const EdgeInsets.only(left: 8.0), height: 2, color: Colors.blue)),
        ],
      ),
    );
  }

  static Widget listButton({required Widget child, required Function onPressed, required bool selected}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: FilledButton(
        style: selected ? UIStyles.buttonListSelected : UIStyles.buttonList,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: child,
        ),
        onPressed: () => onPressed(),
      ),
    );
  }
}
