import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super798_flutter/core/app_state.dart';
import 'package:super798_flutter/pages/login_page.dart';

void main() {
  testWidgets('登录页展示奶娃喝水标题', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(state: AppState())));

    expect(find.text('奶娃喝水'), findsOneWidget);
    expect(find.text('手机号'), findsOneWidget);
  });
}
