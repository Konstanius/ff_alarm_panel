class Station {
  int id;
  String name;
  String get descriptiveName => "$name ($prefix $area $stationNumber)";
  String get descriptiveNameShort => "$prefix $area $stationNumber";
  String area;
  String prefix;
  int stationNumber;
  String address;
  String coordinates;
  List<int> persons;
  List<int> adminPersons;
  DateTime updated;

  Station({
    required this.id,
    required this.name,
    required this.area,
    required this.prefix,
    required this.stationNumber,
    required this.address,
    required this.coordinates,
    required this.persons,
    required this.adminPersons,
    required this.updated,
  });

  static const Map<String, String> jsonShorts = {
    "server": "s",
    "id": "i",
    "name": "n",
    "area": "a",
    "prefix": "p",
    "stationNumber": "sn",
    "address": "ad",
    "coordinates": "c",
    "persons": "pe",
    "adminPersons": "ap",
    "updated": "up",
  };

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json[jsonShorts["id"]],
      name: json[jsonShorts["name"]],
      area: json[jsonShorts["area"]],
      prefix: json[jsonShorts["prefix"]],
      stationNumber: json[jsonShorts["stationNumber"]],
      address: json[jsonShorts["address"]],
      coordinates: json[jsonShorts["coordinates"]],
      persons: List<int>.from(json[jsonShorts["persons"]]),
      adminPersons: List<int>.from(json[jsonShorts["adminPersons"]]),
      updated: DateTime.fromMillisecondsSinceEpoch(json[jsonShorts["updated"]]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonShorts["id"]!: id,
      jsonShorts["name"]!: name,
      jsonShorts["area"]!: area,
      jsonShorts["prefix"]!: prefix,
      jsonShorts["stationNumber"]!: stationNumber,
      jsonShorts["address"]!: address,
      jsonShorts["coordinates"]!: coordinates,
      jsonShorts["persons"]!: persons,
      jsonShorts["adminPersons"]!: adminPersons,
      jsonShorts["updated"]!: updated.millisecondsSinceEpoch,
    };
  }
}
