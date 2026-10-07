enum ScanKind { water, shower, choose }

class ScanTarget {
  const ScanTarget(this.kind, this.id);
  final ScanKind kind;
  final String id;

  static ScanTarget? parse(String value, {int depth = 0}) {
    try {
      return _parse(value, depth: depth);
    } on FormatException {
      return null;
    }
  }

  static ScanTarget? _parse(String value, {required int depth}) {
    final raw = value.trim();
    if (raw.isEmpty || depth > 3) return null;
    if (RegExp(r'^\d{8,20}$').hasMatch(raw)) {
      return ScanTarget(ScanKind.choose, raw);
    }
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    final params = {
      for (final entry in uri.queryParameters.entries)
        entry.key.toLowerCase(): entry.value.trim(),
    };
    for (final key in ['url', 'qrcode', 'page']) {
      final nested = params[key];
      if (nested != null) {
        final result = parse(nested, depth: depth + 1);
        if (result != null) return result;
      }
    }
    final host = uri.host.toLowerCase();
    final shower =
        host == 'qiekj.com' ||
        host.endsWith('.qiekj.com') ||
        host == 'pangguai.com' ||
        host.endsWith('.pangguai.com');
    final water = host == 'ilife798.com' || host.endsWith('.ilife798.com');
    for (final key in ['sn', 'goodssn', 'devicesn']) {
      final id = params[key];
      if (id != null && RegExp(r'^[a-zA-Z0-9_-]{6,40}$').hasMatch(id)) {
        if (water && !RegExp(r'^\d{8,20}$').hasMatch(id)) return null;
        return ScanTarget(water ? ScanKind.water : ScanKind.shower, id);
      }
    }
    for (final key in ['did', 'deviceid', 'id']) {
      final id = params[key];
      if (id != null && RegExp(r'^\d{8,20}$').hasMatch(id)) {
        return ScanTarget(
          shower
              ? ScanKind.shower
              : (water || key != 'id')
              ? ScanKind.water
              : ScanKind.choose,
          id,
        );
      }
    }
    for (final part in uri.pathSegments.reversed) {
      if (RegExp(r'^\d{8,20}$').hasMatch(part)) {
        return ScanTarget(
          shower
              ? ScanKind.shower
              : water
              ? ScanKind.water
              : ScanKind.choose,
          part,
        );
      }
    }
    return null;
  }
}
