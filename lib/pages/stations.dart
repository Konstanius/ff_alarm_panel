import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:panel/dialogs.dart';
import 'package:panel/globals.dart';
import 'package:panel/map.dart';
import 'package:panel/models/unit.dart';
import 'package:flutter/material.dart' as mat show Icons, Icon, IconButton;

import '../interfaces.dart';
import '../models/person.dart';
import '../models/station.dart';

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
    idController.text = station.id.toString();
    nameController.text = station.name;
    areaController.text = station.area;
    prefixController.text = station.prefix;
    stationNumberController.text = station.stationNumber.toString();
    addressController.text = station.address;
    coordinatesLatController.text = station.position?.latitude.toString() ?? '';
    coordinatesLonController.text = station.position?.longitude.toString() ?? '';
    setState(() {
      selectedStation = station;
      fetchStation();
    });
  }

  void fetchStations() async {
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
      Dialogs.errorDialog(title: 'Fehler', message: e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  void fetchStation() async {
    selectedStationData = null;
    setState(() {});
    if (selectedStation == null) {
      return;
    }

    int id = selectedStation!.id;
    try {
      var result = await Interfaces.stationGetDetails(id);
      if (id != selectedStation!.id) return;
      selectedStationData = result;
    } catch (e) {
      Dialogs.errorDialog(title: 'Fehler', message: e.toString());
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchStations();
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
                      Acrylic(
                        child: ListTile(
                          title: Text(station.name),
                          subtitle: Text(station.descriptiveNameShort),
                          onPressed: () => selectStation(station),
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
                      child: MapPage(
                        controller: mapController,
                        initialPosition: LatLng(lat, lon),
                        positionsNotifier: positions,
                        initialZoom: 10.5,
                      ),
                    );
                  }
                  if (selectedStationData == null) return const Center(child: ProgressRing());
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(child: Text(selectedStation!.descriptiveName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
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
                              rowLeading('ID:'),
                              rowEditor(idController, "ID", disabled: true),
                            ],
                          ),
                          TableRow(
                            children: [
                              rowLeading('Name:'),
                              rowEditor(nameController, "Name"),
                            ],
                          ),
                          TableRow(
                            children: [
                              rowLeading('Bereich:'),
                              rowEditor(areaController, "Bereich"),
                            ],
                          ),
                          TableRow(
                            children: [
                              rowLeading('Funktions-Präfix:'),
                              rowEditor(
                                prefixController,
                                "Funktions-Präfix",
                                validation: RegExp(r'^[a-zA-Z]+$'),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              rowLeading('Wachen-Nummer:'),
                              rowEditor(
                                stationNumberController,
                                "Wachen-Nummer",
                                validation: RegExp(r'^\d+$'),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              rowLeading('Adresse:'),
                              rowEditor(addressController, "Adresse"),
                            ],
                          ),
                          TableRow(
                            children: [
                              rowLeading('Koordinaten:'),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 250),
                                        child: rowEditor(
                                          coordinatesLatController,
                                          disabled: true,
                                          "Latitude",
                                        ),
                                      ),
                                      rowLeading('° N'),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 250),
                                        child: rowEditor(
                                          coordinatesLonController,
                                          disabled: true,
                                          "Longitude",
                                        ),
                                      ),
                                      rowLeading('° E'),
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
                                        Dialogs.errorDialog(title: 'Fehler', message: e.toString());
                                      }
                                    },
                                  ),
                                  FilledButton(
                                    child: const Text('Auf Karte wählen'),
                                    onPressed: () async {
                                      var result = await MapLocationPicker.pickLocation(context: context, startLatitude: double.tryParse(coordinatesLatController.text), startLongitude: double.tryParse(coordinatesLonController.text));
                                      if (result != null) {
                                        coordinatesLatController.text = result.latitude.toStringAsFixed(5);
                                        coordinatesLonController.text = result.longitude.toStringAsFixed(5);

                                        Dialogs.loadingDialog(title: 'Suche...', message: 'Suche Adresse für Koordinaten...');
                                        try {
                                          var address = await Interfaces.getAddress(result.latitude, result.longitude);
                                          addressController.text = address;
                                          Navigator.of(Globals.context).pop();
                                        } catch (e) {
                                          Navigator.of(Globals.context).pop();
                                          Dialogs.errorDialog(title: 'Fehler', message: e.toString());
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
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

  Widget rowLeading(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget rowEditor(TextEditingController controller, String text, {RegExp? validation, bool disabled = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextBox(
        controller: controller,
        placeholder: text,
        readOnly: disabled,
        inputFormatters: [
          if (validation != null) FilteringTextInputFormatter.allow(validation),
        ],
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }
}
