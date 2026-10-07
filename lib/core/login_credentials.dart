import 'dart:convert';

class LoginCredentials {
  const LoginCredentials({required this.token, required this.uid});
  final String token;
  final String uid;

  factory LoginCredentials.parse(String input) {
    try {
      final value = jsonDecode(input.trim());
      if (value is Map &&
          value['token'] is String &&
          (value['uid'] is String || value['uid'] is num)) {
        final token = (value['token'] as String).trim();
        final uid = value['uid'].toString().trim();
        if (token.length >= 8 && uid.length >= 8) {
          return LoginCredentials(token: token, uid: uid);
        }
      }
    } on FormatException {
      // Report one useful message for malformed or incomplete credentials.
    }
    throw const FormatException('请粘贴完整登录密钥，需同时包含 token 和 UID');
  }

  String encode() => jsonEncode({'token': token, 'uid': uid});
}
