# Nomaden App - Aplikasi Ojek Online

Aplikasi Flutter untuk layanan ojek online yang menghubungkan driver dan client. Aplikasi ini menggunakan Supabase sebagai backend untuk autentikasi, database, dan realtime updates.

## Fitur Utama

### Untuk Driver:
- **Dashboard Lengkap**: Menampilkan profile, status online/offline, lokasi, riwayat order bulanan, dan status subscription.
- **Order Aktif**: Daftar order yang sedang dikerjakan driver (status 'assigned').
- **Riwayat Order**: Daftar order yang sudah selesai (status 'completed').
- **Pilih Order Manual**: Driver dapat melihat dan mengambil order yang tersedia secara realtime (status 'waiting').
- **Toggle Online/Offline**: Driver dapat mengubah status ketersediaan mereka.
- **Realtime Updates**: Daftar order tersedia diperbarui secara realtime menggunakan Supabase streams.

### Untuk Client:
- Buat order baru.
- Lihat status order.
- Integrasi dengan map untuk lokasi pickup/dropoff.

### Layanan Backend:
- **Supabase**: Digunakan untuk autentikasi, database (tabel users, drivers, orders), dan realtime subscriptions.
- **Geolocator**: Untuk mendapatkan lokasi driver.
- **Flutter Map**: Untuk tampilan peta (jika diperlukan).

## Struktur Proyek

```
lib/
├── app.dart                 # Root widget aplikasi
├── main.dart                # Entry point
├── constants.dart           # Konstanta aplikasi
├── core/
│   ├── constants.dart       # Konstanta inti
│   ├── geo_utils.dart       # Utilitas geografi
│   ├── price_engine.dart    # Engine perhitungan harga
│   └── user_role.dart       # Role pengguna
├── models/
│   ├── bid_model.dart       # Model untuk bid
│   ├── driver_model.dart    # Model untuk driver
│   ├── order_model.dart     # Model untuk order
│   ├── user_model.dart      # Model untuk user
│   └── user_role.dart       # Role user
├── screens/
│   ├── home_client.dart     # Dashboard client
│   ├── home_driver.dart     # Dashboard driver
│   ├── login_screen.dart    # Layar login
│   ├── order_create_screen.dart  # Buat order
│   ├── order_status_screen.dart  # Status order
│   └── splash_screen.dart   # Splash screen
├── services/
│   ├── auth_service.dart    # Layanan autentikasi
│   ├── autobid_service.dart # Layanan auto-assign driver
│   ├── driver_service.dart  # Layanan driver
│   ├── driver_status_service.dart # Status driver
│   ├── location_service.dart # Layanan lokasi
│   ├── order_service.dart   # Layanan order
│   └── profile_service.dart # Layanan profile
└── widgets/
    ├── order_card.dart      # Widget kartu order
    └── price_breakdown.dart # Breakdown harga
```

## Setup dan Instalasi

### Prasyarat:
- Flutter SDK (versi 2.18.0 atau lebih baru)
- Dart SDK
- Akun Supabase (untuk backend)

### Langkah-langkah:
1. **Clone Repository**:
   ```
   git clone https://github.com/username/repo-name.git
   cd wbd_app
   ```

2. **Install Dependencies**:
   ```
   flutter pub get
   ```

3. **Setup Supabase**:
   - Buat project baru di [Supabase](https://supabase.com).
   - Buat tabel-tabel berikut di database:
     - `users`: id, email, dll.
     - `drivers`: user_id, is_online, monthly_completed, subscription_active, lat, lng.
     - `orders`: id, clientId, driverId, serviceType, distanceKm, price, status, createdAt.
   - Aktifkan Row Level Security (RLS) dan realtime untuk tabel `orders`.
   - Salin URL dan anon key dari Supabase dashboard.
   - Buat file `lib/constants.dart` atau update dengan kredensial Supabase:
     ```dart
     const String supabaseUrl = 'your-supabase-url';
     const String supabaseAnonKey = 'your-anon-key';
     ```

4. **Konfigurasi Supabase di Kode**:
   - Pastikan `main.dart` atau `app.dart` menginisialisasi Supabase:
     ```dart
     await Supabase.initialize(
       url: supabaseUrl,
       anonKey: supabaseAnonKey,
     );
     ```

5. **Jalankan Aplikasi**:
   ```
   flutter run
   ```

## Penggunaan

1. **Login**: Masuk dengan email dan password (menggunakan Supabase Auth).
2. **Driver Dashboard**: Setelah login sebagai driver, akses fitur toggle online, lihat order tersedia, ambil order, dll.
3. **Client Dashboard**: Buat order baru, lihat status.

## Kontribusi

- Fork repository ini.
- Buat branch baru untuk fitur Anda.
- Commit perubahan dan push.
- Buat Pull Request.

## Lisensi

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Catatan

- Aplikasi ini masih dalam pengembangan.
- Untuk fitur lokasi, pastikan permission lokasi diaktifkan di device.
- Jika ada error, periksa log Flutter dan konfigurasi Supabase.
