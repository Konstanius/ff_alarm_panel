import 'dart:convert';
import 'dart:html';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:panel/dialogs.dart';

import 'interfaces.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController userController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  List<TextEditingController> otpControllers = List.generate(6, (index) => TextEditingController());
  List<FocusNode> otpFocusNodes = List.generate(6, (index) => FocusNode());

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < otpControllers.length; i++) {
      otpControllers[i].addListener(() {
        // TODO bit janky if clicked on individual text fields and typed a number
        String value = otpControllers[i].text;
        if (value.isNotEmpty) {
          if (value.length > 1) {
            if (i < 5) {
              otpControllers[i + 1].text = value.substring(1);
            }
            otpControllers[i].text = value.substring(0, 1);

            otpFocusNodes[i + value.length - 1].requestFocus();
            return;
          }

          if (i < 5) {
            otpFocusNodes[i + 1].focusInDirection(TraversalDirection.right);
          }
        }
      });
    }

    Uri uri = Uri.base;
    if (uri.queryParameters.isEmpty) return;

    String user = uri.queryParameters['user'] ?? '';
    if (user.isNotEmpty) {
      try {
        userController.text = utf8.decode(base64Decode(user));
      } catch (e) {
        print(e);
      }
    }

    uri = uri.replace(queryParameters: {});

    window.history.pushState({}, '', uri.toString());
  }

  @override
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    otpControllers.forEach((element) {
      element.dispose();
    });
    otpFocusNodes.forEach((element) {
      element.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/login_background.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: Card(
            backgroundColor: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20.0),
            padding: const EdgeInsets.all(20.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FF Alarm - Konsole',
                    style: TextStyle(
                      fontSize: 23.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20.0),
                  Text(
                    'Sie müssen sich anmelden, um auf diese Ressource zugreifen zu können.',
                    style: TextStyle(fontSize: 18.0),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20.0),
                  TextBox(
                    controller: userController,
                    style: TextStyle(fontSize: 16.0),
                    enableSuggestions: true,
                    prefix: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(FluentIcons.user_window),
                        ],
                      ),
                    ),
                    placeholder: 'Benutzername',
                    placeholderStyle: TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 10.0),
                  TextBox(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(fontSize: 16.0),
                    enableSuggestions: true,
                    prefix: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(FluentIcons.password_field),
                        ],
                      ),
                    ),
                    placeholder: 'Passwort',
                    placeholderStyle: TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 10.0),
                  CallbackShortcuts(
                    bindings: {
                      LogicalKeySet(LogicalKeyboardKey.backspace): () {
                        int index = otpFocusNodes.indexWhere((element) => element.hasFocus);
                        if (index == -1) return;

                        if (index > 0) {
                          if (otpControllers[index].text.isEmpty) {
                            otpFocusNodes[index - 1].requestFocus();
                            otpControllers[index - 1].clear();
                          } else {
                            otpControllers[index].clear();
                          }
                        }
                      },
                      LogicalKeySet(LogicalKeyboardKey.delete): () {
                        int index = otpFocusNodes.indexWhere((element) => element.hasFocus);
                        if (index == -1) return;

                        if (index < 5) {
                          if (otpControllers[index].text.isEmpty) {
                            otpFocusNodes[index + 1].requestFocus();
                            otpControllers[index + 1].clear();
                          } else {
                            otpControllers[index].clear();
                          }
                        }
                      },
                      LogicalKeySet(LogicalKeyboardKey.arrowLeft): () {
                        int index = otpFocusNodes.indexWhere((element) => element.hasFocus);
                        if (index == -1) return;

                        if (index > 0) {
                          otpFocusNodes[index - 1].requestFocus();
                        }
                      },
                      LogicalKeySet(LogicalKeyboardKey.arrowRight): () {
                        int index = otpFocusNodes.indexWhere((element) => element.hasFocus);
                        if (index == -1) return;

                        if (index < 5) {
                          otpFocusNodes[index + 1].requestFocus();
                        }
                      },
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.authenticator_app),
                        const SizedBox(width: 10.0),
                        const Text(
                          'OTP',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        const SizedBox(width: 5.0),
                        for (int i = 0; i < 6; i++)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 40.0,
                              child: TextBox(
                                controller: otpControllers[i],
                                focusNode: otpFocusNodes[i],
                                style: TextStyle(fontSize: 16.0),
                                maxLength: 6,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                                enableSuggestions: true,
                                showCursor: false,
                                textAlign: TextAlign.center,
                                placeholderStyle: TextStyle(fontSize: 16.0),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15.0),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            String user = userController.text;
                            String pass = passwordController.text;
                            String otp = otpControllers.map((e) => e.text).join();

                            if (user.isEmpty || pass.isEmpty || otp.length != 6) {
                              Dialogs.errorDialog(
                                context: context,
                                title: 'Anmeldefehler',
                                message: 'Sie müssen zum Anmelden alle Felder ausfüllen.',
                              );
                              return;
                            }

                            try {
                              Dialogs.loadingDialog(
                                context: context,
                                title: 'Anmelden...',
                                message: 'Die Anmeldung wird durchgeführt. Bitte warten Sie einen Moment.',
                              );
                              await Interfaces.login(username: user, password: pass, otp: otp);
                              Navigator.of(context).pop();
                            } catch (e) {
                              Navigator.of(context).pop();
                              Dialogs.errorDialog(
                                context: context,
                                title: 'Anmeldefehler',
                                message: e.toString(),
                              );

                              passwordController.clear();
                              otpControllers.forEach((element) {
                                element.clear();
                              });
                              return;
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Anmelden',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
