import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart' as mat show Icon;
import 'package:panel/other/styles.dart';

import '../dialogs.dart';
import '../globals.dart';
import '../interfaces.dart';
import '../models/station.dart';
import '../models/unit.dart';
import '../models/person.dart';

class AlarmsCreatorPage extends StatefulWidget {
  const AlarmsCreatorPage({super.key});

  @override
  State<AlarmsCreatorPage> createState() => _AlarmsCreatorPageState();
}

class _AlarmsCreatorPageState extends State<AlarmsCreatorPage> {
  List<Station>? stations;
  List<Unit>? units;
  List<Person>? persons;

  bool loading = true;

  TextEditingController typeController = TextEditingController();
  TextEditingController wordController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController notesController = TextEditingController();

  TextEditingController searchController = TextEditingController();
  List<Unit> selectedUnits = [];

  bool busy = false;
  bool queued = false;
  ({Map<String, int> ready, Map<String, int> unknown, Map<String, int> notReady}) readiness = (ready: {}, unknown: {}, notReady: {});

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchReadiness() async {
    if (busy && queued) return;
    while (busy) {
      queued = true;
      await Future.delayed(const Duration(milliseconds: 10));
    }
    busy = true;
    queued = false;
    List<int> startedToFetch = selectedUnits.map((e) => e.id).toList();
    try {
      var result = await Interfaces.getReadinessForUnits(startedToFetch);

      List<int> afterSelectedUnits = selectedUnits.map((e) => e.id).toList();
      if (startedToFetch.toString() != afterSelectedUnits.toString()) return;

      setState(() {
        readiness = result;
      });
    } catch (e) {
      Dialogs.errorDialog(message: e.toString());
    } finally {
      busy = false;
    }
  }

