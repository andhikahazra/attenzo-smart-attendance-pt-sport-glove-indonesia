import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/attendance_record.dart';
import '../services/api_service.dart';
import '../state/auth_state.dart';

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

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final ApiService _api = ApiService();
  late Future<List<AttendanceRecord>> _future;
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _future = _loadAttendance();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<List<AttendanceRecord>> _loadAttendance() async {
    final auth = context.read<AuthState>();
    final token = auth.token;
    final user = auth.user;

    if (token == null || user == null) {
      throw const HttpException('Anda perlu login ulang');
    }

    return _api.getAttendanceRecords(token: token);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadAttendance();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0F172A);

    return SafeArea(
      child: Container(
        color: background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pantau riwayat presensi Anda',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Attendance History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Filter buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterButton('Semua'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Hari Ini'),
                  const SizedBox(width: 8),
                  _buildFilterButton('1 Minggu'),
                  const SizedBox(width: 8),
                  _buildFilterButton('1 Bulan'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: FutureBuilder<List<AttendanceRecord>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return _buildError(snapshot.error.toString());
                      }

                      final records = snapshot.data ?? <AttendanceRecord>[];
                      if (records.isEmpty) {
                        return _buildEmpty();
                      }

                      // Filter records based on selected filter
                      List<AttendanceRecord> filteredRecords = records;
                      final now = DateTime.now();
                      if (_selectedFilter == 'Hari Ini') {
                        final today = DateFormat('yyyy-MM-dd').format(now);
                        filteredRecords = records.where((r) => r.attendanceDate == today).toList();
                      } else if (_selectedFilter == '1 Minggu') {
                        final weekAgo = now.subtract(const Duration(days: 7));
                        filteredRecords = records.where((r) {
                          try {
                            final recordDate = DateTime.parse(r.attendanceDate);
                            return recordDate.isAfter(weekAgo) || recordDate.isAtSameMomentAs(DateTime(recordDate.year, recordDate.month, recordDate.day));
                          } catch (e) {
                            return false;
                          }
                        }).toList();
                      } else if (_selectedFilter == '1 Bulan') {
                        final monthAgo = now.subtract(const Duration(days: 30));
                        filteredRecords = records.where((r) {
                          try {
                            final recordDate = DateTime.parse(r.attendanceDate);
                            return recordDate.isAfter(monthAgo) || recordDate.isAtSameMomentAs(DateTime(recordDate.year, recordDate.month, recordDate.day));
                          } catch (e) {
                            return false;
                          }
                        }).toList();
                      }

                      if (filteredRecords.isEmpty) {
                        return _buildEmpty();
                      }

                      // Group records by date
                      final groupedRecords = <String, List<AttendanceRecord>>{};
                      for (final record in filteredRecords) {
                        final date = record.attendanceDate;
                        groupedRecords.putIfAbsent(date, () => []).add(record);
                      }

                      // Sort dates descending
                      final sortedDates = groupedRecords.keys.toList()
                        ..sort((a, b) => b.compareTo(a));

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        children: [
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
                          ...sortedDates.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final date = entry.value;
                            final dayRecords = groupedRecords[date]!;
                            final bottom = idx == sortedDates.length - 1 ? 0.0 : 12.0;
                            return Padding(
                              padding: EdgeInsets.only(bottom: bottom),
                              child: _buildHistoryItemForDay(date, dayRecords),
                            );
                          }),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
          foregroundColor: isSelected ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          elevation: isSelected ? 4 : 0,
        ),
        child: Text(
          filter,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHistoryItemForDay(String date, List<AttendanceRecord> records) {
    // Sort records by time
    records.sort((a, b) => a.attendanceTime.compareTo(b.attendanceTime));

    // Calculate work duration if both check-in and check-out exist
    String? workDuration;
    if (records.length >= 2) {
      final checkIn = records.firstWhere((r) => r.type == 'check_in', orElse: () => records[0]);
      final checkOut = records.firstWhere((r) => r.type == 'check_out', orElse: () => records.last);
      if (checkIn != checkOut) {
        try {
          final inTime = DateTime.parse('${checkIn.attendanceDate} ${checkIn.attendanceTime}');
          final outTime = DateTime.parse('${checkOut.attendanceDate} ${checkOut.attendanceTime}');
          final duration = outTime.difference(inTime);
          final hours = duration.inHours;
          final minutes = duration.inMinutes % 60;
          workDuration = '${hours}h ${minutes}m';
        } catch (e) {
          // Ignore if parsing fails
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header with calendar icon and duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.calendar_today_rounded, size: 20, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (workDuration != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF22C55E), const Color(0xFF16A34A)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          workDuration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            // Timeline of activities
            ...records.map((record) {
              final statusLower = record.status.toLowerCase();
              Color statusColor;
              if (statusLower == 'hadir') {
                statusColor = const Color(0xFF22C55E);
              } else if (statusLower == 'telat') {
                statusColor = const Color(0xFFF97316);
              } else {
                statusColor = const Color(0xFF6366F1);
              }

              final photoUrl = _buildPhotoUrl(record);
              final isCheckIn = record.type == 'check_in';
              final typeLabel = isCheckIn ? 'Check In' : 'Check Out';
              final typeIcon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Timeline indicator
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(typeIcon, size: 18, color: statusColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      typeLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    record.status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded, size: 14, color: const Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text(
                                    record.attendanceTime,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (photoUrl != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showPhoto(photoUrl),
                                  icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                                  label: const Text('Foto', style: TextStyle(fontSize: 10)),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    foregroundColor: statusColor,
                                    backgroundColor: statusColor.withValues(alpha: 0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Text(
          'Belum ada data absensi',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Coba lakukan presensi lalu tarik untuk melihat rekamannya.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
        const SizedBox(height: 12),
        const Text(
          'Gagal memuat riwayat',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
          ),
        ),
      ],
    );
  }

  String? _buildPhotoUrl(AttendanceRecord record) {
    final raw = record.photoUrl ?? record.photoPath;
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    // Try different possible paths
    final possibleUrls = [
      '${ApiService.baseUrl}/storage/$raw',
      '${ApiService.baseUrl}/api/storage/$raw', 
      '${ApiService.baseUrl}/$raw',
    ];
    // For now, return the first one, but _showPhoto will try all
    return possibleUrls[0];
  }

  void _showPhoto(String url) {
    // Try different possible URLs
    final possibleUrls = [
      url,
      url.replaceFirst('/storage/', '/api/storage/'),
      url.replaceFirst('/storage/', '/'),
    ];

    print('Trying photo URLs: $possibleUrls');

    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: double.infinity,
            height: 400,
            child: Stack(
              children: [
                // Try to load image with fallback
                Image.network(
                  possibleUrls[0],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  headers: const {
                    'Accept': 'image/*',
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('Failed to load ${possibleUrls[0]}, error: $error');
                    return Image.network(
                      possibleUrls[1],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      headers: const {
                        'Accept': 'image/*',
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error2, stackTrace2) {
                        print('Failed to load ${possibleUrls[1]}, error: $error2');
                        return Image.network(
                          possibleUrls[2],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          headers: const {
                            'Accept': 'image/*',
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error3, stackTrace3) {
                            print('All URLs failed: $possibleUrls, final error: $error3');
                            return const Center(child: Text('Tidak dapat memuat foto'));
                          },
                        );
                      },
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
