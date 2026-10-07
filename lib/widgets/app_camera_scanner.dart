import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../pages/camera_permissions_page.dart';
import 'app_scan_view.dart';

/// A cached tab must explicitly release the camera when it is hidden.
class AppCameraScanner extends StatefulWidget {
  const AppCameraScanner({
    required this.onDetect,
    this.active = true,
    super.key,
  });

  final void Function(BarcodeCapture) onDetect;
  final bool active;

  @override
  State<AppCameraScanner> createState() => _AppCameraScannerState();
}

class _AppCameraScannerState extends State<AppCameraScanner>
    with WidgetsBindingObserver {
  final _controller = MobileScannerController(autoStart: false);
  bool _foreground = true;
  bool _syncing = false;
  bool _syncAgain = false;
  bool _requesting = false;
  bool _allowRequest = true;
  bool _permissionPageOpen = false;
  String? _error;

  bool get _shouldRun => widget.active && _foreground && !_permissionPageOpen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didUpdateWidget(covariant AppCameraScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (widget.active) _allowRequest = true;
      unawaited(_sync());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A native permission prompt briefly makes the app inactive.
    if (_requesting && state == AppLifecycleState.inactive) return;
    _foreground = state == AppLifecycleState.resumed;
    unawaited(_sync());
  }

  Future<void> _sync() async {
    if (!mounted) return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _syncAgain = false;
        if (!_shouldRun) {
          await _controller.stop();
          continue;
        }
        if (_controller.value.isRunning) continue;
        setState(() => _error = null);
        var permission = await Permission.camera.status;
        if (!mounted) return;
        if (!permission.isGranted && _allowRequest && _shouldRun) {
          _allowRequest = false;
          _requesting = true;
          try {
            permission = await Permission.camera.request();
          } finally {
            _requesting = false;
          }
        }
        if (!mounted) return;
        if (!_shouldRun) continue;
        if (!permission.isGranted) {
          setState(
            () => _error = permission.isRestricted
                ? '相机使用受到系统限制\n请检查设备的权限设置'
                : '相机权限未开启\n请允许使用相机后继续扫码',
          );
          continue;
        }
        await _controller.start();
        if (!mounted) return;
        final scannerError = _controller.value.error;
        if (scannerError != null) _showScannerError(scannerError);
        // The tab or lifecycle may change while native startup is pending.
        if (!_shouldRun) _syncAgain = true;
      } while (mounted && _syncAgain);
    } catch (error) {
      if (mounted) {
        if (error is MobileScannerException) {
          _showScannerError(error);
        } else {
          setState(() => _error = '暂时无法打开相机\n请检查权限后重试');
        }
      }
    } finally {
      _syncing = false;
      if (mounted && _syncAgain) unawaited(_sync());
    }
  }

  void _showScannerError(MobileScannerException error) {
    setState(
      () => _error = error.errorCode == MobileScannerErrorCode.permissionDenied
          ? '相机权限未开启\n请允许使用相机后继续扫码'
          : '无法启动相机\n请确认相机可用且未被其他应用占用',
    );
  }

  void _retry() {
    _allowRequest = true;
    unawaited(_sync());
  }

  Future<void> _permissions() async {
    _permissionPageOpen = true;
    await _sync();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CameraPermissionsPage()),
    );
    if (!mounted) return;
    _permissionPageOpen = false;
    unawaited(_sync());
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Visibility(
        visible: _error == null,
        maintainState: true,
        child: MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            if (_shouldRun && _error == null) widget.onDetect(capture);
          },
          placeholderBuilder: (_) => const AppCameraPlaceholder(loading: true),
          errorBuilder: (_, error) => _errorView(),
        ),
      ),
      if (_error != null) _errorView(),
    ],
  );

  Widget _errorView() => AppCameraPlaceholder(
    message: _error ?? '无法启动相机\n请检查相机权限后重试',
    actions: [
      FilledButton(onPressed: _retry, child: const Text('重新打开相机')),
      TextButton(onPressed: _permissions, child: const Text('检查权限')),
    ],
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }
}
