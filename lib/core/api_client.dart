import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  String? token;
  static const base = 'https://i.ilife798.com/api/v1/';
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? params,
  }) async {
    final u = Uri.parse('$base$path').replace(queryParameters: params);
    final r = await http.get(
      u,
      headers: token == null ? {} : {'Authorization': token!},
    );
    return jsonDecode(r.body);
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) async {
    final response = await http.post(
      Uri.parse('$base$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': token!,
      },
      body: jsonEncode(body),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String captchaUrl(String seed) =>
      '${base}captcha/?s=$seed&r=${DateTime.now().millisecondsSinceEpoch}';
}
