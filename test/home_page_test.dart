import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super798_flutter/core/app_state.dart';
import 'package:super798_flutter/models/device.dart';
import 'package:super798_flutter/pages/home_page.dart';
import 'package:super798_flutter/pages/profile_page.dart';
import 'package:super798_flutter/models/buddy_character.dart';
import 'package:super798_flutter/widgets/water_buddy.dart';

class _TestAppState extends AppState {
  void publish() => notifyListeners();
}

const _device = Device(
  id: '12345678',
  name: '测试饮水机',
  online: true,
  status: 99,
  address: '测试地址',
);

Future<void> _showHome(WidgetTester tester, AppState state) async {
  SharedPreferences.setMockInitialValues({'seen_welcome_message': true});
  await tester.pumpWidget(
    AnimatedBuilder(
      animation: state,
      builder: (context, child) => MaterialApp(
        builder: (context, child) => Material(
          type: MaterialType.transparency,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: HomePage(state: state, darkMode: state.dark),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'long pressing the raised character changes and saves the buddy',
    (tester) async {
      final state = _TestAppState()
        ..selected = _device.id
        ..devices = [_device];
      await _showHome(tester, state);
      await tester.longPressAt(
        tester.getTopLeft(find.byType(WaterBuddy)) + const Offset(55, 24),
      );
      await tester.pumpAndSettle();
      expect(find.text('选择你的喝水搭子'), findsOneWidget);
      await tester.tap(find.text('活力女生'));
      await tester.pumpAndSettle();
      expect(state.buddy, BuddyCharacter.girl);
      expect(
        tester.widget<WaterBuddy>(find.byType(WaterBuddy)).character,
        BuddyCharacter.girl,
      );
      expect(
        (await SharedPreferences.getInstance()).getString('buddy_character'),
        'girl',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );

  testWidgets('middle tab opens embedded records without a back button', (
    tester,
  ) async {
    final state = _TestAppState();
    await _showHome(tester, state);
    await tester.tap(find.text('记录').first);
    await tester.pumpAndSettle();
    expect(find.text('喝水记录'), findsOneWidget);
    expect(find.byTooltip('返回'), findsNothing);
    expect(find.text('洗漱'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
  testWidgets('copying credentials on the actual home shows confirmation', (
    tester,
  ) async {
    final state = _TestAppState()..token = 'test-token-1234';
    state.api.uid = 'test-uid-1234';
    String? copied;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await _showHome(tester, state);
    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.copy_outlined));
    await tester.pumpAndSettle();
    expect(copied, '{"token":"test-token-1234","uid":"test-uid-1234"}');
    expect(find.text('登录密钥已复制，包含 token 和 UID'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets('cached device page reflects start and stop state changes', (
    tester,
  ) async {
    final state = _TestAppState()
      ..selected = _device.id
      ..devices = [_device];
    await _showHome(tester, state);
    final home = tester.state(find.byType(HomePage));
    expect(find.text('开始接水'), findsOneWidget);

    state.actionLoading = true;
    state.publish();
    await tester.pump();
    expect(find.text('正在启动中…'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );

    state
      ..actionLoading = false
      ..isDrinking = true;
    state.publish();
    await tester.pump();
    expect(find.text('停止接水'), findsOneWidget);
    expect(find.text('进行中'), findsNWidgets(2));
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );

    state.stopPending = true;
    state.publish();
    await tester.pump();
    expect(find.text('正在停止中…'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );

    state
      ..isDrinking = false
      ..stopPending = false;
    state.publish();
    await tester.pump();
    expect(find.text('开始接水'), findsOneWidget);
    expect(find.text('待机'), findsNWidgets(2));
    expect(tester.state(find.byType(HomePage)), same(home));

    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets('cached pages reflect refreshed device and account data', (
    tester,
  ) async {
    final state = _TestAppState();
    await _showHome(tester, state);
    expect(find.text('暂无设备，请扫码添加'), findsOneWidget);

    state
      ..selected = _device.id
      ..devices = [_device]
      ..account = {'name': '刷新后的用户'};
    state.publish();
    await tester.pump();
    expect(find.text('暂无设备，请扫码添加'), findsNothing);
    expect(find.text('测试饮水机'), findsNWidgets(2));
    expect(find.text('刷新后的用户'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ProfilePage, skipOffstage: false),
        matching: find.text('刷新后的用户', skipOffstage: false),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
}
