import 'package:flutter/material.dart';

import '../core/app_state.dart';
import '../core/app_palette.dart';

class DrinkingRecordsPage extends StatefulWidget {
  const DrinkingRecordsPage({
    required this.state,
    this.embedded = false,
    super.key,
  });
  final AppState state;
  final bool embedded;

  @override
  State<DrinkingRecordsPage> createState() => _DrinkingRecordsPageState();
}

class _DrinkingRecordsPageState extends State<DrinkingRecordsPage> {
  DateTime? _day;
  final _deleting = <Map<String, String>>{};

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _day ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: '选择记录日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (mounted && result != null) setState(() => _day = result);
  }

  Future<void> _deleteRecord(Map<String, String> record) async {
    setState(() => _deleting.add(record));
    try {
      await widget.state.removeDrinkingRecord(record);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('删除失败，请稍后重试')));
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(record));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, child) => _buildPage(context),
  );

  Widget _buildPage(BuildContext context) {
    final colors = AppColors(widget.state.dark);
    final now = DateTime.now();
    final all =
        widget.state.drinkingRecords
            .where((record) => !_deleting.contains(record))
            .toList()
          ..sort((a, b) {
            final left = DateTime.tryParse(a['时间'] ?? '');
            final right = DateTime.tryParse(b['时间'] ?? '');
            if (left == null) return right == null ? 0 : 1;
            if (right == null) return -1;
            return right.compareTo(left);
          });
    final todayCount = all.where((record) {
      return DateUtils.isSameDay(DateTime.tryParse(record['时间'] ?? ''), now);
    }).length;
    final groups = <DateTime?, List<Map<String, String>>>{};
    for (final record in all) {
      final date = DateTime.tryParse(record['时间'] ?? '');
      if (_day != null && !DateUtils.isSameDay(date, _day)) continue;
      final day = date == null ? null : DateUtils.dateOnly(date);
      groups.putIfAbsent(day, () => []).add(record);
    }
    final isToday = _day != null && DateUtils.isSameDay(_day, now);

    return Scaffold(
      backgroundColor: AppPalette.pageColorFor(widget.state.dark),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppPalette.pageBackgroundFor(widget.state.dark),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!widget.embedded)
                                IconButton.filledTonal(
                                  tooltip: '返回',
                                  onPressed: () => Navigator.maybePop(context),
                                  style: IconButton.styleFrom(
                                    backgroundColor: colors.surface,
                                    foregroundColor: colors.ink,
                                    side: BorderSide(color: colors.border),
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 20,
                                  ),
                                ),
                              if (!widget.embedded) const SizedBox(width: 12),
                              Text(
                                '喝水记录',
                                style: TextStyle(
                                  color: colors.ink,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _RecordSummary(
                            total: all.length,
                            today: todayCount,
                            colors: colors,
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _FilterChip(
                                label: '全部',
                                selected: _day == null,
                                colors: colors,
                                onTap: () => setState(() => _day = null),
                              ),
                              _FilterChip(
                                label: '今天',
                                selected: isToday,
                                colors: colors,
                                onTap: () => setState(
                                  () => _day = DateUtils.dateOnly(now),
                                ),
                              ),
                              _FilterChip(
                                label: _day == null || isToday
                                    ? '选日期'
                                    : '${_day!.month}月${_day!.day}日',
                                icon: Icons.calendar_today_outlined,
                                selected: _day != null && !isToday,
                                colors: colors,
                                onTap: _pickDay,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  if (groups.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyRecords(
                        filtered: _day != null,
                        colors: colors,
                      ),
                    )
                  else
                    for (final group in groups.entries) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                        sliver: SliverToBoxAdapter(
                          child: _DayHeading(
                            day: group.key,
                            count: group.value.length,
                            colors: colors,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList.separated(
                          itemCount: group.value.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final record = group.value[index];
                            return _RecordTile(
                              key: ObjectKey(record),
                              record: record,
                              colors: colors,
                              onDelete: () => _deleteRecord(record),
                            );
                          },
                        ),
                      ),
                    ],
                  SliverToBoxAdapter(
                    child: SizedBox(height: widget.embedded ? 120 : 32),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordSummary extends StatelessWidget {
  const _RecordSummary({
    required this.total,
    required this.today,
    required this.colors,
  });
  final int total, today;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors.dark
            ? const [Color(0xff1b3b5c), Color(0xff182d46)]
            : const [Color(0xff338cd8), Color(0xff286ab0)],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -30,
          top: -45,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x12ffffff), width: 24),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    color: Color(0xffe1f0ff),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '每一次补水，都有迹可循',
                    style: TextStyle(color: Color(0xffe9f4ff), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _SummaryNumber(label: '累计接水', value: total),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    color: const Color(0x26ffffff),
                  ),
                  Expanded(
                    child: _SummaryNumber(label: '今天接水', value: today),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SummaryNumber extends StatelessWidget {
  const _SummaryNumber({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xffd3e8fa), fontSize: 12),
      ),
      const SizedBox(height: 6),
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$value',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                letterSpacing: -1.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const TextSpan(
              text: '  次',
              style: TextStyle(fontSize: 12, color: Color(0xffe3f0fb)),
            ),
          ],
        ),
        style: const TextStyle(color: Colors.white),
      ),
    ],
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final AppColors colors;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    avatar: icon == null
        ? null
        : Icon(icon, size: 15, color: selected ? colors.accent : colors.muted),
    selected: selected,
    showCheckmark: false,
    onSelected: (_) => onTap(),
    backgroundColor: colors.surface,
    selectedColor: colors.tint,
    side: BorderSide(
      color: selected ? colors.accent.withValues(alpha: .25) : colors.border,
    ),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    labelStyle: TextStyle(
      color: selected ? colors.accent : colors.muted,
      fontSize: 13,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    ),
  );
}

