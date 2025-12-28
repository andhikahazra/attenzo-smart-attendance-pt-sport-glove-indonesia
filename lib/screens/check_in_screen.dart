import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';

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
  String _displayTime = '';
  bool _isPosting = false;
  final ApiService _api = ApiService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTime();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    });
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
    setState(() {
      _displayTime = formatted;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;

    if (state == AppLifecycleState.resumed) {
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
                            isLoading: _isPosting,
                          ),
                          const SizedBox(height: 20),
                          const _LocationCard(),
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
    if (!mounted || _isPosting) return;
    setState(() {
      _isPosting = true;
    });

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _showStatusDialog('Kamera belum siap untuk mengambil foto.', isError: true);
      return;
    }

    final auth = context.read<AuthState>();
    final token = auth.token;
    final user = auth.user;
    if (token == null || user == null) {
      _showStatusDialog('Silakan login ulang untuk absen.', isError: true);
      return;
    }

    final type = _isCheckedIn ? 'check_out' : 'check_in';
    final now = DateTime.now();
    final dateStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';



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
      setState(() {
        _isCheckedIn = !_isCheckedIn;
        _displayTime = formattedTime;
      });

      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog
      _showSuccessDialog(type == 'check_in' ? 'Check-In' : 'Check-Out', formattedTime);
    } on CameraException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _showStatusDialog('Gagal mengambil foto: ${e.description ?? e.code}', isError: true);
    } on HttpException catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final msg = e.message;
      if (msg.contains('Face could not be detected')) {
        _showStatusDialog(
          'Wajah tidak terdeteksi pada foto yang diambil.\n\nPastikan wajah Anda jelas terlihat di dalam frame dan tidak terhalang. Silakan coba lagi.',
          isError: true,
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

  void _showStatusDialog(String message, {bool isError = false}) {
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
                  isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                  size: 48,
                  color: isError ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                ),
                const SizedBox(height: 18),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                      Navigator.of(dialogContext).pop();
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
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
                      'Continue',
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
            forceDisable: isLoading,
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
  });

  final bool isCheckedIn;
  final String time;
  final bool isLoading;
  final Future<void> Function()? onTap;
  final bool forceDisable;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: forceDisable ? Colors.transparent : const Color(0xFF6366F1).withValues(alpha: 0.12),
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
                      isCheckedIn
                          ? 'Tap to Check-Out'
                          : 'Tap to Absen',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
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
  const _LocationCard();

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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                  ),
                ),
                child: const Icon(Icons.location_on, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Current Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Main Office - Entrance Gate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDCEBFF), Color(0xFFEFF6FF)],
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
                      color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
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
