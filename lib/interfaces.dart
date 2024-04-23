import 'dart:convert';
import 'dart:html';

import 'package:archive/archive.dart';
import 'package:panel/globals.dart';
import 'package:dio/dio.dart';

abstract class Interfaces {
  static const int timeout = 5000;

  static Future<({String? error, Map<String, dynamic>? response})> _request({required String method, required Map<String, dynamic> data, String? authorization}) async {
    try {
      authorization ??= Globals.loginInformation?.token ?? 'null';

      String authRaw = 'admin $authorization';

      GZipEncoder gzip = GZipEncoder();

      String encoded = base64Encode(gzip.encode(utf8.encode(authRaw))!);

      BaseOptions options = BaseOptions(
        connectTimeout: Duration(milliseconds: timeout),
        receiveTimeout: Duration(milliseconds: timeout),
        sendTimeout: Duration(milliseconds: timeout),
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
}
