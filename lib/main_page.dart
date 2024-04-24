import 'dart:async';
import 'dart:html';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:panel/interfaces.dart';
import 'package:panel/pages/administrators.dart';
import 'package:panel/pages/alarms.dart';
import 'package:panel/pages/audit_logs.dart';
import 'package:panel/pages/dashboard.dart';
import 'package:flutter/material.dart' as mat show Icons, Icon;
import 'package:panel/pages/diagnostics.dart';
import 'package:panel/pages/logs.dart';
import 'package:panel/pages/persons.dart';
import 'package:panel/pages/stations.dart';
import 'package:panel/pages/units.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int pageIndex = 0;

  bool mouseInside = true;
  int lastMouseMoved = DateTime.now().millisecondsSinceEpoch;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    Uri uri = Uri.base;
    if (uri.queryParameters.isEmpty) return;
    uri = uri.replace(queryParameters: {});
    window.history.pushState({}, '', uri.toString());

    timer = Timer.periodic(Duration(seconds: 30), (_) {
      if (DateTime.now().millisecondsSinceEpoch - lastMouseMoved < 30000) {
        Interfaces.ping().catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: MouseRegion(
        onExit: (_) => mouseInside = false,
        onEnter: (_) => mouseInside = true,
        onHover: (_) {
          if (!mouseInside) return;
          lastMouseMoved = DateTime.now().millisecondsSinceEpoch;
        },
        child: NavigationView(
          appBar: NavigationAppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('assets/icon.png', fit: BoxFit.contain),
                ),
                Text(
                  'FF Alarm - Administrationskonsole',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          pane: NavigationPane(
            selected: pageIndex,
            onChanged: (index) => setState(() => pageIndex = index),
            displayMode: PaneDisplayMode.open,
            items: items,
          ),
        ),
      ),
    );
  }

  static final List<NavigationPaneItem> items = [
    PaneItemSeparator(thickness: 0),
    PaneItem(
      icon: const Icon(FluentIcons.home),
      title: const Text('Startseite'),
      body: const DashboardPage(),
    ),
    PaneItemSeparator(),
    PaneItem(
      icon: const mat.Icon(mat.Icons.business_outlined),
      title: const Text('Wachen'),
      body: const StationsPage(),
    ),
    PaneItem(
      icon: const mat.Icon(mat.Icons.fire_truck_outlined),
      title: const Text('Einheiten'),
      body: const UnitsPage(),
    ),
    PaneItem(
      icon: const mat.Icon(mat.Icons.people_outlined),
      title: const Text('Personen'),
      body: const PersonsPage(),
    ),
    PaneItem(
      icon: const mat.Icon(mat.Icons.local_fire_department_outlined),
      title: const Text('Alarmierungen'),
      body: const AlarmsPage(),
    ),
    PaneItemSeparator(),
    PaneItem(
      icon: const Icon(FluentIcons.text_document),
      title: const Text('Logs'),
      body: const LogsPage(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.backlog_list),
      title: const Text('Audit Logs'),
      body: const AuditLogsPage(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.admin),
      title: const Text('Administratoren'),
      body: const AdministratorsPage(),
    ),
    PaneItem(
      icon: const Icon(FluentIcons.diagnostic),
      title: const Text('Diagnostik'),
      body: const DiagnosticsPage(),
    ),
  ];
}
