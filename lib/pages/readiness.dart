import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:panel/map.dart';
import 'package:panel/models/person.dart';

import '../dialogs.dart';
import '../interfaces.dart';

class ReadinessPage extends StatefulWidget {
  const ReadinessPage({super.key});

  @override
  State<ReadinessPage> createState() => _ReadinessPageState();
}

class _ReadinessPageState extends State<ReadinessPage> {
  List<Person> persons = [];

  DateTime? lastUpdate;
  List<AdminReadinessEntry> readinessEntries = [];
  bool loading = true;

  bool busy = false;

  MapController mapController = MapController();
  ValueNotifier<List<MapPos>> positionsNotifier = ValueNotifier([]);

  late Timer timer;

  @override
  void initState() {
    super.initState();
    fetchReadiness();

    Interfaces.personList().then((value) {
      persons = value;
      updatePositions();
    });

    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchReadiness();
    });
  }

  Future<void> fetchReadiness() async {
    if (busy) return;
    try {
      busy = true;
      readinessEntries = await Interfaces.getReadiness();
      lastUpdate = DateTime.now();

      updatePositions();
    } catch (e) {
      Dialogs.errorDialog(message: e.toString());
    } finally {
      busy = false;
      if (loading) {
        setState(() => loading = false);
      }
    }
  }

  void updatePositions() {
    List<MapPos> positions = [];
    for (var entry in readinessEntries) {
      if (entry.lat == null || entry.lon == null || entry.timestamp == null) continue;

      DateTime time = DateTime.fromMillisecondsSinceEpoch(entry.timestamp!);
      Duration difference = DateTime.now().difference(time);
      print(difference);

      Person? person;
      for (var p in persons) {
        if (p.id == entry.personId) {
          person = p;
          break;
        }
      }

      String name;
      if (person != null) {
        if (entry.amountStationsReady == 1) {
          name = "${person.fullName}\n${entry.amountStationsReady} Wache\n${DateFormat('HH:mm:ss').format(time)} Uhr";
        } else {
          name = "${person.fullName}\n${entry.amountStationsReady} Wachen\n${DateFormat('HH:mm:ss').format(time)} Uhr";
        }
      } else {
        if (entry.amountStationsReady == 1) {
          name = "${entry.personId}\n${entry.amountStationsReady} Wache\n${DateFormat('HH:mm:ss').format(time)} Uhr";
        } else {
          name = "${entry.personId}\n${entry.amountStationsReady} Wachen\n${DateFormat('HH:mm:ss').format(time)} Uhr";
        }
      }

      positions.add(
        MapPos(
          id: entry.personId.toString(),
          position: LatLng(entry.lat!, entry.lon!),
          name: name,
          widget: Icon(
            entry.amountStationsReady > 0 ? FluentIcons.checkbox_composite : FluentIcons.blocked,
            color: difference.inSeconds < 630
                ? Colors.green
                : Colors.red,
          ),
        ),
      );
    }

    positionsNotifier.value = positions;
  }

  @override
  void dispose() {
    timer.cancel();
    positionsNotifier.dispose();
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: ProgressRing());

    if (lastUpdate == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Fehler beim Laden der Bereitschaftsdaten'),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: fetchReadiness,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ClipRRect(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: Colors.grey.withOpacity(0.1),
          child: () {
            double lat = 0;
            double lon = 0;
            int count = 0;
            for (var entry in readinessEntries) {
              if (entry.lat != null && entry.lon != null) {
                lat += entry.lat!;
                lon += entry.lon!;
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
                positionsNotifier: positionsNotifier,
                initialZoom: 10.5,
              ),
            );
          }(),
        ),
      ),
    );
  }
}

class AdminReadinessEntry {
  int personId;
  double? lat;
  double? lon;
  int? timestamp;
  int amountStationsReady;

  AdminReadinessEntry({required this.personId, this.lat, this.lon, this.timestamp, required this.amountStationsReady});

  static AdminReadinessEntry fromString(String data) {
    List<String> parts = data.split(":");

    double? lat = parts[2] == "0" ? null : double.parse(parts[2]);
    double? lon = parts[3] == "0" ? null : double.parse(parts[3]);
    int? timestamp = parts[4] == "0" ? null : int.parse(parts[4]);
    return AdminReadinessEntry(
      personId: int.parse(parts[0]),
      amountStationsReady: int.parse(parts[1]),
      lat: lat,
      lon: lon,
      timestamp: timestamp,
    );
  }
}
