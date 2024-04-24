class Alarm {
  int id;
  String type;
  String word;
  DateTime date;
  int number;
  String address;
  List<String> notes;
  List<int> units;
  Map<int, AlarmResponse> responses;
  DateTime updated;

  Alarm({
    required this.id,
    required this.type,
    required this.word,
    required this.date,
    required this.number,
    required this.address,
    required this.notes,
    required this.units,
    required this.responses,
    required this.updated,
  });

  static const Map<String, String> jsonShorts = {
    "server": "s",
    "id": "i",
    "type": "t",
    "word": "w",
    "date": "d",
    "number": "n",
    "address": "a",
    "notes": "no",
    "units": "u",
    "responses": "r",
    "updated": "up",
  };

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json[jsonShorts["id"]],
      type: json[jsonShorts["type"]],
      word: json[jsonShorts["word"]],
      date: DateTime.fromMillisecondsSinceEpoch(json[jsonShorts["date"]]),
      number: json[jsonShorts["number"]],
      address: json[jsonShorts["address"]],
      notes: List<String>.from(json[jsonShorts["notes"]]),
      units: List<int>.from(json[jsonShorts["units"]]),
      responses: () {
        Map<int, AlarmResponse> responses = {};
        json[jsonShorts["responses"]].forEach((key, value) {
          var alarmResponse = AlarmResponse.fromJson(value);
          responses[int.parse(key)] = alarmResponse;
        });
        return responses;
      }(),
      updated: DateTime.fromMillisecondsSinceEpoch(json[jsonShorts["updated"]]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonShorts["id"]!: id,
      jsonShorts["type"]!: type,
      jsonShorts["word"]!: word,
      jsonShorts["date"]!: date.millisecondsSinceEpoch,
      jsonShorts["number"]!: number,
      jsonShorts["address"]!: address,
      jsonShorts["notes"]!: notes,
      jsonShorts["units"]!: units,
      jsonShorts["responses"]!: responses.map((key, value) => MapEntry(key.toString(), value.toJson())),
      jsonShorts["updated"]!: updated.millisecondsSinceEpoch,
    };
  }
}

/// Each responder gives a single response to each alarm
class AlarmResponse {
  /// The note left to be visible for other responders of the station they are not "Not going" to
  /// If the response is "Not going" to all stations, the note is visible to all responders
  String note;

  /// The time at which the response was given
  DateTime time;

  /// The type of response given, for each station
  Map<int, AlarmResponseType> responses;

  AlarmResponse({
    required this.note,
    required this.time,
    required this.responses,
  });

  static const Map<String, String> jsonShorts = {
    "note": "n",
    "time": "t",
    "responses": "r",
  };

  factory AlarmResponse.fromJson(Map<String, dynamic> json) {
    return AlarmResponse(
      note: json[jsonShorts["note"]],
      time: DateTime.fromMillisecondsSinceEpoch(json[jsonShorts["time"]]),
      responses: () {
        Map<int, AlarmResponseType> responses = {};
        json[jsonShorts["responses"]].forEach((key, value) {
          responses[int.parse(key)] = AlarmResponseType.values[value];
        });
        return responses;
      }(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonShorts["note"]!: note,
      jsonShorts["time"]!: time.millisecondsSinceEpoch,
      jsonShorts["responses"]!: responses.map((key, value) => MapEntry(key.toString(), value.index)),
    };
  }
}

enum AlarmResponseType {
  onStation(0),
  under5(5),
  under10(10),
  under15(15),
  onCall(-1),
  notReady(-2),
  notSet(-3);

  final int timeAmount;

  const AlarmResponseType(this.timeAmount);
}
