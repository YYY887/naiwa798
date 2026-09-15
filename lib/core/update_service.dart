import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseUrl,
  });

  final String version;
  final Uri downloadUrl;
  final Uri releaseUrl;
}

class UpdateService {
  static const _latestRelease =
      'https://api.github.com/repos/YYY887/naiwa798/releases/latest';

  Future<UpdateInfo?> checkForUpdate() async {
    final package = await PackageInfo.fromPlatform();
    final response = await http.get(
      Uri.parse(_latestRelease),
      headers: const {'Accept': 'application/vnd.github+json'},
    );
    if (response.statusCode != 200) return null;
    final release = jsonDecode(response.body) as Map<String, dynamic>;
    final tag = release['tag_name']?.toString().replaceFirst(RegExp(r'^v'), '');
    if (tag == null || !_isNewer(tag, package.version)) return null;
    final assets = List<Map<String, dynamic>>.from(
      release['assets'] ?? const [],
    );
    final suffix = defaultTargetPlatform == TargetPlatform.iOS
        ? 'NaiWawate-ios-unsigned.ipa'
        : 'NaiWawate-android.apk';
    final asset = assets.where((item) => item['name'] == suffix).firstOrNull;
    final download = asset?['browser_download_url']?.toString();
    final releaseUrl = release['html_url']?.toString();
    if (download == null || releaseUrl == null) return null;
    return UpdateInfo(
      version: tag,
      downloadUrl: Uri.parse(download),
      releaseUrl: Uri.parse(releaseUrl),
    );
  }

  bool _isNewer(String next, String current) {
    final newer = next.split('.').map(int.tryParse).toList();
    final existing = current.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final left = i < newer.length ? newer[i] ?? 0 : 0;
      final right = i < existing.length ? existing[i] ?? 0 : 0;
      if (left != right) return left > right;
    }
    return false;
  }
}
