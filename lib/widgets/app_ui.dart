import 'package:flutter/material.dart';

import '../core/app_palette.dart';

class AppSurface extends StatelessWidget {
  const AppSurface({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.dark,
    this.selected = false,
    this.background,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool? dark;
  final bool selected;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(
      dark ?? Theme.of(context).brightness == Brightness.dark,
    );
    return Material(
      color: background ?? colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected
              ? colors.accent.withValues(alpha: .45)
              : colors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({required this.dark, required this.children, super.key});
  final bool dark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppPalette.pageColorFor(dark),
    body: DecoratedBox(
      decoration: BoxDecoration(gradient: AppPalette.pageBackgroundFor(dark)),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    this.subtitle,
    this.back = false,
    this.trailing,
    super.key,
  });
  final String title;
  final String? subtitle;
  final bool back;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(Theme.of(context).brightness == Brightness.dark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          if (back) ...[
            IconButton.filledTonal(
              tooltip: '返回',
              onPressed: () => Navigator.maybePop(context),
              style: IconButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.ink,
                side: BorderSide(color: colors.border),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: back ? 22 : 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.8,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    required this.icon,
    this.size = 44,
    this.color,
    this.background,
    super.key,
  });
  final IconData icon;
  final double size;
  final Color? color, background;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(Theme.of(context).brightness == Brightness.dark);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? colors.tint,
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: Icon(icon, color: color ?? colors.accent, size: size * .47),
    );
  }
}

class AppMenuRow extends StatelessWidget {
  const AppMenuRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.onTap,
    this.trailing,
    super.key,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget, trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(Theme.of(context).brightness == Brightness.dark);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            AppIconBadge(icon: icon, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null || subtitleWidget != null) ...[
                    const SizedBox(height: 4),
                    DefaultTextStyle(
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                      child: subtitleWidget ?? Text(subtitle!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colors.muted,
                ),
          ],
        ),
      ),
    );
  }
}

class AppSectionHeading extends StatelessWidget {
  const AppSectionHeading(this.title, {this.trailing, super.key});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}
