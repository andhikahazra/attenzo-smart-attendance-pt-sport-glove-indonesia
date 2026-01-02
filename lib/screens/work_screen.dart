import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/attendance_record.dart';
import '../services/api_service.dart';
import '../state/auth_state.dart';
import '../utils/app_colors.dart';

enum _HeatmapStatus { onTime, late, absent, future, off, none }

class WorkScreen extends StatefulWidget {
  const WorkScreen({super.key});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  final DateFormat _fullDateFormat = DateFormat('EEEE, d MMM yyyy');
  final DateFormat _monthTitleFormat = DateFormat('MMM yyyy');

  bool _isLoading = true;
  Map<DateTime, List<AttendanceRecord>> _recordsByDate = {};
  Map<DateTime, _HeatmapStatus> _statusCache = {};
  _HeatmapDayDetail? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      final auth = context.read<AuthState>();
      if (auth.token == null || auth.token!.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final api = ApiService();
      final records = await api.getAttendanceRecords(token: auth.token!);
      final grouped = <DateTime, List<AttendanceRecord>>{};

      for (final record in records) {
        final date = _parseDate(record.attendanceDate);
        grouped.putIfAbsent(date, () => <AttendanceRecord>[]).add(record);
      }

      final statuses = _computeStatuses(grouped);
      final today = _jakartaToday();

      DateTime? firstSelection;
      final sortedDates = statuses.keys.toList()..sort();
      for (final date in sortedDates.reversed) {
        if (!date.isAfter(today)) {
          firstSelection = date;
          break;
        }
      }

      setState(() {
        _recordsByDate = grouped;
        _statusCache = statuses;
        _isLoading = false;
        _selectedDay = firstSelection != null
            ? _HeatmapDayDetail(
                date: firstSelection,
                status: statuses[firstSelection] ?? _HeatmapStatus.none,
                records: grouped[firstSelection] ?? const <AttendanceRecord>[],
              )
            : null;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime _jakartaToday() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _parseDate(String raw) {
    final parsed = DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  Map<DateTime, _HeatmapStatus> _computeStatuses(
    Map<DateTime, List<AttendanceRecord>> grouped,
  ) {
    final today = _jakartaToday();
    final firstDay = DateTime(today.year, today.month, 1);
    final lastDay = DateTime(today.year, today.month + 1, 0);

    // Start dari hari Senin sebelum tanggal 1 bulan ini
    DateTime start = firstDay;
    while (start.weekday != DateTime.monday) {
      start = start.subtract(const Duration(days: 1));
    }

    // End di hari Minggu setelah hari terakhir bulan ini
    DateTime end = lastDay;
    while (end.weekday != DateTime.sunday) {
      end = end.add(const Duration(days: 1));
    }

    final result = <DateTime, _HeatmapStatus>{};
    for (
      DateTime day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      final inCurrentMonth = day.month == today.month && day.year == today.year;
      if (!inCurrentMonth) {
        result[day] = _HeatmapStatus.none;
        continue;
      }

      final records = grouped[day];
      _HeatmapStatus status;
      if (records != null && records.isNotEmpty) {
        status = _deriveStatus(records);
      } else if (day.isAfter(today)) {
        status = _HeatmapStatus.future;
      } else if (!_isWorkday(day)) {
        status = _HeatmapStatus.off;
      } else {
        status = _HeatmapStatus.absent;
      }
      result[day] = status;
    }
    return result;
  }

  bool _isWorkday(DateTime date) =>
      date.weekday >= DateTime.monday && date.weekday <= DateTime.friday;

  _HeatmapStatus _deriveStatus(List<AttendanceRecord> records) {
    final normalized = records
        .map((record) => record.status.toLowerCase())
        .where((status) => status.isNotEmpty)
        .toList();
    if (normalized.any((s) => s.contains('late') || s.contains('telat'))) {
      return _HeatmapStatus.late;
    }
    if (normalized.any((s) => s.contains('absen') || s.contains('alpha'))) {
      return _HeatmapStatus.absent;
    }
    return _HeatmapStatus.onTime;
  }

  @override
  Widget build(BuildContext context) {
    final periodLabel = _buildPeriodLabel();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadAttendance,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _isLoading
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(periodLabel),
                      const SizedBox(height: 24),
                      _buildSummaryRow(),
                      const SizedBox(height: 24),
                      _buildHeatmapCard(),
                      const SizedBox(height: 24),
                      _buildSelectedDayCard(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _buildPeriodLabel() {
    final today = _jakartaToday();
    return _monthTitleFormat.format(today);
  }

  Widget _buildHeaderSection(String periodLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pantau riwayat presensi Anda',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Heatmap Kehadiran',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  periodLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final today = _jakartaToday();
    final monthEntries = _statusCache.entries
        .where(
          (entry) =>
              entry.key.year == today.year && entry.key.month == today.month,
        )
        .toList();

    final present = monthEntries
        .where((entry) => entry.value == _HeatmapStatus.onTime)
        .length;
    final late = monthEntries
        .where((entry) => entry.value == _HeatmapStatus.late)
        .length;
    final absent = monthEntries
        .where((entry) => entry.value == _HeatmapStatus.absent)
        .length;
    final streak = _currentStreak();
    final longest = _longestStreak();

    final cards = [
      _SummaryCardConfig(
        label: 'Hari On Time',
        value: '$present',
        color: _statusColor(_HeatmapStatus.onTime),
        icon: Icons.check_circle_rounded,
      ),
      _SummaryCardConfig(
        label: 'Hari Telat',
        value: '$late',
        color: _statusColor(_HeatmapStatus.late),
        icon: Icons.access_time_rounded,
      ),
      _SummaryCardConfig(
        label: 'Hari Alfa',
        value: '$absent',
        color: _statusColor(_HeatmapStatus.absent),
        icon: Icons.cancel_rounded,
      ),
      _SummaryCardConfig(
        label: 'Streak',
        value: '$streak hari',
        color: AppColors.primary,
        icon: Icons.local_fire_department_rounded,
        trailing: 'Maks $longest hari',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final isWide = constraints.maxWidth >= 600;
        final crossAxisCount = isWide ? 4 : 2;
        final cardWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
            crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: cardWidth,
                  child: _buildSummaryCard(
                    label: card.label,
                    value: card.value,
                    color: card.color,
                    icon: card.icon,
                    trailing: card.trailing,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    String? trailing,
  }) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.2,
                ),
              ),
              SizedBox(height: trailing != null ? 4 : 0),
              SizedBox(
                height: 16,
                child: trailing != null
                    ? Text(
                        trailing,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard() {
    final weeks = _generateWeeks();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kalender bulan ini',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              // Header hari
              Row(
                children: [
                  const SizedBox(width: 40),
                  ...['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'].map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Grid kalender
              ...weeks.asMap().entries.map((entry) {
                final weekIndex = entry.key;
                final week = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      // Label minggu ke-
                      SizedBox(
                        width: 40,
                        child: Text(
                          'W${weekIndex + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Tanggal-tanggal
                      ...week.map(
                        (date) => Expanded(child: _buildHeatmapCell(date)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          _buildLegendRow(),
        ],
      ),
    );
  }

  Widget _buildHeatmapCell(DateTime date) {
    final status = _statusCache[date] ?? _HeatmapStatus.none;
    final isSelected = _selectedDay?.date == date;
    final today = _jakartaToday();
    final inCurrentMonth = date.month == today.month && date.year == today.year;
    final isOutsideMonth = !inCurrentMonth;

    final backgroundColor = isOutsideMonth
        ? Colors.grey.shade100
        : _statusColor(status);
    final borderColor = isSelected
        ? AppColors.primary
        : (isOutsideMonth ? Colors.grey.shade300 : Colors.grey.shade200);

    return GestureDetector(
      onTap: inCurrentMonth ? () => _handleDayTap(date) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2 : 0.5,
              ),
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isOutsideMonth
                      ? Colors.grey.shade400
                      : (status == _HeatmapStatus.onTime ||
                                status == _HeatmapStatus.late
                            ? Colors.white
                            : (status == _HeatmapStatus.absent
                                  ? Colors.white
                                  : Colors.grey.shade700)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendRow() {
    final items = [
      _LegendItem('On time', _HeatmapStatus.onTime),
      _LegendItem('Telat', _HeatmapStatus.late),
      _LegendItem('Alfa', _HeatmapStatus.absent),
      _LegendItem('Libur', _HeatmapStatus.off),
      _LegendItem('Mendatang', _HeatmapStatus.future),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _statusColor(item.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  List<List<DateTime>> _generateWeeks() {
    final today = _jakartaToday();
    final firstDay = DateTime(today.year, today.month, 1);
    final lastDay = DateTime(today.year, today.month + 1, 0);

    // Start dari hari Senin sebelum tanggal 1 bulan ini
    DateTime start = firstDay;
    while (start.weekday != DateTime.monday) {
      start = start.subtract(const Duration(days: 1));
    }

    // End di hari Minggu setelah hari terakhir bulan ini
    DateTime end = lastDay;
    while (end.weekday != DateTime.sunday) {
      end = end.add(const Duration(days: 1));
    }

    final weeks = <List<DateTime>>[];
    for (
      DateTime weekStart = start;
      !weekStart.isAfter(end);
      weekStart = weekStart.add(const Duration(days: 7))
    ) {
      weeks.add(
        List.generate(7, (index) => weekStart.add(Duration(days: index))),
      );
    }
    return weeks;
  }

  void _handleDayTap(DateTime date) {
    final status = _statusCache[date] ?? _HeatmapStatus.none;
    final records = _recordsByDate[date] ?? const <AttendanceRecord>[];
    setState(() {
      _selectedDay = _HeatmapDayDetail(
        date: date,
        status: status,
        records: records,
      );
    });
  }

  Widget _buildSelectedDayCard() {
    final detail = _selectedDay;
    if (detail == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          'Ketuk salah satu hari pada heatmap untuk melihat detail.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      );
    }

    final label = _fullDateFormat.format(detail.date);
    final statusLabel = _statusLabel(detail.status);
    final statusColor = _statusColor(detail.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (detail.records.isEmpty)
            Text(
              'Tidak ada data kehadiran terekam pada tanggal ini.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            )
          else
            Column(
              children: detail.records
                  .map((record) => _buildRecordTile(record))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordTile(AttendanceRecord record) {
    final time = _formatTime(record.attendanceTime);
    final typeLabel = record.type.isEmpty ? 'Kehadiran' : record.type;
    final statusLabel = record.status.isEmpty ? 'Tercatat' : record.status;
    final statusColor = _chipColor(record.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconForRecord(record.type), color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Waktu $time',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          _buildStatusChip(statusLabel, statusColor),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  IconData _iconForRecord(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('out')) return Icons.logout_rounded;
    if (lower.contains('in')) return Icons.login_rounded;
    return Icons.access_time_rounded;
  }

  Color _chipColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('late') || lower.contains('telat')) {
      return const Color(0xFFF97316);
    }
    if (lower.contains('on')) {
      return const Color(0xFF22C55E);
    }
    if (lower.contains('absen') || lower.contains('alpha')) {
      return const Color(0xFFEF4444);
    }
    return AppColors.primary;
  }

  String _statusLabel(_HeatmapStatus status) {
    switch (status) {
      case _HeatmapStatus.onTime:
        return 'Hadir tepat waktu';
      case _HeatmapStatus.late:
        return 'Hadir tetapi telat';
      case _HeatmapStatus.absent:
        return 'Tidak ada kehadiran';
      case _HeatmapStatus.off:
        return 'Hari libur';
      case _HeatmapStatus.future:
        return 'Belum terjadi';
      case _HeatmapStatus.none:
        return 'Tidak ada data';
    }
  }

  Color _statusColor(_HeatmapStatus status) {
    switch (status) {
      case _HeatmapStatus.onTime:
        return const Color(0xFF34D399);
      case _HeatmapStatus.late:
        return const Color(0xFFFBBF24);
      case _HeatmapStatus.absent:
        return const Color(0xFFF87171);
      case _HeatmapStatus.off:
        return const Color(0xFFF8FAFC);
      case _HeatmapStatus.future:
        return const Color(0xFFE2E8F0);
      case _HeatmapStatus.none:
        return const Color(0xFFD1D5DB);
    }
  }

  String _formatTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final hour12 = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $suffix';
  }

  bool _isPositiveStatus(_HeatmapStatus status) =>
      status == _HeatmapStatus.onTime || status == _HeatmapStatus.late;

  int _currentStreak() {
    if (_statusCache.isEmpty) return 0;
    int streak = 0;
    DateTime cursor = _jakartaToday();
    while (true) {
      final status = _statusCache[cursor];
      if (status == null) break;
      if (_isPositiveStatus(status)) {
        streak++;
      } else if (status == _HeatmapStatus.off ||
          status == _HeatmapStatus.future) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _longestStreak() {
    if (_statusCache.isEmpty) return 0;
    final dates = _statusCache.keys.toList()..sort();
    int longest = 0;
    int current = 0;
    for (final date in dates) {
      final status = _statusCache[date] ?? _HeatmapStatus.none;
      if (_isPositiveStatus(status)) {
        current++;
        if (current > longest) longest = current;
      } else if (status == _HeatmapStatus.off ||
          status == _HeatmapStatus.future) {
        continue;
      } else {
        current = 0;
      }
    }
    return longest;
  }
}

class _HeatmapDayDetail {
  const _HeatmapDayDetail({
    required this.date,
    required this.status,
    required this.records,
  });

  final DateTime date;
  final _HeatmapStatus status;
  final List<AttendanceRecord> records;
}

class _SummaryCardConfig {
  const _SummaryCardConfig({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.trailing,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final String? trailing;
}

class _LegendItem {
  const _LegendItem(this.label, this.status);

  final String label;
  final _HeatmapStatus status;
}
