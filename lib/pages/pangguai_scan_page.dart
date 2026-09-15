import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/pangguai_client.dart';

class PangGuaiScanPage extends StatefulWidget {
  const PangGuaiScanPage({this.embedded = false, super.key});

  final bool embedded;

  @override
  State<PangGuaiScanPage> createState() => _PangGuaiScanPageState();
}

class _PangGuaiScanPageState extends State<PangGuaiScanPage> {
  final _scanner = MobileScannerController();
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
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, widget.embedded ? 82 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '胖乖洗澡',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              '请确保已安装支付宝。扫码后将跳转至支付宝胖乖小程序的机器启动页，减少无关页面干扰。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xffc7c7c7),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _status,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xff8f8f8f), fontSize: 12),
            ),
            Expanded(
              child: Center(
                child: Semantics(
                  label: _status,
                  child: SizedBox(
                    width: 236,
                    height: 236,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: _scanner,
                            onDetect: _onDetect,
                          ),
                          IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                          ),
                          if (_busy)
                            const ColoredBox(
                              color: Color(0x66000000),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (widget.embedded) {
      return ColoredBox(color: Colors.black, child: content);
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('胖乖洗澡'),
      ),
      body: content,
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }
}
