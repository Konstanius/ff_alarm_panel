import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:panel/dialogs.dart';
import 'package:panel/main_page.dart';
import 'package:panel/globals.dart';
import 'package:panel/interfaces.dart';
import 'package:panel/login.dart';

Future<void> main() async {
  await Globals.init();
  runApp(const FFAlarmApp());
}

class FFAlarmApp extends StatelessWidget {
  const FFAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'FF Alarm - Konsole',
      theme: FluentThemeData(brightness: Brightness.light, accentColor: Colors.blue),
      darkTheme: FluentThemeData(brightness: Brightness.light, accentColor: Colors.blue),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const LandingPage(),
      navigatorKey: Globals.navigatorKey,
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  static final ValueNotifier<int> lastInteractionAgoSeconds = ValueNotifier(0);
  static late Timer logoutTimer;

  @override
  void initState() {
    super.initState();

    logoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!Globals.loggedIn.value) return;

      if (lastInteractionAgoSeconds.value > 300) {
        Globals.logout();
        Dialogs.error(message: 'Sie wurden automatisch ausgeloggt, da Sie über 5 Minuten inaktiv waren.');
        lastInteractionAgoSeconds.value = 0;
      } else {
        lastInteractionAgoSeconds.value++;
      }
    });

    if (Globals.loggedIn.value) Interfaces.ping().catchError((_) {});
  }
  
  @override
  void dispose() {
    logoutTimer.cancel();
    lastInteractionAgoSeconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 1400) {
      return const ScaffoldPage(
        content: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Die FF Alarm Administrationskonsole ist nur auf Bildschirmen mit einer Breite von mindestens 1400 Pixeln verfügbar.'),
            ],
          ),
        ),
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: Globals.loggedIn,
      builder: (context, loggedIn, child) {
        if (loggedIn) return const MainPage();
        return const LoginPage();
      },
    );
  }
}
