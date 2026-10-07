import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super798_flutter/core/app_state.dart';
import 'package:super798_flutter/pages/login_page.dart';

void main() {
  testWidgets('密钥登录只需粘贴一行，格式不完整时显示提示', (tester) async {
    final state = AppState();
    await tester.pumpWidget(MaterialApp(home: LoginPage(state: state)));
    await tester.tap(find.byTooltip('使用登录凭证'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      '{"token":"test-token-1234"}',
    );
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();
    expect(find.text('请粘贴完整登录密钥，需同时包含 token 和 UID'), findsOneWidget);
    expect(state.token, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets('登录页展示奶娃喝水标题', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginPage(state: AppState())));

    expect(find.text('奶娃喝水'), findsOneWidget);
    expect(find.text('手机号'), findsOneWidget);
  });
}
