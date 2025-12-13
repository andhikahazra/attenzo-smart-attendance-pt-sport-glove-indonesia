import 'dart:io';

import 'package:flutter/material.dart';
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

    return _api.getAttendanceRecords(token: token, userId: user.id);
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
                      color: Colors.white.withOpacity(0.72),
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

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        children: [
                          _buildSummary(records),
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
                          ...records.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final record = entry.value;
                            final bottom = idx == records.length - 1 ? 0.0 : 12.0;
                            return Padding(
                              padding: EdgeInsets.only(bottom: bottom),
                              child: _buildHistoryItem(record),
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

  Widget _buildSummary(List<AttendanceRecord> records) {
    final hadir = records.where((r) => r.status.toLowerCase() == 'hadir').length;
    final telat = records.where((r) => r.status.toLowerCase() == 'telat').length;
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Hadir',
            hadir.toString(),
            const Color(0xFF22C55E),
            Icons.check_circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard(
            'Total Telat',
            telat.toString(),
            const Color(0xFFF97316),
            Icons.access_time,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(AttendanceRecord record) {
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

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                record.status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  record.type,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTimeDetail(Icons.calendar_today_rounded, record.attendanceDate),
              const SizedBox(width: 16),
              _buildTimeDetail(Icons.access_time_rounded, record.attendanceTime),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.pin_drop_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'User ID: ${record.userId}',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (photoUrl != null)
                TextButton.icon(
                  onPressed: () => _showPhoto(photoUrl),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: const Text('View Photo'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    foregroundColor: const Color(0xFF0F172A),
                  ),
                )
              else
                Text(
                  'Tanpa foto',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
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

  Widget _buildTimeDetail(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
    final needsStoragePrefix = !raw.startsWith('/storage/') && !raw.startsWith('storage/');
    final withStorage = needsStoragePrefix ? '/storage/$raw' : (raw.startsWith('/') ? raw : '/$raw');
    return '${ApiService.baseUrl}$withStorage';
  }

  void _showPhoto(String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(child: Text('Tidak dapat memuat foto')),
                ),
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
    );
  }
}
