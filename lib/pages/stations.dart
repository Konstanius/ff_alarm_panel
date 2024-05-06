import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:panel/dialogs.dart';
import 'package:panel/globals.dart';
import 'package:panel/main_page.dart';
import 'package:panel/map.dart';
import 'package:panel/models/unit.dart';
import 'package:flutter/material.dart' as mat show Icons, Icon, IconButton;
import 'package:panel/other/styles.dart';

import '../interfaces.dart';
import '../models/person.dart';
import '../models/station.dart';
import '../other/elements.dart';

class StationsPage extends StatefulWidget {
  const StationsPage({super.key});

  @override
  State<StationsPage> createState() => _StationsPageState();
}

class _StationsPageState extends State<StationsPage> {
  List<Station>? stations;
  Station? selectedStation;
  bool loading = true;

  final TextEditingController searchController = TextEditingController();

  ({List<Unit> units, List<Person> persons})? selectedStationData;

  final ValueNotifier<List<MapPos>> positions = ValueNotifier([]);
  MapController mapController = MapController();

  final TextEditingController idController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController prefixController = TextEditingController();
  final TextEditingController stationNumberController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController coordinatesLatController = TextEditingController();
  final TextEditingController coordinatesLonController = TextEditingController();

  void selectStation(Station station) {
    if (selectedStation?.id == station.id) return;
    setControllers(station);
    setState(() {
      selectedStation = station;
      fetchStation();
    });
  }

  void setControllers(Station station) {
    idController.text = station.id.toString();
    nameController.text = station.name;
    areaController.text = station.area;
    prefixController.text = station.prefix;
    stationNumberController.text = station.stationNumber.toString();
    addressController.text = station.address;
    coordinatesLatController.text = station.position?.latitude.toString() ?? '';
    coordinatesLonController.text = station.position?.longitude.toString() ?? '';
  }

