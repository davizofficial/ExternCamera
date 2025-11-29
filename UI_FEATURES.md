# ExternCamera - UI Features

## Layout Utama

### Top Controls (Kontrol Atas)
- **Flash Button** (Kiri) - Toggle flash mode: Off / Auto / On
- **HDR Button** - Toggle HDR untuk foto
- **Live Photo Button** (Tengah) - Toggle Live Photo
- **Timer Button** - Set timer: Off / 3s / 10s
- **Settings Button** (Kanan) - Buka halaman settings

### Center Area
- **Camera Preview** - Fullscreen preview dari kamera
- **Focus Guide** - Kotak kuning di tengah dengan corner indicators
- **Grid Overlay** - Grid 3x3 (dapat diaktifkan di settings)
- **Recording Label** - Timer saat merekam video (00:00)
- **Zoom Slider** - Slider zoom (muncul saat pinch gesture)

### Bottom Controls (Kontrol Bawah)
- **Thumbnail Button** (Kiri) - Preview foto/video terakhir, buka gallery
- **Capture Button** (Tengah) - Tombol utama untuk foto/video
  - Mode Photo: Lingkaran putih
  - Mode Video: Lingkaran merah
  - Saat Recording: Kotak merah kecil
- **Switch Camera Button** (Kanan) - Toggle front/back camera

### Mode Selector
- **TIME-LAPSE** - Mode time-lapse (belum diimplementasi)
- **VIDEO** - Mode video recording
- **PHOTO** - Mode foto (default)
- **SQUARE** - Mode foto square 1:1
- **PANO** - Mode panorama (belum diimplementasi)

## Settings Page

### Storage Section
- **Current Storage** - Pilih Internal atau USB Drive
- **USB Drive Status** - Status koneksi USB
- **USB Path** - Path ke USB drive

### Camera Section
- **Grid** - Toggle grid overlay
- **Preserve Settings** - Simpan pengaturan kamera

### Photo Section
- **Auto HDR** - Toggle HDR otomatis
- **Live Photo** - Toggle Live Photo

### Video Section
- **Record Video** - Pengaturan kualitas video (1080p 30fps)

### About Section
- **Version** - Versi aplikasi
- **USB Path** - Path default USB

## Fitur Interaksi

### Gestures
- **Tap** - Focus pada titik yang di-tap
- **Pinch** - Zoom in/out (1x - 5x)
- **Swipe** - Ganti mode kamera (di mode selector)

### Animasi
- **Button Press** - Scale down saat ditekan
- **Camera Switch** - Flip animation
- **Recording** - Pulsing red indicator
- **Focus** - Yellow box fade in/out

## Storage Management

### Internal Storage
- Path: `/Documents/ExternCamera/`
- Otomatis tersedia

### External Storage (USB)
- Path: `/private/var/mobile/Media/USBDRIVE/`
- Memerlukan Lightning Camera Connection Kit
- Format: FAT32
- Auto-detect saat tersambung

## Catatan
- UI mengikuti design pattern iOS Camera app
- Semua tombol memiliki haptic feedback
- Status bar disembunyikan untuk fullscreen experience
- Support portrait dan landscape orientation
