# 🚀 Panduan Menjalankan Aplikasi Smart Attendance

## Quick Start

### Cara Tercepat (Recommended)

```powershell
# Buka terminal di VS Code (Ctrl + `)
# Pastikan sudah berada di folder project

# 1. Install dependencies
flutter pub get

# 2. Jalankan aplikasi
flutter run
```

### Pilih Device

Ketika menjalankan `flutter run`, Flutter akan menampilkan list device yang tersedia:

```
Connected devices:
[1]: Windows (desktop)
[2]: Chrome (web)
[3]: Edge (web)
[4]: Pixel 6 (mobile) - jika ada emulator/device Android
```

Pilih device dengan mengetik angka (contoh: `1` untuk Windows)

## 📱 Testing di Device Berbeda

### 1. Windows Desktop
```powershell
flutter run -d windows
```

### 2. Web Browser
```powershell
# Chrome
flutter run -d chrome

# Edge
flutter run -d edge
```

### 3. Android (Emulator atau Physical Device)

**Buka Android Emulator:**
1. Buka Android Studio
2. Tools → Device Manager
3. Pilih device dan klik "Play"

**Jalankan:**
```powershell
flutter run
# Atau spesifik device
flutter run -d <device-id>
```

## 🔧 Troubleshooting

### Error: "No devices found"

**Solusi untuk Windows:**
```powershell
# Enable Windows desktop support
flutter config --enable-windows-desktop

# Restart VS Code
```

**Solusi untuk Web:**
```powershell
# Enable web support
flutter config --enable-web

# Restart VS Code
```

### Error: "Pub get failed"

```powershell
# Clean project
flutter clean

# Get dependencies again
flutter pub get
```

### Error: "Build failed"

```powershell
# Clean build folder
flutter clean

# Rebuild
flutter run
```

## 🎯 Hot Reload & Hot Restart

Saat aplikasi sudah running:

- **Hot Reload** (r): Reload UI tanpa restart aplikasi
- **Hot Restart** (R): Restart aplikasi dari awal
- **Quit** (q): Stop aplikasi

## 📦 Build Release APK (Android)

```powershell
# Build APK
flutter build apk --release

# File APK akan tersimpan di:
# build/app/outputs/flutter-apk/app-release.apk
```

## 🖥️ Build Windows App

```powershell
# Build Windows executable
flutter build windows --release

# File .exe akan tersimpan di:
# build/windows/runner/Release/smart_attendance.exe
```

## 🌐 Build Web App

```powershell
# Build web
flutter build web --release

# File akan tersimpan di:
# build/web/
```

## 💡 Tips

### 1. Gunakan VS Code Extensions
- Flutter
- Dart
- Flutter Widget Snippets

### 2. Shortcut Penting
- `Ctrl + .` - Quick Fix
- `F5` - Start Debugging
- `Shift + F5` - Stop Debugging
- `Ctrl + F5` - Run without Debugging

### 3. Debug Console
Lihat output log di terminal untuk debugging

### 4. Flutter DevTools
```powershell
# Buka DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## 📊 Check Flutter Status

```powershell
# Cek instalasi Flutter
flutter doctor

# Lihat semua device yang tersedia
flutter devices

# Lihat dependency yang outdated
flutter pub outdated
```

## 🎨 Testing UI di Berbagai Screen Size

Di VS Code dengan Flutter extension:
1. Start debugging (F5)
2. Gunakan hot reload (r) untuk melihat perubahan
3. Resize window untuk test responsive design

## ⚡ Performance Tips

1. **Gunakan Release Mode untuk testing performa**
```powershell
flutter run --release
```

2. **Profile Mode untuk debugging performa**
```powershell
flutter run --profile
```

3. **Debug Mode untuk development**
```powershell
flutter run --debug  # atau flutter run
```

## 🔍 Debugging

### Debug di VS Code
1. Set breakpoint (klik di sebelah line number)
2. Press F5 untuk start debugging
3. Gunakan Debug Console untuk inspect variables

### Print Debugging
```dart
print('Debug: $variableName');
debugPrint('Debug message');
```

## 📱 Recommended Test Devices

### Android
- Min SDK: 21 (Android 5.0 Lollipop)
- Target SDK: 33 (Android 13)
- Test di berbagai screen size

### iOS (jika tersedia)
- Min iOS: 12.0
- Test di iPhone & iPad

### Desktop
- Windows 10/11
- Screen resolution: 1920x1080 atau lebih

## 🆘 Get Help

Jika mengalami masalah:

1. **Check Flutter Doctor**
```powershell
flutter doctor -v
```

2. **Clean & Rebuild**
```powershell
flutter clean
flutter pub get
flutter run
```

3. **Update Flutter**
```powershell
flutter upgrade
```

4. **Check Dependencies**
```powershell
flutter pub outdated
flutter pub upgrade
```

---

## 📞 Support

Untuk pertanyaan atau issue, hubungi tim development:
- Email: dev@sportglove.id
- Team: Mahasiswa Ganteng Coding

---

**Happy Coding! 🎉**
