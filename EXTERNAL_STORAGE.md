# External Storage Detection

## Cara Kerja

Aplikasi ExternCamera dapat mendeteksi dan menyimpan foto/video ke external storage (USB drive, SD card) yang terhubung ke iPhone melalui Lightning adapter.

## Metode Deteksi

### 1. Mounted Volumes
- Scan folder `/Volumes` untuk mencari removable storage
- Cek property `volumeIsRemovable` untuk memastikan ini external storage

### 2. Media Paths
- Scan path berikut untuk external storage:
  - `/private/var/mobile/Media/DCIM`
  - `/var/mobile/Media/DCIM`
  - `/private/var/mobile/Media/ExternalStorage`
  - `/var/mobile/Media/ExternalStorage`

### 3. Write Test
- Melakukan test write untuk memastikan storage dapat diakses
- Jika gagal, fallback ke internal storage

## Persyaratan

### Hardware
- iPhone dengan port Lightning atau USB-C
- Lightning to USB Camera Adapter atau Lightning to SD Card Reader
- USB drive atau SD card (format FAT32 atau exFAT)

### Software
- iOS 15.0 atau lebih baru
- Permission: `UIFileSharingEnabled` dan `LSSupportsOpeningDocumentsInPlace`

## Struktur Folder

### Internal Storage
```
Documents/
  └── ExternCamera/
      ├── IMG_20231130_143022.jpg
      ├── VID_20231130_143045.mov
      └── SQ_20231130_143100.jpg
```

### External Storage
```
/Volumes/USB_DRIVE/
  └── ExternCamera/
      ├── IMG_20231130_143022.jpg
      ├── VID_20231130_143045.mov
      └── SQ_20231130_143100.jpg
```

## Fallback Behavior

Jika external storage tidak tersedia atau terjadi error:
1. Aplikasi otomatis fallback ke internal storage
2. User akan melihat notifikasi "External storage not available"
3. Foto/video tetap tersimpan di internal storage

## Testing

### Cara Test External Storage:
1. Hubungkan Lightning to USB adapter ke iPhone
2. Colokkan USB drive (format FAT32/exFAT)
3. Buka app ExternCamera
4. Masuk ke Settings → Storage
5. Cek "External Storage Status" - harus menampilkan "Connected ✅"
6. Pilih "External Storage" sebagai save location
7. Ambil foto/video
8. Cek di Files app → USB drive → ExternCamera folder

### Troubleshooting:
- **External storage tidak terdeteksi**: 
  - Pastikan USB drive sudah ter-mount di Files app
  - Format ulang USB drive ke FAT32 atau exFAT
  - Coba cabut dan colok ulang adapter
  
- **Gagal save ke external storage**:
  - Cek apakah USB drive masih terhubung
  - Cek apakah USB drive tidak full
  - App akan otomatis fallback ke internal storage

## Limitations

- iOS tidak memberikan akses langsung ke USB drive seperti Android
- Detection bergantung pada iOS mounting system
- Beberapa USB drive mungkin tidak kompatibel
- Performa write ke external storage bisa lebih lambat dari internal
