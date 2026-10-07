import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionLabel extends StatefulWidget {
  const AppVersionLabel({this.style, super.key});
  final TextStyle? style;

  @override
  State<AppVersionLabel> createState() => _AppVersionLabelState();
}

class _AppVersionLabelState extends State<AppVersionLabel> {
  late final _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: _info,
    builder: (context, snapshot) {
      final info = snapshot.data;
      final text = info == null
          ? (snapshot.hasError ? '版本信息暂不可用' : '正在读取版本…')
          : '当前版本 v${info.version}${info.buildNumber.isEmpty ? '' : ' (${info.buildNumber})'}';
      return Text(text, style: widget.style);
    },
  );
}
