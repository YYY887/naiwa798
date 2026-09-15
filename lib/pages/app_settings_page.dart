import 'package:flutter/material.dart';

import '../core/app_state.dart';
import 'about_page.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({required this.state, super.key});
  final AppState state;
  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool _checkingUpdate = false;

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
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _checkingUpdate = false);
    _dialog('检查更新', '当前已是最新版本');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: widget.state.dark ? Colors.black : const Color(0xfff7f8fa),
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.state.dark
              ? const [Colors.black, Colors.black, Colors.black, Colors.black]
              : const [
                  Color(0xff9fe1e3),
                  Color(0xffd9eeeb),
                  Color(0xfff2d8cc),
                  Color(0xfff7f8fa),
                ],
        ),
      ),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: '返回',
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: widget.state.dark
                            ? Colors.white
                            : const Color(0xff171717),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '应用设置',
                      style: TextStyle(
                        color: widget.state.dark
                            ? Colors.white
                            : const Color(0xff171717),
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle('主题', dark: widget.state.dark),
                const SizedBox(height: 9),
                _Panel(
                  dark: widget.state.dark,
                  child: SwitchListTile(
                    secondary: Icon(
                      Icons.dark_mode_outlined,
                      color: widget.state.dark
                          ? Colors.white
                          : const Color(0xff171717),
                    ),
                    title: Text(
                      '暗色模式',
                      style: TextStyle(
                        color: widget.state.dark
                            ? Colors.white
                            : Color(0xff171717),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '跟随你的视觉偏好',
                      style: TextStyle(
                        color: widget.state.dark
                            ? const Color(0xffc9c9c9)
                            : const Color(0xff65728f),
                        fontSize: 12,
                      ),
                    ),
                    value: widget.state.dark,
                    activeThumbColor: widget.state.dark
                        ? Colors.white
                        : const Color(0xff171717),
                    activeTrackColor: widget.state.dark
                        ? const Color(0xff555555)
                        : const Color(0xffa9d9d7),
                    inactiveThumbColor: widget.state.dark
                        ? const Color(0xffbdbdbd)
                        : Colors.white,
                    inactiveTrackColor: widget.state.dark
                        ? const Color(0xff303030)
                        : const Color(0xffaeb9c1),
                    onChanged: widget.state.setDark,
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle('应用', dark: widget.state.dark),
                const SizedBox(height: 9),
                _Panel(
                  dark: widget.state.dark,
                  child: Column(
                    children: [
                      _Row(
                        icon: Icons.system_update_outlined,
                        title: '检查更新',
                        subtitle: '当前版本 1.0.0',
                        dark: widget.state.dark,
                        trailing: _checkingUpdate
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xff171717),
                                ),
                              )
                            : null,
                        onTap: _checkingUpdate ? null : _checkUpdate,
                      ),
                      const Divider(height: 1),
                      _Row(
                        icon: Icons.info_outline_rounded,
                        title: '关于奶娃喝水',
                        subtitle: '版本信息与使用说明',
                        dark: widget.state.dark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AboutPage(state: widget.state),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      _Row(
                        icon: Icons.privacy_tip_outlined,
                        title: '隐私与安全',
                        subtitle: '账户资料仅保存在当前设备',
                        dark: widget.state.dark,
                        onTap: () => _dialog(
                          '隐私与安全',
                          '登录凭证仅用于账户登录，并安全保存在当前设备中。请勿向他人分享。',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.dark});
  final String text;
  final bool dark;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: dark ? Colors.white : const Color(0xff58677e),
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.dark});
  final Widget child;
  final bool dark;
  @override
  Widget build(BuildContext context) => Container(
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

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.dark,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool dark;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: dark ? const Color(0xff252525) : const Color(0xffe7f3f4),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        color: dark ? Colors.white : const Color(0xff171717),
        size: 19,
      ),
    ),
    title: Text(
      title,
      style: TextStyle(
        color: dark ? Colors.white : const Color(0xff171717),
        fontWeight: FontWeight.w700,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: TextStyle(
        color: dark ? const Color(0xffc9c9c9) : const Color(0xff65728f),
        fontSize: 12,
      ),
    ),
    trailing:
        trailing ??
        Icon(
          Icons.chevron_right_rounded,
          color: dark ? Colors.white : const Color(0xff171717),
        ),
    onTap: onTap,
  );
}
