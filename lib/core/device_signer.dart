import 'dart:convert';

import 'package:crypto/crypto.dart';

const _salt = 'AbCdEfGhIjKlMnOpQrStUvWxYz12345';

/// Signs the exact parameter values sent to the Android device API.
String signDeviceRequest({
  required Map<String, String> params,
  required String token,
  required String uid,
  required int serverNowMs,
}) {
  if (token.length < 8 || uid.length < 8) {
    throw ArgumentError('登录凭证或账号 UID 无效');
  }

  final pairs =
      params.entries.map((entry) => '${entry.key}=${entry.value}').toList()
        ..sort((a, b) {
          final aKey = a.split('=').first;
          final bKey = b.split('=').first;
          final keyOrder = aKey.compareTo(bKey);
          return keyOrder != 0 ? keyOrder : a.compareTo(b);
        });
  final timeBucketSeconds = (serverNowMs ~/ 30000) * 30;
  final payload =
      '${pairs.join('&')}$timeBucketSeconds${token.substring(token.length - 8)}'
      '${uid.substring(uid.length - 8)}$_salt';
  return md5.convert(utf8.encode(payload)).toString();
}
