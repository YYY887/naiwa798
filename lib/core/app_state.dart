import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/device.dart';
import 'api_client.dart';

class AppState extends ChangeNotifier {
  final secure = const FlutterSecureStorage();
  final api = ApiClient();
  String? token;
  Map<String, dynamic>? account;
  List<Device> devices = [];
  String selected = '', message = '';
  bool authLoading = false;
  bool actionLoading = false;
  bool isDrinking = false;
  bool stopPending = false;
  int selectedDeviceStatus = 99;
  int _idleStatusCount = 0;
  Timer? _statusTimer;
  bool dark = false;
  final Map<String, String> remarks = {};
  final List<Map<String, String>> drinkingRecords = [];
  Future<void> init() async {
    token = await secure.read(key: 'token');
    api.token = token;
    final p = await SharedPreferences.getInstance();
    dark = p.getBool('dark') ?? false;
    selected = p.getString('selected_device') ?? '';
    for (final key in p.getKeys().where(
      (key) => key.startsWith('device_remark_'),
    )) {
      remarks[key.substring('device_remark_'.length)] = p.getString(key) ?? '';
    }
    for (final key in p.getKeys().where(
      (key) => key.startsWith('drink_record_'),
    )) {
      final parts = (p.getString(key) ?? '').split('|');
      if (parts.length >= 2)
        drinkingRecords.add({'设备': parts[0], '时间': parts[1], 'key': key});
    }
    if (token != null) await refresh();
    notifyListeners();
  }

  Future<void> login(String v) async {
    if (v.trim().isEmpty) return;
    token = v.trim();
    api.token = token;
    await secure.write(key: 'token', value: token);
    await refresh();
    notifyListeners();
  }

  Future<String?> sendSmsCode(String phone, String captcha, String seed) async {
    authLoading = true;
    notifyListeners();
    try {
      final result = await api.post(
        'acc/login/code',
        body: {'s': seed, 'authCode': captcha, 'un': phone},
      );
      if (result['code'] == 0) return null;
      return '${result['msg'] ?? 'Captcha verification failed'}';
    } catch (_) {
      return 'Network error';
    } finally {
      authLoading = false;
      notifyListeners();
    }
  }

  Future<String?> loginBySms(String phone, String code) async {
    authLoading = true;
    notifyListeners();
    try {
      final result = await api.post(
        'acc/login',
        body: {
          'openCode': '',
          'authCode': code,
          'un': phone,
          'cid': 'drinkwaterapp123456789',
        },
      );
      final next = result['data']?['al']?['token']?.toString();
      if (result['code'] == 0 && next != null && next.isNotEmpty) {
        await login(next);
        return null;
      }
      return '${result['msg'] ?? 'Invalid verification code'}';
    } catch (_) {
      return 'Network error';
    } finally {
      authLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    token = null;
    api.token = null;
    devices = [];
    account = null;
    await secure.delete(key: 'token');
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('selected_device');
    selected = '';
    isDrinking = false;
    stopPending = false;
    _stopStatusPolling();
    notifyListeners();
  }

  Future<void> refresh() async {
    if (token == null) return;
    try {
      final d = await api.get('ui/app/master');
      account = Map<String, dynamic>.from(d['data']?['account'] ?? {});
      final a = (d['data']?['favos'] as List? ?? []);
      devices = a.map((v) {
        final x = Map<String, dynamic>.from(v);
        return Device(
          id: '${x['id']}',
          name: remarks['${x['id']}']?.isNotEmpty == true
              ? remarks['${x['id']}']!
              : '${x['name'] ?? '设备'}',
          online: x['status'] == 1,
          status: x['gene']?['status'] ?? 99,
          address: '${x['addr']?['detail'] ?? ''}',
        );
      }).toList();
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString('selected_device');
      if (devices.isNotEmpty) {
        selected = devices.any((device) => device.id == stored)
            ? stored!
            : devices.first.id;
        await preferences.setString('selected_device', selected);
        await checkDeviceStatus(recover: true);
      }
    } catch (_) {
      message = 'Loading failed';
    }
    notifyListeners();
  }

  Future<String?> drink() async {
    if (selected.isEmpty || actionLoading) return '请先选择设备';
    final start = !isDrinking;
    actionLoading = true;
    notifyListeners();
    try {
      final d = await api.get(
        start ? 'dev/start' : 'dev/end',
        params: start
            ? {'did': selected, 'upgrade': 'true', 'rcp': 'false', 'stype': '5'}
            : {'did': selected},
      );
      final succeeded = d['code'] == 0;
      message = succeeded
          ? (start ? 'Drinking' : 'Settled')
          : '${d['msg'] ?? '操作失败'}';
      if (succeeded && start) {
        isDrinking = true;
        stopPending = false;
        _idleStatusCount = 0;
        _startStatusPolling();
      }
      if (succeeded && !start) {
        // Keep checking until the device itself reports idle (status 99).
        stopPending = true;
        _idleStatusCount = 0;
        _startStatusPolling();
      }
      if (d['code'] == 0 && start) {
        final device = devices.where((item) => item.id == selected).firstOrNull;
        final now = DateTime.now();
        final time =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        final recordKey = 'drink_record_${now.microsecondsSinceEpoch}';
        drinkingRecords.insert(0, {
          '设备': device?.name ?? '设备',
          '时间': time,
          'key': recordKey,
        });
        final p = await SharedPreferences.getInstance();
        await p.setString(recordKey, '${device?.name ?? '设备'}|$time');
      }
      if (succeeded && !start) await refresh();
      return succeeded ? (start ? '已开始接水' : '已停止接水') : message;
    } catch (_) {
      message = '操作失败，请稍后重试';
      return message;
    } finally {
      actionLoading = false;
      notifyListeners();
    }
  }

  Future<String?> bind(String id) async {
    try {
      final result = await api.get(
        'dev/favo',
        params: {'did': id, 'remove': 'false'},
      );
      if (result['code'] != 0) return '${result['msg'] ?? '设备绑定失败'}';
    } catch (_) {
      return '网络异常，设备绑定失败';
    }
    await refresh();
    return null;
  }

  Future<void> remove(String id) async {
    await api.get('dev/favo', params: {'did': id, 'remove': 'true'});
    devices = devices.where((device) => device.id != id).toList();
    notifyListeners();
  }

  Future<void> removeDrinkingRecord(Map<String, String> record) async {
    final key = record['key'];
    if (key != null) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(key);
    }
    drinkingRecords.remove(record);
    notifyListeners();
  }

