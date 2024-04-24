import 'package:fluent_ui/fluent_ui.dart';
import 'package:panel/dialogs.dart';

import '../interfaces.dart';
import '../models/unit.dart';

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

  void fetchUnits() async {
    try {
      setState(() => loading = true);
      units = await Interfaces.unitList();
    } catch (e) {
      Dialogs.errorDialog(title: 'Fehler', message: e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUnits();
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
                      Acrylic(
                        child: ListTile(
                          title: Text(unit.callSign),
                          subtitle: Text(unit.unitDescription),
                          onPressed: () {
                            setState(() => selectedUnit = unit);
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
                child: selectedUnit == null
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
