import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:lactosure_connect_app/services/authen_service.dart';

class TokenCheck {
  static Future<bool> isLoggedIn() async {
    final token = await AuthService.getToken();
    print("STORED TOKEN: $token");
    if (token == null || token.isEmpty) {
      return false;
    }

    // 🔥 THIS is what you are missing
    if (JwtDecoder.isExpired(token)) {
      await AuthService.logout();
      return false;
    }

    return true;
  }

  static Future<String?> getEmail() async {
    final token = await AuthService.getToken();

    if (token == null) return null;

    final decoded = JwtDecoder.decode(token);
    return decoded["email"];
  }
}