  Future<void> fetchAllData() async {
    try {
      if (!loading) setState(() => loading = true);
      stations = await Interfaces.stationList();
      stations!.sort((a, b) => a.descriptiveName.compareTo(b.descriptiveName));
      units = await Interfaces.unitList();
      units!.sort((a, b) => a.callSign.compareTo(b.callSign));
      persons = await Interfaces.personList();
      persons!.sort((a, b) => a.fullName.compareTo(b.fullName));
    } catch (e) {
      Dialogs.errorDialog(message: e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    typeController.dispose();
    wordController.dispose();
    numberController.dispose();
    addressController.dispose();
    notesController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: ProgressRing());

    if (stations == null || units == null || persons == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Daten konnten nicht geladen werden'),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: fetchAllData,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ClipRRect(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          borderRadius: BorderRadius.circular(20),
          child: ColoredBox(
            color: Colors.grey.withOpacity(0.1),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            TextBox(
                              controller: typeController,
                              inputFormatters: [LengthLimitingTextInputFormatter(100)],
                              maxLines: 1,
                              prefix: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 10),
                                  Icon(FluentIcons.tag),
                                  SizedBox(width: 10),
                                  Text('Einsatz-Typ'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextBox(
                              controller: wordController,
                              inputFormatters: [LengthLimitingTextInputFormatter(100)],
                              maxLines: 1,
                              prefix: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 10),
                                  Icon(FluentIcons.help),
                                  SizedBox(width: 10),
                                  Text('Stichwort'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextBox(
                              controller: numberController,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              maxLines: 1,
                              prefix: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 10),
                                  Icon(FluentIcons.number_sequence),
                                  SizedBox(width: 10),
                                  Text('Einsatznummer'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextBox(
                              controller: addressController,
                              inputFormatters: [LengthLimitingTextInputFormatter(200)],
                              maxLines: 1,
                              prefix: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 10),
                                  Icon(FluentIcons.input_address),
                                  SizedBox(width: 10),
                                  Text('Adresse'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormBox(
                              controller: notesController,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(1000),
                              ],
                              autovalidateMode: AutovalidateMode.always,
                              validator: (value) {
                                if (value == null) return null;
                                if (value.split('\n').length > 20) {
                                  return 'Maximal 20 Zeilen erlaubt';
                                }
                                return null;
                              },
                              maxLines: 20,
                              minLines: 1,
                              prefix: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 10),
                                  Icon(FluentIcons.shared_notes),
                                  SizedBox(width: 10),
                                  Text('Notizen'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('Zu alarmierende Einheiten (${selectedUnits.length})', style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 10),
                            for (var unit in selectedUnits)
                              () {
                                Station? station;
                                for (var s in stations!) {
                                  if (s.id == unit.stationId) {
                                    station = s;
                                    break;
                                  }
                                }
                                return unitCard(unit, station);
                              }(),
                            const SizedBox(height: 10),
                            TextBox(
                              controller: searchController,
                              inputFormatters: [LengthLimitingTextInputFormatter(100)],
                              maxLines: 1,
                              onChanged: (value) {
                                setState(() {});
                              },
                              prefix: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 10),
                                  Icon(FluentIcons.search),
                                  SizedBox(width: 10),
                                  Text('Suche'),
                                ],
                              ),
                              suffix: IconButton(
                                icon: const Icon(FluentIcons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            () {
                              var filtered = <Unit>[];
                              String search = searchController.text.toLowerCase().trim();
                              for (var unit in units!) {
                                if (unit.callSign.toLowerCase().contains(search) || unit.unitDescription.toLowerCase().contains(search) || unit.tetraId.toLowerCase().contains(search)) {
                                  filtered.add(unit);
                                }
                              }

                              return Column(
                                children: [
                                  for (var unit in units!)
                                    () {
                                      Station? station;
                                      for (var s in stations!) {
                                        if (s.id == unit.stationId) {
                                          station = s;
                                          break;
                                        }
                                      }

                                      if (!unit.callSign.toLowerCase().contains(search) &&
                                          !unit.unitDescription.toLowerCase().contains(search) &&
                                          !unit.tetraId.toLowerCase().contains(search) &&
                                          !(station?.descriptiveName.toLowerCase().contains(search) ?? false)) {
                                        return const SizedBox();
                                      }

                                      return unitCard(unit, station);
                                    }(),
                                ],
                              );
                            }(),
                          ],
                        ),
                      ),
                      () {
                        List<({String qualification, int ready, int unknown, int notReady})> qualifications = [];
                        Set<String> seenQualifications = {};

                        for (var key in readiness.ready.keys) {
                          if (key.isEmpty) continue;
                          if (seenQualifications.contains(key)) continue;
                          seenQualifications.add(key);
                          qualifications.add((
                            qualification: key,
                            ready: readiness.ready[key] ?? 0,
                            unknown: readiness.unknown[key] ?? 0,
                            notReady: readiness.notReady[key] ?? 0,
                          ));
                        }

                        for (var key in readiness.unknown.keys) {
                          if (key.isEmpty) continue;
                          if (seenQualifications.contains(key)) continue;
                          seenQualifications.add(key);
                          qualifications.add((
                            qualification: key,
                            ready: readiness.ready[key] ?? 0,
                            unknown: readiness.unknown[key] ?? 0,
                            notReady: readiness.notReady[key] ?? 0,
                          ));
                        }

                        for (var key in readiness.notReady.keys) {
                          if (key.isEmpty) continue;
                          if (seenQualifications.contains(key)) continue;
                          seenQualifications.add(key);
                          qualifications.add((
                            qualification: key,
                            ready: readiness.ready[key] ?? 0,
                            unknown: readiness.unknown[key] ?? 0,
                            notReady: readiness.notReady[key] ?? 0,
                          ));
                        }

                        qualifications.sort((a, b) => a.qualification.compareTo(b.qualification));

                        return Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(12),
                            children: [
                              // send alarm
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () async {
                                        bool? confirm = await Dialogs.confirmDialog(
                                          title: 'Alarm senden',
                                          message: 'Sind Sie sicher, dass Sie den Alarm senden möchten?',
                                        );
                                        if (confirm != true) return;

                                        if (selectedUnits.isEmpty) {
                                          Dialogs.errorDialog(message: 'Keine Einheiten ausgewählt');
                                          return;
                                        }

                                        if (typeController.text.isEmpty) {
                                          Dialogs.errorDialog(message: 'Einsatz-Typ fehlt');
                                          return;
                                        }

                                        if (wordController.text.isEmpty) {
                                          Dialogs.errorDialog(message: 'Stichwort fehlt');
                                          return;
                                        }

                                        if (numberController.text.isEmpty) {
                                          Dialogs.errorDialog(message: 'Einsatznummer fehlt');
                                          return;
                                        }

                                        if (addressController.text.isEmpty) {
                                          Dialogs.errorDialog(message: 'Adresse fehlt');
                                          return;
                                        }

                                        if (notesController.text.split('\n').length > 20) {
                                          Dialogs.errorDialog(message: 'Maximal 20 Zeilen Notizen erlaubt');
                                          return;
                                        }

                                        List<int> unitIds = selectedUnits.map((e) => e.id).toList();
                                        String type = typeController.text;
                                        String word = wordController.text;
                                        int? number = int.tryParse(numberController.text);
                                        if (number == null) {
                                          Dialogs.errorDialog(message: 'Einsatznummer ist keine Zahl');
                                          return;
                                        }
                                        String address = addressController.text;
                                        String notesString = notesController.text;
                                        List<String> notes = notesString.split('\n');

                                        try {
                                          Dialogs.loadingDialog(title: 'Alarm senden', message: 'Alarm wird gesendet...');
                                          await Interfaces.sendAlarm(address: address, notes: notes, number: number, type: type, units: unitIds, word: word);
                                          Navigator.of(Globals.context).pop();

                                          typeController.clear();
                                          wordController.clear();
                                          numberController.clear();
                                          addressController.clear();
                                          notesController.clear();
                                          searchController.clear();
                                          selectedUnits.clear();
                                          setState(() {});
                                        } catch (e) {
                                          Navigator.of(Globals.context).pop();
                                          Dialogs.errorDialog(message: e.toString());
                                        }
                                      },
                                      child: const Text('Alarm senden', style: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                borderRadius: BorderRadius.circular(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: ColoredBox(
                                        color: Colors.grey.withOpacity(0.1),
                                        child: Column(
                                          children: [
                                            const Text('Qualifikation', style: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.bold)),
                                            const Divider(),
                                            const Text(
                                              'Gesamt:',
                                              style: TextStyle(fontWeight: FontWeight.bold, height: 1.3, fontSize: kDefaultFontSize * 1.3),
                                            ),
                                            const Divider(),
                                            for (var qualification in qualifications)
                                              Text(
                                                qualification.qualification,
                                                style: const TextStyle(fontWeight: FontWeight.bold, height: 1.3, fontSize: kDefaultFontSize * 1.3),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ColoredBox(
                                        color: Colors.green.withOpacity(0.3),
                                        child: Column(
                                          children: [
                                            const Text('Bereit', style: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.bold)),
                                            const Divider(),
                                            Text(
                                              readiness.ready[""]?.toString() ?? '0',
                                              style: const TextStyle(height: 1.3, fontSize: kDefaultFontSize * 1.3),
                                            ),
                                            const Divider(),
                                            for (var qualification in qualifications)
                                              Text(
                                                qualification.ready.toString(),
                                                style: const TextStyle(height: 1.3, fontSize: kDefaultFontSize * 1.3),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ColoredBox(
                                        color: Colors.yellow.withOpacity(0.3),
                                        child: Column(
                                          children: [
                                            const Text('Unbekannt', style: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.bold)),
                                            const Divider(),
                                            Text(
                                              readiness.unknown[""]?.toString() ?? '0',
                                              style: const TextStyle(height: 1.3, fontSize: kDefaultFontSize * 1.3),
                                            ),
                                            const Divider(),
                                            for (var qualification in qualifications)
                                              Text(
                                                qualification.unknown.toString(),
                                                style: const TextStyle(height: 1.3, fontSize: kDefaultFontSize * 1.3),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ColoredBox(
                                        color: Colors.red.withOpacity(0.3),
                                        child: Column(
                                          children: [
                                            const Text('Nicht Bereit', style: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.bold)),
                                            const Divider(),
                                            Text(
                                              readiness.notReady[""]?.toString() ?? '0',
                                              style: const TextStyle(height: 1.3, fontSize: kDefaultFontSize * 1.3),
                                            ),
                                            const Divider(),
                                            for (var qualification in qualifications)
                                              Text(
                                                qualification.notReady.toString(),
                                                style: const TextStyle(height: 1.3, fontSize: kDefaultFontSize * 1.3),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget unitCard(Unit unit, Station? station) {
    var status = UnitStatus.fromInt(unit.status);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FilledButton(
        style: selectedUnits.contains(unit) ? UIStyles.buttonGreen : UIStyles.buttonBlue,
        onPressed: () {
          setState(() {
            if (selectedUnits.contains(unit)) {
              selectedUnits.remove(unit);
            } else {
              selectedUnits.add(unit);
            }
          });
          fetchReadiness();
        },
        child: ListTile(
          onPressed: () {
            setState(() {
              if (selectedUnits.contains(unit)) {
                selectedUnits.remove(unit);
              } else {
                selectedUnits.add(unit);
              }
            });
            fetchReadiness();
          },
          title: Text(unit.callSign),
          subtitle: Text('${unit.unitDescription} - ${station?.name}'),
          trailing: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(status.description, style: TextStyle(color: status.color)),
                    const SizedBox(width: 10),
                    mat.Icon(status.icon, color: status.color),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
