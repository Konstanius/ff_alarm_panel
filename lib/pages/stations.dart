import 'package:fluent_ui/fluent_ui.dart';
import 'package:panel/dialogs.dart';

import '../interfaces.dart';
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

  TextEditingController searchController = TextEditingController();

  void fetchStations() async {
    try {
      setState(() => loading = true);
      stations = await Interfaces.stationList();
    } catch (e) {
      Dialogs.errorDialog(title: 'Fehler', message: e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStations();
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
        if (station.name.toLowerCase().contains(search) || station.address.toLowerCase().contains(search) || station.area.toLowerCase().contains(search)) {
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
                          onPressed: () {
                            setState(() => selectedStation = station);
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
                child: selectedStation == null
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
