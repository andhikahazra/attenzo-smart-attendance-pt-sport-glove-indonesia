import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../state/face_registration_state.dart';
import '../utils/app_colors.dart';

class FaceRegistrationScreen extends StatelessWidget {
  const FaceRegistrationScreen({super.key});

  static const List<String> _angles = [
    'Center',
    'Kanan',
    'Kiri',
    'Agak ke atas',
    'Agak ke bawah',
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FaceRegistrationState(angles: _angles),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          title: Text(
            'Register Wajah',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: _FaceRegistrationBody(),
          ),
        ),
      ),
    );
  }
}

class _FaceRegistrationBody extends StatefulWidget {
  const _FaceRegistrationBody();

  @override
  State<_FaceRegistrationBody> createState() => _FaceRegistrationBodyState();
}

class _FaceRegistrationBodyState extends State<_FaceRegistrationBody> {
  @override
  void initState() {
    super.initState();
    // Load existing face photos from server when screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthState>();
      final token = auth.token;
      if (token != null) {
        await context.read<FaceRegistrationState>().loadExisting(token: token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FaceRegistrationState>();
    return _buildFaceRegistrationSection(context, state);
  }

  Widget _buildFaceRegistrationSection(BuildContext context, FaceRegistrationState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.isLoadingRemote)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Memuat foto wajah dari server...'),
                ],
              ),
            ),
          Text(
            'Registrasi Wajah',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ambil 5 foto dengan sudut berbeda agar sistem dapat mengenali wajah Anda lebih akurat.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          ...state.angles.map(
            (angle) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildFaceCaptureRow(
                context: context,
                label: angle,
                photo: state.captures[angle],
                remoteUrl: state.remoteUrls[angle],
                onCapture: () => _handleCapture(context, angle, state),
                onView: () => _handleView(context, angle, state),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.isSaving
                  ? null
                  : (state.isComplete ? () => _savePhotos(context, state) : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.25),
                disabledForegroundColor: Colors.white.withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.save_outlined),
              label: state.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Simpan Foto Wajah',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Verifikasi wajah dimulai.')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text(
                'Verifikasi Wajah',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceCaptureRow({
    required BuildContext context,
    required String label,
    required XFile? photo,
    String? remoteUrl,
    required VoidCallback onCapture,
    required VoidCallback onView,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 56,
                  width: 56,
                  color: Colors.grey.shade200,
                  child: photo != null
                      ? Image.file(
                          File(photo.path),
                          fit: BoxFit.cover,
                        )
                      : (remoteUrl != null
                          ? Image.network(remoteUrl, fit: BoxFit.cover)
                          : const Icon(Icons.image_outlined, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ambil sudut $label',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: onCapture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Ambil Foto',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onView,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Lihat Foto',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCapture(BuildContext context, String angle, FaceRegistrationState state) async {
    final granted = await _ensureCameraPermission();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin kamera diperlukan untuk mengambil foto.')),
      );
      return;
    }

    final captured = await _openCameraPage(context, angle);
    if (captured != null) {
      state.setCapture(angle, captured);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto sudut $angle disimpan sementara.')),
      );
    }
  }

  void _handleView(BuildContext context, String angle, FaceRegistrationState state) {
    final photo = state.captures[angle];
    final remoteUrl = state.remoteUrls[angle];
    if (photo == null && remoteUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Belum ada foto untuk sudut $angle.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Foto sudut $angle',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: photo != null
              ? Image.file(
                  File(photo.path),
                  fit: BoxFit.contain,
                )
              : Image.network(remoteUrl!, fit: BoxFit.contain),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePhotos(BuildContext context, FaceRegistrationState state) async {
    final auth = context.read<AuthState>();
    final token = auth.token;
    final user = auth.user;
    if (!state.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi 5 foto sebelum menyimpan.')),
      );
      return;
    }
    if (token == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi tidak ditemukan, silakan login ulang.')),
      );
      return;
    }

    try {
      await state.savePhotos(token: token, userId: user.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto wajah berhasil diunggah.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan foto: $e')),
      );
    }
  }

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  Future<XFile?> _openCameraPage(BuildContext context, String angle) async {
    try {
      final result = await Navigator.of(context).push<XFile?>(
        MaterialPageRoute(
          builder: (_) => _FullScreenCameraPage(angle: angle),
          fullscreenDialog: true,
        ),
      );
      return result;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuka kamera: $e')),
        );
      }
      return null;
    }
  }
}

class _FullScreenCameraPage extends StatefulWidget {
  const _FullScreenCameraPage({required this.angle});

  final String angle;

  @override
  State<_FullScreenCameraPage> createState() => _FullScreenCameraPageState();
}

class _FullScreenCameraPageState extends State<_FullScreenCameraPage> {
  CameraController? _controller;
  late Future<void> _initFuture;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('Kamera tidak ditemukan.');
    }
    final selectedCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller!.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Ambil sudut ${widget.angle}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<void>(
                future: _initFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Gagal membuka kamera',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }
                  if (_controller == null || !_controller!.value.isInitialized) {
                    return const Center(
                      child: Text('Kamera belum siap', style: TextStyle(color: Colors.white)),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final maxW = constraints.maxWidth;
                      final maxH = constraints.maxHeight;
                      final boxSize = maxW < maxH ? maxW : maxH * 0.72;
                      final size = boxSize.clamp(240.0, maxW);
                      final aspect = _controller!.value.aspectRatio; // width/height

                      // Scale camera to cover the square box without letterbox.
                      final renderWidth = size;
                      final renderHeight = renderWidth / aspect;
                      final coverH = renderHeight < size ? size : renderHeight;
                      final coverW = coverH * aspect;

                      return Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: SizedBox(
                                width: size,
                                height: size,
                                child: OverflowBox(
                                  alignment: Alignment.center,
                                  maxWidth: coverW,
                                  maxHeight: coverH,
                                  child: SizedBox(
                                    width: coverW,
                                    height: coverH,
                                    child: CameraPreview(_controller!),
                                  ),
                                ),
                              ),
                            ),
                            // Overlay rings
                            IgnorePointer(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: size * 0.88,
                                    height: size * 0.88,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.55), width: 3),
                                    ),
                                  ),
                                  Container(
                                    width: size * 0.68,
                                    height: size * 0.68,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.45), width: 2),
                                    ),
                                  ),
                                  Container(
                                    width: size * 0.50,
                                    height: size * 0.50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCapturing ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCapturing ? null : _takePhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isCapturing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Ambil'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() => _isCapturing = true);
    try {
      final photo = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(photo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }
}
