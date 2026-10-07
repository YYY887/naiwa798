import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/app_palette.dart';
import '../core/update_service.dart';
import '../models/device.dart';
import '../widgets/account_avatar.dart';
import '../widgets/app_ui.dart';
import '../widgets/buddy_picker.dart';
import '../widgets/water_buddy.dart';
import '../widgets/update_announcement.dart';
import 'drinking_records_page.dart';
import 'unified_scan_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.state, required this.darkMode, super.key});
  final AppState state;
  final bool darkMode;
  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> with WidgetsBindingObserver {
  int i = 0;
  final _updateService = UpdateService();
  Timer? _deviceStatusTimer;
  ValueNotifier<Brightness>? _tabBarBrightness;
  // Flutter preserves child State by position while fresh widgets keep tab
  // content current after hot reload and changes to the tab layout.
  List<Widget> get _pages => [
    ListenableBuilder(
      listenable: widget.state,
      builder: (context, child) => DevicesPage(state: widget.state),
    ),
    DrinkingRecordsPage(state: widget.state, embedded: true),
    ListenableBuilder(
      listenable: widget.state,
      builder: (context, child) => ProfilePage(state: widget.state),
    ),
  ];

  ValueNotifier<Brightness> get _effectiveTabBarBrightness =>
      _tabBarBrightness ??= ValueNotifier(
        widget.darkMode ? Brightness.dark : Brightness.light,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.statusPollingEnabled = true;
    _startDeviceStatusTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFirstFrame());
  }

  void _startDeviceStatusTimer() {
    _deviceStatusTimer?.cancel();
    var idleTicks = 0;
    _deviceStatusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted &&
          i == 0 &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          !widget.state.isDrinking) {
        idleTicks += 1;
        if (idleTicks >= 2) {
          idleTicks = 0;
          unawaited(widget.state.checkDeviceStatus());
        }
      } else {
        idleTicks = 0;
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addObserver(this);
    widget.state.statusPollingEnabled =
        i == 0 &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _startDeviceStatusTimer();
    unawaited(widget.state.checkDeviceStatus());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    widget.state.statusPollingEnabled =
        lifecycleState == AppLifecycleState.resumed && i == 0;
    if (lifecycleState == AppLifecycleState.resumed && i == 0) {
      unawaited(widget.state.checkDeviceStatus());
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.darkMode != widget.darkMode) {
      _effectiveTabBarBrightness.value = widget.darkMode
          ? Brightness.dark
          : Brightness.light;
    }
  }

  @override
  void dispose() {
    widget.state.statusPollingEnabled = false;
    _deviceStatusTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabBarBrightness?.dispose();
    super.dispose();
  }

  Future<void> _onFirstFrame() async {
    await _showWelcomeOnce();
    await _showUpdateIfAvailable();
  }

  Future<void> _showWelcomeOnce() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted || preferences.getBool('seen_welcome_message') == true) return;
    await preferences.setBool('seen_welcome_message', true);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('奶娃喝水'),
        content: const Text('我感觉每个人都是一只小小的奶娃，记得按时喝水哦。'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateIfAvailable() async {
    try {
      final update = await _updateService.checkForUpdate();
      if (!mounted || update == null) return;
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
      // Automatic checks are intentionally silent when the network is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppPalette.pageColorFor(widget.darkMode),
    body: GlassScaffold(
      backgroundColor: AppPalette.pageColorFor(widget.darkMode),
      background: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppPalette.pageBackgroundFor(widget.darkMode),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: i,
          children: [
            for (final (index, page) in _pages.indexed)
              TickerMode(enabled: index == i, child: page),
          ],
        ),
      ),
      bottomBar: GlassTabBar.bottom(
        tabs: const [
          GlassTab(icon: Icon(Icons.water_drop_outlined), label: '设备'),
          GlassTab(icon: Icon(Icons.history_rounded), label: '记录'),
          GlassTab(icon: Icon(Icons.person_outline), label: '我的'),
        ],
        selectedIndex: i,
        onTabSelected: (value) {
          setState(() => i = value);
          widget.state.statusPollingEnabled = value == 0;
          if (value == 0) unawaited(widget.state.checkDeviceStatus());
        },
        horizontalPadding: 18,
        verticalPadding: 12,
        barHeight: 66,
        indicatorColor: widget.darkMode
            ? const Color(0xff244362)
            : const Color(0xffe4f0ff),
        selectedIconColor: AppColors(widget.darkMode).accent,
        selectedLabelColor: AppColors(widget.darkMode).accent,
        unselectedIconColor: widget.darkMode
            ? const Color(0xffa9a9a9)
            : AppPalette.mutedInk,
        unselectedLabelColor: widget.darkMode
            ? const Color(0xffa9a9a9)
            : AppPalette.mutedInk,
        quality: GlassQuality.minimal,
        backgroundQuality: GlassQuality.minimal,
        glowOpacity: widget.darkMode ? 0 : .6,
        brightnessOverride: _effectiveTabBarBrightness,
      ),
    ),
  );
}

