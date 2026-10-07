import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:super798_flutter/widgets/app_version_label.dart';

void main() {
  testWidgets('version label reads installed version and build number', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: '测试应用',
      packageName: 'test.app',
      version: '2.3.4',
      buildNumber: '42',
      buildSignature: '',
    );
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppVersionLabel())),
    );
    await tester.pumpAndSettle();
    expect(find.text('当前版本 v2.3.4 (42)'), findsOneWidget);
  });
}
