import 'dart:convert';
import 'dart:html';

import 'package:archive/archive.dart';
import 'package:panel/globals.dart';
import 'package:dio/dio.dart';
import 'package:panel/models/alarm.dart';
import 'package:panel/models/person.dart';
import 'package:panel/models/station.dart';
import 'package:panel/models/unit.dart';

abstract class Interfaces {
  static const int timeout = 5000;

  static Future<({String? error, Map<String, dynamic>? response})> _request({required String method, required Map<String, dynamic> data, String? authorization}) async {
    try {
      authorization ??= Globals.loginInformation?.token ?? 'null';

      String authRaw = 'admin $authorization';

      GZipEncoder gzip = GZipEncoder();

      String encoded = base64Encode(gzip.encode(utf8.encode(authRaw))!);

      BaseOptions options = BaseOptions(
        connectTimeout: const Duration(milliseconds: timeout),
        receiveTimeout: const Duration(milliseconds: timeout),
        sendTimeout: const Duration(milliseconds: timeout),
        headers: {'authorization': encoded},
        method: 'POST',
        baseUrl: Globals.apiUrl,
        receiveDataWhenStatusError: true,
        validateStatus: (_) => true,
      );

      Dio dio = Dio(options);

      Response response = await dio.post(
        '/$method',
        data: jsonEncode(data),
        options: Options(validateStatus: (status) => true, responseType: ResponseType.bytes),
      );

      Map<String, dynamic> responseData = jsonDecode(utf8.decode(response.data));
      print("REQUEST: $method\nDATA: $data\nRESPONSE: $responseData\n\n");

      if (response.statusCode == HttpStatus.unauthorized) {
        Globals.logout();
      }

      if (response.statusCode == HttpStatus.ok) {
        if (Globals.loginInformation != null) {
          Globals.loginInformation!.updated = DateTime.now();
          Globals.prefs.setInt('auth_updated', Globals.loginInformation!.updated.millisecondsSinceEpoch);
        }
        return (error: null, response: responseData);
      } else {
        return (error: responseData['message'] as String, response: null);
      }
    } catch (e, s) {
      print('Error: $e\nStack: $s');
      return (error: 'Fehler bei der Verbindung mit dem Server', response: null);
    }
  }

  static Future<void> login({required String username, required String password, required String otp}) async {
    String baseUsername = base64Encode(utf8.encode(username));
    String basePassword = base64Encode(utf8.encode(password));
    String baseOtp = base64Encode(utf8.encode(otp));
    var response = await _request(method: 'login', data: {}, authorization: '$baseUsername:$basePassword:$baseOtp');
    if (response.error != null) throw response.error!;

    LoginInformation information = LoginInformation(
      user: username,
      token: response.response!['token'] as String,
      created: DateTime.now(),
      updated: DateTime.now(),
    );

    Globals.loginInformation = information;
    Globals.prefs.setString('auth_user', username);
    Globals.prefs.setString('auth_token', information.token);
    Globals.prefs.setInt('auth_created', information.created.millisecondsSinceEpoch);
    Globals.prefs.setInt('auth_updated', information.updated.millisecondsSinceEpoch);
    Globals.loggedIn.value = true;
  }

  static Future<void> ping() async {
    var response = await _request(method: 'ping', data: {});
    if (response.error != null) throw response.error!;
  }

  static Future<List<Unit>> unitList() async {
    var response = await _request(method: 'unitList', data: {});
    if (response.error != null) throw response.error!;

    List<Unit> units = [];
    for (var unit in response.response!['units']) {
      units.add(Unit.fromJson(unit));
    }
    return units;
  }

  static Future<({List<Person> persons, Station station})> unitGetDetails(int unitId) async {
    var response = await _request(method: 'unitGetDetails', data: {'id': unitId});
    if (response.error != null) throw response.error!;

    List<Person> persons = [];
    for (var person in response.response!['persons']) {
      persons.add(Person.fromJson(person));
    }

    Station station = Station.fromJson(response.response!['station']);

    return (persons: persons, station: station);
  }

