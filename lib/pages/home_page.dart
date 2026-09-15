import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_state.dart';
import '../widgets/account_avatar.dart';
import 'pangguai_scan_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.state, super.key});
  final AppState state;
  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  int i = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showWelcomeOnce());
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

  @override
  Widget build(BuildContext c) {
    final wide = MediaQuery.sizeOf(c).width >= 760;
    final showerPage = i == 1;
    final pages = [
      DevicesPage(state: widget.state),
      const PangGuaiScanPage(embedded: true),
      ProfilePage(state: widget.state),
    ];
    return Scaffold(
      backgroundColor: showerPage
          ? Colors.black
          : widget.state.dark
          ? Colors.black
          : const Color(0xfff7f8fa),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0, .34, .58, 1],
            colors: showerPage || widget.state.dark
                ? const [Colors.black, Colors.black, Colors.black, Colors.black]
                : const [
                    Color(0xff9fe1e3),
                    Color(0xffd9eeeb),
                    Color(0xfff2d8cc),
                    Color(0xfff7f8fa),
                  ],
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: pages[i]),
              Align(
                alignment: Alignment.bottomCenter,
                child: _FloatingNavigation(
                  wide: wide,
                  dark: widget.state.dark,
                  selectedIndex: i,
                  onSelect: (value) => setState(() => i = value),
                  onScan: () => setState(() => i = 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingNavigation extends StatelessWidget {
  const _FloatingNavigation({
    required this.wide,
    required this.dark,
    required this.selectedIndex,
    required this.onSelect,
    required this.onScan,
  });
  final bool wide;
  final bool dark;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Container(
    width: wide ? 360 : null,
    margin: EdgeInsets.fromLTRB(wide ? 0 : 20, 0, wide ? 0 : 20, 18),
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: dark ? Colors.black : const Color(0xcfffffff),
      border: Border.all(
        color: dark ? const Color(0xff323232) : const Color(0xaaffffff),
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x260f244d),
          blurRadius: 22,
          offset: Offset(0, 9),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: _NavigationItem(
            label: '设备',
            icon: Icons.water_drop_outlined,
            selected: selectedIndex == 0,
            dark: dark,
            onTap: () => onSelect(0),
          ),
        ),
        Expanded(
          child: _NavigationItem(
            label: '胖乖洗澡',
            icon: Icons.shower_outlined,
            selected: selectedIndex == 1,
            dark: dark,
            onTap: onScan,
          ),
        ),
        Expanded(
          child: _NavigationItem(
            label: '我的',
            icon: Icons.person_outline_rounded,
            selected: selectedIndex == 2,
            dark: dark,
            onTap: () => onSelect(2),
          ),
        ),
      ],
    ),
  );
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.dark,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? (dark ? const Color(0xff202020) : const Color(0xffe7f3f4))
        : Colors.transparent,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: SizedBox(
        height: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: dark ? Colors.white : const Color(0xff171717),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: dark ? Colors.white : const Color(0xff171717),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DevicesPage extends StatelessWidget {
  const DevicesPage({required this.state, super.key});
  final AppState state;
  @override
  Widget build(BuildContext c) {
    final selected = state.devices
        .where((device) => device.id == state.selected)
        .firstOrNull;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: RefreshIndicator(
          onRefresh: state.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 112),
            children: [
              Row(
                children: [
                  AccountAvatar(
                    account: state.account,
                    size: 46,
                    dark: state.dark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.account?['name'] ?? '798 用户'}',
                          style: Theme.of(c).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${state.account?['pn'] ?? '账户'}',
                          style: const TextStyle(color: Color(0xff65728f)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '扫码添加设备',
                    onPressed: () => Navigator.push(
                      c,
                      MaterialPageRoute(
                        builder: (_) => BindDevicePage(state: state),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      maximumSize: const Size(40, 40),
                      backgroundColor: const Color(0xbfffffff),
                      foregroundColor: const Color(0xff171717),
                    ),
                  ),
                ],
              ),
              if (state.devices.isNotEmpty) ...[
                const SizedBox(height: 18),
                _FrostedPanel(
                  height: 122,
                  dark: state.dark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '当前设备',
                        style: TextStyle(
                          color: state.dark
                              ? Color(0xffd5d5d5)
                              : Color(0xff58677e),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        selected?.name ?? '请选择设备',
                        style: TextStyle(
                          color: state.dark ? Colors.white : Color(0xff1d2947),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _DeviceStatusBadge(
                            status: _deviceStatus(state, selected),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('设备列表', style: Theme.of(c).textTheme.titleLarge),
                  Text(
                    '共 ${state.devices.length} 台',
                    style: const TextStyle(color: Color(0xff65728f)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '暂无设备，请扫码添加',
                    style: TextStyle(color: Color(0xff65728f), fontSize: 15),
                  ),
                )
              else ...[
                ...state.devices.map(
                  (device) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onLongPress: () => _showDeviceActions(c, state, device),
                      child: _FrostedPanel(
                        height: 96,
                        dark: state.dark,
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: state.dark
                                    ? const Color(0xff252525)
                                    : const Color(0xffe6f5f5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.water_drop_outlined,
                                color: state.dark
                                    ? Colors.white
                                    : Color(0xff277eab),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: state.dark
                                          ? Colors.white
                                          : Color(0xff1d2947),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    device.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: state.dark
                                          ? Color(0xffc9c9c9)
                                          : Color(0xff65728f),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _DeviceStatusBadge(
                                  status: _deviceStatus(state, device),
                                ),
                                const SizedBox(height: 6),
                                Icon(
                                  device.id == state.selected
                                      ? Icons.check_circle_rounded
                                      : Icons.more_horiz_rounded,
                                  size: 20,
                                  color: state.dark
                                      ? Colors.white
                                      : const Color(0xff171717),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 220,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: state.actionLoading || state.stopPending
                        ? null
                        : () async {
                            final result = await state.drink();
                            if (!c.mounted || result == null) return;
                            ScaffoldMessenger.maybeOf(c)
                                ?.showSnackBar(SnackBar(content: Text(result)));
                          },
                    icon: state.actionLoading || state.stopPending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.water_drop_outlined),
                    label: Text(
                      state.actionLoading || state.stopPending
                          ? (state.isDrinking ? '正在停止中…' : '正在启动中…')
                          : state.isDrinking
                          ? '停止接水'
                          : '开始接水',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.isDrinking
                          ? const Color(0xffe45d68)
                          : const Color(0xff79b9ef),
                      foregroundColor: state.isDrinking
                          ? Colors.white
                          : const Color(0xff12304f),
                      disabledBackgroundColor: state.isDrinking
                          ? const Color(0xffe45d68)
                          : const Color(0xffb4cce2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
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

_DeviceStatus _deviceStatus(AppState state, dynamic device) {
  if (device == null || !device.online) return _DeviceStatus.offline;
  if (device.id == state.selected &&
      (state.actionLoading || state.stopPending)) {
    return _DeviceStatus.busy;
  }
  if (device.id == state.selected && state.isDrinking) {
    return _DeviceStatus.running;
  }
  return _DeviceStatus.idle;
}

enum _DeviceStatus { busy, running, idle, offline }

class _DeviceStatusBadge extends StatelessWidget {
  const _DeviceStatusBadge({required this.status});
  final _DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      _DeviceStatus.busy => ('忙碌中', const Color(0xffd98235)),
      _DeviceStatus.running => ('进行中', const Color(0xff4779d5)),
      _DeviceStatus.idle => ('空闲', const Color(0xff338d92)),
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

class _FrostedPanel extends StatelessWidget {
  const _FrostedPanel({required this.child, this.height, this.dark = false});
  final Widget child;
  final double? height;
  final bool dark;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
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

class BindDevicePage extends StatefulWidget {
  const BindDevicePage({required this.state, super.key});
  final AppState state;
  @override
  State<BindDevicePage> createState() => _BindDevicePageState();
}

class _BindDevicePageState extends State<BindDevicePage> {
  final scanner = MobileScannerController();
  bool handled = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: '返回',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                ),
                const Expanded(
                  child: Text(
                    '扫码添加设备',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 7),
            const Text(
              '请将净水设备二维码放入框内',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xffc7c7c7), fontSize: 13),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 236,
                  height: 236,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(controller: scanner, onDetect: _onDetect),
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                        ),
                        if (handled)
                          const ColoredBox(
                            color: Color(0x66000000),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (handled) return;
    final raw = capture.barcodes.firstOrNull?.rawValue ?? '';
    final id = RegExp(r'\d{8,20}').firstMatch(raw)?.group(0);
    if (id == null) return;
    setState(() => handled = true);
    await scanner.stop();
    final error = await widget.state.bind(id);
    if (!mounted) return;
    if (error != null) {
      setState(() => handled = false);
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(error)));
      await scanner.start();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    scanner.dispose();
    super.dispose();
  }
}
