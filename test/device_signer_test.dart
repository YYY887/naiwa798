import 'package:flutter_test/flutter_test.dart';
import 'package:super798_flutter/core/device_signer.dart';

void main() {
  test(
    'Android device start signature uses sorted fields and a 30-second bucket',
    () {
      final signature = signDeviceRequest(
        params: {
          'did': '867926073268789',
          'upgrade': 'true',
          'ptype': '21',
          'rcp': 'false',
          'cnt': '1',
        },
        token: 'aaaaaaaaaaaaaaaaaaaaaaaa12345678',
        uid: '12dd12cbabcd9999',
        serverNowMs: 1790609080992,
      );

      expect(signature, 'e314fc71da0daaac08d666cd6c1ae816');
    },
  );
}
