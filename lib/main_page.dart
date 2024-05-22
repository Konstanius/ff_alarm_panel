import 'dart:async';
import 'dart:html';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:panel/globals.dart';
import 'package:panel/interfaces.dart';
import 'package:panel/pages/administrators.dart';
import 'package:panel/pages/alarms.dart';
import 'package:panel/pages/alarms_creator.dart';
import 'package:panel/pages/audit_logs.dart';
import 'package:panel/pages/dashboard.dart';
import 'package:flutter/material.dart' as mat show Icons, Icon;
import 'package:panel/pages/diagnostics.dart';
import 'package:panel/pages/logs.dart';
import 'package:panel/pages/persons.dart';
import 'package:panel/pages/readiness.dart';
import 'package:panel/pages/stations.dart';
import 'package:panel/pages/units.dart';

import 'other/styles.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => MainPageState();
}

enum NavigationPage {
  dashboard,
  alarmsCreator,
  stations,
  units,
  persons,
  alarms,
  readiness,
  logs,
  auditLogs,
  administrators,
  diagnostics,
}

class MainPageState extends State<MainPage> {
  static final ValueNotifier<NavigationPage> page = ValueNotifier(NavigationPage.dashboard);
  static final ValueNotifier<int?> selectionQueue = ValueNotifier(null);

  int lastMouseMoved = DateTime.now().millisecondsSinceEpoch;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    Uri uri = Uri.base;
    if (uri.queryParameters.isEmpty) return;
    uri = uri.replace(queryParameters: {});
    window.history.pushState({}, '', uri.toString());

    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      Interfaces.ping().catchError((e, s) {
        print('Ping error: $e\n$s');
      });
      if (DateTime.now().millisecondsSinceEpoch - lastMouseMoved < 31000) {
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
        onHover: (_) => lastMouseMoved = DateTime.now().millisecondsSinceEpoch,
        child: ValueListenableBuilder(
          valueListenable: page,
          builder: (context, NavigationPage page, child) {
            return NavigationView(
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
                actions: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilledButton(
                    onPressed: Globals.logout,
                    style: UIStyles.buttonRed,
                    child: const Text('Abmelden'),
                  ),
                ),
              ),
              pane: NavigationPane(
                selected: page.index,
                onChanged: (index) => MainPageState.page.value = NavigationPage.values[index],
                displayMode: PaneDisplayMode.open,
                items: items,
              ),
            );
          }
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
    PaneItem(
      icon: const Icon(FluentIcons.new_analytics_query),
      title: const Text('Neue Einsatz-Alarmierung'),
      body: const AlarmsCreatorPage(),
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
      icon: const Icon(FluentIcons.clock),
      title: const Text('Geo-Bereitschaft'),
      body: const ReadinessPage(),
    ),
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
