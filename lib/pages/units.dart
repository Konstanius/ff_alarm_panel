import 'package:fluent_ui/fluent_ui.dart';
import 'package:panel/dialogs.dart';
import 'package:panel/globals.dart';
import 'package:panel/models/person.dart';
import 'package:panel/other/styles.dart';

import '../interfaces.dart';
import '../main_page.dart';
import '../models/station.dart';
import '../models/unit.dart';
import '../other/elements.dart';

class UnitsPage extends StatefulWidget {
  const UnitsPage({super.key});

  @override
  State<UnitsPage> createState() => _UnitsPageState();
}

class _UnitsPageState extends State<UnitsPage> {
  List<Unit>? units;
  Unit? selectedUnit;
  bool loading = true;

  TextEditingController searchController = TextEditingController();

  ({List<Person> persons, Station station})? selectedUnitData;

  Future<void> fetchUnits() async {
    try {
      setState(() => loading = true);
      units = await Interfaces.unitList();
    } catch (e) {
      Dialogs.error(message: e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  void fetchUnit() async {
    selectedUnitData = null;
    setState(() {});
    if (selectedUnit == null) {
      return;
    }

    int id = selectedUnit!.id;
    try {
      var result = await Interfaces.unitGetDetails(id);
      if (id != selectedUnit!.id) return;
      selectedUnitData = result;
    } catch (e) {
      Dialogs.error(message: e.toString());
    }
    setState(() {});
  }

  void selectUnit(Unit unit) {
    if (selectedUnit?.id == unit.id) return;
    setState(() {
      selectedUnit = unit;
      fetchUnit();
    });
  }

  @override
  void initState() {
    super.initState();

    fetchUnits().then((_) {
      try {
        int? id = MainPageState.selectionQueue.value;
        if (id != null) {
          MainPageState.selectionQueue.value = null;
          var unit = units!.firstWhere((element) => element.id == id);
          selectUnit(unit);
        }
      } catch (e) {
        Dialogs.error(message: "Die ausgewählte Einheit konnte nicht gefunden werden.");
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

    if (units == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Einheiten konnten nicht geladen werden'),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: fetchUnits,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    List<Unit> filtered = [];
    if (searchController.text.isNotEmpty) {
      String search = searchController.text.toLowerCase().trim();
      for (var unit in units!) {
        if (unit.callSign.toLowerCase().contains(search) || unit.unitDescription.toLowerCase().contains(search) || unit.tetraId.toLowerCase().contains(search)) {
          filtered.add(unit);
        }
      }
    } else {
      filtered = units!;
    }

    filtered.sort((a, b) => a.callSign.compareTo(b.callSign));

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
                    for (var unit in filtered)
                      UIElements.listButton(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  unit.callSign,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  unit.unitDescription,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onPressed: () => selectUnit(unit),
                        selected: selectedUnit?.id == unit.id,
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
                  if (selectedUnit == null) {
                    Map<int, Map<int, int>> statusMap = {};
                    Set<int> statusSet = {};
                    Map<int, String?> statusNames = {};
                    for (var unit in units!) {
                      statusSet.add(unit.status);
                      var info = unit.unitInformation;
                      if (info == null) {
                        if (!statusMap.containsKey(-1)) statusMap[-1] = {};
                        if (!statusMap[-1]!.containsKey(unit.status)) statusMap[-1]![unit.status] = 0;
                        statusMap[-1]![unit.status] = statusMap[-1]![unit.status]! + 1;
                        continue;
                      }

                      if (!statusMap.containsKey(info.unitType)) statusMap[info.unitType] = {};
                      if (!statusMap[info.unitType]!.containsKey(unit.status)) statusMap[info.unitType]![unit.status] = 0;
                      statusMap[info.unitType]![unit.status] = statusMap[info.unitType]![unit.status]! + 1;

                      if (!statusNames.containsKey(info.unitType)) {
                        statusNames[info.unitType] = unit.unitDescription;
                      } else if (statusNames[info.unitType] != null && statusNames[info.unitType] != unit.unitDescription) {
                        statusNames[info.unitType] = null;
                      }
                    }

                    List<({int unitType, Map<int, int> statusMap})> sorted = [];
                    statusMap.forEach((key, value) {
                      sorted.add((unitType: key, statusMap: value));
                    });
                    sorted.sort((a, b) => a.unitType.compareTo(b.unitType));

                    List<int> sortedStatus = statusSet.toList();
                    sortedStatus.sort();

                    return SafeArea(
                      child: ClipRRect(
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          children: [
                            SingleChildScrollView(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ColoredBox(
                                      color: Colors.white.withOpacity(0.3),
                                      child: Column(
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'Typ',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                          const Divider(),
                                          for (var entry in sorted) ...[
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                entry.unitType == -1 ? 'Unbekannt' : ("${entry.unitType}  -  ${statusNames[entry.unitType] ?? 'Verschiedene'}"),
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  for (var status in sortedStatus)
                                    Expanded(
                                      child: ColoredBox(
                                        color: UnitStatus.fromInt(status).color.withOpacity(0.3),
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                status.toString(),
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const Divider(),
                                            for (var entry in sorted) ...[
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(
                                                  entry.statusMap[status]?.toString() ?? '0',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (selectedUnitData == null) return const Center(child: ProgressRing());
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    selectedUnit!.id == 0 ? "Neue Einheit" : "${selectedUnit!.callSign} (${selectedUnit!.unitDescription})",
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Text('Zurück zur Übersicht'),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedUnit = null;
                                selectedUnitData = null;
                              });
                            },
                          ),
                          if (selectedUnit!.id != 0) const SizedBox(width: 10),
                          if (selectedUnit!.id != 0)
                            FilledButton(
                              onPressed: () async {
                                bool confirm = await Dialogs.confirm(title: 'Einheit löschen', message: 'Sind Sie sicher, dass Sie die Einheit löschen möchten?');
                                if (!confirm) return;

                                Dialogs.loading(title: 'Löschen...', message: 'Lösche Einheit...');
                                try {
                                  await Interfaces.unitDelete(selectedUnit!.id);
                                  units!.remove(selectedUnit!);
                                  selectedUnit = null;
                                  selectedUnitData = null;
                                  if (mounted) setState(() {});
                                  fetchUnits();
                                  Navigator.of(Globals.context).pop();
                                } catch (e) {
                                  Navigator.of(Globals.context).pop();
                                  Dialogs.error(message: e.toString());
                                }
                              },
                              style: UIStyles.buttonRed,
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text('Einheit löschen'),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
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
