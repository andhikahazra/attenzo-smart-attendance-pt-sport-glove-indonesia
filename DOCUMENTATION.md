# Smart Attendance App

Aplikasi Smart Attendance untuk PT Sport Gloves Indonesia - Sistem Absensi Karyawan Modern dengan Face Recognition.

## 🎨 Fitur Tampilan

### 1. **Splash Screen**
- Logo perusahaan Sport Glove Indonesia
- Animasi loading otomatis
- Design minimalis dengan background gradient

### 2. **Login Screen**
- Form login dengan username & password
- Toggle visibility password
- Forgot password link
- Design modern dengan gradient background
- Logo perusahaan di tengah

### 3. **Motivation Screen**
- Pesan motivasi harian untuk karyawan
- Quotes inspiratif tentang kedisiplinan
- Button untuk melanjutkan ke check-in
- Design card yang menarik

### 4. **Check-in Screen (Face Recognition)**
- Face recognition placeholder dengan icon
- Location verification indicator
- Informasi lokasi kantor
- Instruksi untuk pengguna
- Button "Capture & Check In"

### 5. **Home Dashboard**
- Header dengan greeting berdasarkan waktu
- Banner promosi (contoh: Kuliner BCA)
- Card profil karyawan dengan informasi:
  - Nama karyawan
  - Divisi
  - Lokasi kantor
  - Button "CHECK IN NOW"
- Status kehadiran hari ini:
  - Time In dengan status checklist
  - Time Out dengan status progress
- Grid statistik kehadiran:
  - Hadir (25 hari) - Hijau
  - Telat (3 hari) - Orange
  - Cuti (1 hari) - Kuning
  - Tidak Hadir (1 hari) - Merah

### 6. **History/Riwayat Screen**
- Filter berdasarkan bulan
- List history kehadiran dengan informasi:
  - Tanggal lengkap
  - Status (Hadir/Telat/Tidak Hadir)
  - Lokasi kantor
  - Time In & Time Out
- Color coding untuk status berbeda

### 7. **Profile Screen**
- Photo profil karyawan
- Informasi lengkap:
  - Nama
  - Divisi
  - Email
  - No. Telepon
  - Lokasi
  - Employee ID
- Button logout

### 8. **Bottom Navigation**
- 4 Menu utama:
  - Home (Dashboard)
  - Riwayat (History)
  - Kerja (Work)
  - Profil (Profile)
- Active state indicator
- Icon yang jelas dan mudah dipahami

## 🎨 Design System

### Color Palette
- **Primary**: `#1E3A4C` (Dark Blue)
- **Secondary**: `#2A5570` (Medium Blue)
- **Success**: Green (untuk status Hadir)
- **Warning**: Orange (untuk status Telat)
- **Danger**: Red (untuk status Tidak Hadir)
- **Info**: Yellow (untuk Cuti)

### Typography
- **Font Family**: Poppins (default Flutter system font)
- **Heading**: Bold, 24-32px
- **Body**: Regular, 14-16px
- **Caption**: Light, 12px

### Components
- **Cards**: Rounded corners (12-20px), subtle shadows
- **Buttons**: Full width, 16px padding, rounded 12px
- **Input Fields**: Light gray background, no borders, rounded 12px

## 📱 Screens Structure

```
lib/
├── main.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── motivation_screen.dart
│   ├── check_in_screen.dart
│   ├── home_screen.dart
│   ├── history_screen.dart
│   └── profile_screen.dart
└── widgets/
    └── bottom_nav_bar.dart
```

## 🚀 Cara Menjalankan

1. Install dependencies:
```bash
flutter pub get
```

2. Jalankan aplikasi:
```bash
flutter run
```

## 📝 Catatan

- Aplikasi ini hanya UI/UX (tampilan saja)
- Tidak ada koneksi ke backend atau database
- Face recognition hanya placeholder
- Data yang ditampilkan adalah data dummy/static

## 🎯 Features yang Bisa Ditambahkan di Masa Depan

1. **Backend Integration**
   - API untuk login
   - Database untuk menyimpan data kehadiran
   - Real-time synchronization

2. **Face Recognition**
   - Implementasi actual face recognition
   - Machine learning model integration
   - Liveness detection

3. **Geolocation**
   - Real GPS location tracking
   - Geofencing untuk area kantor
   - Multiple location support

4. **Notifications**
   - Push notifications
   - Reminder untuk check-in/check-out
   - Daily/weekly attendance reports

5. **Additional Features**
   - Laporan kehadiran PDF
   - Export data ke Excel
   - Calendar view untuk kehadiran
   - Leave request system
   - Overtime tracking

## 👨‍💻 Developer

PT Sport Gloves ID - By Mahasiswa Ganteng Coding

## 📄 License

Private - PT Sport Gloves Indonesia