class DevicesPage extends StatelessWidget {
  const DevicesPage({required this.state, super.key});
  final AppState state;

  Future<void> _operate(BuildContext context) async {
    final result = await state.drink();
    if (!context.mounted || result == null) return;
    if (state.lastActionCode == -2) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('设备正在运行'),
          content: Text(result),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 104),
        content: Text(result),
      ),
    );
  }

  void _scan(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => UnifiedScanPage(state: state)),
  );

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(state.dark);
    final selected = state.devices
        .where((device) => device.id == state.selected)
        .firstOrNull;
    final offline = selected == null || !selected.online;
    final busy = state.actionLoading || state.stopPending;
    final label = offline
        ? '设备离线'
        : busy
        ? (state.isDrinking ? '正在停止中…' : '正在启动中…')
        : state.isDrinking
        ? '停止接水'
        : '开始接水';
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: RefreshIndicator(
          onRefresh: state.refresh,
          color: colors.accent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            children: [
              Row(
                children: [
                  AccountAvatar(
                    account: state.account,
                    size: 42,
                    dark: state.dark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.account?['name'] ?? '798 用户'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '今天也记得喝水',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: '扫一扫：饮水设备 / 胖乖洗澡',
                    onPressed: () => _scan(context),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.surface,
                      foregroundColor: colors.accent,
                      side: BorderSide(color: colors.border),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 21),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 116,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 124),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '喝水吧',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '今天也要元气满满',
                                  style: TextStyle(
                                    color: colors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (selected != null)
                        AppSurface(
                          dark: state.dark,
                          background: state.dark
                              ? const Color(0xff1a3049)
                              : const Color(0xfff0f7ff),
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 110),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '当前设备',
                                      style: TextStyle(
                                        color: colors.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    _DeviceStatusBadge(
                                      status: _deviceStatus(state, selected),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selected.name,
                                          style: TextStyle(
                                            color: colors.ink,
                                            fontSize: 23,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          selected.address.isEmpty
                                              ? '已绑定的饮水设备'
                                              : selected.address,
                                          style: TextStyle(
                                            color: colors.muted,
                                            fontSize: 12,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: offline || busy
                                      ? null
                                      : () => _operate(context),
                                  icon: busy
                                      ? const SizedBox(
                                          width: 17,
                                          height: 17,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Icon(
                                          offline
                                              ? Icons.wifi_off_rounded
                                              : state.isDrinking
                                              ? Icons.stop_rounded
                                              : Icons.water_drop_outlined,
                                          size: 20,
                                        ),
                                  label: Text(label),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 54),
                                    elevation: 0,
                                    backgroundColor: state.isDrinking
                                        ? colors.danger
                                        : AppPalette.primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: offline
                                        ? colors.field
                                        : state.isDrinking
                                        ? colors.danger.withValues(alpha: .7)
                                        : colors.tint,
                                    disabledForegroundColor: offline
                                        ? colors.muted
                                        : colors.ink,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        AppSurface(
                          dark: state.dark,
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              const AppIconBadge(
                                icon: Icons.water_drop_outlined,
                                size: 64,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                '添加你的第一台饮水机',
                                style: TextStyle(
                                  color: colors.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '暂无设备，请扫码添加',
                                style: TextStyle(
                                  color: colors.muted,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _scan(context),
                                  icon: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('扫码添加设备'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (selected != null)
                    Positioned(
                      top: 116 - state.buddy.seatOffset,
                      right: 14,
                      child: Semantics(
                        label: '当前角色：${state.buddy.label}，长按更换角色',
                        button: true,
                        onLongPress: () => showBuddyPicker(context, state),
                        child: Tooltip(
                          message: '长按更换角色',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onLongPress: () => showBuddyPicker(context, state),
                            child: WaterBuddy(character: state.buddy),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (state.devices.isNotEmpty) ...[
                AppSectionHeading(
                  '我的设备',
                  trailing: Text(
                    '${state.devices.length} 台',
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                ),
                for (final device in state.devices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onLongPress: () =>
                          _showDeviceActions(context, state, device),
                      child: AppSurface(
                        dark: state.dark,
                        selected: device.id == state.selected,
                        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                        onTap: () => state.selectDevice(device.id),
                        child: Row(
                          children: [
                            const AppIconBadge(
                              icon: Icons.water_drop_outlined,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (device.address.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      device.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  _DeviceStatusBadge(
                                    status: _deviceStatus(state, device),
                                  ),
                                ],
                              ),
                            ),
                            if (device.id == state.selected) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle_rounded,
                                color: colors.accent,
                                size: 18,
                              ),
                            ],
                            IconButton(
                              tooltip: '${device.name}更多操作',
                              onPressed: () =>
                                  _showDeviceActions(context, state, device),
                              icon: Icon(
                                Icons.more_horiz_rounded,
                                color: colors.muted,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '点击设备切换，右侧菜单可修改备注或删除',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

_DeviceStatus _deviceStatus(AppState state, Device? device) {
  if (device == null || !device.online) return _DeviceStatus.offline;
  if (device.id == state.selected &&
      (state.actionLoading || state.stopPending)) {
    return _DeviceStatus.busy;
  }
  if (device.id == state.selected && state.isDrinking) {
    return _DeviceStatus.running;
  }
  return switch (device.status) {
    0 => _DeviceStatus.off,
    1 => _DeviceStatus.running,
    2 => _DeviceStatus.error,
    10 => _DeviceStatus.running,
    20 => _DeviceStatus.flushing,
    30 => _DeviceStatus.preparing,
    98 => _DeviceStatus.disabled,
    99 => _DeviceStatus.standby,
    _ => _DeviceStatus.unknown,
  };
}

enum _DeviceStatus {
  busy,
  running,
  flushing,
  preparing,
  off,
  disabled,
  error,
  unknown,
  standby,
  offline,
}

class _DeviceStatusBadge extends StatelessWidget {
  const _DeviceStatusBadge({required this.status});
  final _DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _DeviceStatus.busy => ('忙碌中', const Color(0xffd98235)),
      _DeviceStatus.running => ('进行中', const Color(0xff4779d5)),
      _DeviceStatus.flushing => ('冲洗中', const Color(0xffd98235)),
      _DeviceStatus.preparing => ('准备中', const Color(0xffd98235)),
      _DeviceStatus.off => ('关闭', const Color(0xff7c8492)),
      _DeviceStatus.disabled => ('已禁用', const Color(0xffb25858)),
      _DeviceStatus.error => ('异常', const Color(0xffb25858)),
      _DeviceStatus.unknown => ('状态未知', const Color(0xff7c8492)),
      _DeviceStatus.standby => ('待机', const Color(0xff338d92)),
      _DeviceStatus.offline => ('离线', const Color(0xff7c8492)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: .34)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Future<void> _showDeviceActions(
  BuildContext context,
  AppState state,
  dynamic device,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: const Text('选择设备'),
            onTap: () => Navigator.pop(sheetContext, 'select'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('设置备注'),
            onTap: () => Navigator.pop(sheetContext, 'remark'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('删除设备'),
            onTap: () => Navigator.pop(sheetContext, 'delete'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || action == null) return;
  if (action == 'select') {
    await state.selectDevice(device.id);
  } else if (action == 'delete') {
    await _confirmRemove(context, state, device);
  } else if (action == 'remark') {
    final controller = TextEditingController(text: device.name);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('设置设备备注'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例如：宿舍饮水机'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await state.setRemark(device.id, value);
  }
}

Future<void> _confirmRemove(
  BuildContext context,
  AppState state,
  dynamic device,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('删除设备'),
      content: Text('确定要删除“${device.name}”吗？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('确定删除'),
        ),
      ],
    ),
  );
  if (confirmed == true) await state.remove(device.id);
}