  Future<void> fetchStations() async {
    try {
      setState(() => loading = true);
      stations = await Interfaces.stationList();

      List<MapPos> positions = [];
      for (var station in stations!) {
        var pos = station.position;
        if (pos != null) {
          positions.add(
            MapPos(
              id: station.id.toString(),
              position: pos,
              name: "${station.name}\n${station.descriptiveNameShort}",
              widget: mat.IconButton(
                icon: const mat.Icon(mat.Icons.business_outlined),
                color: Colors.blue,
                onPressed: () => selectStation(station),
              ),
            ),
          );
        }
      }
      this.positions.value = positions;
    } catch (e) {
      Dialogs.errorDialog(message: e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  void fetchStation() async {
    selectedStationData = null;
    setState(() {});
    if (selectedStation == null) return;

    int id = selectedStation!.id;
    try {
      var result = await Interfaces.stationGetDetails(id);
      if (id != selectedStation!.id) return;
      selectedStationData = result;
    } catch (e) {
      Dialogs.errorDialog(message: e.toString());
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchStations().then((_) {
      try {
        int? id = MainPageState.selectionQueue.value;
        if (id != null) {
          MainPageState.selectionQueue.value = null;
          var station = stations!.firstWhere((element) => element.id == id);
          selectStation(station);
        }
      } catch (e) {
        Dialogs.errorDialog(message: "Die ausgewählte Wache konnte nicht gefunden werden.");
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    positions.dispose();
    mapController.dispose();

    idController.dispose();
    nameController.dispose();
    areaController.dispose();
    prefixController.dispose();
    stationNumberController.dispose();
    addressController.dispose();
    coordinatesLatController.dispose();
    coordinatesLonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: ProgressRing());

    if (stations == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Einheiten konnten nicht geladen werden'),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: fetchStations,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    List<Station> filtered = [];
    if (searchController.text.isNotEmpty) {
      String search = searchController.text.toLowerCase().trim();
      for (var station in stations!) {
        if (station.descriptiveName.toLowerCase().contains(search) || station.address.toLowerCase().contains(search) || station.area.toLowerCase().contains(search)) {
          filtered.add(station);
        }
      }
    } else {
      filtered = stations!;
    }

    filtered.sort((a, b) => a.descriptiveNameShort.compareTo(b.descriptiveNameShort));

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
                    for (var station in filtered)
                      UIElements.listButton(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  station.descriptiveName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  station.address,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onPressed: () => selectStation(station),
                        selected: selectedStation?.id == station.id,
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
                  if (selectedStation == null) {
                    double lat = 0;
                    double lon = 0;
                    int count = 0;
                    for (var station in stations!) {
                      if (station.position != null) {
                        lat += station.position!.latitude;
                        lon += station.position!.longitude;
                        count++;
                      }
                    }

                    if (count > 0) {
                      lat /= count;
                      lon /= count;
                    }

                    return SafeArea(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: MapPage(
                              controller: mapController,
                              initialPosition: LatLng(lat, lon),
                              positionsNotifier: positions,
                              initialZoom: 10.5,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: FilledButton(
                              onPressed: () {
                                Station newStation = Station(
                                  id: 0,
                                  name: '',
                                  area: '',
                                  prefix: '',
                                  stationNumber: 0,
                                  address: '',
                                  adminPersons: [],
                                  coordinates: '0.00000,0.00000',
                                  persons: [],
                                  updated: DateTime.now(),
                                );
                                selectedStation = newStation;
                                selectedStationData = (persons: [], units: []);
                                setControllers(newStation);
                                setState(() {});
                              },
                              child: const Text(
                                'Neue Wache erstellen',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (selectedStationData == null) return const Center(child: ProgressRing());
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
                                    selectedStation!.id == 0 ? "Neue Wache" : selectedStation!.descriptiveName,
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
                                selectedStation = null;
                                selectedStationData = null;
                              });
                            },
                          ),
                          if (selectedStation!.id != 0) const SizedBox(width: 10),
                          if (selectedStation!.id != 0)
                            FilledButton(
                              onPressed: () async {
                                if (selectedStationData!.units.isNotEmpty) {
                                  Dialogs.errorDialog(message: "Wache kann nicht gelöscht werden, da dieser noch Einheiten zugeordnet sind.");
                                  return;
                                }

                                bool confirm = await Dialogs.confirmDialog(title: 'Wache löschen', message: 'Sind Sie sicher, dass Sie die Wache löschen möchten?');
                                if (!confirm) return;

                                Dialogs.loadingDialog(title: 'Löschen...', message: 'Lösche Wache...');
                                try {
                                  await Interfaces.stationDelete(selectedStation!.id);
                                  stations!.remove(selectedStation!);
                                  selectedStation = null;
                                  selectedStationData = null;
                                  if (mounted) setState(() {});
                                  fetchStations();
                                } catch (e) {
                                  Dialogs.errorDialog(message: e.toString());
                                }
                              },
                              style: UIStyles.buttonRed,
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text('Wache löschen'),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(0.2),
                          1: FlexColumnWidth(0.8),
                        },
                        children: [
                          TableRow(
                            children: [
                              UIElements.rowLeading('ID:'),
                              UIElements.rowEditor(idController, "ID", disabled: true),
                            ],
                          ),
                          TableRow(
                            children: [
                              UIElements.rowLeading('Name:'),
                              UIElements.rowEditor(
                                nameController,
                                "Name",
                                validation: RegExp(r'^.{1,200}$'),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              UIElements.rowLeading('Bereich:'),
                              UIElements.rowEditor(
                                areaController,
                                "Bereich",
                                validation: RegExp(r'^.{1,200}$'),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              UIElements.rowLeading('Funktions-Präfix:'),
                              UIElements.rowEditor(
                                prefixController,
                                "Funktions-Präfix",
                                validation: RegExp(r'^[a-zA-ZäöüÄÖÜ]{1,200}$'),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              UIElements.rowLeading('Wachen-Nummer:'),
                              UIElements.rowEditor(
                                stationNumberController,
                                "Wachen-Nummer",
                                validation: RegExp(r'^[0-9]{1,10}$'),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              UIElements.rowLeading('Adresse:'),
                              UIElements.rowEditor(
                                addressController,
                                "Adresse",
                                validation: RegExp(r'^.{1,200}$'),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              UIElements.rowLeading('Koordinaten:'),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 250),
                                        child: UIElements.rowEditor(
                                          coordinatesLatController,
                                          disabled: true,
                                          "Latitude",
                                        ),
                                      ),
                                      UIElements.rowLeading('° N'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 250),
                                        child: UIElements.rowEditor(
                                          coordinatesLonController,
                                          disabled: true,
                                          "Longitude",
                                        ),
                                      ),
                                      UIElements.rowLeading('° E'),
                                    ],
                                  ),
                                  FilledButton(
                                    child: const Text('Von Adresse suchen'),
                                    onPressed: () async {
                                      Dialogs.loadingDialog(title: 'Suche...', message: 'Suche Koordinaten für Adresse...');
                                      try {
                                        var result = await Interfaces.getCoordinates(addressController.text);
                                        coordinatesLatController.text = result.lat.toStringAsFixed(5);
                                        coordinatesLonController.text = result.long.toStringAsFixed(5);
                                        Navigator.of(Globals.context).pop();
                                      } catch (e) {
                                        Navigator.of(Globals.context).pop();
                                        Dialogs.errorDialog(message: e.toString());
                                      }
                                    },
                                  ),
                                  FilledButton(
                                    child: const Text('Auf Karte wählen'),
                                    onPressed: () async {
                                      var result = await MapLocationPicker.pickLocation(
                                        context: context,
                                        startLatitude: double.tryParse(coordinatesLatController.text),
                                        startLongitude: double.tryParse(coordinatesLonController.text),
                                      );
                                      if (result == null) return;

                                      coordinatesLatController.text = result.latitude.toStringAsFixed(5);
                                      coordinatesLonController.text = result.longitude.toStringAsFixed(5);

                                      Dialogs.loadingDialog(title: 'Suche...', message: 'Suche Adresse für Koordinaten...');
                                      try {
                                        var address = await Interfaces.getAddress(result.latitude, result.longitude);
                                        addressController.text = address;
                                        Navigator.of(Globals.context).pop();
                                      } catch (e) {
                                        Navigator.of(Globals.context).pop();
                                        Dialogs.errorDialog(message: e.toString());
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      () {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton(
                              onPressed: () async {
                                if (selectedStation!.id != 0) {
                                  bool changes = false;
                                  if (nameController.text != selectedStation!.name) changes = true;
                                  if (areaController.text != selectedStation!.area) changes = true;
                                  if (prefixController.text != selectedStation!.prefix) changes = true;
                                  if (stationNumberController.text != selectedStation!.stationNumber.toString()) changes = true;
                                  if (addressController.text != selectedStation!.address) changes = true;
                                  if (coordinatesLatController.text != selectedStation!.position?.latitude.toString()) changes = true;
                                  if (coordinatesLonController.text != selectedStation!.position?.longitude.toString()) changes = true;
                                  if (!changes) return;
                                  bool confirm = await Dialogs.confirmDialog(title: 'Änderungen speichern', message: 'Sind Sie sicher, dass Sie die Änderungen an der Wache speichern möchten?');
                                  if (!confirm) return;
                                } else {
                                  bool confirm = await Dialogs.confirmDialog(title: 'Wache erstellen', message: 'Sind Sie sicher, dass Sie die Wache erstellen möchten?');
                                  if (!confirm) return;
                                }

                                Dialogs.loadingDialog(
                                  title: 'Speichern...',
                                  message: selectedStation!.id == 0 ? 'Die Wache wird erstellt...' : 'Die Änderungen an der Wache werden gespeichert...',
                                );

                                try {
                                  String name = nameController.text;
                                  String area = areaController.text;
                                  String prefix = prefixController.text;
                                  int stationNumber;
                                  try {
                                    stationNumber = int.parse(stationNumberController.text);
                                  } catch (e) {
                                    throw "Wachen-Nummer muss eine Zahl sein";
                                  }
                                  String address = addressController.text;
                                  String coordinates = "${coordinatesLatController.text},${coordinatesLonController.text}";
                                  if (selectedStation!.id != 0) {
                                    await Interfaces.stationUpdate(
                                      id: selectedStation!.id,
                                      name: name,
                                      area: area,
                                      prefix: prefix,
                                      stationNumber: stationNumber,
                                      address: address,
                                      coordinates: coordinates,
                                    );
                                  } else {
                                    Station newStation = await Interfaces.stationCreate(
                                      name: name,
                                      area: area,
                                      prefix: prefix,
                                      stationNumber: stationNumber,
                                      address: address,
                                      coordinates: coordinates,
                                    );
                                    stations!.add(newStation);
                                    selectedStation = newStation;
                                  }
                                  if (mounted) setState(() {});
                                  fetchStations().then((_) {
                                    try {
                                      selectedStation = stations!.firstWhere((element) => element.id == selectedStation!.id);
                                      if (mounted) setState(() {});
                                    } catch (_) {}
                                  });
                                  Navigator.of(Globals.context).pop();
                                } catch (e) {
                                  Navigator.of(Globals.context).pop();
                                  Dialogs.errorDialog(message: e.toString());
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(selectedStation!.id == 0 ? 'Wache erstellen' : 'Änderungen speichern'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: () {
                                if (selectedStation!.id == 0) {
                                  selectedStation = null;
                                  selectedStationData = null;
                                  setState(() {});
                                  return;
                                }
                                setControllers(selectedStation!);
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text('Änderungen verwerfen'),
                              ),
                            ),
                          ],
                        );
                      }(),
                      UIElements.divider('Zugeordnete Einheiten'),
                      for (var unit in selectedStationData!.units)
                        UIElements.listButton(
                          child: Row(
                            children: [
                              Column(
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
                              const Spacer(),
                              // TODO more details
                            ],
                          ),
                          onPressed: () {
                            MainPageState.selectionQueue.value = unit.id;
                            MainPageState.page.value = NavigationPage.units;
                          },
                          selected: false,
                        ),
                      UIElements.divider('Zugeordnete Personen'),
                      for (var person in selectedStationData!.persons)
                        UIElements.listButton(
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        person.fullName,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Geb.: ${DateFormat('dd.MM.yyyy').format(person.birthday)}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              // TODO more details
                            ],
                          ),
                          onPressed: () {
                            MainPageState.selectionQueue.value = person.id;
                            MainPageState.page.value = NavigationPage.persons;
                          },
                          selected: false,
                        ),
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
