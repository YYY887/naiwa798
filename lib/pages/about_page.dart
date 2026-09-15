import 'package:flutter/material.dart';

import '../core/app_state.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: state.dark ? Colors.black : const Color(0xfff7f8fa),
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0, .34, .58, 1],
          colors: state.dark
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: '返回',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xff171717),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '关于奶娃喝水',
                      style: TextStyle(
                        color: Color(0xff171717),
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _AboutPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '奶娃喝水',
                        style: TextStyle(
                          color: Color(0xff171717),
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '当前版本 1.0.1',
                        style: TextStyle(
                          color: Color(0xff545454),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '用于管理 798 净水设备，并支持胖乖洗澡扫码直达。',
                        style: TextStyle(
                          color: Color(0xff303030),
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '使用说明',
                  style: TextStyle(
                    color: Color(0xff171717),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                const _AboutPanel(
                  child: Column(
                    children: [
                      _AboutTip(number: '1', text: '登录后可查看并操作 798 净水设备。'),
                      Divider(height: 24, color: Color(0x2271819a)),
                      _AboutTip(number: '2', text: '胖乖洗澡会直接打开相机，识别洗澡二维码。'),
                      Divider(height: 24, color: Color(0x2271819a)),
                      _AboutTip(
                        number: '3',
                        text: '在“我的”中可选择设备并同步到 Android 桌面快捷组件。',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '隐私说明',
                  style: TextStyle(
                    color: Color(0xff171717),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                const _AboutPanel(
                  child: Text(
                    '登录凭证仅保存在当前设备，用于快捷登录。请勿向他人分享登录凭证。',
                    style: TextStyle(color: Color(0xff303030), height: 1.6),
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

class _AboutPanel extends StatelessWidget {
  const _AboutPanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xcfffffff), Color(0x8fffffff)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0x99ffffff)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x120f244d),
          blurRadius: 16,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: child,
  );
}

class _AboutTip extends StatelessWidget {
  const _AboutTip({required this.number, required this.text});
  final String number;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 23,
        height: 23,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xffe7f3f4),
          shape: BoxShape.circle,
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: Color(0xff171717),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: Color(0xff303030), height: 1.55),
        ),
      ),
    ],
  );
}
