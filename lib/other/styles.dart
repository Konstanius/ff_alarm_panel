import 'package:fluent_ui/fluent_ui.dart';

abstract class UIStyles {
  static ButtonStyle get buttonRed => ButtonStyle(
        backgroundColor: ButtonState.resolveWith((states) {
          if (states.contains(ButtonStates.hovering)) return Colors.red.dark;
          return Colors.red;
        }),
      );

  static ButtonStyle get buttonGreen => ButtonStyle(
        backgroundColor: ButtonState.resolveWith((states) {
          if (states.contains(ButtonStates.hovering)) return Colors.green.dark;
          return Colors.green;
        }),
      );

  static ButtonStyle get buttonBlue => ButtonStyle(
        backgroundColor: ButtonState.resolveWith((states) {
          if (states.contains(ButtonStates.hovering)) return Colors.blue.dark;
          return Colors.blue;
        }),
      );

  static ButtonStyle get buttonList => ButtonStyle(
        backgroundColor: ButtonState.resolveWith((states) {
          if (states.contains(ButtonStates.hovering)) return const Color.fromARGB(255, 84, 84, 84);
          return Colors.grey;
        }),
      );

  static ButtonStyle get buttonListSelected => ButtonStyle(
        backgroundColor: ButtonState.resolveWith((states) {
          if (states.contains(ButtonStates.hovering)) return mixColor(Colors.blue, const Color.fromARGB(255, 84, 84, 84));
          return mixColor(Colors.blue, Colors.grey);
        }),
      );

  static ButtonStyle get buttonTransparent => ButtonStyle(
        backgroundColor: ButtonState.resolveWith((states) {
          return Colors.transparent;
        }),
      );

  static Color mixColor(Color a, Color b) {
    return Color.fromARGB(
      255,
      (a.red + b.red) ~/ 2,
      (a.green + b.green) ~/ 2,
      (a.blue + b.blue) ~/ 2,
    );
  }
}
