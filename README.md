# Smart Attendance - PT Sport Glove Indonesia

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/UI/UX-FF6B6B?style=for-the-badge&logo=figma&logoColor=white" />
</div>

## 📱 Tentang Aplikasi

Aplikasi **Smart Attendance** adalah sistem absensi karyawan modern untuk PT Sport Glove Indonesia yang dilengkapi dengan fitur face recognition dan tracking kehadiran real-time. Aplikasi ini dirancang dengan UI/UX yang menarik dan user-friendly.

## ✨ Fitur Utama

### 🎯 **Splash Screen & Authentication**
- Splash screen dengan logo perusahaan
- Login dengan username & password
- Toggle visibility password
- Motivational quotes untuk karyawan

### 📸 **Face Recognition Check-in**
- Face recognition untuk absensi
- Location verification
- Real-time check-in/check-out
- Status kehadiran langsung

### 🏠 **Dashboard Home**
- Greeting berdasarkan waktu
- Banner promosi interaktif
- Profile card karyawan
- Status kehadiran hari ini (Time In/Out)
- Statistik kehadiran bulanan:
  - ✅ Hadir (25 hari)
  - ⏰ Telat (3 hari)
  - 📅 Cuti (1 hari)
  - ❌ Tidak Hadir (1 hari)

### 📊 **Riwayat Kehadiran**
- Filter berdasarkan bulan
- Summary cards (Total Hadir & Telat)
- Detail history per hari dengan:
  - Tanggal & hari
  - Status kehadiran
  - Time In & Time Out
  - Color coding status

### 💼 **Menu Kerja**
- Quick Actions (Check In/Out)
- Pengajuan:
  - Cuti
  - Sakit
  - Lembur
  - Izin
- Task Management
- Priority indicators

### 👤 **Profile**
- Informasi karyawan lengkap
- Employee details (ID, Division, Location)
- Contact information
- Logout function

## 🎨 Design System

### Color Palette
```
Primary:   #1E3A4C (Dark Blue)
Secondary: #2A5570 (Medium Blue)
Success:   #4CAF50 (Green)
Warning:   #FF9800 (Orange)
Error:     #F44336 (Red)
Info:      #FFC107 (Yellow)
```

### Typography
- **Heading**: Bold, 24-32px
- **Subheading**: SemiBold, 18-20px
- **Body**: Regular, 14-16px
- **Caption**: Light, 12px

## 📁 Struktur Folder

```
lib/
├── main.dart
├── screens/
│   ├── splash_screen.dart          # Splash screen awal
│   ├── login_screen.dart           # Halaman login
│   ├── motivation_screen.dart      # Motivational quotes
│   ├── check_in_screen.dart        # Face recognition check-in
│   ├── home_screen.dart            # Dashboard utama
│   ├── riwayat_screen.dart         # Riwayat kehadiran
│   ├── work_screen.dart            # Menu kerja & pengajuan
│   ├── history_screen.dart         # Detail history (legacy)
│   └── profile_screen.dart         # Profile karyawan
└── widgets/
    ├── bottom_nav_bar.dart         # Bottom navigation bar
    ├── attendance_card.dart        # Card statistik kehadiran
    ├── custom_button.dart          # Custom button widget
    └── custom_text_field.dart      # Custom text field widget
```

## 🚀 Cara Menjalankan

### Prerequisites
- Flutter SDK (3.8.1 atau lebih baru)
- Dart SDK
- Android Studio / VS Code
- Android Emulator / Physical Device

### Instalasi

1. **Clone repository** (atau buka project yang sudah ada)
```bash
cd d:\smart_attendance
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Jalankan aplikasi**
```bash
flutter run
```

4. **Build APK** (opsional)
```bash
flutter build apk --release
```

## 📱 Screenshots

### Login & Splash
- Splash screen dengan logo Sport Glove Indonesia
- Login form dengan modern design
- Motivational quotes screen

### Main Features
- Dashboard dengan statistik lengkap
- Face recognition check-in screen
- Riwayat kehadiran dengan filter
- Menu kerja & pengajuan

## 🎯 Navigasi Aplikasi

```
Splash Screen (3s) → Login Screen → Motivation Screen → Check-in Screen → Home Dashboard
                                                              ↓
                                            ┌─────────────────┴─────────────────┐
                                            ↓                 ↓                 ↓
                                         Riwayat           Kerja            Profile
```

## 🔧 Teknologi yang Digunakan

- **Framework**: Flutter 3.8.1
- **Language**: Dart
- **State Management**: setState (StatefulWidget)
- **UI Components**: Material Design 3
- **Icons**: Material Icons & Cupertino Icons

## 📝 Catatan Penting

⚠️ **Aplikasi ini adalah UI/UX prototype (tampilan saja)**

- ❌ Tidak ada koneksi ke backend/server
- ❌ Tidak ada database real
- ❌ Face recognition adalah placeholder
- ❌ Location tracking belum terintegrasi
- ✅ Semua data adalah dummy/static data

## 🔮 Pengembangan Selanjutnya

### Backend Integration
- [ ] REST API integration
- [ ] Real-time database (Firebase/Supabase)
- [ ] Authentication & authorization
- [ ] JWT token management

### Face Recognition
- [ ] ML Kit face detection
- [ ] TensorFlow Lite integration
- [ ] Liveness detection
- [ ] Anti-spoofing measures

### Advanced Features
- [ ] Push notifications
- [ ] Geofencing & GPS tracking
- [ ] PDF report generation
- [ ] Excel export
- [ ] Calendar view
- [ ] Overtime tracking
- [ ] Leave management system
- [ ] Payroll integration

### UI/UX Improvements
- [ ] Dark mode support
- [ ] Multi-language (ID/EN)
- [ ] Onboarding tutorial
- [ ] Skeleton loading
- [ ] Pull to refresh
- [ ] Infinite scroll

## 👥 Tim Pengembang

**PT Sport Gloves Indonesia**
Developed by: Mahasiswa Ganteng Coding

## 📄 License

Private & Confidential - PT Sport Gloves Indonesia
© 2025 All Rights Reserved

---

<div align="center">
  <p><strong>Made with ❤️ for PT Sport Glove Indonesia</strong></p>
  <p>Smart Attendance - Absensi Pintar, Kerja Lebih Produktif</p>
</div>
