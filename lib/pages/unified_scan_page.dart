import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/app_state.dart';
import '../core/pangguai_client.dart';
import '../core/scan_target.dart';
import '../widgets/app_camera_scanner.dart';
import '../widgets/app_scan_view.dart';

class UnifiedScanPage extends StatefulWidget {
  const UnifiedScanPage({required this.state, this.client, super.key});
  final AppState state;
  final PangGuaiClient? client;

  @override
  State<UnifiedScanPage> createState() => _UnifiedScanPageState();
}

class _UnifiedScanPageState extends State<UnifiedScanPage> {
  late final _client = widget.client ?? PangGuaiClient();
  bool _busy = false;
  bool _finished = false;
  String _status = '扫描饮水机或胖乖洗澡二维码，自动识别并继续';
  String? _lastValue;
  DateTime? _lastTime;

  Future<ScanKind?> _choose() => showModalBottomSheet<ScanKind>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('请选择设备类型', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('这个二维码只有编号，选择后即可继续'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: const Text('饮水设备'),
              subtitle: const Text('添加到我的设备'),
              onTap: () => Navigator.pop(sheetContext, ScanKind.water),
            ),
            ListTile(
              leading: const Icon(Icons.shower_outlined),
              title: const Text('胖乖洗澡'),
              subtitle: const Text('打开支付宝洗澡服务'),
              onTap: () => Navigator.pop(sheetContext, ScanKind.shower),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _detect(BarcodeCapture capture) async {
    if (_busy || _finished) return;
    final raw = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (raw == null) return;
    final now = DateTime.now();
    if (_lastValue == raw &&
        _lastTime != null &&
        now.difference(_lastTime!) < const Duration(seconds: 3)) {
      return;
    }
    _lastValue = raw;
    _lastTime = now;
    final target = ScanTarget.parse(raw);
    if (target == null) {
      setState(() => _status = '未识别到设备信息，请扫描饮水机或胖乖洗澡的二维码');
      return;
    }
    setState(() => _busy = true);
    try {
      final kind = target.kind == ScanKind.choose
          ? await _choose()
          : target.kind;
      if (!mounted || kind == null) return;
      if (kind == ScanKind.water) {
        setState(() => _status = '正在添加饮水设备…');
        final error = await widget.state.bind(target.id);
        if (!mounted) return;
        if (error != null) throw StateError(error);
        _finished = true;
        Navigator.pop(context);
      } else {
        setState(() => _status = '正在识别洗澡设备…');
        final goodsId = await _client.lookupGoodsId(target.id);
        if (!mounted) return;
        setState(() => _status = '正在打开支付宝…');
        await _client.openAlipayShower(goodsId);
        if (mounted) setState(() => _status = '已打开洗澡服务，也可以继续扫描其他设备');
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _status = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppScanView(
    title: '扫一扫',
    subtitle: '喝水、洗澡，一个入口就够了',
    status: _status,
    busy: _busy,
    camera: AppCameraScanner(active: !_busy && !_finished, onDetect: _detect),
  );
}
