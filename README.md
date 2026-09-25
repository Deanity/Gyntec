# Gyntec

Gyntec adalah aplikasi mobile berbasis Flutter yang dirancang untuk memfasilitasi proses pembelajaran interaktif di lingkungan pendidikan. Aplikasi ini memungkinkan seorang pengajar untuk mengelola sesi belajar secara terstruktur, mulai dari penyampaian materi, diskusi kelompok, hingga evaluasi melalui kuis — semuanya dalam satu alur yang terpadu.

## Gambaran Umum

Aplikasi ini dibangun dengan pendekatan mobile-first untuk mendukung kegiatan belajar mengajar secara langsung di kelas. Pengajar berperan sebagai operator utama yang menjalankan sesi, sementara peserta didik mengikuti alur pembelajaran yang dipandu melalui layar.

Fitur offline detection memastikan pengajar selalu mengetahui status koneksi jaringan perangkat, sehingga pengelolaan sesi tetap dapat berjalan dengan baik di lingkungan dengan koneksi terbatas.

## Fitur Utama

**Manajemen Modul**
Pengajar dapat melihat daftar modul pembelajaran yang tersedia beserta detail kontennya, termasuk materi teks, pertanyaan diskusi kelompok, dan soal kuis.

**Manajemen Peserta**
Sebelum memulai sesi, pengajar menambahkan peserta yang akan mengikuti pembelajaran. Peserta terbagi ke dalam kelompok secara otomatis oleh sistem saat sesi diskusi dimulai.

**Alur Sesi Pembelajaran (3 Tahap)**

Tahap pertama adalah penyampaian materi, di mana pengajar mempresentasikan konten modul kepada peserta. Tahap kedua adalah diskusi kelompok yang dilengkapi dengan timer countdown. Saat timer berjalan, peserta berdiskusi dalam kelompok masing-masing. Setelah waktu habis, sistem secara otomatis melanjutkan ke tahap ketiga yaitu kuis interaktif. Pada tahap kuis, pengajar memandu peserta menjawab setiap soal dan menandai kelompok yang memberikan jawaban benar.

**Kuis Interaktif**
Soal kuis ditampilkan satu per satu dengan navigasi Sebelumnya dan Selanjutnya. Setiap soal memiliki pilihan jawaban yang dapat dipilih, serta panel pemilihan kelompok yang menjawab dengan benar. Saat semua soal telah dijawab, pengajar dapat menyelesaikan kuis melalui konfirmasi modal.

**Rekap Pasca Kuis**
Setelah sesi selesai, ditampilkan halaman rekap yang merangkum informasi modul, perolehan poin setiap kelompok, dan daftar anggota masing-masing kelompok.

**Deteksi Status Jaringan**
Banner offline ditampilkan secara otomatis di halaman utama dan halaman modul ketika perangkat tidak memiliki koneksi internet. Status diperbarui secara real-time melalui kombinasi stream event dan polling setiap 4 detik. Pengguna juga dapat menyegarkan status koneksi secara manual dengan menarik layar ke bawah (pull-to-refresh).

## Teknologi

| Komponen | Keterangan |
|---|---|
| Framework | Flutter 3.41.6 |
| Bahasa | Dart 3.11.4 |
| State Management | Stateful Widget (lokal, tanpa library eksternal) |
| Ikon | lucide_icons_flutter 3.1.20 |
| SVG | flutter_svg 2.3.0 |
| Konektivitas | connectivity_plus 7.3.1 |
| Data | JSON lokal via rootBundle (lib/utils/data.json) |

## Struktur Proyek

```
gyntec/
  lib/
    main.dart                            Titik masuk aplikasi
    mainScreen/
      login_screen.dart                  Halaman login
      home_screen.dart                   Halaman utama dengan daftar modul dan sesi terakhir
      modul_materi_screen.dart           Detail modul (tab Materi, Diskusi, Kuis)
      participant_screen.dart            Manajemen peserta sebelum sesi dimulai
      session_learning_screen.dart       Alur sesi 3 tahap (Materi, Diskusi, Kuis)
      discussion_timer_screen.dart       Layar timer diskusi fullscreen
      post_quiz_screen.dart              Rekap hasil sesi
    components/
      common/                            Komponen umum (button, input, navbar, dll)
      home/                              Komponen halaman utama
      materi/                            Komponen konten materi dan kuis preview
      peserta/                           Komponen manajemen peserta
      session/                           Komponen alur sesi aktif
    utils/
      data.json                          Data modul, peserta, dan soal kuis
      models.dart                        Definisi model data
      connectivity_service.dart          Service deteksi status jaringan
  test/
    widget_test.dart                     Smoke test aplikasi
    session_flow_test.dart               Widget test alur sesi pembelajaran
  assets/
    MateriImage/                         Gambar pendukung konten materi
```

## Alur Navigasi

```
LoginScreen
  HomeScreen
    ModulMateriScreen
      ParticipantScreen
        SessionLearningScreen
          DiscussionTimerScreen (push/pop)
          QuizFinishModal (dialog)
          PostQuizScreen
            HomeScreen (pop until first)
```

## Cara Menjalankan

Pastikan Flutter SDK sudah terpasang pada sistem. Kemudian jalankan perintah berikut secara berurutan.

```bash
flutter pub get
flutter run
```

Untuk menjalankan seluruh pengujian:

```bash
flutter test
```

Untuk membangun APK rilis:

```bash
flutter build apk --release
```

File APK akan tersedia di `build/app/outputs/flutter-apk/app-release.apk`.

## Pengujian di Perangkat Fisik

Aktifkan USB Debugging pada perangkat Android melalui menu Developer Options, sambungkan perangkat ke komputer via kabel USB, lalu jalankan `flutter run`. Flutter akan mendeteksi perangkat secara otomatis dan melakukan instalasi langsung.

Untuk menguji fitur offline badge, aktifkan mode pesawat pada perangkat. Badge akan muncul dalam waktu maksimal 4 detik. Tarik layar ke bawah untuk memperbarui status koneksi secara instan.

## Kontribusi

Repositori ini bersifat privat dan dikembangkan untuk kebutuhan internal. Untuk pertanyaan atau pengembangan lebih lanjut, hubungi tim pengembang melalui saluran yang telah ditentukan.
