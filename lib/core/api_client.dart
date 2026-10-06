import 'dart:convert';

import 'package:http/http.dart' as http;

import 'device_signer.dart';

class ApiClient {
  String? token;
  String? uid;
  static const base = 'https://i.ilife798.com/api/v1/';
  static const _deviceHeaders = {
    'User-Agent': 'iLife798/3.1.8 (Android)',
    'Content-Type': 'application/json',
    'VersionCode': '3.1.8',
    'Accept-Language': 'zh-Hans-CN;q=1',
  };

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? params,
    Map<String, String>? headers,
  }) async {
    final u = Uri.parse('$base$path').replace(queryParameters: params);
    final r = await http.get(
      u,
      headers: {if (token != null) 'Authorization': token!, ...?headers},
    );
    return jsonDecode(r.body);
  }

  Future<Map<String, dynamic>> signedDeviceGet(
    String path, {
    required Map<String, String> params,
  }) async {
    final currentToken = token;
    if (currentToken == null || currentToken.length < 8) {
      throw StateError('请先登录');
    }

    final before = DateTime.now().millisecondsSinceEpoch;
    final master = await get(
      'ui/app/master',
      params: {'ad': 'false'},
      headers: _deviceHeaders,
    );
    final after = DateTime.now().millisecondsSinceEpoch;
    if (master['code'] != 0) {
      throw StateError('${master['msg'] ?? '获取账号信息失败'}');
    }
    final account = master['data']?['account'];
    final currentUid =
        uid ??
        (account is Map ? (account['uid'] ?? account['id'])?.toString() : null);
    final rawServerTime = master['time'];
    final serverTime = rawServerTime is num
        ? rawServerTime.toInt()
        : int.tryParse('$rawServerTime');
    if (currentUid == null || currentUid.length < 8) {
      throw StateError('缺少账号 UID，请重新登录或在凭证登录时填写 UID');
    }
    if (serverTime == null) {
      throw StateError('无法取得服务器时间');
    }

    final offset = serverTime - ((before + after) ~/ 2);
    var serverNow = DateTime.now().millisecondsSinceEpoch + offset;
    final position = serverNow % 30000;
    if (position < 3000) {
      await Future<void>.delayed(Duration(milliseconds: 3000 - position));
    } else if (position > 27000) {
      await Future<void>.delayed(Duration(milliseconds: 33000 - position));
    }
    serverNow = DateTime.now().millisecondsSinceEpoch + offset;
    if (token != currentToken) {
      throw StateError('登录状态已变更，请重试');
    }
    final signature = signDeviceRequest(
      params: params,
      token: currentToken,
      uid: currentUid,
      serverNowMs: serverNow,
    );
    return get(
      path,
      params: {...params, 'sign': signature},
      headers: _deviceHeaders,
    );
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
