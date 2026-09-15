import 'package:flutter/material.dart';

import '../core/app_state.dart';

class DrinkingRecordsPage extends StatefulWidget {
  const DrinkingRecordsPage({required this.state, super.key});
  final AppState state;
  @override
  State<DrinkingRecordsPage> createState() => _DrinkingRecordsPageState();
}

class _DrinkingRecordsPageState extends State<DrinkingRecordsPage> {
  DateTime? _day;

  Future<void> _pickDay() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _day ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (result != null) setState(() => _day = result);
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.state.dark;
    final records = widget.state.drinkingRecords.where((record) {
      if (_day == null) return true;
      final date = DateTime.tryParse(record['时间'] ?? '');
      return date != null &&
          date.year == _day!.year &&
          date.month == _day!.month &&
          date.day == _day!.day;
    }).toList();
    return Scaffold(
      backgroundColor: dark ? Colors.black : const Color(0xfff7f8fa),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: dark
              ? const LinearGradient(colors: [Colors.black, Colors.black])
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: '返回',
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: dark ? Colors.white : const Color(0xff171717),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '喝水记录',
                        style: TextStyle(
                          color: dark ? Colors.white : const Color(0xff171717),
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _GlassRecord(
                    dark: dark,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _day == null ? '全部记录' : _dateLabel(_day!),
                                  style: TextStyle(
                                    color: dark
                                        ? Colors.white
                                        : const Color(0xff171717),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '共 ${records.length} 次接水',
                                  style: TextStyle(
                                    color: dark
                                        ? const Color(0xffc9c9c9)
                                        : const Color(0xff65728f),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: '筛选日期',
                            onPressed: _pickDay,
                            style: IconButton.styleFrom(
                              backgroundColor: dark
                                  ? const Color(0xff252525)
                                  : const Color(0xffe5f4f1),
                              foregroundColor: dark
                                  ? Colors.white
                                  : const Color(0xff171717),
                            ),
                            icon: const Icon(Icons.calendar_month_outlined),
                          ),
                          if (_day != null)
                            IconButton(
                              tooltip: '清除筛选',
                              onPressed: () => setState(() => _day = null),
                              icon: Icon(
                                Icons.close_rounded,
                                color: dark
                                    ? Colors.white
                                    : const Color(0xff171717),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (records.isEmpty)
                    _GlassRecord(
                      dark: dark,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Text(
                            '这一天还没有喝水记录',
                            style: TextStyle(
                              color: dark
                                  ? Colors.white
                                  : const Color(0xff65728f),
                            ),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      '时间线',
                      style: TextStyle(
                        color: dark ? Colors.white : const Color(0xff58677e),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...records.map(
                      (record) => _TimelineItem(
                        record: record,
                        dark: dark,
                        onDelete: () async {
                          await widget.state.removeDrinkingRecord(record);
                          if (mounted) setState(() {});
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _dateLabel(DateTime day) => '${day.year}年${day.month}月${day.day}日';

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.record,
    required this.dark,
    required this.onDelete,
  });
  final Map<String, String> record;
  final bool dark;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) {
    final time = record['时间'] ?? '';
    final timeOnly = time.contains(' ') ? time.split(' ').last : time;
    return Dismissible(
      key: ValueKey(record['key'] ?? '$time-${record['设备']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: const Color(0xffdf5360),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 58,
              child: Padding(
                padding: const EdgeInsets.only(top: 17),
                child: Text(
                  timeOnly,
                  style: TextStyle(
                    color: dark
                        ? const Color(0xffd2d2d2)
                        : const Color(0xff65728f),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 22,
              height: 78,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 4,
                    child: Container(
                      width: 2,
                      color: dark
                          ? const Color(0xff4a4a4a)
                          : const Color(0xffa9d9d7),
                    ),
                  ),
                  Positioned(
                    top: 17,
                    left: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dark ? Colors.white : const Color(0xff277eab),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dark ? const Color(0xff181818) : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _GlassRecord(
                dark: dark,
                child: ListTile(
                  leading: Icon(
                    Icons.water_drop_outlined,
                    color: dark ? Colors.white : const Color(0xff171717),
                  ),
                  title: Text(
                    record['设备'] ?? '设备',
                    style: TextStyle(
                      color: dark ? Colors.white : const Color(0xff171717),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    time,
                    style: TextStyle(
                      color: dark
                          ? const Color(0xffc9c9c9)
                          : const Color(0xff65728f),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassRecord extends StatelessWidget {
  const _GlassRecord({required this.dark, required this.child});
  final bool dark;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: dark
            ? const [Color(0xff181818), Color(0xff080808)]
            : const [Color(0xdffeffff), Color(0xc6f8ece6)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: dark ? const Color(0xff353535) : const Color(0x99ffffff),
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
