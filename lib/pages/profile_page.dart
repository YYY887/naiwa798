import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../widgets/account_avatar.dart';
import 'app_settings_page.dart';
import 'drinking_records_page.dart';

const _widgetChannel = MethodChannel('奶娃喝水/桌面组件');

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '我的',
                style: TextStyle(
                  color: state.dark ? Colors.white : const Color(0xff171717),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                tooltip: '应用设置',
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => AppSettingsPage(state: state),
                  ),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0x99ffffff),
                  foregroundColor: state.dark
                      ? Colors.white
                      : const Color(0xff171717),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 22),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _copyToken(context, state.token),
            child: _ProfilePanel(
              dark: state.dark,
              child: Row(
                children: [
                  AccountAvatar(
                    account: state.account,
                    size: 62,
                    dark: state.dark,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.account?['name'] ?? '用户'}',
                          style: TextStyle(
                            color: state.dark
                                ? Colors.white
                                : Color(0xff171717),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.account?['pn'] ?? '已登录账户'}',
                          style: TextStyle(
                            color: state.dark
                                ? const Color(0xffc9c9c9)
                                : const Color(0xff65728f),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.copy_outlined,
                    color: state.dark ? Colors.white : const Color(0xff171717),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _ProfilePanel(
            dark: state.dark,
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(
                Icons.settings_outlined,
                color: state.dark ? Colors.white : const Color(0xff171717),
              ),
              title: Text(
                '应用设置',
                style: TextStyle(
                  color: state.dark ? Colors.white : Color(0xff171717),
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '主题、更新与隐私设置',
                style: TextStyle(
                  color: state.dark
                      ? const Color(0xffc9c9c9)
                      : const Color(0xff65728f),
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: state.dark ? Colors.white : const Color(0xff171717),
              ),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => AppSettingsPage(state: state),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '常用',
            style: TextStyle(
              color: state.dark ? Colors.white : const Color(0xff58677e),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          _ProfilePanel(
            dark: state.dark,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.history_rounded,
                    color: state.dark ? Colors.white : const Color(0xff171717),
                  ),
                  title: Text(
                    '喝水记录',
                    style: TextStyle(
                      color: state.dark ? Colors.white : Color(0xff171717),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '查看接水次数和时间',
                    style: TextStyle(
                      color: state.dark
                          ? const Color(0xffc9c9c9)
                          : const Color(0xff65728f),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: state.dark ? Colors.white : const Color(0xff171717),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DrinkingRecordsPage(state: state),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.widgets_outlined,
                    color: state.dark ? Colors.white : const Color(0xff171717),
                  ),
                  title: Text(
                    '桌面快捷组件',
                    style: TextStyle(
                      color: state.dark ? Colors.white : Color(0xff171717),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '选择一台设备快捷启动',
                    style: TextStyle(
                      color: state.dark
                          ? const Color(0xffc9c9c9)
                          : const Color(0xff65728f),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: state.dark ? Colors.white : const Color(0xff171717),
                  ),
                  onTap: () => _chooseWidgetDevice(context, state),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: state.logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('退出登录'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xffdf5360),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _copyToken(BuildContext context, String? token) async {
  if (token == null || token.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: token));
  if (context.mounted)
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(const SnackBar(content: Text('登录凭证已复制')));
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

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.dark = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: dark
            ? const [Color(0xff181818), Color(0xff0b0b0b)]
            : const [Color(0xdffeffff), Color(0xc6f8ece6)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: dark ? const Color(0xff363636) : const Color(0x99ffffff),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1f406c7c),
          blurRadius: 20,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: child,
  );
}