class _DayHeading extends StatelessWidget {
  const _DayHeading({
    required this.day,
    required this.count,
    required this.colors,
  });
  final DateTime? day;
  final int count;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final label = day == null
        ? '其他记录'
        : DateUtils.isSameDay(day, now)
        ? '今天'
        : DateUtils.isSameDay(day, yesterday)
        ? '昨天'
        : '${day!.year == now.year ? '' : '${day!.year}年'}${day!.month}月${day!.day}日';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (day != null) ...[
                const SizedBox(height: 3),
                Text(
                  '${day!.year}.${day!.month.toString().padLeft(2, '0')}.${day!.day.toString().padLeft(2, '0')}  ${const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][day!.weekday - 1]}',
                  style: TextStyle(color: colors.muted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        Text('$count 次接水', style: TextStyle(color: colors.muted, fontSize: 12)),
      ],
    );
  }
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.colors,
    required this.onDelete,
    super.key,
  });
  final Map<String, String> record;
  final AppColors colors;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(record['时间'] ?? '');
    final time = date == null
        ? '--:--'
        : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return Dismissible(
      key: ObjectKey(record),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xffc95c63),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.water_drop_outlined,
                color: colors.accent,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record['设备'] ?? '饮水机',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '接水',
                    style: TextStyle(color: colors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              time,
              style: TextStyle(
                color: colors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                letterSpacing: -.5,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords({required this.filtered, required this.colors});
  final bool filtered;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: colors.tint, shape: BoxShape.circle),
          child: Icon(
            Icons.water_drop_outlined,
            size: 32,
            color: colors.accent,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          filtered ? '这一天，还没有记录' : '从第一杯水开始',
          style: TextStyle(
            color: colors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          filtered ? '换个日期，看看其他补水时刻' : '在设备页开始接水后\n你的补水时刻会出现在这里',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.muted, fontSize: 13, height: 1.8),
        ),
      ],
    ),
  );
}
