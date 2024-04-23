import 'dart:html';

import 'package:fluent_ui/fluent_ui.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();

    Uri uri = Uri.base;
    if (uri.queryParameters.isEmpty) return;
    uri = uri.replace(queryParameters: {});
    window.history.pushState({}, '', uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return const Text('Dashboard');
  }
}
