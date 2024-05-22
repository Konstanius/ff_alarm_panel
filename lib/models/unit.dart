import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as mat show Icons;

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
  UnitStatus get statusEnum => UnitStatus.fromInt(status);

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

enum UnitStatus {
  invalid,
  onRadio,
  onStation,
  onRoute,
  onScene,
  notAvailable,
  toHospital,
  atHospital;

  static const Map<UnitStatus, int> sw = {
    UnitStatus.invalid: 0,
    UnitStatus.onRadio: 1,
    UnitStatus.onStation: 2,
    UnitStatus.onRoute: 3,
    UnitStatus.onScene: 4,
    UnitStatus.notAvailable: 6,
    UnitStatus.toHospital: 7,
    UnitStatus.atHospital: 8,
  };

  static UnitStatus fromInt(int status) {
    for (var entry in sw.entries) {
      if (entry.value == status) return entry.key;
    }
    return UnitStatus.invalid;
  }

  int get value => sw[this] ?? 0;

  IconData get icon {
    switch (this) {
      case UnitStatus.invalid:
        return mat.Icons.question_mark_outlined;
      case UnitStatus.onRadio:
        return mat.Icons.radio_outlined;
      case UnitStatus.onStation:
        return mat.Icons.home_outlined;
      case UnitStatus.onRoute:
        return mat.Icons.directions_outlined;
      case UnitStatus.onScene:
        return mat.Icons.location_on_outlined;
      case UnitStatus.notAvailable:
        return mat.Icons.block_outlined;
      case UnitStatus.toHospital:
        return mat.Icons.emergency_outlined;
      case UnitStatus.atHospital:
        return mat.Icons.local_hospital_outlined;
    }
  }

  Color get color {
    switch (this) {
      case UnitStatus.invalid:
        return Colors.grey;
      case UnitStatus.onRadio:
        return Colors.blue;
      case UnitStatus.onStation:
        return Colors.green;
      case UnitStatus.onRoute:
      case UnitStatus.toHospital:
        return Colors.orange;
      case UnitStatus.onScene:
      case UnitStatus.atHospital:
        return Colors.red;
      case UnitStatus.notAvailable:
        return Colors.grey;
    }
  }

  String get description {
    switch (this) {
      case UnitStatus.invalid:
        return 'Ungültiger Status';
      case UnitStatus.onRadio:
        return 'Frei über Funk';
      case UnitStatus.onStation:
        return 'Auf Wache';
      case UnitStatus.onRoute:
        return 'Einsatz übernommen';
      case UnitStatus.onScene:
        return 'Am Einsatzort';
      case UnitStatus.notAvailable:
        return 'Nicht einsatzbereit';
      case UnitStatus.toHospital:
        return 'Patient aufgenommen';
      case UnitStatus.atHospital:
        return 'Am Zielort angekommen';
    }
  }
}
