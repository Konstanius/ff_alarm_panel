import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import 'package:panel/dialogs.dart';

import '../interfaces.dart';
import '../models/person.dart';
import '../models/station.dart';
import '../models/unit.dart';

class PersonsPage extends StatefulWidget {
  const PersonsPage({super.key});

  @override
  State<PersonsPage> createState() => _PersonsPageState();
}

class _PersonsPageState extends State<PersonsPage> {
  List<Person>? persons;
  Person? selectedPerson;
  bool loading = true;

  TextEditingController searchController = TextEditingController();

  ({List<Unit> units, List<Station> stations})? selectedPersonData;

  void fetchPersons() async {
    try {
      setState(() => loading = true);
      persons = await Interfaces.personList();
    } catch (e) {
      Dialogs.errorDialog(message: e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  void fetchPerson() async {
    selectedPersonData = null;
    setState(() {});
    if (selectedPerson == null) {
      return;
    }

    int id = selectedPerson!.id;
    try {
      var result = await Interfaces.personGetDetails(id);
      if (id != selectedPerson!.id) return;
      selectedPersonData = result;
    } catch (e) {
      Dialogs.errorDialog(message: e.toString());
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    fetchPersons();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: ProgressRing());

    if (persons == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Einheiten konnten nicht geladen werden'),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: fetchPersons,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    List<Person> filtered = [];
    if (searchController.text.isNotEmpty) {
      String search = searchController.text.toLowerCase().trim();
      for (var person in persons!) {
        if (person.fullName.toLowerCase().contains(search)) {
          filtered.add(person);
        }
      }
    } else {
      filtered = persons!;
    }

    filtered.sort((a, b) => a.fullName.compareTo(b.fullName));

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
                    for (var person in filtered)
                      Acrylic(
                        child: ListTile(
                          title: Text(person.fullName),
                          subtitle: Text('Geb.: ${DateFormat('dd.MM.yyyy').format(person.birthday)}'),
                          onPressed: () {
                            setState(() {
                              selectedPerson = person;
                              fetchPerson();
                            });
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
                child: () {
                  // TODO if selectedPerson is null, show a statistic of all persons
                  if (selectedPerson == null) return const SizedBox();
                  if (selectedPersonData == null) return const Center(child: ProgressRing());
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
