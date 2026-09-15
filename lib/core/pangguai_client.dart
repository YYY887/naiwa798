import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PangGuaiClient {
  static final Uri _scanUri = Uri.parse(
    'https://userapi.qiekj.com/goods/scan/v2',
  );

  String extractSerialNumber(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) return '';

    final uri = Uri.tryParse(raw);
    if (uri != null) {
      for (final key in const [
        'SN',
        'sn',
        'goodsSn',
        'goodsSN',
        'deviceSn',
        'deviceSN',
      ]) {
        final value = uri.queryParameters[key]?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
      final fromPath = uri.pathSegments.reversed.firstWhere(
        (segment) => RegExp(r'^\d{8,20}$').hasMatch(segment),
        orElse: () => '',
      );
      if (fromPath.isNotEmpty) return fromPath;
    }

    final matches = RegExp(r'\d{8,20}')
        .allMatches(raw)
        .map((match) => match.group(0)!)
        .toList();
    if (matches.isEmpty) return '';
    matches.sort((left, right) => right.length.compareTo(left.length));
    return matches.first;
  }

  Future<String> lookupGoodsId(String serialNumber) async {
    final response = await http.post(
      _scanUri,
      headers: {
        'Version': '1.114.0',
        'channel': 'ios_app',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'SN': serialNumber},
    );
    final body = jsonDecode(response.body);
    final data = body is Map<String, dynamic> ? body['data'] : null;
    final goodsId = data is Map<String, dynamic>
        ? data['id']?.toString()
        : null;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body is! Map<String, dynamic> ||
        body['code'] != 0 ||
        goodsId == null ||
        goodsId.isEmpty) {
      final message = body is Map<String, dynamic>
          ? body['msg']?.toString()
          : null;
      throw StateError(message?.isNotEmpty == true ? message! : '未获取到洗澡设备信息');
    }
    return goodsId;
  }

  Future<void> openAlipayShower(String goodsId) async {
    final page =
        'pages/chooseShowerMachine/showerMachine/showerMachine?__appxPageId=8&goodsId=$goodsId';
    final uri = Uri.parse('alipays://platformapi/startapp')
        .replace(queryParameters: {'appId': '2018072460764274', 'page': page});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('无法唤起支付宝，请确认已安装支付宝');
    }
  }
}
