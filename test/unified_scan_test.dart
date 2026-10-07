import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:super798_flutter/core/app_state.dart';
import 'package:super798_flutter/core/pangguai_client.dart';
import 'package:super798_flutter/pages/unified_scan_page.dart';
import 'package:super798_flutter/widgets/app_camera_scanner.dart';

class _State extends AppState {
  String? bound;
  @override
  Future<String?> bind(String id) async {
    bound = id;
    return null;
  }
}

class _Shower extends PangGuaiClient {
  String? scanned, opened;
  @override
  Future<String> lookupGoodsId(String serialNumber) async {
    scanned = serialNumber;
    return 'goods-123';
  }

  @override
  Future<void> openAlipayShower(String goodsId) async {
    opened = goodsId;
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = binding.defaultBinaryMessenger;
  setUp(() {
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => call.method == 'requestPermissions' ? {1: 0} : 0,
    );
    for (final name in ['method', 'event', 'deviceOrientation']) {
      messenger.setMockMethodCallHandler(
        MethodChannel('dev.steenbakker.mobile_scanner/scanner/$name'),
        (_) async => null,
      );
    }
  });

  Future<void> open(WidgetTester tester, _State state, _Shower shower) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => UnifiedScanPage(state: state, client: shower),
                ),
              ),
              child: const Text('打开扫码'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开扫码'));
    await tester.pumpAndSettle();
  }

  void scan(WidgetTester tester, String value) => tester
      .widget<AppCameraScanner>(find.byType(AppCameraScanner))
      .onDetect(BarcodeCapture(barcodes: [Barcode(rawValue: value)]));

  testWidgets('one scanner binds water codes and returns to the device page', (
    tester,
  ) async {
    final state = _State();
    final shower = _Shower();
    await open(tester, state, shower);
    scan(tester, 'https://i.ilife798.com/device/12345678');
    await tester.pumpAndSettle();
    expect(state.bound, '12345678');
    expect(shower.opened, isNull);
    expect(find.byType(UnifiedScanPage), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });

  testWidgets(
    'the same scanner routes shower codes to Alipay without binding',
    (tester) async {
      final state = _State();
      final shower = _Shower();
      await open(tester, state, shower);
      scan(tester, 'https://www.qiekj.com/scan?SN=987654321012');
      await tester.pumpAndSettle();
      expect(state.bound, isNull);
      expect(shower.scanned, '987654321012');
      expect(shower.opened, 'goods-123');
      await tester.scrollUntilVisible(
        find.text('已打开洗澡服务，也可以继续扫描其他设备'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('已打开洗澡服务，也可以继续扫描其他设备'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );

  testWidgets('ambiguous numeric code waits for a service choice', (
    tester,
  ) async {
    final state = _State();
    final shower = _Shower();
    await open(tester, state, shower);
    scan(tester, '12345678');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('请选择设备类型'), findsOneWidget);
    expect(state.bound, isNull);
    expect(shower.opened, isNull);
    await tester.tap(find.text('胖乖洗澡'));
    await tester.pumpAndSettle();
    expect(shower.scanned, '12345678');
    expect(state.bound, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    state.dispose();
  });
}
