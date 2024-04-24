import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:panel/dialogs.dart';

import '../interfaces.dart';
import '../models/alarm.dart';

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

  void fetchAlarms() async {
    try {
      setState(() => loading = true);
      alarms = await Interfaces.alarmList();
    } catch (e) {
      Dialogs.errorDialog(title: 'Fehler', message: e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAlarms();
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
                      Acrylic(
                        child: ListTile(
                          title: Text("${alarm.type} - ${alarm.word}"),
                          subtitle: Text('Geb.: ${DateFormat('dd.MM.yyyy HH:mm').format(alarm.date)}'),
                          onPressed: () {
                            setState(() => selectedAlarm = alarm);
                          },
                        ),
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
                child: selectedAlarm == null
                    ? null
                    : ListView(
                        padding: const EdgeInsets.all(12),
                        children: [],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
