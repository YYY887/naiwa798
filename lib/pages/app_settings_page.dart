import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/app_palette.dart';
import '../core/update_service.dart';
import '../widgets/update_announcement.dart';
import '../widgets/app_version_label.dart';
import '../widgets/app_ui.dart';
import '../widgets/buddy_picker.dart';
import 'about_page.dart';
import 'camera_permissions_page.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({required this.state, super.key});
  final AppState state;
  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool _checkingUpdate = false;
  final _updateService = UpdateService();

  void _dialog(String title, String content) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('知道了'),
        ),
      ],
    ),
  );

  Future<void> _checkUpdate() async {
    setState(() => _checkingUpdate = true);
    try {
      final update = await _updateService.checkForUpdate();
      if (!mounted) return;
      if (update == null) {
        _dialog('检查更新', '当前已是最新版本');
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('发现新版本 v${update.version}'),
          content: UpdateAnnouncement(notes: update.releaseNotes),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('暂不更新'),
            ),
            FilledButton(
              onPressed: () async {
                final opened = await launchUrl(
                  update.downloadUrl,
                  mode: LaunchMode.externalApplication,
                );
                if (!opened) {
                  await launchUrl(
                    update.releaseUrl,
                    mode: LaunchMode.externalApplication,
                  );
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('立即更新'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) _dialog('检查更新', '暂时无法连接更新服务，请稍后重试');
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, child) => AppPage(
      dark: widget.state.dark,
      children: [
        const AppHeader(title: '应用设置', subtitle: '让每一次使用，都更合心意', back: true),
        const AppSectionHeading('外观'),
        AppSurface(
          padding: EdgeInsets.zero,
          child: AppMenuRow(
            icon: Icons.dark_mode_outlined,
            title: '暗色模式',
            subtitle: '夜晚也有舒适的阅读体验',
            onTap: () => widget.state.setDark(!widget.state.dark),
            trailing: Switch.adaptive(
              value: widget.state.dark,
              onChanged: widget.state.setDark,
              activeTrackColor: AppPalette.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        AppSurface(
          padding: EdgeInsets.zero,
          child: AppMenuRow(
            icon: Icons.face_retouching_natural_outlined,
            title: '首页角色',
            subtitle: '${widget.state.buddy.label} · 长按首页人物也可更换',
            onTap: () => showBuddyPicker(context, widget.state),
          ),
        ),
        const AppSectionHeading('权限与功能'),
        AppSurface(
          padding: EdgeInsets.zero,
          child: AppMenuRow(
            icon: Icons.camera_alt_outlined,
            title: '权限检查',
            subtitle: '查看相机权限，解决扫码无法打开的问题',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const CameraPermissionsPage(),
              ),
            ),
          ),
        ),
        const AppSectionHeading('关于应用'),
        AppSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              AppMenuRow(
                icon: Icons.system_update_outlined,
                title: '检查更新',
                subtitleWidget: const AppVersionLabel(),
                trailing: _checkingUpdate
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _checkingUpdate ? null : _checkUpdate,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 72, right: 18),
                child: Divider(),
              ),
              AppMenuRow(
                icon: Icons.info_outline_rounded,
                title: '关于奶娃喝水',
                subtitle: '了解应用与使用方式',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AboutPage(state: widget.state),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 72, right: 18),
                child: Divider(),
              ),
              AppMenuRow(
                icon: Icons.shield_outlined,
                title: '隐私与安全',
                subtitle: '登录密钥安全保存在当前设备',
                onTap: () =>
                    _dialog('隐私与安全', '登录密钥仅用于账户登录，并安全保存在当前设备中。请勿向他人分享。'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
