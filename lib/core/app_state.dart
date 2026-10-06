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
  int? lastActionCode;
  bool isDrinking = false;
  bool stopPending = false;
  bool statusPollingEnabled = false;
  int selectedDeviceStatus = -1;
  int _idleStatusCount = 0;
  bool _hasSeenRunningStatus = false;
  Timer? _statusTimer;
  Future<void>? _statusRequest;
  bool dark = false;
  final Map<String, String> remarks = {};
  final List<Map<String, String>> drinkingRecords = [];
  Future<void> init() async {
    token = await secure.read(key: 'token');
    api.token = token;
    api.uid = await secure.read(key: 'uid');
    final p = await SharedPreferences.getInstance();
    dark = p.getBool('dark_mode') ?? p.getBool('dark') ?? false;
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

  Future<void> login(String v, {String? uid}) async {
    if (v.trim().isEmpty) return;
    final newToken = v.trim();
    final tokenChanged = token != newToken;
    token = newToken;
    api.token = token;
    if (uid != null && uid.trim().length >= 8) {
      api.uid = uid.trim();
      await secure.write(key: 'uid', value: api.uid);
    } else if (tokenChanged) {
      api.uid = null;
      await secure.delete(key: 'uid');
    }
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
      final uid = result['data']?['al']?['uid']?.toString();
      if (result['code'] == 0 && next != null && next.isNotEmpty) {
        await login(next, uid: uid);
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
    api.uid = null;
    devices = [];
    account = null;
    await secure.delete(key: 'token');
    await secure.delete(key: 'uid');
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('selected_device');
    selected = '';
    isDrinking = false;
    stopPending = false;
    _hasSeenRunningStatus = false;
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
        final geneStatus = (x['gene']?['status'] as num?)?.toInt() ?? -1;
        return Device(
          id: '${x['id']}',
          name: remarks['${x['id']}']?.isNotEmpty == true
              ? remarks['${x['id']}']!
              : '${x['name'] ?? '设备'}',
          online: x['status'] == 1,
          status: geneStatus,
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
    lastActionCode = null;
    if (selected.isEmpty) return '请先选择设备';
    final selectedDevice = devices
        .where((device) => device.id == selected)
        .firstOrNull;
    if (selectedDevice == null) return '请先选择设备';
    if (!selectedDevice.online) return '设备离线，无法操作';
    if (actionLoading) return '正在操作，请稍候';
    final start = !isDrinking;
    actionLoading = true;
    notifyListeners();
    try {
      final d = await api.signedDeviceGet(
        start ? 'dev/start' : 'dev/end',
        params: start
            ? {
                'did': selected,
                'upgrade': 'true',
                'ptype': '21',
                'rcp': 'false',
                'cnt': '1',
              }
            : {'did': selected, 'rcp': 'false'},
      );
      lastActionCode = (d['code'] as num?)?.toInt();
      final succeeded = d['code'] == 0;
      message = succeeded
          ? (start ? 'Drinking' : 'Settled')
          : '${d['msg'] ?? '操作失败'}';
      if (lastActionCode == -2) {
        final actionMessage = message;
        await checkDeviceStatus(recover: true);
        return actionMessage;
      }
      if (succeeded && start) {
        isDrinking = true;
        stopPending = false;
        _idleStatusCount = 0;
        _hasSeenRunningStatus = false;
        _startStatusPolling();
      }
      if (succeeded && !start) {
        // Keep checking until the device reports an inactive status.
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
    } on StateError catch (error) {
      message = error.message.toString();
      return message;
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
    _hasSeenRunningStatus = false;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('selected_device', id);
    await checkDeviceStatus(recover: true);
    notifyListeners();
  }

  Future<void> checkDeviceStatus({bool recover = false}) async {
    while (_statusRequest != null) {
      if (!recover) return;
      await _statusRequest;
    }
    final request = _fetchDeviceStatus(recover: recover);
    _statusRequest = request;
    try {
      await request;
    } finally {
      if (identical(_statusRequest, request)) _statusRequest = null;
    }
  }

  Future<void> _fetchDeviceStatus({required bool recover}) async {
    if (selected.isEmpty || token == null) return;
    final queriedDeviceId = selected;
    try {
      final result = await api.get(
        'ui/app/dev/status',
        params: {'did': queriedDeviceId, 'more': '0'},
      );
      if (selected != queriedDeviceId) return;
      if (result['code'] != 0) {
        selectedDeviceStatus = -1;
        final index = devices.indexWhere((device) => device.id == selected);
        if (index >= 0) {
          final device = devices[index];
          devices[index] = Device(
            id: device.id,
            name: device.name,
            online: device.online,
            status: -1,
            address: device.address,
          );
        }
        notifyListeners();
        return;
      }
      final detail = result['data']?['device'];
      final gene = detail is Map ? detail['gene'] : null;
      if (gene is! Map) return;
      final status = (gene['status'] as num?)?.toInt() ?? -1;
      final onlineStatus = detail['status'];
      selectedDeviceStatus = status;
      final index = devices.indexWhere((device) => device.id == selected);
      final online = onlineStatus is num
          ? onlineStatus.toInt() == 1
          : index >= 0 && devices[index].online;
      final active =
          online &&
          (status == 1 || status == 10 || status == 20 || status == 30);
      if (index >= 0) {
        final device = devices[index];
        devices[index] = Device(
          id: device.id,
          name: device.name,
          online: online,
          status: status,
          address: device.address,
        );
      }
      if (recover) {
        isDrinking = active;
        stopPending = false;
        _idleStatusCount = 0;
        _hasSeenRunningStatus = active;
        if (active) {
          message = 'Drinking';
          _startStatusPolling();
        } else {
          _stopStatusPolling();
        }
      } else if (active) {
        _idleStatusCount = 0;
        _hasSeenRunningStatus = true;
        if (!isDrinking) {
          isDrinking = true;
          stopPending = false;
          message = 'Drinking';
          _startStatusPolling();
        }
      } else if (isDrinking) {
        _idleStatusCount += 1;
        if (stopPending || _hasSeenRunningStatus || _idleStatusCount >= 3) {
          isDrinking = false;
          stopPending = false;
          _hasSeenRunningStatus = false;
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
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!statusPollingEnabled) return;
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
    await p.setBool('dark_mode', v);
    notifyListeners();
  }
}
