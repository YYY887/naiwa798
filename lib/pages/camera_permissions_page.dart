import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/app_palette.dart';
import '../widgets/app_ui.dart';

class CameraPermissionsPage extends StatefulWidget {
  const CameraPermissionsPage({super.key});

  @override
  State<CameraPermissionsPage> createState() => _CameraPermissionsPageState();
}

class _CameraPermissionsPageState extends State<CameraPermissionsPage>
    with WidgetsBindingObserver {
  PermissionStatus? _status;
  bool _working = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_working) _check();
  }

  Future<void> _check({bool request = false}) async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final status = request
          ? await Permission.camera.request()
          : await Permission.camera.status;
      if (mounted) setState(() => _status = status);
    } catch (_) {
      if (mounted) {
        setState(() => _error = '暂时无法检查相机权限，请重试');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _openSettings() async {
    try {
      final opened = !kIsWeb && await openAppSettings();
      if (!opened && mounted) {
        setState(
          () => _error = kIsWeb
              ? '请在浏览器的地址栏或网站设置中，允许此网站使用相机，然后重新检查'
              : '无法打开系统设置，请手动进入本应用的权限设置，允许使用相机',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = '请在系统设置中手动开启本应用的相机权限');
    }
  }

  String get _label {
    if (_status == null) return _error == null ? '正在检查…' : '检查失败';
    if (_status!.isGranted) return '已授权';
    if (_status!.isRestricted) return '受到系统限制';
    if (_status!.isPermanentlyDenied) return '需要在设置中开启';
    return '未授权';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors(dark);
    final granted = _status?.isGranted == true;
    final needsSettings =
        _status?.isPermanentlyDenied == true || _status?.isRestricted == true;
    return AppPage(
      dark: dark,
      children: [
        const AppHeader(title: '权限检查', subtitle: '让扫码顺畅起来', back: true),
        AppSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppIconBadge(icon: Icons.camera_alt_outlined),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '相机权限',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _label,
                          style: TextStyle(
                            color: granted ? colors.accent : colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (granted)
                    Icon(Icons.check_circle_rounded, color: colors.accent),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                granted
                    ? '相机权限已开启，可以返回首页使用扫一扫。'
                    : '扫码添加饮水设备和胖乖洗澡，需要使用相机识别二维码。请允许本应用使用相机。',
                style: TextStyle(color: colors.muted, height: 1.7),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: colors.danger, height: 1.6),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _working
                      ? null
                      : () => needsSettings
                            ? _openSettings()
                            : _check(request: !granted),
                  icon: _working
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          needsSettings
                              ? Icons.settings_outlined
                              : granted
                              ? Icons.refresh_rounded
                              : Icons.camera_alt_outlined,
                        ),
                  label: Text(
                    needsSettings
                        ? '前往设置开启'
                        : granted
                        ? '重新检查'
                        : '允许使用相机',
                  ),
                ),
              ),
              if (!needsSettings && !granted)
                Center(
                  child: TextButton(
                    onPressed: _working ? null : _openSettings,
                    child: Text(kIsWeb ? '如何开启浏览器权限' : '前往系统设置'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '从系统设置返回后会自动更新权限状态。',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.muted, fontSize: 12),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