  static Future<List<Station>> stationList() async {
    var response = await _request(method: 'stationList', data: {});
    if (response.error != null) throw response.error!;

    List<Station> stations = [];
    for (var station in response.response!['stations']) {
      stations.add(Station.fromJson(station));
    }
    return stations;
  }

  static Future<({List<Unit> units, List<Person> persons})> stationGetDetails(int stationId) async {
    var response = await _request(method: 'stationGetDetails', data: {'id': stationId});
    if (response.error != null) throw response.error!;

    List<Unit> units = [];
    for (var unit in response.response!['units']) {
      units.add(Unit.fromJson(unit));
    }

    List<Person> persons = [];
    for (var person in response.response!['persons']) {
      persons.add(Person.fromJson(person));
    }

    return (units: units, persons: persons);
  }

  static Future<List<Person>> personList() async {
    var response = await _request(method: 'personList', data: {});
    if (response.error != null) throw response.error!;

    List<Person> persons = [];
    for (var person in response.response!['persons']) {
      persons.add(Person.fromJson(person));
    }
    return persons;
  }

  static Future<({List<Unit> units, List<Station> stations})> personGetDetails(int personId) async {
    var response = await _request(method: 'personGetDetails', data: {'id': personId});
    if (response.error != null) throw response.error!;

    List<Unit> units = [];
    for (var unit in response.response!['units']) {
      units.add(Unit.fromJson(unit));
    }

    List<Station> stations = [];
    for (var station in response.response!['stations']) {
      stations.add(Station.fromJson(station));
    }

    return (units: units, stations: stations);
  }

  static Future<List<Alarm>> alarmList() async {
    var response = await _request(method: 'alarmList', data: {});
    if (response.error != null) throw response.error!;

    List<Alarm> alarms = [];
    for (var alarm in response.response!['alarms']) {
      alarms.add(Alarm.fromJson(alarm));
    }
    return alarms;
  }

  static Future<({List<Unit> units, List<Station> stations, List<Person> persons})> alarmGetDetails(int alarmId) async {
    var response = await _request(method: 'alarmGetDetails', data: {'id': alarmId});
    if (response.error != null) throw response.error!;

    List<Unit> units = [];
    for (var unit in response.response!['units']) {
      units.add(Unit.fromJson(unit));
    }

    List<Station> stations = [];
    for (var station in response.response!['stations']) {
      stations.add(Station.fromJson(station));
    }

    List<Person> persons = [];
    for (var person in response.response!['persons']) {
      persons.add(Person.fromJson(person));
    }

    return (units: units, stations: stations, persons: persons);
  }

  static Future<({double lat, double long})> getCoordinates(String address) async {
    var response = await _request(method: 'getCoordinates', data: {'address': address});
    if (response.error != null) throw response.error!;

    return (lat: response.response!['lat'] as double, long: response.response!['lon'] as double);
  }

  static Future<String> getAddress(double lat, double long) async {
    var response = await _request(method: 'getAddress', data: {'lat': lat, 'lon': long});
    if (response.error != null) throw response.error!;

    return response.response!['address'] as String;
  }

  static Future<void> stationDelete(int stationId) async {
    var response = await _request(method: 'stationDelete', data: {'id': stationId});
    if (response.error != null) throw response.error!;
  }

  static Future<void> stationUpdate({
    required int id,
    required String name,
    required String area,
    required String prefix,
    required int stationNumber,
    required String address,
    required String coordinates,
  }) async {
    var data = {
      'id': id,
      'name': name,
      'area': area,
      'prefix': prefix,
      'stationnumber': stationNumber,
      'address': address,
      'coordinates': coordinates,
    };

    var response = await _request(method: 'stationUpdate', data: data);
    if (response.error != null) throw response.error!;
  }

  static Future<Station> stationCreate({
    required String name,
    required String area,
    required String prefix,
    required int stationNumber,
    required String address,
    required String coordinates,
  }) async {
    var data = {
      'name': name,
      'area': area,
      'prefix': prefix,
      'stationnumber': stationNumber,
      'address': address,
      'coordinates': coordinates,
    };

    var response = await _request(method: 'stationCreate', data: data);
    if (response.error != null) throw response.error!;

    return Station.fromJson(response.response!);
  }
}