  Future<void> setRemark(String id, String value) async {
    final preferences = await SharedPreferences.getInstance();
    if (value.trim().isEmpty) {
      remarks.remove(id);
      await preferences.remove('device_remark_$id');
    } else {
      remarks[id] = value.trim();
      await preferences.setString('device_remark_$id', value.trim());
    }
    final index = devices.indexWhere((device) => device.id == id);
    if (index >= 0) {
      final old = devices[index];
      devices[index] = Device(
        id: old.id,
        name: value.trim().isEmpty ? old.name : value.trim(),
        online: old.online,
        status: old.status,
        address: old.address,
      );
    }
    notifyListeners();
  }

  Future<void> selectDevice(String id) async {
    selected = id;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('selected_device', id);
    await checkDeviceStatus(recover: true);
    notifyListeners();
  }

  Future<void> checkDeviceStatus({bool recover = false}) async {
    if (selected.isEmpty || token == null) return;
    try {
      final result = await api.get(
        'ui/app/dev/status',
        params: {'did': selected, 'more': 'true', 'promo': 'false'},
      );
      final gene = result['data']?['device']?['gene'];
      if (gene is! Map) return;
      final status = (gene['status'] as num?)?.toInt() ?? 99;
      selectedDeviceStatus = status;
      final index = devices.indexWhere((device) => device.id == selected);
      if (index >= 0) {
        final device = devices[index];
        devices[index] = Device(
          id: device.id,
          name: device.name,
          online: device.online,
          status: status,
          address: device.address,
        );
      }
      if (recover && status != 99) {
        isDrinking = true;
        message = 'Drinking';
        _startStatusPolling();
      }
      if (status != 99) {
        _idleStatusCount = 0;
      } else if (isDrinking && !recover) {
        _idleStatusCount += 1;
        if (stopPending || _idleStatusCount >= 3) {
          isDrinking = false;
          stopPending = false;
          message = 'Settled';
          _stopStatusPolling();
        }
      }
      notifyListeners();
    } catch (_) {
      // Keep the last known device state when the status endpoint is transient.
    }
  }

  void _startStatusPolling() {
    _stopStatusPolling();
    checkDeviceStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!isDrinking) {
        _stopStatusPolling();
        return;
      }
      checkDeviceStatus();
    });
  }

  void _stopStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  Future<void> setDark(bool v) async {
    dark = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('dark', v);
    notifyListeners();
  }
}
