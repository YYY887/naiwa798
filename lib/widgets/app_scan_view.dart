import 'package:flutter/material.dart';

import '../core/app_palette.dart';
import 'app_ui.dart';

class AppScanView extends StatelessWidget {
  const AppScanView({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.camera,
    this.busy = false,
    this.embedded = false,
    super.key,
  });
  final String title, subtitle, status;
  final Widget camera;
  final bool busy, embedded;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = AppColors(dark);
    final children = <Widget>[
      AppHeader(title: title, subtitle: subtitle, back: !embedded),
      const SizedBox(height: 12),
      AppSurface(
        background: colors.tint,
        padding: const EdgeInsets.all(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                camera,
                const IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.fromBorderSide(
                          BorderSide(color: Color(0xb3ffffff), width: 2),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                    ),
                  ),
                ),
                if (busy)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 22),
      AppSurface(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              busy ? Icons.hourglass_top_rounded : Icons.qr_code_rounded,
              color: colors.accent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                status,
                style: TextStyle(color: colors.ink, fontSize: 13, height: 1.6),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Text(
        '将二维码置于框内，识别后自动继续',
        textAlign: TextAlign.center,
        style: TextStyle(color: colors.muted, fontSize: 12),
      ),
    ];
    if (!embedded) return AppPage(dark: dark, children: children);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          children: children,
        ),
      ),
    );
  }
}

class AppCameraPlaceholder extends StatelessWidget {
  const AppCameraPlaceholder({
    this.loading = false,
    this.message,
    this.actions = const [],
    super.key,
  });
  final bool loading;
  final String? message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(Theme.of(context).brightness == Brightness.dark);
    return ColoredBox(
      color: colors.field,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  loading
                      ? Icons.qr_code_scanner_rounded
                      : Icons.videocam_off_outlined,
                  size: 44,
                  color: colors.accent,
                ),
                const SizedBox(height: 18),
                Text(
                  message ?? (loading ? '正在打开相机…' : '相机暂不可用\n请检查相机权限后重试'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                if (actions.isNotEmpty) const SizedBox(height: 14),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
