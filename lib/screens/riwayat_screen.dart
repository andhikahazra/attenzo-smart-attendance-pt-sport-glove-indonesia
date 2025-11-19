import 'package:flutter/material.dart';

class RiwayatScreenPage extends StatelessWidget {
  const RiwayatScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: RiwayatScreen(),
    );
  }
}

class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0F172A);
    const dateItems = <_DateItem>[
      _DateItem(day: 'Mon', date: '19'),
      _DateItem(day: 'Tue', date: '20'),
      _DateItem(day: 'Wed', date: '21'),
      _DateItem(day: 'Thu', date: '22'),
      _DateItem(day: 'Fri', date: '23'),
      _DateItem(day: 'Sat', date: '24'),
      _DateItem(day: 'Sun', date: '25'),
    ];
    const selectedDateIndex = 2;

    const historyEntries = <_HistoryEntry>[
      _HistoryEntry(
        date: '25',
        day: 'Sen',
        month: 'Sep',
        status: 'Hadir',
        timeIn: '07:59',
        timeOut: '17:00',
        isPresent: true,
      ),
      _HistoryEntry(
        date: '24',
        day: 'Min',
        month: 'Sep',
        status: 'Telat',
        timeIn: '08:15',
        timeOut: '17:05',
      ),
      _HistoryEntry(
        date: '23',
        day: 'Sab',
        month: 'Sep',
        status: 'Hadir',
        timeIn: '07:55',
        timeOut: '17:00',
        isPresent: true,
      ),
      _HistoryEntry(
        date: '22',
        day: 'Jum',
        month: 'Sep',
        status: 'Hadir',
        timeIn: '08:00',
        timeOut: '17:02',
        isPresent: true,
      ),
      _HistoryEntry(
        date: '21',
        day: 'Kam',
        month: 'Sep',
        status: 'Hadir',
        timeIn: '07:58',
        timeOut: '17:00',
        isPresent: true,
      ),
      _HistoryEntry(
        date: '20',
        day: 'Rab',
        month: 'Sep',
        status: 'Telat',
        timeIn: '08:10',
        timeOut: '17:15',
      ),
      _HistoryEntry(
        date: '19',
        day: 'Sel',
        month: 'Sep',
        status: 'Hadir',
        timeIn: '07:59',
        timeOut: '17:00',
        isPresent: true,
      ),
      _HistoryEntry(
        date: '18',
        day: 'Sen',
        month: 'Sep',
        status: 'Cuti',
        timeIn: '-',
        timeOut: '-',
        isCuti: true,
      ),
    ];

    return SafeArea(
      child: Container(
        color: background,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View your attendance details',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Attendance History',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildHeaderAction(Icons.remove_red_eye_outlined),
                        const SizedBox(width: 10),
                        _buildHeaderAction(Icons.more_horiz_rounded),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.09),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Select Date',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
                                      color: Color(0xFF6366F1),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Wed, Jul 22 2024',
                                      style: TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(dateItems.length, (
                                index,
                              ) {
                                final item = dateItems[index];
                                final isSelected = index == selectedDateIndex;
                                return _buildDateChip(
                                  item,
                                  isSelected,
                                  isLast: index == dateItems.length - 1,
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Hadir',
                              '25',
                              const Color(0xFF22C55E),
                              Icons.check_circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Telat',
                              '3',
                              const Color(0xFFF97316),
                              Icons.access_time,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'History Timeline',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(historyEntries.length, (index) {
                        final entry = historyEntries[index];
                        final bottom = index == historyEntries.length - 1
                            ? 0.0
                            : 12.0;
                        return Padding(
                          padding: EdgeInsets.only(bottom: bottom),
                          child: _buildHistoryItem(entry),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  Widget _buildDateChip(
    _DateItem item,
    bool isSelected, {
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(right: isLast ? 0 : 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFFBFBFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.day,
            style: TextStyle(
              color: isSelected
                  ? Colors.white.withOpacity(0.85)
                  : const Color(0xFF64748B),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.date,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDetail(IconData icon, String time) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 3),
        Text(
          time,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(_HistoryEntry entry) {
    Color statusColor;
    if (entry.isCuti) {
      statusColor = const Color(0xFF6366F1);
    } else if (entry.isPresent) {
      statusColor = const Color(0xFF22C55E);
    } else {
      statusColor = const Color(0xFFF97316);
    }

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.day,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.date,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  entry.month,
                  style: TextStyle(
                    color: statusColor.withOpacity(0.7),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        entry.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (!entry.isCuti)
                  Row(
                    children: [
                      _buildTimeDetail(Icons.login_rounded, entry.timeIn),
                      const SizedBox(width: 18),
                      _buildTimeDetail(Icons.logout_rounded, entry.timeOut),
                    ],
                  )
                else
                  Text(
                    'Karyawan sedang cuti',
                    style: TextStyle(
                      color: const Color(0xFF64748B).withOpacity(0.9),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateItem {
  const _DateItem({required this.day, required this.date});

  final String day;
  final String date;
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.date,
    required this.day,
    required this.month,
    required this.status,
    required this.timeIn,
    required this.timeOut,
    this.isPresent = false,
    this.isCuti = false,
  });

  final String date;
  final String day;
  final String month;
  final String status;
  final String timeIn;
  final String timeOut;
  final bool isPresent;
  final bool isCuti;
}
