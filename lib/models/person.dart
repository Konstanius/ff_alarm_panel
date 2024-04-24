class Person {
  int id;
  String firstName;
  String lastName;
  String get fullName => "$firstName $lastName";
  DateTime birthday;

  /// The ids of the units that this user is allowed to operate
  /// If an integer is negative, that means the user has been removed from the unit, and the id shall not be added to the list, when the unit is changed to or from the station
  /// If the integer is positive, that means the user should be alarmed for the unit
  /// If the integer is not present, the unit is not associated with the user in any way, and therefore the user should not be alarmed for it
  List<int> allowedUnits;
  List<Qualification> qualifications;

  List<Qualification> visibleQualificationsAt(DateTime date) {
    List<Qualification> active = [];

    for (var qualification in qualifications) {
      if (qualification.type.startsWith("_")) continue;
      if (qualification.start == null && qualification.end == null) continue;
      if (qualification.start == null && qualification.end != null && qualification.end!.isAfter(date)) active.add(qualification);
      if (qualification.start != null && qualification.end == null && qualification.start!.isBefore(date)) active.add(qualification);
      if (qualification.start != null && qualification.end != null && qualification.start!.isBefore(date) && qualification.end!.isAfter(date)) active.add(qualification);
    }

    return active;
  }

  DateTime updated;

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthday,
    required this.allowedUnits,
    required this.qualifications,
    required this.updated,
  });

  static const Map<String, String> jsonShorts = {
    "server": "s",
    "id": "i",
    "firstName": "f",
    "lastName": "l",
    "birthday": "b",
    "allowedUnits": "au",
    "qualifications": "q",
    "updated": "up",
  };

  Map<String, dynamic> toJson() {
    return {
      jsonShorts["id"]!: id,
      jsonShorts["firstName"]!: firstName,
      jsonShorts["lastName"]!: lastName,
      jsonShorts["birthday"]!: birthday.millisecondsSinceEpoch,
      jsonShorts["allowedUnits"]!: allowedUnits,
      jsonShorts["qualifications"]!: qualifications.map((e) => e.toString()).toList(),
      jsonShorts["updated"]!: updated.millisecondsSinceEpoch,
    };
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json[jsonShorts["id"]],
      firstName: json[jsonShorts["firstName"]],
      lastName: json[jsonShorts["lastName"]],
      birthday: DateTime.fromMillisecondsSinceEpoch(json[jsonShorts["birthday"]]),
      allowedUnits: List<int>.from(json[jsonShorts["allowedUnits"]]),
      qualifications: (json[jsonShorts["qualifications"]] as List).map((e) => Qualification.fromString(e)).toList(),
      updated: DateTime.fromMillisecondsSinceEpoch(json[jsonShorts["updated"]]),
    );
  }
}

class Qualification {
  final String type;
  final DateTime? start;
  final DateTime? end;

  Qualification(this.type, this.start, this.end);

  factory Qualification.fromString(String str) {
    var parts = str.split(':');
    String type = parts[0];
    DateTime? start = parts[1] == "0" ? null : DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1]));
    DateTime? end = parts[2] == "0" ? null : DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2]));
    return Qualification(type, start, end);
  }

  @override
  String toString() {
    return "$type:${start?.millisecondsSinceEpoch ?? 0}:${end?.millisecondsSinceEpoch ?? 0}";
  }
}
