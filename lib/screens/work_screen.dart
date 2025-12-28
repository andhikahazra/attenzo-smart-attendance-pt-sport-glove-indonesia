import 'package:flutter/material.dart';

class WorkScreen extends StatelessWidget {
  const WorkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kerja',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A4C),
                ),
              ),
              const SizedBox(height: 20),

              // Attendance Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grafik Kehadiran Minggu Ini',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A4C),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildDayBox('Sen', 8 > 0),
                        _buildDayBox('Sel', 7 > 0),
                        _buildDayBox('Rab', 9 > 0),
                        _buildDayBox('Kam', 6 > 0),
                        _buildDayBox('Jum', 8 > 0),
                        _buildDayBox('Sab', 0 > 0),
                        _buildDayBox('Min', 8 > 0),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Attendance Statistics
              const Text(
                'Statistik Kehadiran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A4C),
                ),
              ),
              const SizedBox(height: 15),

              // Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Masuk',
                      value: '22',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Telat',
                      value: '3',
                      icon: Icons.access_time,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Hari Kerja',
                      value: '25',
                      icon: Icons.calendar_today,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Tidak Masuk',
                      value: '0',
                      icon: Icons.cancel,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Leave Request Section
              const Text(
                'Pengajuan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A4C),
                ),
              ),
              const SizedBox(height: 15),

              _buildMenuCard(
                icon: Icons.event_note,
                title: 'Pengajuan Cuti',
                subtitle: 'Ajukan permohonan cuti',
                color: Colors.blue,
                onTap: () {},
              ),
              _buildMenuCard(
                icon: Icons.medical_services,
                title: 'Pengajuan Sakit',
                subtitle: 'Laporan sakit dengan surat keterangan',
                color: Colors.red,
                onTap: () {},
              ),
              _buildMenuCard(
                icon: Icons.access_time,
                title: 'Lembur',
                subtitle: 'Pengajuan lembur',
                color: Colors.purple,
                onTap: () {},
              ),
              _buildMenuCard(
                icon: Icons.work_off,
                title: 'Izin',
                subtitle: 'Pengajuan izin tidak masuk',
                color: Colors.orange,
                onTap: () {},
              ),

              const SizedBox(height: 25),

              // Task Section
              const Text(
                'Tugas Hari Ini',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A4C),
                ),
              ),
              const SizedBox(height: 15),

              _buildTaskCard(
                title: 'Quality Control Check',
                time: '09:00 - 11:00',
                status: 'In Progress',
                priority: 'High',
              ),
              _buildTaskCard(
                title: 'Machine Maintenance',
                time: '13:00 - 15:00',
                status: 'Pending',
                priority: 'Medium',
              ),
              _buildTaskCard(
                title: 'Team Meeting',
                time: '15:30 - 16:30',
                status: 'Scheduled',
                priority: 'Low',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF1E3A4C),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String time,
    required String status,
    required String priority,
  }) {
    Color statusColor;
    switch (status) {
      case 'In Progress':
        statusColor = Colors.blue;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    Color priorityColor;
    switch (priority) {
      case 'High':
        priorityColor = Colors.red;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E3A4C),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 5),
              Text(
                time,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayBox(String day, bool isPresent) {
    return Column(
      children: [
        Text(
          day,
          style: const TextStyle(
            color: Color(0xFF1E3A4C),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPresent ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isPresent ? Icons.check : Icons.close,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
