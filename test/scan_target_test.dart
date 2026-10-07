import 'package:flutter_test/flutter_test.dart';
import 'package:super798_flutter/core/scan_target.dart';

void main() {
  test('water and shower URLs route to their matching service', () {
    final water = ScanTarget.parse('https://i.ilife798.com/device/12345678');
    expect(water?.kind, ScanKind.water);
    expect(water?.id, '12345678');
    final shower = ScanTarget.parse('https://www.qiekj.com/qr?SN=987654321012');
    expect(shower?.kind, ScanKind.shower);
    expect(shower?.id, '987654321012');
    expect(
      ScanTarget.parse('https://example.com/?deviceId=12345678')?.kind,
      ScanKind.water,
    );
  });

  test(
    'embedded Alipay page and encoded redirect retain shower serial number',
    () {
      final code = Uri(
        scheme: 'alipays',
        host: 'platformapi',
        path: '/startapp',
        queryParameters: {'page': 'pages/scan?goodsSN=SN12345678'},
      ).toString();
      expect(ScanTarget.parse(code)?.kind, ScanKind.shower);
      expect(ScanTarget.parse(code)?.id, 'SN12345678');
    },
  );

  test('number-only codes ask for the service without guessing', () {
    expect(ScanTarget.parse('12345678')?.kind, ScanKind.choose);
    expect(
      ScanTarget.parse('https://example.com/12345678')?.kind,
      ScanKind.choose,
    );
    expect(
      ScanTarget.parse('https://not-ilife798.com/?id=12345678')?.kind,
      ScanKind.choose,
    );
  });

  test('unrelated, malformed and oversized codes are ignored', () {
    for (final code in [
      '',
      'hello 12345678',
      'https://example.com/?price=12345678',
      '123456789012345678901',
      'https://example.com/?SN=bad%20value',
    ]) {
      expect(ScanTarget.parse(code), isNull, reason: code);
    }
  });
}
