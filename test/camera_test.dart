import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:super798_flutter/pages/camera_permissions_page.dart';
import 'package:super798_flutter/widgets/app_camera_scanner.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
  const scanner = MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/method',
  );
  final messenger = binding.defaultBinaryMessenger;
  var permission = 1;
  var requestResult = 1;
  var starts = 0;
  var stops = 0;
  var requests = 0;
  var settings = 0;
  Completer<Map<int, int>>? pendingRequest;

  setUp(() {
    permission = requestResult = 1;
    starts = stops = requests = settings = 0;
    pendingRequest = null;
    messenger.setMockMethodCallHandler(permissions, (call) async {
      switch (call.method) {
        case 'checkPermissionStatus':
          return permission;
        case 'requestPermissions':
          requests++;
          if (pendingRequest != null) return pendingRequest!.future;
          permission = requestResult;
          return {1: permission};
        case 'openAppSettings':
          settings++;
          return true;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(scanner, (call) async {
      switch (call.method) {
        case 'state':
          return permission == 1 ? 1 : 2;
        case 'start':
          starts++;
          return {
            'textureId': 1,
            'size': {'width': 640.0, 'height': 480.0},
            'cameraDirection': 1,
            'handlesCropAndRotation': true,
            'naturalDeviceOrientation': 'PORTRAIT_UP',
            'sensorOrientation': 90,
          };
        case 'stop':
          // MobileScanner forces a debug stop while attaching its widget.
          if ((call.arguments as Map?)?['force'] != true) stops++;
      }
      return null;
    });
    for (final name in ['event', 'deviceOrientation']) {
      messenger.setMockMethodCallHandler(
        MethodChannel('dev.steenbakker.mobile_scanner/scanner/$name'),
        (_) async => null,
      );
    }
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(permissions, null);
    messenger.setMockMethodCallHandler(scanner, null);
    for (final name in ['event', 'deviceOrientation']) {
      messenger.setMockMethodCallHandler(
        MethodChannel('dev.steenbakker.mobile_scanner/scanner/$name'),
        null,
      );
    }
  });

  Future<void> showScanner(WidgetTester tester, {bool active = true}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              height: 320,
              child: AppCameraScanner(active: active, onDetect: (_) {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (active) {
      final state = tester
          .widget<MobileScanner>(
            find.byType(MobileScanner, skipOffstage: false),
          )
          .controller!
          .value;
      if (permission == 1) {
        expect(state.error, isNull, reason: state.error.toString());
        expect(state.isRunning, isTrue);
      }
    }
  }

  testWidgets(
    'hidden tab leaves camera idle; visibility and resume control preview',
    (tester) async {
      await showScanner(tester, active: false);
      expect(starts, 0);
      expect(requests, 0);
      await showScanner(tester);
      expect(starts, 1);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(stops, 1);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(starts, 2);
      await showScanner(tester, active: false);
      expect(stops, 2);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(starts, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('denied permission exposes retry and a permission check', (
    tester,
  ) async {
    permission = requestResult = 0;
    await showScanner(tester);
    expect(starts, 0);
    expect(requests, 1);
    expect(find.text('相机权限未开启\n请允许使用相机后继续扫码'), findsOneWidget);
    expect(find.text('检查权限'), findsOneWidget);
    requestResult = 1;
    await tester.tap(find.text('重新打开相机'));
    await tester.pumpAndSettle();
    expect(starts, 1);
    expect(find.text('重新打开相机'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'switching away while permission is pending never starts camera',
    (tester) async {
      permission = 0;
      pendingRequest = Completer<Map<int, int>>();
      await showScanner(tester);
      expect(requests, 1);
      await showScanner(tester, active: false);
      permission = 1;
      pendingRequest!.complete({1: 1});
      await tester.pumpAndSettle();
      expect(starts, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'permission check offers settings after permanent denial and refreshes on return',
    (tester) async {
      permission = 0;
      requestResult = 4;
      await tester.pumpWidget(const MaterialApp(home: CameraPermissionsPage()));
      await tester.pumpAndSettle();
      expect(find.text('未授权'), findsOneWidget);
      await tester.tap(find.text('允许使用相机'));
      await tester.pumpAndSettle();
      expect(find.text('需要在设置中开启'), findsOneWidget);
      await tester.tap(find.text('前往设置开启'));
      await tester.pumpAndSettle();
      expect(settings, 1);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      permission = 1;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('已授权'), findsOneWidget);
      expect(requests, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
