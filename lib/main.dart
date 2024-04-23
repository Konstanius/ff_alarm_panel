import 'package:fluent_ui/fluent_ui.dart';
import 'package:panel/dashboard.dart';
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
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();

    if (Globals.loggedIn.value) Interfaces.ping().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Globals.loggedIn,
      builder: (context, loggedIn, child) {
        if (loggedIn) return const DashboardPage();
        return const LoginPage();
      },
    );
  }
}
