import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/app_palette.dart';
import '../widgets/app_ui.dart';
import '../widgets/account_avatar.dart';
import 'app_settings_page.dart';
import 'drinking_records_page.dart';

const _widgetChannel = MethodChannel('奶娃喝水/桌面组件');

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(state.dark);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          children: [
            const AppHeader(title: '我的', subtitle: '把喝水这件小事，放进日常'),
            AppSurface(
              dark: state.dark,
              padding: const EdgeInsets.all(22),
              onTap: () => _copyCredentials(context, state),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AccountAvatar(
                        account: state.account,
                        size: 58,
                        dark: state.dark,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${state.account?['name'] ?? '用户'}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.ink,
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${state.account?['pn'] ?? '已登录账户'}',
                              style: TextStyle(
                                color: colors.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.copy_outlined, color: colors.accent, size: 20),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.field,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.key_outlined,
                          size: 15,
                          color: colors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '点击卡片，复制完整登录密钥',
                            style: TextStyle(color: colors.muted, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const AppSectionHeading('日常与设备'),
            AppSurface(
              dark: state.dark,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppMenuRow(
                    icon: Icons.history_rounded,
                    title: '喝水记录',
                    subtitle: '回看每一次补水时刻',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DrinkingRecordsPage(state: state),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 72, right: 18),
                    child: Divider(),
                  ),
                  AppMenuRow(
                    icon: Icons.widgets_outlined,
                    title: '桌面快捷组件',
                    subtitle: '常用设备，一键开始接水',
                    onTap: () => _chooseWidgetDevice(context, state),
                  ),
                ],
              ),
            ),
            const AppSectionHeading('偏好设置'),
            AppSurface(
              dark: state.dark,
              padding: EdgeInsets.zero,
              child: AppMenuRow(
                icon: Icons.tune_rounded,
                title: '应用设置',
                subtitle: '外观、版本更新与隐私',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AppSettingsPage(state: state),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            TextButton.icon(
              onPressed: state.logout,
              style: TextButton.styleFrom(
                foregroundColor: colors.danger,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('退出登录'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _copyCredentials(BuildContext context, AppState state) async {
  try {
    final credentials = await state.exportLoginCredentials();
    await Clipboard.setData(ClipboardData(text: credentials));
    if (context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(20, 0, 20, 104),
          duration: Duration(seconds: 2),
          content: Text('登录密钥已复制，包含 token 和 UID'),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            error is StateError ? error.message.toString() : '复制失败，请稍后重试',
          ),
        ),
      );
    }
  }
}

Future<void> _chooseWidgetDevice(BuildContext context, AppState state) async {
  void notice(String text) =>
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(text)));
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android)
    return notice('桌面快捷组件仅支持 Android 设备');
  if (state.devices.isEmpty) return notice('请先添加设备，再设置桌面快捷组件');
  final id = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('选择快捷启动设备'),
      content: SizedBox(
        width: 340,
        child: ListView(
          shrinkWrap: true,
          children: state.devices
              .map(
                (device) => ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  onTap: () => Navigator.pop(dialogContext, device.id),
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
  if (!context.mounted || id == null) return;
  final device = state.devices.firstWhere((item) => item.id == id);
  await state.selectDevice(id);
  try {
    await _widgetChannel.invokeMethod<void>('设置快捷设备', {
      '编号': device.id,
      '名称': device.name,
    });
    if (context.mounted) notice('已同步“${device.name}”到桌面快捷组件');
  } on PlatformException {
    if (context.mounted) notice('桌面快捷组件同步失败，请重新添加组件');
  }
}
