import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/pangguai_client.dart';
import '../widgets/app_scan_view.dart';
import '../widgets/app_camera_scanner.dart';

class PangGuaiScanPage extends StatefulWidget {
  const PangGuaiScanPage({
    this.embedded = false,
    this.active = true,
    super.key,
  });

  final bool embedded;
  final bool active;

  @override
  State<PangGuaiScanPage> createState() => _PangGuaiScanPageState();
}

class _PangGuaiScanPageState extends State<PangGuaiScanPage> {
  final _client = PangGuaiClient();
  String _status = '请将胖乖生活洗澡二维码放入框内';
  bool _busy = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue ?? '';
    final serialNumber = _client.extractSerialNumber(rawValue);
    if (serialNumber.isEmpty) {
      setState(() => _status = '未识别到设备编号，请调整角度后重试');
      return;
    }

    setState(() {
      _busy = true;
      _status = '正在识别设备…';
    });
    try {
      final goodsId = await _client.lookupGoodsId(serialNumber);
      if (!mounted) return;
      setState(() => _status = '正在打开支付宝…');
      await _client.openAlipayShower(goodsId);
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
    title: '胖乖洗澡',
    subtitle: '扫一下，去享受清爽时刻',
    status: _busy ? _status : '$_status。请确保已安装支付宝。',
    embedded: widget.embedded,
    busy: _busy,
    camera: AppCameraScanner(
      active: widget.active && !_busy,
      onDetect: _onDetect,
    ),
  );
}
