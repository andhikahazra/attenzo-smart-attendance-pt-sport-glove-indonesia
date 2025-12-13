import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../utils/app_colors.dart';
import '../widgets/bottom_nav_bar.dart';
import 'check_in_screen.dart';
import 'profile_screen.dart';
import 'riwayat_screen.dart';
import 'work_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _currentIndex == 0
          ? HomeContent(userName: user?.name)
          : _currentIndex == 1
          ? const RiwayatScreen()
          : _currentIndex == 2
          ? const WorkScreen()
          : const ProfileContent(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key, this.userName});

  final String? userName;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0F172A);
    return SafeArea(
      child: Container(
        color: background,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(userName),
                    const SizedBox(height: 24),
                    Text(
                      'Time to do what you do best',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "What's up, ${userName ?? 'there'}?",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _buildCheckInCard(context, userName),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              _buildDashboardSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(String? name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Text(
                (name != null && name.isNotEmpty) ? name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckInCard(BuildContext context, String? name) {
    return SizedBox(
      height: 190,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 24,
            right: 24,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
          Positioned(
            top: 22,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                color: const Color(0xFF112032),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name ?? '—',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Machine Division',
                              style: TextStyle(
                                color: Color(0xFFCBD5F5),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFFCBD5F5),
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Office, Yogyakarta, IN',
                                  style: TextStyle(
                                    color: Color(0xFFCBD5F5),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Divider(color: Colors.white.withOpacity(0.2), height: 1),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckInScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF112032),
                        shadowColor: Colors.transparent,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('CHECK IN NOW'),
                          SizedBox(width: 10),
                          Icon(Icons.qr_code_scanner_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSection(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(),
            const SizedBox(height: 30),
            _buildRecentActivitySection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final cards = <_OverviewCardData>[
      _OverviewCardData(
        icon: Icons.logout_rounded,
        iconBackground: const Color(0xFFE0E7FF),
        iconColor: const Color(0xFF4338CA),
        title: 'Check in',
        value: '09:10',
        valueSuffix: 'AM',
        subtitle: 'Checked in success',
        statusLabel: 'On time',
        statusColor: const Color(0xFFF97316),
      ),
      _OverviewCardData(
        icon: Icons.login_rounded,
        iconBackground: const Color(0xFFE2E8F0),
        iconColor: const Color(0xFF1E293B),
        title: 'Check out',
        value: '--:--',
        subtitle: "It's not time yet",
        statusLabel: 'n/a',
        statusColor: const Color(0xFFE2E8F0),
        statusTextColor: const Color(0xFF475569),
      ),
      _OverviewCardData(
        icon: Icons.coffee_rounded,
        iconBackground: const Color(0xFFFDE68A),
        iconColor: const Color(0xFFB45309),
        title: 'Break',
        value: '11:40',
        valueSuffix: 'AM',
        subtitle: 'Break ongoing',
        statusLabel: 'Too Early',
        statusColor: const Color(0xFFEF4444),
      ),
      _OverviewCardData(
        icon: Icons.timelapse_rounded,
        iconBackground: const Color(0xFFE0F2FE),
        iconColor: const Color(0xFF0369A1),
        title: 'Overtime',
        value: 'Total',
        valueSuffix: '8 Hour',
        subtitle: 'Update, Jul 18 2024',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Wed, Jul 22 2024',
                    style: TextStyle(
                      color: Color(0xFF475569),
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) => _buildOverviewCard(cards[index]),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    final activities = <_RecentActivityData>[
      _RecentActivityData(
        icon: Icons.logout_rounded,
        title: 'Team standup',
        subtitle: '08:30 AM | Zoom meeting',
        status: 'Completed',
        statusColor: const Color(0xFFE0F2FE),
        statusTextColor: const Color(0xFF0C4A6E),
      ),
      _RecentActivityData(
        icon: Icons.login_rounded,
        title: 'Check in',
        subtitle: '09:10 AM | HQ lobby',
        status: 'On time',
        statusColor: const Color(0xFFDCFCE7),
        statusTextColor: const Color(0xFF166534),
      ),
      _RecentActivityData(
        icon: Icons.coffee_rounded,
        title: 'Coffee break',
        subtitle: '11:40 AM | Pantry',
        status: 'Ongoing',
        statusColor: const Color(0xFFFDE68A),
        statusTextColor: const Color(0xFF854D0E),
      ),
      _RecentActivityData(
        icon: Icons.logout_rounded,
        title: 'Check out',
        subtitle: '--:-- | Pending checkout',
        status: 'Pending',
        statusColor: const Color(0xFFFFF7ED),
        statusTextColor: const Color(0xFFC2410C),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RiwayatScreenPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                foregroundColor: const Color(0xFF1D4ED8),
                backgroundColor: const Color(0xFFEFF6FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                children: const [
                  Text(
                    'See all',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          separatorBuilder: (_, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Container(height: 1, color: const Color(0xFFE2E8F0)),
          ),
          itemBuilder: (_, index) =>
              _buildRecentActivityItem(activities[index]),
        ),
      ],
    );
  }

  Widget _buildRecentActivityItem(_RecentActivityData data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(data.icon, color: const Color(0xFF0F172A), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.subtitle,
                style: TextStyle(color: const Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
        _buildStatusChip(data.status, data.statusColor, data.statusTextColor),
      ],
    );
  }

  Widget _buildStatusChip(
    String label,
    Color background,
    Color textColor, {
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: isCompact ? 10 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildOverviewCard(_OverviewCardData data) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          if (data.valueSuffix != null || data.statusLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (data.valueSuffix != null)
                    Text(
                      data.valueSuffix!,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (data.valueSuffix != null && data.statusLabel != null)
                    const SizedBox(width: 8),
                  if (data.statusLabel != null)
                    _buildStatusChip(
                      data.statusLabel!,
                      data.statusColor,
                      data.statusTextColor,
                      isCompact: true,
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              data.subtitle,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10.5,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCardData {
  const _OverviewCardData({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.valueSuffix,
    this.statusLabel,
    this.statusColor = const Color(0xFF22C55E),
    this.statusTextColor = Colors.white,
    this.iconBackground = const Color(0xFFE2E8F0),
    this.iconColor = const Color(0xFF1E293B),
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final String? valueSuffix;
  final String? statusLabel;
  final Color statusColor;
  final Color statusTextColor;
  final Color iconBackground;
  final Color iconColor;
}

class _RecentActivityData {
  const _RecentActivityData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    this.statusTextColor = Colors.white,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final Color statusTextColor;
}
