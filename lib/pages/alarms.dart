import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:panel/dialogs.dart';

import '../interfaces.dart';
import '../main_page.dart';
import '../models/alarm.dart';
import '../models/person.dart';
import '../models/station.dart';
import '../models/unit.dart';
import '../other/elements.dart';

class AlarmsPage extends StatefulWidget {
  const AlarmsPage({super.key});

  @override
  State<AlarmsPage> createState() => _AlarmsPageState();
}

class _AlarmsPageState extends State<AlarmsPage> {
  List<Alarm>? alarms;
  Alarm? selectedAlarm;
  bool loading = true;

  TextEditingController searchController = TextEditingController();

  ({List<Unit> units, List<Station> stations, List<Person> persons})? selectedAlarmData;

  Future<void> fetchAlarms() async {
    try {
      setState(() => loading = true);
      alarms = await Interfaces.alarmList();
    } catch (e) {
      Dialogs.error(message: e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  void fetchAlarm() async {
    selectedAlarmData = null;
    setState(() {});
    if (selectedAlarm == null) {
      return;
    }

    int id = selectedAlarm!.id;
    try {
      var result = await Interfaces.alarmGetDetails(id);
      if (id != selectedAlarm!.id) return;
      selectedAlarmData = result;
    } catch (e) {
      Dialogs.error(message: e.toString());
    }
    setState(() {});
  }

  void selectAlarm(Alarm alarm) {
    if (selectedAlarm?.id == alarm.id) return;
    setState(() {
      selectedAlarm = alarm;
      fetchAlarm();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchAlarms().then((_) {
      try {
        int? id = MainPageState.selectionQueue.value;
        if (id != null) {
          MainPageState.selectionQueue.value = null;
          var alarm = alarms!.firstWhere((element) => element.id == id);
          selectAlarm(alarm);
        }
      } catch (e) {
        Dialogs.error(message: "Die ausgewählte Alarmierung konnte nicht gefunden werden.");
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: ProgressRing());

    if (alarms == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Einheiten konnten nicht geladen werden'),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: fetchAlarms,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    List<Alarm> filtered = [];
    if (searchController.text.isNotEmpty) {
      String search = searchController.text.toLowerCase().trim();
      for (var alarm in alarms!) {
        if (alarm.address.toLowerCase().contains(search) || alarm.type.toLowerCase().contains(search) || alarm.word.toLowerCase().contains(search)) {
          filtered.add(alarm);
        }
      }
    } else {
      filtered = alarms!;
    }

    filtered.sort((a, b) => b.date.compareTo(a.date));

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ClipRRect(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              borderRadius: BorderRadius.circular(20),
              child: ColoredBox(
                color: Colors.grey.withOpacity(0.1),
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    TextBox(
                      controller: searchController,
                      placeholder: 'Suche',
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    for (var alarm in filtered)
                      UIElements.listButton(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${alarm.type} - ${alarm.word}",
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  alarm.address,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  DateFormat('HH:mm - EEEE, dd.MM.yyyy', 'de_DE').format(alarm.date),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onPressed: () => selectAlarm(alarm),
                        selected: selectedAlarm?.id == alarm.id,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ClipRRect(
              clipBehavior: Clip.antiAliasWithSaveLayer,
              borderRadius: BorderRadius.circular(20),
              child: ColoredBox(
                color: Colors.grey.withOpacity(0.1),
                child: () {
                  // TODO if selectedAlarm is null, show a Map and statistic of all alarms of a selected time frame
                  if (selectedAlarm == null) return const SizedBox();
                  if (selectedAlarmData == null) return const Center(child: ProgressRing());
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [],
                  );
                }(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
