import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../models/location.dart';
import '../models/shift.dart';
import '../services/api_service.dart';
import '../state/auth_state.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  Future<void>? _initializeCameraFuture;
  String? _cameraError;
  bool _permissionPermanentlyDenied = false;
  bool _isCheckedIn = false;
  bool _canCheckIn = true;
  bool _canCheckOut = false;
  String _attendanceStatus = 'not_checked_in';
  String _displayTime = '';
  bool _isPosting = false;
  bool _isLoadingStatus = true;
  final ApiService _api = ApiService();
  Timer? _timer;
  DateTime? _lastStatusFetchDate; // Track last date status was fetched

  // Location validation states
  List<Location> _officeLocations = [];
  bool _isLocationValid = false;
  bool _isCheckingLocation = true;
  String _locationStatus = 'Memeriksa lokasi...';
  String? _locationWarning;
  bool _hasShownLocationWarning = false; // Track if warning has been shown

  // Shift data from backend
  Shift? _shift;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _initializeLocationValidation();
    // Delay status check to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchShiftData();
      _fetchTodayStatus();
      _updateTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    });
  }

  Future<void> _fetchShiftData() async {
    debugPrint('🔍 Starting shift data fetch...');
    final auth = context.read<AuthState>();
    final token = auth.token;

    if (token == null) {
      debugPrint('❌ No token available for shift fetch');
      return;
    }

    try {
      debugPrint('📡 Fetching shift from API...');
      final shift = await _api.getShift(token: token);

      debugPrint('=== SHIFT DATA RECEIVED ===');
      if (shift != null) {
        debugPrint('✅ Shift loaded successfully');
        debugPrint('Shift Name: ${shift.name}');
        debugPrint('Start Time: ${shift.startTime}');
        debugPrint('End Time: ${shift.endTime}');
        debugPrint(
          'Early Check-in Tolerance: ${shift.earlyCheckinTolerance} min',
        );
        debugPrint('Max Check-in Hours: ${shift.maxCheckinHours} hours');
        debugPrint(
          'Early Check-out Tolerance: ${shift.earlyLeaveTolerance} min',
        );
        debugPrint('Max Check-out Hours: ${shift.maxCheckoutHours} hours');
      } else {
        debugPrint('⚠️ Shift is null - user has no shift assigned');
      }
      debugPrint('===========================');

      setState(() {
        _shift = shift;
      });

      // Show dialog if no shift assigned
      if (shift == null && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _showNoShiftDialog();
        }
      } else if (shift != null && mounted) {
        // Validate timing for check-in/check-out
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _validateAttendanceTiming();
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching shift data: $e');
    }
  }

  Future<void> _initializeLocationValidation() async {
    await _fetchOfficeLocations();
    await _validateUserLocation();
  }

  Future<void> _fetchTodayStatus({bool skipDialogs = false}) async {
    final auth = context.read<AuthState>();
    final token = auth.token;

    if (token == null) {
      setState(() {
        _isLoadingStatus = false;
      });
      return;
    }

    try {
      final statusData = await _api.getTodayStatus(token: token);

      // Check if the response date matches today's date
      final responseDate = statusData['date'] as String?;
      final now = DateTime.now();
      final todayString =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      String status;
      bool canCheckIn;
      bool canCheckOut;

      if (responseDate != null && responseDate != todayString) {
        // Response is for a different date, reset to default values
        debugPrint(
          '⚠️ Response date ($responseDate) does not match today ($todayString)',
        );
        debugPrint('Resetting status to not_checked_in');
        status = 'not_checked_in';
        canCheckIn = true; // Assume can check in for new day
        canCheckOut = false;
      } else {
        // Response is for today or no date field, use the response values
        status = statusData['status'] as String? ?? 'not_checked_in';
        canCheckIn = statusData['can_check_in'] as bool? ?? false;
        canCheckOut = statusData['can_check_out'] as bool? ?? false;
      }

      // Debug logging
      debugPrint('=== TODAY STATUS DEBUG ===');
      debugPrint('Response Date: $responseDate');
      debugPrint('Today Date: $todayString');
      debugPrint('Status: $status');
      debugPrint('Can Check In: $canCheckIn');
      debugPrint('Can Check Out: $canCheckOut');
      debugPrint('Full Response: $statusData');
      debugPrint('========================');

      setState(() {
        _canCheckIn = canCheckIn;
        _canCheckOut = canCheckOut;
        _attendanceStatus = status;
        _isCheckedIn =
            _attendanceStatus == 'checked_in' ||
            _attendanceStatus == 'completed';
        _isLoadingStatus = false;
        _lastStatusFetchDate = DateTime.now(); // Save fetch date
      });

      // Check attendance status and show appropriate dialog
      if (!mounted) return;

      // Skip dialogs if requested (e.g., after successful attendance)
      if (skipDialogs) {
        debugPrint('Skipping dialog validation as requested');
        return;
      }

      // Show dialog immediately after setState
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Small delay for UI to settle
      if (!mounted) return;

      if (status == 'completed') {
        // Already completed both check-in and check-out today
        debugPrint('Showing completed dialog');
        _showAttendanceCompletedDialog();
      } else if (status == 'not_checked_in' && !canCheckIn) {
        // Not checked in yet but can't check in anymore (past maximum time)
        debugPrint('Showing not allowed dialog for check_in');
        _showAttendanceNotAllowedDialog('check_in');
      } else if (status == 'checked_in' && !canCheckOut) {
        // Already checked in but can't check out anymore (past maximum time)
        debugPrint('Showing not allowed dialog for check_out');
        _showAttendanceNotAllowedDialog('check_out');
      } else {
        // Validate timing for early check-in/check-out
        debugPrint('Validating attendance timing...');
        _validateAttendanceTiming();
      }
    } catch (e) {
      debugPrint('Error fetching today status: $e');
      setState(() {
        _isLoadingStatus = false;
      });
    }
  }

  void _validateAttendanceTiming() {
    if (!mounted || _shift == null) return;

    final now = DateTime.now();
    final shift = _shift!;

    // Get timing boundaries
    final earlyCheckinTime = shift.getEarlyCheckinTime(now);
    final earlyCheckoutTime = shift.getEarlyCheckoutTime(now);

    debugPrint('=== TIMING VALIDATION ===');
    debugPrint('Current Time: ${now.hour}:${now.minute}');
    debugPrint('Early Check-in Time: ${earlyCheckinTime.hour}:${earlyCheckinTime.minute}');
    debugPrint('Early Checkout Time: ${earlyCheckoutTime.hour}:${earlyCheckoutTime.minute}');
    debugPrint('Attendance Status: $_attendanceStatus');
    debugPrint('Can Check In: $_canCheckIn');
    debugPrint('Can Check Out: $_canCheckOut');
    debugPrint('========================');

    // Check if user is trying to check-in too early
    if (_attendanceStatus == 'not_checked_in' && now.isBefore(earlyCheckinTime)) {
      debugPrint('⚠️ Too early for check-in!');
      _showEarlyAttendanceDialog('check_in', earlyCheckinTime);
      return;
    }

    // Check if user is trying to check-out too early
    if (_attendanceStatus == 'checked_in' && now.isBefore(earlyCheckoutTime)) {
      debugPrint('⚠️ Too early for check-out!');
      _showEarlyAttendanceDialog('check_out', earlyCheckoutTime);
      return;
    }

    debugPrint('✅ Timing is valid for attendance');
  }

  void _showEarlyAttendanceDialog(String type, DateTime allowedTime) {
    if (!mounted) return;

    final isCheckIn = type == 'check_in';
    final title = isCheckIn ? 'Terlalu Cepat untuk Check-in' : 'Terlalu Cepat untuk Check-out';
    final message = isCheckIn
        ? 'Anda hanya dapat melakukan check-in mulai pukul ${allowedTime.hour.toString().padLeft(2, '0')}:${allowedTime.minute.toString().padLeft(2, '0')}.\n\nSilakan kembali pada waktu yang tepat.'
        : 'Anda hanya dapat melakukan check-out mulai pukul ${allowedTime.hour.toString().padLeft(2, '0')}:${allowedTime.minute.toString().padLeft(2, '0')}.\n\nSilakan kembali pada waktu yang tepat.';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    size: 40,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Kembali ke Home',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNoShiftDialog() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 40,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Shift Belum Ditentukan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Anda belum memiliki shift kerja.\\n\\nSilakan hubungi admin untuk mengatur shift Anda.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Kembali ke Home',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAttendanceCompletedDialog() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 40,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Absensi Sudah Selesai',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Anda sudah menyelesaikan check-in dan check-out untuk hari ini.\n\nSampai jumpa besok!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Kembali ke Home',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAttendanceNotAllowedDialog(String type) {
    if (!mounted) return;

    final isCheckIn = type == 'check_in';
    String? maxTime;

    if (_shift != null) {
      if (isCheckIn) {
        final maxCheckinTime = _shift!.getMaxCheckinTime(DateTime.now());
        maxTime =
            '${maxCheckinTime.hour.toString().padLeft(2, '0')}:${maxCheckinTime.minute.toString().padLeft(2, '0')}';
      } else {
        final maxCheckoutTime = _shift!.getMaxCheckoutTime(DateTime.now());
        maxTime =
            '${maxCheckoutTime.hour.toString().padLeft(2, '0')}:${maxCheckoutTime.minute.toString().padLeft(2, '0')}';
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    size: 40,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Waktu Absensi Terlewat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isCheckIn
                      ? maxTime != null
                            ? 'Waktu maksimal check-in adalah pukul $maxTime.\\n\\nAnda sudah melewati batas waktu. Silakan hubungi admin untuk informasi lebih lanjut.'
                            : 'Waktu untuk check-in hari ini sudah terlewat.\\n\\nSilakan hubungi admin untuk informasi lebih lanjut.'
                      : maxTime != null
                      ? 'Waktu maksimal check-out adalah pukul $maxTime.\\n\\nAnda sudah melewati batas waktu. Silakan hubungi admin untuk informasi lebih lanjut.'
                      : 'Waktu untuk check-out hari ini sudah terlewat.\\n\\nSilakan hubungi admin untuk informasi lebih lanjut.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Kembali ke Home',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTooEarlyDialog(String type) {
    if (!mounted) return;

    final isCheckIn = type == 'check_in';
    String? earlyTime;
    String shiftInfo = '';

    if (_shift != null) {
      if (isCheckIn) {
        final earlyCheckinTime = _shift!.getEarlyCheckinTime(DateTime.now());
        earlyTime =
            '${earlyCheckinTime.hour.toString().padLeft(2, '0')}:${earlyCheckinTime.minute.toString().padLeft(2, '0')}';
        shiftInfo =
            'Shift ${_shift!.name}\\nJam Kerja: ${_shift!.formatTime(_shift!.startTime)} - ${_shift!.formatTime(_shift!.endTime)}';
      } else {
        final earlyCheckoutTime = _shift!.getEarlyCheckoutTime(DateTime.now());
        earlyTime =
            '${earlyCheckoutTime.hour.toString().padLeft(2, '0')}:${earlyCheckoutTime.minute.toString().padLeft(2, '0')}';
        shiftInfo =
            'Shift ${_shift!.name}\\nJam Kerja: ${_shift!.formatTime(_shift!.startTime)} - ${_shift!.formatTime(_shift!.endTime)}';
      }
    }

    final timeLabel = isCheckIn ? 'check-in' : 'check-out';

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    size: 40,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Belum Waktu Absen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  earlyTime != null && shiftInfo.isNotEmpty
                      ? 'Anda mencoba $timeLabel terlalu cepat.\\n\\n$shiftInfo\\n\\nWaktu $timeLabel dimulai pukul $earlyTime.\\n\\nSilakan coba lagi nanti.'
                      : 'Anda mencoba $timeLabel terlalu cepat.\\n\\nSilakan coba lagi nanti.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchOfficeLocations() async {
    final auth = context.read<AuthState>();
    final token = auth.token;

    if (token == null) {
      setState(() {
        _isCheckingLocation = false;
        _locationWarning = 'Token tidak tersedia';
      });
      return;
    }

    try {
      final locations = await _api.getLocations(token: token);
      setState(() {
        _officeLocations = locations;
      });
    } catch (e) {
      debugPrint('Error fetching office locations: $e');
      setState(() {
        _isCheckingLocation = false;
        _locationWarning = 'Gagal memuat data lokasi kantor';
      });
    }
  }

  Future<void> _validateUserLocation() async {
    if (_officeLocations.isEmpty) {
      setState(() {
        _isCheckingLocation = false;
        _locationWarning = 'Tidak ada data lokasi kantor';
      });
      return;
    }

    try {
      // Request location permission
      final permissionStatus = await Permission.location.status;
      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        final permission = await Permission.location.request();
        if (!permission.isGranted) {
          setState(() {
            _isCheckingLocation = false;
            _locationWarning = 'Izin lokasi diperlukan untuk absensi';
          });
          return;
        }
      } else if (!permissionStatus.isGranted) {
        setState(() {
          _isCheckingLocation = false;
          _locationWarning = 'Izin lokasi diperlukan untuk absensi';
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Check if user is within any office location radius
      bool isValid = false;
      Location? nearestLocation;
      double minDistance = double.infinity;

      for (final office in _officeLocations) {
        final distance = _calculateDistance(
          position.latitude,
          position.longitude,
          office.latitude,
          office.longitude,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearestLocation = office;
        }

        if (distance <= office.allowedRadiusMeters) {
          isValid = true;
          break;
        }
      }

      setState(() {
        _isCheckingLocation = false;
        _isLocationValid = isValid;
        if (isValid) {
          _locationStatus = 'Lokasi valid ✓';
          _locationWarning = null;
          _hasShownLocationWarning =
              false; // Reset flag when location becomes valid
        } else {
          _locationStatus = 'Lokasi tidak valid';
          _locationWarning =
              'Anda tidak berada di lokasi kerja. Jarak dari ${nearestLocation?.name ?? "kantor"}: ${minDistance.toStringAsFixed(0)} meter';
        }
      });

      // Show warning flash if location is invalid
      if (!isValid) {
        _showLocationWarning();
      }
    } catch (e) {
      debugPrint('Error validating user location: $e');
      setState(() {
        _isCheckingLocation = false;
        _isLocationValid = false;
        _locationWarning = 'Gagal memeriksa lokasi Anda';
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Radius bumi dalam meter
    final double dLat = (lat2 - lat1) * pi / 180;
    final double dLon = (lon2 - lon1) * pi / 180;
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  void _showLocationWarning() {
    // Only show warning if not already shown to prevent spam
    if (_hasShownLocationWarning) return;

    _hasShownLocationWarning = true;

    // Show warning snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _locationWarning ?? 'Anda tidak berada di lokasi kerja',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 8), // Increased duration
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            }
          },
        ),
        onVisible: () {
          // Reset flag when snackbar is dismissed
          Future.delayed(const Duration(seconds: 8), () {
            if (mounted) {
              _hasShownLocationWarning = false;
            }
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _api.dispose();
    _cameraController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final formatted = TimeOfDay.fromDateTime(now).format(context);

    // Check if day has changed since last status fetch
    final lastFetchDate = _lastStatusFetchDate;
    if (lastFetchDate != null &&
        (now.year != lastFetchDate.year ||
            now.month != lastFetchDate.month ||
            now.day != lastFetchDate.day)) {
      debugPrint('Day changed during timer, refreshing status...');
      _fetchTodayStatus();
      _validateUserLocation();
    }

    setState(() {
      _displayTime = formatted;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (state == AppLifecycleState.resumed) {
      // Check if day has changed and refresh status
      final now = DateTime.now();
      final lastFetchDate = _lastStatusFetchDate;

      if (lastFetchDate == null ||
          now.year != lastFetchDate.year ||
          now.month != lastFetchDate.month ||
          now.day != lastFetchDate.day) {
        debugPrint('Day changed or first load, refreshing status...');
        _fetchTodayStatus();
        _validateUserLocation();
      }

      if (controller == null) {
        _initializeCamera();
      }
      return;
    }

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      setState(() {
        _cameraController = null;
        _initializeCameraFuture = null;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      if (!await _ensureCameraPermission()) {
        return;
      }

      final previousController = _cameraController;
      if (previousController != null) {
        await previousController.dispose();
      }

      final cameras = await availableCameras();
      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() {
          _cameraController = null;
          _initializeCameraFuture = null;
          _cameraError = 'Tidak ada kamera yang tersedia.';
          _permissionPermanentlyDenied = false;
        });
        return;
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      final initializeFuture = controller.initialize();

      setState(() {
        _cameraController = controller;
        _initializeCameraFuture = initializeFuture;
        _cameraError = null;
        _permissionPermanentlyDenied = false;
      });

      await initializeFuture;
      if (!mounted) {
        await controller.dispose();
        return;
      }

      if (controller.value.isInitialized) {
        setState(() {});
      }
    } on CameraException catch (error) {
      setState(() {
        _cameraController = null;
        _initializeCameraFuture = null;
        _cameraError = error.description ?? error.code;
        _permissionPermanentlyDenied = false;
      });
    } catch (error) {
      setState(() {
        _cameraController = null;
        _initializeCameraFuture = null;
        _cameraError = error.toString();
        _permissionPermanentlyDenied = false;
      });
    }
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      setState(() {
        _permissionPermanentlyDenied = false;
      });
      return true;
    }

    final result = await Permission.camera.request();

    if (result.isGranted) {
      setState(() {
        _permissionPermanentlyDenied = false;
        _cameraError = null;
      });
      return true;
    }

    if (!mounted) {
      return false;
    }

    setState(() {
      _cameraController = null;
      _initializeCameraFuture = null;
      _permissionPermanentlyDenied = result.isPermanentlyDenied;
      _cameraError = result.isPermanentlyDenied
          ? 'Izin kamera ditolak permanen. Silakan aktifkan melalui Pengaturan aplikasi.'
          : 'Izin kamera diperlukan untuk menampilkan pratinjau.';
    });

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F7),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4F6FB), Color(0xFFDDE1EE)],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const _TopBar(),
                          const SizedBox(height: 16),
                          _ScanCard(
                            cameraController: _cameraController,
                            initializeFuture: _initializeCameraFuture,
                            cameraError: _cameraError,
                            permissionPermanentlyDenied:
                                _permissionPermanentlyDenied,
                            onOpenSettings: () async {
                              await openAppSettings();
                            },
                            onRetry: _initializeCamera,
                            onActionTap: _handleCheckAction,
                            displayTime: _displayTime,
                            isCheckedIn: _isCheckedIn,
                            isLoading: _isPosting || _isLoadingStatus,
                            isLocationValid: _isLocationValid,
                          ),
                          const SizedBox(height: 20),
                          _LocationCard(
                            isCheckingLocation: _isCheckingLocation,
                            isLocationValid: _isLocationValid,
                            locationStatus: _locationStatus,
                            locationWarning: _locationWarning,
                            onRetryLocation: () {
                              setState(() {
                                _isCheckingLocation = true;
                                _locationWarning = null;
                                _hasShownLocationWarning =
                                    false; // Reset warning flag
                              });
                              _validateUserLocation();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleCheckAction() async {
    debugPrint('🔘 CHECK ACTION BUTTON PRESSED');

    if (!mounted || _isPosting) {
      debugPrint('⚠️ Action blocked: mounted=$mounted, isPosting=$_isPosting');
      return;
    }

    setState(() {
      _isPosting = true;
    });

    debugPrint('📌 Shift data status: ${_shift != null ? "LOADED" : "NULL"}');
    if (_shift != null) {
      debugPrint('   Shift: ${_shift!.name}');
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      debugPrint('❌ Camera not ready');
      setState(() {
        _isPosting = false;
      });
      _showStatusDialog(
        'Kamera belum siap untuk mengambil foto.',
        isError: true,
      );
      return;
    }

    final auth = context.read<AuthState>();
    final token = auth.token;
    final user = auth.user;
    if (token == null || user == null) {
      debugPrint('❌ No token or user');
      setState(() {
        _isPosting = false;
      });
      _showStatusDialog('Silakan login ulang untuk absen.', isError: true);
      return;
    }

    // Determine action type based on backend status
    String type;
    if (_canCheckIn) {
      type = 'check_in';
      debugPrint('📍 Action type: CHECK-IN');
    } else if (_canCheckOut) {
      type = 'check_out';
      debugPrint('📍 Action type: CHECK-OUT');
    } else {
      debugPrint('❌ No action available (already completed)');
      _showStatusDialog(
        'Anda sudah menyelesaikan absensi hari ini.',
        isError: false,
      );
      setState(() {
        _isPosting = false;
      });
      return;
    }

    // Check if shift data is available and validate time
    if (_shift != null) {
      final now = DateTime.now();

      debugPrint('=== SHIFT TIME VALIDATION ===');
      debugPrint('Current time: ${now.hour}:${now.minute}:${now.second}');
      debugPrint('Action type: $type');
      debugPrint('Shift: ${_shift!.name}');

      if (type == 'check_in') {
        // Check if too early for check-in
        final earlyCheckinTime = _shift!.getEarlyCheckinTime(now);
        debugPrint(
          'Early check-in time: ${earlyCheckinTime.hour}:${earlyCheckinTime.minute}',
        );
        debugPrint('Is before early time: ${now.isBefore(earlyCheckinTime)}');

        if (now.isBefore(earlyCheckinTime)) {
          debugPrint('❌ TOO EARLY FOR CHECK-IN');
          setState(() {
            _isPosting = false;
          });
          _showTooEarlyDialog(type);
          return;
        }

        // Check if too late for check-in
        final maxCheckinTime = _shift!.getMaxCheckinTime(now);
        debugPrint(
          'Max check-in time: ${maxCheckinTime.hour}:${maxCheckinTime.minute}',
        );
        debugPrint('Is after max time: ${now.isAfter(maxCheckinTime)}');
        debugPrint('Can check in: $_canCheckIn');

        if (now.isAfter(maxCheckinTime) && !_canCheckIn) {
          debugPrint('❌ TOO LATE FOR CHECK-IN');
          setState(() {
            _isPosting = false;
          });
          _showAttendanceNotAllowedDialog(type);
          return;
        }
      } else if (type == 'check_out') {
        // Check if too early for check-out
        final earlyCheckoutTime = _shift!.getEarlyCheckoutTime(now);
        debugPrint(
          'Early check-out time: ${earlyCheckoutTime.hour}:${earlyCheckoutTime.minute}',
        );
        debugPrint('Is before early time: ${now.isBefore(earlyCheckoutTime)}');

        if (now.isBefore(earlyCheckoutTime)) {
          debugPrint('❌ TOO EARLY FOR CHECK-OUT');
          setState(() {
            _isPosting = false;
          });
          _showTooEarlyDialog(type);
          return;
        }

        // Check if too late for check-out
        final maxCheckoutTime = _shift!.getMaxCheckoutTime(now);
        debugPrint(
          'Max check-out time: ${maxCheckoutTime.hour}:${maxCheckoutTime.minute}',
        );
        debugPrint('Is after max time: ${now.isAfter(maxCheckoutTime)}');
        debugPrint('Can check out: $_canCheckOut');

        if (now.isAfter(maxCheckoutTime) && !_canCheckOut) {
          debugPrint('❌ TOO LATE FOR CHECK-OUT');
          setState(() {
            _isPosting = false;
          });
          _showAttendanceNotAllowedDialog(type);
          return;
        }
      }

      debugPrint('✅ TIME VALIDATION PASSED');
      debugPrint('============================');
    } else {
      debugPrint('⚠️ No shift data available, skipping time validation');
    }

    final now = DateTime.now();
    final dateStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEEF2FF), Color(0xFFD1D5FA)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.13),
                  blurRadius: 44,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Mohon tunggu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3730A3),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Proses verifikasi wajah sedang berlangsung...\nJangan tutup aplikasi atau keluar dari halaman ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final picture = await controller.takePicture();
      final file = File(picture.path);

      await _api.storeAttendance(
        token: token,
        type: type,
        attendanceDate: dateStr,
        attendanceTime: timeStr,
        photoFile: file,
      );

      if (!mounted) return;
      final formattedTime = TimeOfDay.now().format(context);

      // Refresh today's status from backend (skip dialogs)
      await _fetchTodayStatus(skipDialogs: true);

      if (!mounted) return;
      setState(() {
        _displayTime = formattedTime;
      });

      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
      _showSuccessDialog(
        type == 'check_in' ? 'Check-In' : 'Check-Out',
        formattedTime,
      );
    } on CameraException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showStatusDialog(
        'Gagal mengambil foto: ${e.description ?? e.code}',
        isError: true,
      );
    } on HttpException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final msg = e.message;
      if (msg.contains('Face could not be detected')) {
        _showStatusDialog(
          'Wajah tidak terdeteksi pada foto yang diambil.\n\nPastikan wajah Anda jelas terlihat di dalam frame dan tidak terhalang. Silakan coba lagi.',
          isError: true,
        );
      } else if (msg.contains('tidak diperbolehkan') ||
          msg.contains('Maksimal')) {
        // Handle maximum check-in/check-out hours validation errors
        _showStatusDialog(
          msg,
          isError: true,
          title: 'Waktu Absensi Tidak Valid',
        );
      } else if (msg.contains('Face not matched')) {
        _showStatusDialog(
          'Wajah tidak cocok dengan data yang terdaftar.\n\nPastikan wajah Anda yang terdaftar untuk akun ini.',
          isError: true,
          title: 'Verifikasi Wajah Gagal',
        );
      } else {
        _showStatusDialog('Gagal kirim absen: $msg', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final msg = e.toString();
      if (msg.contains('Face could not be detected')) {
        _showStatusDialog(
          'Wajah tidak terdeteksi pada foto yang diambil.\n\nPastikan wajah Anda jelas terlihat di dalam frame dan tidak terhalang. Silakan coba lagi.',
          isError: true,
        );
      } else if (msg.contains('tidak diperbolehkan') ||
          msg.contains('Maksimal')) {
        // Handle maximum check-in/check-out hours validation errors
        _showStatusDialog(
          msg,
          isError: true,
          title: 'Waktu Absensi Tidak Valid',
        );
      } else if (msg.contains('Face not matched')) {
        _showStatusDialog(
          'Wajah tidak cocok dengan data yang terdaftar.\n\nPastikan wajah Anda yang terdaftar untuk akun ini.',
          isError: true,
          title: 'Verifikasi Wajah Gagal',
        );
      } else {
        _showStatusDialog('Gagal kirim absen: $msg', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  void _showStatusDialog(
    String message, {
    bool isError = false,
    String? title,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isError
                      ? Icons.error_outline_rounded
                      : Icons.info_outline_rounded,
                  size: 48,
                  color: isError
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF6366F1),
                ),
                const SizedBox(height: 18),
                if (title != null) ...[
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: title != null ? 14 : 16,
                    fontWeight: title != null
                        ? FontWeight.w500
                        : FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isError
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String actionLabel, String formattedTime) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 40,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '$actionLabel Successful',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$formattedTime · Main Office Entrance Gate',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280).withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Close dialog
                      Navigator.of(dialogContext).pop();
                      // Pop the check-in screen to return to home
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Kembali ke Home',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TopIconButton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Morning Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Main Office · Today',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _TopIconButton(icon: Icons.more_horiz),
      ],
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF111827), size: 18),
      ),
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({
    required this.cameraController,
    required this.initializeFuture,
    required this.cameraError,
    required this.permissionPermanentlyDenied,
    required this.onOpenSettings,
    required this.onRetry,
    required this.onActionTap,
    required this.displayTime,
    required this.isCheckedIn,
    required this.isLoading,
    required this.isLocationValid,
  });

  final CameraController? cameraController;
  final Future<void>? initializeFuture;
  final String? cameraError;
  final bool permissionPermanentlyDenied;
  final Future<void> Function() onOpenSettings;
  final Future<void> Function() onRetry;
  final Future<void> Function() onActionTap;
  final String displayTime;
  final bool isCheckedIn;
  final bool isLoading;
  final bool isLocationValid;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3F4FF), Color(0xFFE0E6FF)],
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Face Recognition',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.82),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Align your face with the guide below to begin check-in.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 236,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(child: _buildCameraSurface()),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.28),
                      width: 3,
                    ),
                  ),
                ),
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 3,
                    ),
                  ),
                ),
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _CheckActionButton(
            isCheckedIn: isCheckedIn,
            time: displayTime,
            isLoading: isLoading,
            onTap: isLoading ? null : onActionTap,
            forceDisable: isLoading || !isLocationValid,
            isLocationValid: isLocationValid,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSurface() {
    if (cameraError != null && cameraError!.isNotEmpty) {
      return _CameraStatusBanner(
        icon: Icons.videocam_off_rounded,
        title: 'Kamera tidak tersedia',
        subtitle: cameraError,
        actionLabel: permissionPermanentlyDenied
            ? 'Buka Pengaturan'
            : 'Coba Lagi',
        onAction: permissionPermanentlyDenied ? onOpenSettings : onRetry,
      );
    }

    final future = initializeFuture;
    final controller = cameraController;

    if (future == null || controller == null) {
      return const _CameraStatusBanner(
        icon: Icons.videocam_rounded,
        title: 'Menyiapkan kamera...',
      );
    }

    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _CameraStatusBanner(
            icon: Icons.autorenew_rounded,
            title: 'Mengaktifkan kamera...',
          );
        }

        if (snapshot.hasError) {
          return _CameraStatusBanner(
            icon: Icons.videocam_off_rounded,
            title: 'Gagal memulai kamera',
            subtitle: snapshot.error?.toString(),
            actionLabel: 'Coba Lagi',
            onAction: onRetry,
          );
        }

        if (!controller.value.isInitialized) {
          return const _CameraStatusBanner(
            icon: Icons.videocam_rounded,
            title: 'Menunggu kamera siap...',
          );
        }

        if (controller.value.hasError) {
          return _CameraStatusBanner(
            icon: Icons.videocam_off_rounded,
            title: 'Kamera bermasalah',
            subtitle: controller.value.errorDescription,
            actionLabel: 'Coba Lagi',
            onAction: onRetry,
          );
        }

        final previewSize = controller.value.previewSize;

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (previewSize != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewSize.height,
                    height: previewSize.width,
                    child: CameraPreview(controller),
                  ),
                )
              else
                CameraPreview(controller),
            ],
          ),
        );
      },
    );
  }
}

