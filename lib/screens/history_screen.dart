import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A4C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Back',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header with month selector
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Bulan Ini',
                  hintStyle: TextStyle(
                    color: const Color(0xFF1E3A4C),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1E3A4C)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                readOnly: true,
              ),
            ),

            const SizedBox(height: 10),

            // History List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                children: [
                  _buildHistoryCard(
                    date: '25 - September - 2025',
                    office: 'Office H',
                    timeIn: '18.00',
                    timeOut: '01.00',
                    status: 'HADIR',
                    isPresent: true,
                  ),
                  _buildHistoryCard(
                    date: '25 - September - 2025',
                    office: 'Office H',
                    timeIn: '18.00',
                    timeOut: '01.00',
                    status: 'TELAT',
                    isPresent: false,
                  ),
                  _buildHistoryCard(
                    date: '25 - September - 2025',
                    office: 'Office H',
                    timeIn: '18.00',
                    timeOut: '01.00',
                    status: 'HADIR',
                    isPresent: true,
                  ),
                  _buildHistoryCard(
                    date: '25 - September - 2025',
                    office: 'Office H',
                    timeIn: '18.00',
                    timeOut: '01.00',
                    status: 'HADIR',
                    isPresent: true,
                  ),
                  _buildHistoryCard(
                    date: '25 - September - 2025',
                    office: 'Office H',
                    timeIn: '18.00',
                    timeOut: '01.00',
                    status: 'HADIR',
                    isPresent: true,
                  ),
                  _buildHistoryCard(
                    date: '25 - September - 2025',
                    office: 'Office H',
                    timeIn: '18.00',
                    timeOut: '01.00',
                    status: 'HADIR',
                    isPresent: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required String date,
    required String office,
    required String timeIn,
    required String timeOut,
    required String status,
    required bool isPresent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: Color(0xFF1E3A4C),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPresent
                      ? Colors.green.shade50
                      : status == 'TELAT'
                      ? Colors.orange.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isPresent
                        ? Colors.green
                        : status == 'TELAT'
                        ? Colors.orange
                        : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            office,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'TIME IN',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      timeIn,
                      style: const TextStyle(
                        color: Color(0xFF1E3A4C),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'TIME OUT',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      timeOut,
                      style: const TextStyle(
                        color: Color(0xFF1E3A4C),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
