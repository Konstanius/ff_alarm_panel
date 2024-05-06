import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:panel/dialogs.dart';
import 'package:panel/globals.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    required this.initialPosition,
    required this.positionsNotifier,
    required this.controller,
    this.initialZoom = 15.5,
    this.onTap,
  });

  final LatLng initialPosition;
  final ValueNotifier<List<MapPos>> positionsNotifier;
  final MapController controller;
  final double initialZoom;
  final void Function(TapPosition, LatLng)? onTap;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  ValueNotifier<bool> textVisible = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    widget.controller.mapEventStream.listen((event) {
      textVisible.value = widget.controller.camera.zoom > 13;

      if (widget.controller.camera.rotation != 0) {
        widget.controller.rotate(0);
      }
    });

    if (widget.initialZoom > 13) {
      textVisible.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: widget.controller,
      options: MapOptions(
        initialCenter: widget.initialPosition,
        initialZoom: widget.initialZoom,
        onTap: widget.onTap,
        maxZoom: 20,
        minZoom: 5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          keepBuffer: 2,
          panBuffer: 1,
          tileProvider: CancellableNetworkTileProvider(
            silenceExceptions: true,
          ),
        ),
        ValueListenableBuilder(
          valueListenable: widget.positionsNotifier,
          builder: (BuildContext context, List<MapPos> positions, Widget? child) {
            return MarkerLayer(
              alignment: Alignment.topCenter,
              markers: [
                for (var position in positions.where((element) => element.radius == null))
                  Marker(
                    width: 150.0,
                    height: 0,
                    alignment: Alignment.center,
                    point: position.position,
                    rotate: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        position.widget,
                        ValueListenableBuilder(
                          valueListenable: textVisible,
                          builder: (context, bool visible, child) {
                            if (!visible) return const SizedBox();
                            return Text(
                              position.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: widget.positionsNotifier,
          builder: (BuildContext context, List<MapPos> positions, Widget? child) {
            return CircleLayer(
              circles: [
                for (var position in positions.where((element) => element.radius != null))
                  CircleMarker(
                    point: position.position,
                    radius: position.radius!.toDouble(),
                    color: Colors.blue.withOpacity(0.3),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class MapPos {
  String id;
  LatLng position;
  String name;
  Widget widget;
  int? radius;

  MapPos({
    required this.id,
    required this.position,
    required this.name,
    required this.widget,
    this.radius,
  });
}

extension SmoothMapController on MapController {
  Future<void> smoothMove(LatLng position, double zoom) async {
    double startX = camera.center.latitude;
    double startY = camera.center.longitude;
    double startZoom = zoom;

    double dx = position.latitude - startX;
    double dy = position.longitude - startY;
    double dz = zoom - startZoom;

    const minStepSize = 0.001;
    const maxSteps = 100;

    int steps = (dx.abs() / minStepSize).ceil();
    steps = steps > maxSteps ? maxSteps : steps;

    double stepX = dx / steps;
    double stepY = dy / steps;
    double stepZ = dz / steps;

    for (int i = 1; i <= steps; i++) {
      try {
        await Future.delayed(const Duration(milliseconds: 17));
        move(LatLng(startX + stepX * i, startY + stepY * i), startZoom + stepZ * i);
      } catch (_) {
        return;
      }
    }

    move(position, zoom);
  }
}

class MapLocationPicker extends StatefulWidget {
  const MapLocationPicker({super.key, this.startLatitude, this.startLongitude});

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();

  static Future<({double latitude, double longitude})?> pickLocation({required BuildContext context, double? startLatitude, double? startLongitude}) async {
    return await showDialog(
      context: context,
      dismissWithEsc: true,
      barrierDismissible: true,
      builder: (context) {
        return Center(child: MapLocationPicker(startLatitude: startLatitude, startLongitude: startLongitude));
      },
    );
  }

  final double? startLatitude;
  final double? startLongitude;
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  MapController controller = MapController();
  ValueNotifier<List<MapPos>> positionsNotifier = ValueNotifier([]);

  @override
  void dispose() {
    controller.dispose();
    positionsNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.startLatitude != null && widget.startLongitude != null) {
      positionsNotifier.value = [
        MapPos(
          id: 'picked',
          position: LatLng(widget.startLatitude ?? 0, widget.startLongitude ?? 0),
          name: 'Gewählte Position',
          widget: const Icon(FluentIcons.location),
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: MapPage(
                    initialPosition: LatLng(widget.startLatitude ?? 0, widget.startLongitude ?? 0),
                    controller: controller,
                    initialZoom: 12,
                    positionsNotifier: positionsNotifier,
                    onTap: (tapPosition, latLng) {
                      positionsNotifier.value = [
                        MapPos(
                          id: 'picked',
                          position: latLng,
                          name: 'Gewählte Position',
                          widget: const Icon(FluentIcons.location),
                        ),
                      ];
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Button(
                      onPressed: () {
                        Navigator.of(Globals.context).pop();
                      },
                      child: const Text('Abbrechen'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () {
                        if (positionsNotifier.value.isEmpty) {
                          Dialogs.errorDialog(message: 'Bitte wählen Sie eine Position auf der Karte aus.');
                        }
                        Navigator.of(Globals.context).pop((latitude: positionsNotifier.value[0].position.latitude, longitude: positionsNotifier.value[0].position.longitude));
                      },
                      child: const Text('Bestätigen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