class _CameraStatusBanner extends StatelessWidget {
  const _CameraStatusBanner({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        color: const Color(0xFFE8ECFF),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: const Color(0xFF6366F1)),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () async {
                    await onAction?.call();
                  },
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckActionButton extends StatelessWidget {
  const _CheckActionButton({
    required this.isCheckedIn,
    required this.time,
    required this.isLoading,
    this.onTap,
    this.forceDisable = false,
    this.isLocationValid = true,
  });

  final bool isCheckedIn;
  final String time;
  final bool isLoading;
  final Future<void> Function()? onTap;
  final bool forceDisable;
  final bool isLocationValid;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: forceDisable
            ? Colors.transparent
            : const Color(0xFF6366F1).withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        onTap: forceDisable ? null : () => onTap?.call(),
        child: Opacity(
          opacity: forceDisable ? 0.6 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        (isCheckedIn
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF6366F1))
                            .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    isCheckedIn ? Icons.logout_rounded : Icons.login_rounded,
                    size: 20,
                    color: isCheckedIn
                        ? const Color(0xFF15803D)
                        : const Color(0xFF4C51BF),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      forceDisable && !isLocationValid
                          ? 'Lokasi tidak valid'
                          : isCheckedIn
                          ? 'Tap to Check-Out'
                          : 'Tap to Absen',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: forceDisable && !isLocationValid
                            ? const Color(0xFFD97706)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 15,
                          color: Color(0xFF4C51BF),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final bool isCheckingLocation;
  final bool isLocationValid;
  final String locationStatus;
  final String? locationWarning;
  final VoidCallback onRetryLocation;

  const _LocationCard({
    required this.isCheckingLocation,
    required this.isLocationValid,
    required this.locationStatus,
    this.locationWarning,
    required this.onRetryLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: isCheckingLocation
                        ? [Colors.blue, Colors.blue.shade700]
                        : isLocationValid
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                  ),
                ),
                child: isCheckingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        isLocationValid ? Icons.check_circle : Icons.warning,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationStatus,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isCheckingLocation
                            ? Colors.blue
                            : isLocationValid
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                    ),
                    if (locationWarning != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        locationWarning!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD97706),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isCheckingLocation && !isLocationValid)
                IconButton(
                  onPressed: onRetryLocation,
                  icon: const Icon(Icons.refresh, color: Color(0xFFD97706)),
                  tooltip: 'Coba lagi',
                ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                gradient: isCheckingLocation
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFDCEBFF), Color(0xFFEFF6FF)],
                      )
                    : isLocationValid
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFD1FAE5), Color(0xFFF0F9FF)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFDF2E0), Color(0xFFFFF8E1)],
                      ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      color:
                          (isCheckingLocation
                                  ? Colors.blue
                                  : isLocationValid
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B))
                              .withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color:
                          (isCheckingLocation
                                  ? Colors.blue
                                  : isLocationValid
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B))
                              .withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCheckingLocation
                          ? Colors.blue
                          : isLocationValid
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isCheckingLocation
                                      ? Colors.blue
                                      : isLocationValid
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B))
                                  .withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: isCheckingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            isLocationValid
                                ? Icons.check_circle
                                : Icons.warning,
                            color: Colors.white,
                            size: 20,
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
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9CA3AF).withValues(alpha: 0.15)
      ..strokeWidth = 1;

    const step = 24.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
