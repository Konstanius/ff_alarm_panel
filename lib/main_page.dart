import 'dart:html';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:panel/globals.dart';
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

import 'main.dart';
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
    return SafeArea(
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        onPressed: Globals.logout,
                        style: UIStyles.buttonRed,
                        child: const Text('Abmelden'),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder(
                        valueListenable: LandingPageState.lastInteractionAgoSeconds,
                        builder: (context, int lastInteraction, child) {
                          double progress = 100 - lastInteraction / 300 * 100;

                          List<Color> colors = [
                            Colors.green,
                            Colors.yellow,
                            Colors.orange,
                            Colors.red,
                          ];

                          // smooth transition between colors
                          Color first;
                          Color second;
                          int invertProgress = 100 - progress.toInt();
                          switch (invertProgress ~/ 25) {
                            case 0:
                              first = colors[0];
                              second = colors[0];
                              break;
                            case 1:
                              first = colors[0];
                              second = colors[1];
                              break;
                            case 2:
                              first = colors[1];
                              second = colors[2];
                              break;
                            default:
                              first = colors[2];
                              second = colors[3];
                              break;
                          }

                          int firstProgress = invertProgress % 25 * 4;
                          Color color = Color.lerp(first, second, firstProgress / 100)!;

                          return Tooltip(
                            displayHorizontally: false,
                            enableFeedback: false,
                            richMessage: WidgetSpan(
                              child: ValueListenableBuilder(
                                valueListenable: LandingPageState.lastInteractionAgoSeconds,
                                builder: (context, int ago, child) {
                                  int remaining = 300 - ago;
                                  int minutes = remaining ~/ 60;
                                  int seconds = remaining % 60;
                                  if (minutes > 0) {
                                    return Text('Automatische Abmeldung in ${minutes}m ${seconds}s');
                                  }
                                  return Text('Automatische Abmeldung in ${seconds}s');
                                },
                              ),
                            ),
                            triggerMode: TooltipTriggerMode.manual,
                            useMousePosition: false,
                            style: const TooltipThemeData(
                              preferBelow: true,
                              waitDuration: Duration.zero,
                            ),
                            child: ProgressRing(
                              value: progress,
                              strokeWidth: 4,
                              activeColor: color,
                            ),
                          );
                        },
                      ),
                    ],
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
          }),
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
