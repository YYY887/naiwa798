import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../widgets/app_ui.dart';
import '../widgets/app_version_label.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({required this.state, super.key});
  final AppState state;

  @override
  Widget build(BuildContext context) => AppPage(
    dark: state.dark,
    children: [
      const AppHeader(title: '关于奶娃喝水', subtitle: '把喝水这件小事，照顾好', back: true),
      AppSurface(
        child: Column(
          children: [
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('lib/static/logo.png', width: 72, height: 72),
            ),
            const SizedBox(height: 18),
            Text('奶娃喝水', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const AppVersionLabel(),
            const SizedBox(height: 16),
            Text(
              '饮水设备管理 · 胖乖洗澡扫码',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
      const AppSectionHeading('使用说明'),
      const AppSurface(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            AppMenuRow(
              icon: Icons.water_drop_outlined,
              title: '管理饮水设备',
              subtitle: '扫码绑定 798 饮水机，随时开始或停止接水。',
              trailing: SizedBox.shrink(),
            ),
            Padding(
              padding: EdgeInsets.only(left: 72, right: 18),
              child: Divider(),
            ),
            AppMenuRow(
              icon: Icons.qr_code_scanner_rounded,
              title: '扫码去洗澡',
              subtitle: '扫描胖乖二维码，直达支付宝对应服务。',
              trailing: SizedBox.shrink(),
            ),
            Padding(
              padding: EdgeInsets.only(left: 72, right: 18),
              child: Divider(),
            ),
            AppMenuRow(
              icon: Icons.widgets_outlined,
              title: '桌面快捷启动',
              subtitle: '在“我的”选择常用设备，添加 Android 桌面快捷组件。',
              trailing: SizedBox.shrink(),
            ),
          ],
        ),
      ),
      const AppSectionHeading('隐私说明'),
      AppSurface(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppIconBadge(icon: Icons.lock_outline_rounded, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '登录密钥仅保存在当前设备，用于快捷登录。请勿向他人分享。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
