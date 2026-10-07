import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super798_flutter/core/api_client.dart';
import 'package:super798_flutter/core/app_state.dart';
import 'package:super798_flutter/core/login_credentials.dart';
import 'package:super798_flutter/models/device.dart';

class _FakeApi extends ApiClient {
  bool running = false;
  int actionCode = 0;
  final actions = <String>[];

  @override
  Future<Map<String, dynamic>> signedDeviceGet(
    String path, {
    required Map<String, String> params,
  }) async {
    actions.add(path);
    if (actionCode == 0) running = path == 'dev/start';
    return {'code': actionCode, 'msg': '测试响应'};
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? params,
    Map<String, String>? headers,
  }) async => {
    'code': 0,
    'data': path == 'ui/app/master'
        ? {
            'account': {'uid': 'test-uid-1234'},
            'favos': [
              {
                'id': '12345678',
                'status': 1,
                'gene': {'status': running ? 1 : 99},
              },
            ],
          }
        : {
            'device': {
              'status': 1,
              'gene': {'status': running ? 1 : 99},
            },
          },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('a successful start adds one record; stopping adds none', () async {
    final api = _FakeApi();
    final state = AppState(api: api)
      ..token = 'test-token-1234'
      ..selected = '12345678'
      ..devices = [
        const Device(
          id: '12345678',
          name: '测试设备',
          online: true,
          status: 99,
          address: '',
        ),
      ];
    addTearDown(state.dispose);
    expect(await state.drink(), '已开始接水');
    expect(state.drinkingRecords, hasLength(1));
    final record = Map<String, String>.from(state.drinkingRecords.single);
    expect(await state.drink(), '已停止接水');
    expect(api.actions, ['dev/start', 'dev/end']);
    expect(state.drinkingRecords, [record]);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getKeys().where((key) => key.startsWith('drink_record_')),
      hasLength(1),
    );
  });

  test('a failed start does not create a drinking record', () async {
    final state = AppState(api: _FakeApi()..actionCode = -1)
      ..token = 'test-token-1234'
      ..selected = '12345678'
      ..devices = [
        const Device(
          id: '12345678',
          name: '测试设备',
          online: true,
          status: 99,
          address: '',
        ),
      ];
    addTearDown(state.dispose);
    await state.drink();
    expect(state.drinkingRecords, isEmpty);
  });

  test(
    'copied credentials can be pasted to restore both token and UID',
    () async {
      final source = AppState(api: _FakeApi()..uid = 'test-uid-1234')
        ..token = 'test-token-1234';
      final target = AppState(api: _FakeApi());
      addTearDown(source.dispose);
      addTearDown(target.dispose);
      final text = await source.exportLoginCredentials();
      expect(text.contains('\n'), isFalse);
      expect(await target.loginWithCredentials(text), isNull);
      expect(target.token, source.token);
      expect(target.api.uid, source.api.uid);
      expect(await target.secure.read(key: 'token'), source.token);
      expect(await target.secure.read(key: 'uid'), source.api.uid);
      expect(target.authLoading, isFalse);
    },
  );

  test('copy fetches a missing UID from the account endpoint', () async {
    final state = AppState(api: _FakeApi())..token = 'test-token-1234';
    addTearDown(state.dispose);
    final credentials = LoginCredentials.parse(
      await state.exportLoginCredentials(),
    );
    expect(credentials.uid, 'test-uid-1234');
    expect(credentials.token, state.token);
  });

  test(
    'incomplete or malformed credentials leave the session unchanged',
    () async {
      final state = AppState()..token = 'existing-token';
      addTearDown(state.dispose);
      for (final input in [
        '',
        'plain-token',
        '{"token":"test-token-1234"}',
        '{"token":"a","uid":"b"}',
      ]) {
        expect(await state.loginWithCredentials(input), isNotNull);
        expect(state.token, 'existing-token');
      }
    },
  );
}
