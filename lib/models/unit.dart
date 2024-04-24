class Unit {
  int id;
  String tetraId;
  int stationId;

  /// Callsign should match regex:
  /// ^\S+\s+\S+(?:\s+\S+)*\s+\d+-\d+-\d+$
  /// Florian Jena 5-43-1
  String callSign;
  static final RegExp callSignRegex = RegExp(r"^\S+\s+\S+(?:\s+\S+)*\s+\d+-\d+-\d+$");

  ({String prefix, String area, int stationIdentifier, int unitType, int unitIndex})? get unitInformation {
    List<String> splits = callSign.split(' ');
    if (splits.length < 3) return null;
    List<String> stationSplits = splits.last.split('-');
    if (stationSplits.length != 3) return null;

    String prefix = splits[0];
    String area = splits.sublist(1, splits.length - 1).join(' ');

    int? stationIdentifier = int.tryParse(stationSplits[0]);
    int? unitType = int.tryParse(stationSplits[1]);
    int? unitIndex = int.tryParse(stationSplits[2]);

    if (stationIdentifier == null || unitType == null || unitIndex == null) return null;

    return (prefix: prefix, area: area, stationIdentifier: stationIdentifier, unitType: unitType, unitIndex: unitIndex);
  }

  String unitDescription;
  int status;
  List<UnitPosition> positions;
  int capacity;
  DateTime updated;

  Unit({
    required this.id,
    required this.tetraId,
    required this.stationId,
    required this.callSign,
    required this.unitDescription,
    required this.status,
    required this.positions,
    required this.capacity,
    required this.updated,
  });

  static const Map<String, String> jsonShorts = {
    "server": "s",
    "tetraId": "t",
    "id": "i",
    "stationId": "si",
    "callSign": "c",
    "unitDescription": "d",
    "status": "st",
    "positions": "p",
    "capacity": "ca",
    "updated": "u",
  };

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json[jsonShorts["id"]],
      tetraId: json[jsonShorts["tetraId"]],
      stationId: json[jsonShorts["stationId"]],
      callSign: json[jsonShorts["callSign"]],
      unitDescription: json[jsonShorts["unitDescription"]],
      status: json[jsonShorts["status"]],
      positions: List<UnitPosition>.from(json[jsonShorts["positions"]].map((e) => UnitPosition.values[e])),
      capacity: json[jsonShorts["capacity"]],
      updated: DateTime.fromMillisecondsSinceEpoch(json[jsonShorts["updated"]]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      jsonShorts["tetraId"]!: tetraId,
      jsonShorts["id"]!: id,
      jsonShorts["stationId"]!: stationId,
      jsonShorts["callSign"]!: callSign,
      jsonShorts["unitDescription"]!: unitDescription,
      jsonShorts["status"]!: status,
      jsonShorts["positions"]!: positions.map((e) => e.index).toList(),
      jsonShorts["capacity"]!: capacity,
      jsonShorts["updated"]!: updated.millisecondsSinceEpoch,
    };
  }
}

enum UnitPosition {
  zf,
  ma,
  gf,
  atf,
  atm,
  wtf,
  wtm,
  stf,
  stm,
  me;
}
