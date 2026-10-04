PHONKIFY

Phonkify adalah aplikasi mobile berbasis Flutter untuk mendengarkan dan mengelola musik. Aplikasi menyediakan fitur pencarian lagu, pemutaran musik, Favorite, Playlist, riwayat pemutaran, Trending, serta rekomendasi musik berdasarkan aktivitas dan preferensi pengguna.


TEKNOLOGI

- Flutter
- Dart
- Supabase
- PostgreSQL
- Supabase Authentication
- Supabase Storage
- just_audio
- audio_service


SETUP PROJECT

1. Clone Repository

git clone https://github.com/Azkakaban/Phonkify.git

Masuk ke folder project:

cd Phonkify


2. Install Dependencies

flutter pub get


3. Cek Environment Flutter

flutter doctor

Pastikan environment Flutter yang diperlukan sudah tersedia.


MENJALANKAN APLIKASI

1. Menjalankan pada Device

Cek device yang tersedia:

flutter devices

Kemudian jalankan:

flutter run


2. Menjalankan pada Chrome

flutter run -d chrome


3. Menjalankan pada Device Tertentu

flutter run -d <device_id>


4. Analisis Kode

flutter analyze


5. Membersihkan Build

Jika terdapat masalah pada proses build, jalankan:

flutter clean
flutter pub get
flutter run


DATA DUMMY

Phonkify menggunakan data musik pada database Supabase untuk mendukung proses pengujian dan simulasi aplikasi.

Data yang digunakan meliputi:

- Songs
- Trending Songs
- Favorites
- Playlists
- Playlist Songs
- Listening History
- User Preferences

Data lagu digunakan sebagai data utama aplikasi, sedangkan data Trending, Favorite, Playlist, History, dan User Preferences digunakan untuk mendukung fitur serta proses rekomendasi musik.


SKENARIO SIMULASI

1. Login dan Home

1. Buka aplikasi Phonkify.
2. Masukkan akun pengguna yang tersedia.
3. Tekan tombol Login.
4. Setelah berhasil login, pengguna masuk ke halaman Home.
5. Periksa bagian:
   - Daftar lagu
   - Trending
   - Recently Played
   - Recommendation

Hasil yang diharapkan:
Pengguna berhasil masuk dan konten pada halaman Home dapat ditampilkan.


2. Search dan Music Player

1. Buka halaman Search.
2. Masukkan judul lagu.
3. Pilih salah satu hasil pencarian.
4. Lagu akan dibuka pada Full Player.
5. Gunakan kontrol:
   - Play
   - Pause
   - Next
   - Previous
   - Seek
   - Playback Speed

Hasil yang diharapkan:
Lagu dapat diputar dan kontrol pemutar musik dapat digunakan sesuai fungsinya.


3. Favorite dan Playlist

1. Buka sebuah lagu.
2. Tekan tombol Favorite.
3. Buka halaman Favorite.
4. Pastikan lagu muncul pada daftar Favorite.
5. Buka halaman Playlist.
6. Buat playlist baru.
7. Tambahkan lagu ke playlist.
8. Buka Playlist Detail.

Hasil yang diharapkan:
Lagu berhasil disimpan sebagai Favorite dan dapat ditambahkan ke Playlist.


4. History

1. Pilih sebuah lagu.
2. Putar lagu.
3. Setelah lagu diputar, buka halaman Recently Played / History.
4. Periksa daftar riwayat.

Hasil yang diharapkan:
Lagu yang telah diputar tercatat pada riwayat pengguna.


5. Recommendation

1. Login menggunakan akun pengguna.
2. Lakukan beberapa aktivitas seperti:
   - Memutar lagu
   - Menambahkan lagu ke Favorite
   - Menambahkan lagu ke Playlist
3. Buka bagian Recommendation.

Hasil yang diharapkan:
Sistem menampilkan rekomendasi musik berdasarkan aktivitas dan preferensi pengguna.


CATATAN

Phonkify menggunakan Supabase sebagai backend sehingga beberapa fitur membutuhkan koneksi internet yang bagus.

Pada fitur Register, terdapat batasan pengiriman email verifikasi karena menggunakan layanan SMTP bawaan Supabase. Oleh karena itu, pendaftaran akun dalam jumlah banyak atau dalam waktu yang berdekatan dapat terkena batasan pengiriman email.
Jika batas pengiriman email tercapai, pengguna perlu menunggu sampai batas tersebut tersedia kembali sebelum dapat menerima email verifikasi berikutnya.
