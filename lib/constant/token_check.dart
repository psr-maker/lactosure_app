import 'package:shared_preferences/shared_preferences.dart';

class TokenCheck {

  static Future<bool> isLoggedIn() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    String? token = prefs.getString("token");

    return token != null && token.isNotEmpty;
  }

  static Future<String?> getEmail() async {

    SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString("email");
  }
}