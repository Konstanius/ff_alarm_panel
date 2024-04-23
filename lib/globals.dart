import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class Globals {
  static late SharedPreferences prefs;
  static LoginInformation? loginInformation;
  static final ValueNotifier<bool> loggedIn = ValueNotifier(false);
  static late String apiUrl;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    checkLogin();
    apiUrl = '${Uri.base.origin}/api';
    if (kDebugMode) {
      apiUrl = 'http://hbvjena90.ddns.net:443/api';
    }
  }

  static void checkLogin() {
    String? user = prefs.getString('auth_user');
    String? token = prefs.getString('auth_token');
    DateTime? created = prefs.getInt('auth_created') != null ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt('auth_created')!) : null;
    DateTime? updated = prefs.getInt('auth_updated') != null ? DateTime.fromMillisecondsSinceEpoch(prefs.getInt('auth_updated')!) : null;
    if (user != null && token != null && created != null && updated != null) {
      if (updated.difference(DateTime.now()).inMinutes > 10) {
        logout();
        return;
      }

      loginInformation = LoginInformation(user: user, token: token, created: created, updated: updated);
      loggedIn.value = true;
    } else {
      loginInformation = null;
      loggedIn.value = false;
    }
  }

  static void logout() {
    prefs.remove('auth_user');
    prefs.remove('auth_token');
    prefs.remove('auth_created');
    prefs.remove('auth_updated');
    loginInformation = null;
    loggedIn.value = false;
  }
}

class LoginInformation {
  String user;
  String token;
  DateTime created;
  DateTime updated;

  LoginInformation({
    required this.user,
    required this.token,
    required this.created,
    required this.updated,
  });
}
