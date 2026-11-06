# Planning Update 1 — P2P Module Sharing (Real, Offline)

> Status: **Draft / belum dieksekusi**
> Tanggal: 6 November 2026
> Scope: Mengganti simulasi sharing modul (timer + nama device palsu) menjadi transfer **asli** antar perangkat terdekat, tanpa internet.

---

## 1. Latar Belakang

Saat ini fitur sharing di `lib/features/sharing/` **100% simulasi**:

| Bagian | Kondisi sekarang |
|---|---|
| Terima modul (`sharing_hub_screen.dart`) | `Timer` 2200ms memunculkan request palsu dari `"Rama (SM-2BXX)"` |
| Kirim modul (`send_module_screen.dart`) | `Timer` 1800ms memunculkan device palsu `"Rama (SM-1980)"` dan `"iPad Olivia"` |
| Progress transfer | `Timer.periodic(60ms)` +0.015 per tick (~4 detik), bukan progress asli |
| Hasil terima | Tidak disimpan ke mana pun, langsung kembali ke Home |
| Data modul | Hanya dari `assets/data/mock_data.json` (read-only), dan hanya ada **1** `modulDetail` |
| Inkonsistensi | Nama pengirim `SM-2BXX` vs `SM-1980` di layar yang sama |

### Kebutuhan

| Kebutuhan | Keputusan |
|---|---|
| Siapa yang berbagi | Guru ↔ Guru dan Guru ↔ Siswa (semua pakai aplikasi Gyntec yang sama) |
| Platform | Android **dan** iOS, termasuk **lintas platform** (Android ↔ iOS) |
| Koneksi | Offline, model mirip Quick Share / AirDrop (Bluetooth / Wi-Fi lokal) |
| Isi data | Teks + gambar (perkiraan 1–50 MB per kiriman) |

---

## 2. Pemilihan Teknologi

### 2.1 Perbandingan

| Package | Android ↔ Android | iOS ↔ iOS | **Android ↔ iOS** | Transport | Catatan |
|---|---|---|---|---|---|
| `nearby_service` | ✅ | ✅ | ❌ | Wi-Fi Direct / Multipeer | README menyebut tidak mendukung Android ↔ iOS. **Gugur.** |
| `flutter_nearby_connections(_plus)` | ✅ | ✅ | ❌ | Nearby Connections / Multipeer | Protokol berbeda per OS. **Gugur.** |
| `nearby_connections` | ✅ | ❌ | ❌ | Google Nearby | Android saja. **Gugur.** |
| Quick Share / AirDrop | — | — | — | — | Tidak ada API Flutter, tidak bisa dipanggil dari aplikasi. **Gugur.** |
| `flutter_blue_plus` (BLE murni) | ✅ | ✅ | ✅ | BLE | Throughput sangat rendah, gambar 10 MB bisa makan waktu bermenit-menit. **Hanya cocok sebagai cadangan.** |
| **`nearby` (Navideck) ^0.2.0** | ✅ | ✅ | ✅ | Wi-Fi/LAN (mDNS + TCP) + cadangan BLE | API satu pintu, sudah ada enkripsi, PIN, file + progress. |
| `bonsoir` + `dart:io` Socket | ✅ | ✅ | ✅ | Wi-Fi/LAN | Bangun sendiri; dipakai sebagai **Plan B**. |

### 2.2 Keputusan: `nearby` (Navideck)

Alasan:
1. **Satu-satunya opsi siap pakai yang lintas platform** dengan bandwidth cukup untuk gambar.
2. API-nya cocok dengan alur UI yang sudah ada:
   - `startAdvertising()` → layar **Terima**
   - `startDiscovery()` + `discoveredPeersStream` → daftar device di layar **Kirim**
   - `connectionRequestsStream` + `acceptConnection()` → tahap `requestReceived`
   - `sendFile()` + `payloadProgressStream` → progress bar **asli**
3. Ada enkripsi sesi dan verifikasi PIN bawaan.

### 2.3 Batasan yang HARUS dipahami tim

> **Penting:** Android dan iOS tidak punya protokol Wi-Fi peer-to-peer yang sama (Android: Wi-Fi Direct, iOS: AWDL/Multipeer). Karena itu, transfer cepat lintas platform hanya bisa lewat **jaringan Wi-Fi yang sama**.

Artinya, ada dua kondisi saat dipakai di lapangan:

| Kondisi | Transport | Kecepatan | Butuh internet? |
|---|---|---|---|
| Kedua device terhubung ke Wi-Fi yang sama (Wi-Fi sekolah, atau **hotspot HP salah satu guru**) | TCP via LAN | Cepat (MB/detik) | **Tidak** — hotspot tanpa kuota pun bisa |
| Tidak ada Wi-Fi bersama | BLE (cadangan otomatis) | Lambat (KB/detik) | Tidak |

**Solusi UX:** Di layar sharing, tampilkan tips: *"Untuk transfer cepat, sambungkan kedua perangkat ke Wi-Fi atau hotspot yang sama. Kuota internet tidak diperlukan."*

### 2.4 Risiko package

`nearby` masih sangat baru (v0.2.0, rilis Oktober 2026, likes masih sedikit). Karena itu, **Phase 0 (spike)** wajib dilakukan dulu sebelum mengubah UI. Kalau gagal → pindah ke **Plan B** (lihat Bagian 9).

---

## 3. Arsitektur Solusi

### 3.1 Gambaran alur

```
 PENGIRIM (tab "Kirim")                         PENERIMA (tab "Terima")
 ────────────────────────                       ─────────────────────────
 SelectModuleToSendScreen                       SharingHubScreen
   pilih modul                                    startAdvertising()
        │                                              │ stage: scanning
 SendModuleScreen                                      │
   startDiscovery() ──── mDNS / BLE ─────────────▶ terlihat
   daftar device ASLI                                  │
   tap "Kirim"                                         │
   requestConnection(peer) ─────────────────────▶ connectionRequestsStream
                                                   acceptConnection() (otomatis)
   kirim OFFER (manifest JSON kecil) ───────────▶ stage: requestReceived
                                                   (tampilkan nama ASLI + daftar modul ASLI)
                                                   user tap "Terima File"
   ◀──────────────────────────────────────────── kirim ACCEPT
   tulis payload ke file temp
   sendFile() ──────────────────────────────────▶ stage: inProgress
   payloadProgressStream (progress ASLI)           payloadProgressStream
                                                   payloadReceivedStream (file)
                                                   simpan ke storage lokal
   ◀──────────────────────────────────────────── kirim DONE
   stage: success                                  stage: done
   disconnect                                      modul muncul di daftar Modul
```

Kalau penerima menekan **Batal** pada `requestReceived`, penerima mengirim `REJECT`, lalu pengirim menampilkan pesan *"Ditolak oleh {nama}"*.

### 3.2 Protokol pesan (di atas `sendBytes`)

Semua pesan kontrol berupa JSON UTF-8 dengan field `type`:

```json
{ "type": "offer",  "v": 1, "sender": "Gisa (Android)", "modules": [ {ModuleModel...} ], "sizeBytes": 2483112 }
{ "type": "accept", "v": 1 }
{ "type": "reject", "v": 1 }
{ "type": "done",   "v": 1, "savedIds": ["m1", "m3"] }
```

Field `v` (versi protokol) disertakan supaya penerima bisa menolak versi yang tidak cocok, karena versi app di device guru/siswa bisa berbeda.

### 3.3 Format payload (file yang dikirim via `sendFile`)

Satu file JSON berisi semua modul + gambar (base64):

```json
{
  "v": 1,
  "modules": [
    {
      "module": { "id": "m1", "level": "SMA", "title": "...", "...": "..." },
      "detail": { "id": "m1", "materi": [ ... ], "groupQuestion": { ... }, "quiz": [ ... ] },
      "images": { "Materi1.png": "<base64>", "Materi2.png": "<base64>" }
    }
  ]
}
```

- Base64 menambah ukuran ~33%, masih aman untuk target < 50 MB.
- Satu file = satu progress bar = sederhana.
- `ponytail:` kalau nanti modul berisi video / > 100 MB, ganti ke ZIP (`archive`) atau kirim per file.

### 3.4 Penyimpanan modul yang diterima

Sekarang semua layar membaca langsung `rootBundle.loadString('assets/data/mock_data.json')` (ada di 8 file). Asset bersifat read-only, jadi modul yang diterima **tidak bisa** ditulis ke sana.

Solusinya adalah satu `ModuleRepository` kecil:

```
<app documents dir>/modules/
├── index.json                 ← daftar ModuleModel yang diterima
└── m1/
    ├── detail.json            ← ModuleDetailModel (imageAsset diganti path file lokal)
    └── images/
        ├── Materi1.png
        └── Materi2.png
```

- `loadModules()` = modul dari asset + modul dari `index.json` (yang diterima akan menimpa modul asset jika `id` sama).
- `loadDetail(id)` = cek folder lokal dulu, lalu fallback ke asset.
- Hanya pakai `dart:io` (File/Directory) + `path_provider` untuk lokasi folder. **Tanpa database.**

### 3.5 Struktur file (baru / diubah)

```
lib/
├── core/services/
│   ├── nearby_sharing_service.dart     ← BARU: wrapper `nearby` + protokol offer/accept/done
│   └── module_repository.dart          ← BARU: baca asset + baca/tulis modul lokal
├── features/module/
│   ├── models/module_model.dart        ← UBAH: tambah toJson()
│   ├── models/module_detail_model.dart ← UBAH: tambah toJson()
│   ├── screens/module_list_screen.dart ← UBAH: pakai ModuleRepository
│   ├── screens/module_detail_screen.dart ← UBAH: load detail sesuai id modul
│   └── widgets/image_block_view.dart   ← UBAH: Image.asset vs Image.file
├── features/session/models/quiz_question_model.dart ← UBAH: tambah toJson()
├── features/sharing/
│   ├── screens/sharing_hub_screen.dart        ← UBAH: hapus Timer, pakai service
│   ├── screens/select_module_to_send_screen.dart ← UBAH: pakai ModuleRepository
│   ├── screens/send_module_screen.dart        ← UBAH: hapus Timer, pakai service
│   └── widgets/device_select_card.dart        ← UBAH: TargetDeviceModel dari peer asli
assets/data/mock_data.json              ← UBAH: modulDetail → modulDetails (per id)
android/app/src/main/AndroidManifest.xml ← UBAH: permission
ios/Runner/Info.plist                   ← UBAH: usage description + Bonjour
pubspec.yaml                            ← UBAH: tambah `nearby`, `path_provider`
```

Hanya 2 file baru. Tidak ada state management baru: layar tetap `StatefulWidget`, service mengekspos `Stream`, dan UI cukup `listen` lalu `setState`.

---

## 4. Phase Eksekusi

Urutannya disusun supaya **risiko terbesar dicek paling awal**. Setiap phase punya *Definition of Done* (DoD) yang harus lolos sebelum lanjut ke phase berikutnya.

---

### Phase 0 — Spike / Proof of Concept (0.5–1 hari) — **WAJIB**

**Tujuan:** Membuktikan `nearby` bisa transfer file Android ↔ iOS di device fisik sebelum menyentuh kode UI.

**Prasyarat:**
- Minimal 2 HP Android fisik + 1 iPhone fisik (emulator **tidak** mendukung Wi-Fi P2P/BLE).
- **Mac + Xcode** untuk build iOS (tidak bisa build iOS dari Windows). Kalau tim tidak punya Mac, lakukan Android ↔ Android dulu dan cari pinjaman Mac atau pakai CI macOS (GitHub Actions `macos-latest`) untuk build iOS.

**Langkah:**
1. Buat branch `spike/nearby`.
2. Tambahkan `nearby: ^0.2.0` ke `pubspec.yaml`, lalu jalankan `flutter pub get`.
3. Tambahkan permission Android + iOS (lihat Phase 1 langkah 2–3).
4. Buat satu layar tes sementara (`lib/spike_screen.dart`, **dihapus setelah spike**) berisi:
   - Tombol "Advertise" → `startAdvertising(serviceId: 'gyntec')`
   - Tombol "Discover" → `startDiscovery(serviceId: 'gyntec')` + tampilkan list peer
   - Tap peer → `requestConnection` → kirim file dummy 10 MB via `sendFile`
   - Tampilkan `payloadProgressStream` dalam bentuk persen
5. Uji matriks berikut dan catat hasilnya:

| # | Pengirim → Penerima | Kondisi jaringan | Hasil | Waktu 10 MB |
|---|---|---|---|---|
| 1 | Android → Android | Wi-Fi sama | | |
| 2 | Android → iOS | Wi-Fi sama | | |
| 3 | iOS → Android | Wi-Fi sama | | |
| 4 | Android → iOS | Hotspot HP salah satu (tanpa kuota) | | |
| 5 | Android → Android | Tanpa Wi-Fi (BLE) | | |
| 6 | Android → iOS | Tanpa Wi-Fi (BLE) | | |

6. Cek juga: apakah `payloadProgressStream` muncul di **sisi penerima**? (Menentukan apakah progress penerima asli atau harus dihitung dari `sizeBytes` di `offer`.)

**DoD / Decision gate:**
- ✅ Baris 1–4 berhasil → **lanjut Phase 1** dengan `nearby`.
- ❌ Baris 2–4 gagal → **pindah ke Plan B** (Bagian 9), lalu ulangi spike dengan Plan B.
- Baris 5–6 lambat/gagal = boleh; BLE hanya cadangan dan UI akan menampilkan tips hotspot.

---

### Phase 1 — Fondasi: Data Layer & Konfigurasi Platform (1–1.5 hari)

**Tujuan:** Modul bisa diserialisasi, disimpan, dan dibaca ulang. Konfigurasi platform siap. Belum ada perubahan di UI sharing.

**Langkah:**

1. **Dependency** — `pubspec.yaml`:
   ```yaml
   dependencies:
     nearby: ^0.2.0
     path_provider: ^2.1.5
   ```

2. **Android** — `android/app/src/main/AndroidManifest.xml` (di atas `<application>`):
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
   <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
   <uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
   <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
   <uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
   <uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
   <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
   ```
   Catatan: `INTERNET` sekarang hanya ada di manifest `debug`/`profile`. Tanpa baris ini di `main`, socket TCP akan **gagal di build release**.

3. **iOS** — `ios/Runner/Info.plist`:
   ```xml
   <key>NSBluetoothAlwaysUsageDescription</key>
   <string>Digunakan untuk menemukan perangkat terdekat saat berbagi modul.</string>
   <key>NSBluetoothPeripheralUsageDescription</key>
   <string>Digunakan agar perangkat ini terlihat saat menerima modul.</string>
   <key>NSLocalNetworkUsageDescription</key>
   <string>Digunakan untuk mengirim dan menerima modul dengan perangkat di jaringan yang sama.</string>
   <key>NSBonjourServices</key>
   <array>
     <string>_gyntec._tcp</string>
   </array>
   ```
   `_gyntec._tcp` **harus sama persis** dengan `serviceId: 'gyntec'` di kode.

4. **Model** — tambahkan `toJson()` (pasangan dari `fromJson()` yang sudah ada) di:
   - `ModuleModel`
   - `ModuleDetailModel`, `MateriBlockModel`, `GroupQuestionModel`
   - `QuizQuestionModel`

5. **Mock data** — `assets/data/mock_data.json`: ubah `"modulDetail": {...}` menjadi `"modulDetails": { "m1": {...}, "m2": {...}, ... }` supaya setiap modul punya detail sendiri (sekaligus memperbaiki bug "detail modul selalu sama"). Modul yang belum punya konten boleh menyalin isi m1 dulu dengan judul diganti.

6. **`ModuleRepository`** (`lib/core/services/module_repository.dart`), singleton seperti `ConnectivityService`:
   - `Future<List<ModuleModel>> loadModules()` — modul asset + `index.json` lokal
   - `Future<ModuleDetailModel> loadDetail(String id)` — lokal dulu, lalu asset
   - `Future<Uint8List> readImageBytes(String path)` — dari asset atau file
   - `Future<void> saveReceived(Map<String, dynamic> payloadModule)` — tulis `detail.json`, decode gambar ke `images/`, ganti `imageAsset` dengan path file lokal, lalu update `index.json`
   - Tulis ke file `.tmp` dulu, lalu `rename()`, supaya `index.json` tidak korup kalau app mati di tengah proses (**mencegah kehilangan data**).

7. **Pakai repository** di `module_list_screen.dart`, `module_detail_screen.dart` (load sesuai `module.id`), `home_screen.dart` (bagian modul), dan `participant_selection_screen.dart` (bagian `modulDetail`).

8. **Gambar** — di `image_block_view.dart`: kalau path diawali `assets/` pakai `Image.asset`, selain itu `Image.file(File(path))`.

9. **Self-check** — `test/module_repository_test.dart`: round-trip `ModuleDetailModel → toJson → fromJson` harus menghasilkan data yang sama, dan `saveReceived` lalu `loadDetail` harus mengembalikan modul yang sama.

**DoD:**
- `flutter analyze` 0 issue, `flutter test` lulus.
- Semua layar yang ada tetap berjalan seperti sebelumnya (regresi nol).
- Tap modul m2 menampilkan detail m2, bukan m1.

---

### Phase 2 — `NearbySharingService` (1 hari)

**Tujuan:** Semua logika P2P ada di satu file. UI tidak menyentuh package `nearby` secara langsung.

**File:** `lib/core/services/nearby_sharing_service.dart`

**API publik (minimum):**

```dart
class NearbySharingService {
  static final instance = NearbySharingService._();

  // Penerima
  Future<void> startReceiving();                     // startAdvertising
  Stream<IncomingOffer> get offers;                  // offer masuk: nama pengirim + List<ModuleModel> + sizeBytes
  Future<void> acceptOffer(IncomingOffer offer);     // kirim "accept"
  Future<void> rejectOffer(IncomingOffer offer);     // kirim "reject"
  Stream<List<String>> get received;                 // id modul yang berhasil disimpan

  // Pengirim
  Future<void> startDiscovery();
  Stream<List<TargetDeviceModel>> get devices;       // dari discoveredPeersStream
  Future<SendResult> send(TargetDeviceModel device, List<ModuleModel> modules);
                                                     // connect → offer → tunggu accept/reject → sendFile → tunggu done

  // Bersama
  Stream<double> get progress;                       // 0.0–1.0 dari payloadProgressStream
  Future<void> stop();                               // stop advertising/discovery + disconnectAll
}
```

**Detail implementasi:**
1. Inisialisasi `NearbyService(localDisplayName: ...)`. Nama device = nama user (`user.name` dari data) + platform, contoh `"Gisa (Android)"`.
   `ponytail:` nama model HP asli butuh `device_info_plus`; tambahkan kalau guru merasa sulit membedakan perangkat.
2. `serviceId: 'gyntec'`, `strategy: DiscoveryStrategy.hybrid`.
3. **Keamanan:** pakai `SecurityMode.pinVerification`. PIN ditampilkan di kedua layar supaya guru bisa memastikan perangkat yang terhubung memang perangkat yang dimaksud (penting di kelas dengan banyak HP). Kalau UX-nya dirasa terlalu ribet, turun ke `autoAccept`, tetapi tetap ada konfirmasi "Terima File" di penerima.
4. **Validasi input di sisi penerima** (trust boundary — data datang dari perangkat lain):
   - Tolak pesan dengan `v` tidak dikenal.
   - Tolak payload yang lebih besar dari `sizeBytes` yang diumumkan atau lebih dari batas 100 MB.
   - Nama file gambar disanitasi (buang `/`, `\`, `..`) supaya tidak bisa menulis di luar folder modul (**path traversal**).
   - `fromJson` dibungkus `try/catch`; payload rusak ditampilkan sebagai error, app tidak crash.
5. Konflik `id`: jika modul dengan `id` sama sudah ada, modul lama ditimpa. `ponytail:` tambahkan dialog "Ganti / Simpan sebagai salinan" kalau guru sering mengedit modul yang sama.
6. Timeout: `offer` tanpa jawaban 60 detik → dibatalkan; transfer tanpa progress 30 detik → dianggap gagal.
7. File temp payload di pengirim dihapus setelah selesai atau gagal.

**Self-check:** `test/sharing_protocol_test.dart` — encode/decode pesan `offer/accept/reject/done`, penolakan versi salah, penolakan nama file `../evil.png`.

**DoD:** Tes lulus; service bisa dipanggil dari layar spike Phase 0 dan transfer modul nyata berhasil, lalu modul muncul via `ModuleRepository.loadModules()`.

---

### Phase 3 — Integrasi Alur Terima / `SharingHubScreen` (1 hari)

**Tujuan:** Mengganti seluruh simulasi di layar Terima dengan service asli **tanpa mengubah tampilan**.

**Langkah:**
1. Hapus `_incomingSimTimer`, `_progressTimer`, `.take(3)`, dan semua string hardcoded `"Rama (...)"` serta `"3 module"`.
2. `initState`: panggil `NearbySharingService.instance.startReceiving()`, lalu subscribe ke `offers`, `progress`, dan `received`.
3. Pemetaan stage (enum `ReceiveStage` tetap dipakai):

| Stage | Pemicu (dulu → sekarang) | Data yang ditampilkan |
|---|---|---|
| `scanning` | default → default setelah `startReceiving()` | "Menunggu pengirim di sekitar..." + tips hotspot |
| `requestReceived` | Timer 2200ms → event dari `offers` | `offer.senderName`, `offer.modules`, jumlah modul asli, PIN |
| `inProgress` | tap "Terima File" → `acceptOffer()` | `progress` asli |
| `done` | progress = 1.0 → event dari `received` | jumlah modul yang tersimpan |

4. **Batal** di `requestReceived` → `rejectOffer()`. Batal di `inProgress` → `stop()` lalu `startReceiving()` lagi.
5. `dispose()` → cancel semua subscription + `stop()`. Ini wajib, kalau tidak device tetap advertising di background.
6. "Kembali" di `done` → `popUntil(isFirst)`. Daftar modul di Home/Modul harus ter-refresh (panggil ulang `loadModules()` saat tab Modul aktif, atau `await` hasil `Navigator.push` lalu reload).
7. Pindah ke tab "Kirim" → `stop()` dulu sebelum push ke `SelectModuleToSendScreen`.

**DoD:** Dua device fisik: B membuka Terima, A mengirim lewat layar spike. B melihat nama A asli, modul asli, dan progress asli. Setelah selesai, modul muncul di tab Modul B dan bisa dibuka (teks + gambar tampil).

---

### Phase 4 — Integrasi Alur Kirim / `SelectModuleToSendScreen` + `SendModuleScreen` (1 hari)

**Langkah:**
1. `SelectModuleToSendScreen`: ganti `rootBundle` dengan `ModuleRepository.loadModules()` (modul yang pernah diterima juga bisa diteruskan ke guru lain).
2. `SendModuleScreen`:
   - Hapus `_discoveryTimer` dan device hardcoded `dev_1` / `dev_2`.
   - `initState` → `startDiscovery()`, lalu subscribe `devices` → `setState(_discoveredDevices = ...)`.
   - Jangan auto-select device pertama; biarkan guru memilih sendiri.
   - **Satu penerima per kiriman** (koneksi `nearby` bersifat 1:1). Ubah `DeviceSelectCard` dari multi-select menjadi single-select.
     `ponytail:` kirim ke banyak siswa sekaligus = loop `send()` berurutan per device; tambahkan kalau guru perlu membagikan ke satu kelas.
   - Tap "Kirim" → `send(device, modules)`; tampilkan stage:
     - "Menunggu konfirmasi dari {nama}..." (setelah offer terkirim)
     - Progress asli (setelah accept)
     - Sukses (setelah `done`)
     - "Ditolak oleh {nama}" (setelah reject) → kembali ke daftar device
3. Kalau daftar device kosong selama 15 detik, tampilkan bantuan:
   - Pastikan penerima membuka tab **Terima**
   - Sambungkan ke Wi-Fi / hotspot yang sama
   - Tombol "Cari Ulang"
4. `dispose()` → `stop()`.
5. Hapus `TargetDeviceModel` buatan simulasi jika diganti tipe dari service, atau pertahankan dengan `id`/`name` dari peer asli (pilih yang diff-nya paling kecil).

**DoD:** Alur end-to-end tanpa layar spike: A (Kirim) → B (Terima) berhasil untuk Android → Android, Android → iOS, dan iOS → Android. Layar spike dihapus.

---

### Phase 5 — Error Handling, Permission & Polish (1 hari)

**Langkah:**
1. **Permission flow:** sebelum `startReceiving()`/`startDiscovery()`, cek hasilnya. Kalau ditolak, tampilkan kartu penjelasan + tombol buka Settings. Jangan biarkan layar radar berputar selamanya.
2. **Bluetooth/Wi-Fi mati:** tampilkan banner "Nyalakan Wi-Fi atau Bluetooth".
3. **Putus di tengah transfer** (device menjauh, layar dikunci):
   - Pengirim: pesan "Koneksi terputus" + tombol "Coba Lagi".
   - Penerima: buang file parsial, kembali ke `scanning`. Data lama tidak boleh tersentuh karena penulisan memakai pola `.tmp` → `rename`.
4. **App lifecycle:** saat app ke background (`AppLifecycleState.paused`) → `stop()`; saat kembali (`resumed`) → mulai ulang sesuai layar aktif. iOS memutus koneksi di background, jadi ini perilaku yang benar, bukan bug.
5. **Teks UI:** hapus semua sisa string hardcoded; ganti ke data asli.
6. **Offline banner:** pesan di `mock_data.json` → `offlineBanner.description` sudah menyebut Bluetooth; sesuaikan menjadi "Bluetooth atau Wi-Fi/hotspot".
7. `flutter analyze` 0 issue.

**DoD:** Semua skenario di checklist Bagian 6 lulus.

---

## 5. Ringkasan Timeline

| Phase | Isi | Estimasi | Bisa paralel? |
|---|---|---|---|
| 0 | Spike `nearby` lintas platform | 0.5–1 hari | — (gate) |
| 1 | Data layer, model `toJson`, repository, permission | 1–1.5 hari | UI dev bisa mulai mockup tips/permission card |
| 2 | `NearbySharingService` + protokol | 1 hari | — |
| 3 | Alur Terima | 1 hari | Phase 3 & 4 bisa paralel oleh 2 orang |
| 4 | Alur Kirim | 1 hari | ↑ |
| 5 | Error handling & polish | 1 hari | — |
| **Total** | | **5.5–6.5 hari** (≈ 4.5 hari jika 3 & 4 paralel) | |

---

## 6. Checklist Pengujian (Device Fisik)

| # | Skenario | Diharapkan |
|---|---|---|
| 1 | Android → Android, Wi-Fi sama, 1 modul | Berhasil, modul bisa dibuka |
| 2 | Android → iOS, hotspot tanpa kuota, 3 modul | Berhasil |
| 3 | iOS → Android, Wi-Fi sama | Berhasil |
| 4 | Penerima tap Batal saat `requestReceived` | Pengirim melihat "Ditolak" |
| 5 | Pengirim menjauh / Wi-Fi dimatikan saat transfer | Keduanya menampilkan error, tidak crash, data lama aman |
| 6 | Kirim modul dengan `id` yang sudah ada di penerima | Modul lama tertimpa, tidak duplikat |
| 7 | Permission ditolak | Muncul penjelasan + tombol Settings |
| 8 | App ke background saat advertising | Berhenti; resume → mulai lagi |
| 9 | Restart app penerima setelah menerima | Modul yang diterima masih ada |
| 10 | Teruskan modul hasil terima ke device ketiga | Berhasil, gambar ikut terkirim |
| 11 | Build **release** Android (`flutter build apk`) | Sharing tetap jalan (cek permission `INTERNET`) |

---

## 7. Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| `nearby` masih baru / ada bug | Tinggi | Phase 0 sebagai gate; semua kode P2P terisolasi di 1 file service, jadi ganti ke Plan B hanya mengubah file itu |
| Tidak ada Wi-Fi bersama di kelas | Sedang | Cadangan BLE otomatis (lambat) + tips hotspot di UI |
| Tim tidak punya Mac untuk build iOS | Tinggi untuk iOS | Pinjam Mac / CI macOS; Android tetap bisa dikembangkan penuh |
| Wi-Fi sekolah memblokir komunikasi antar-client (AP/client isolation) | Sedang | Tips: pakai hotspot HP; tampilkan bantuan setelah 15 detik tidak ada device |
| Data dari device lain berbahaya / rusak | Sedang | Validasi versi, ukuran, sanitasi nama file, `try/catch` parsing |
| Ukuran gambar besar membuat transfer lambat | Rendah | Base64 aman < 50 MB; `ponytail:` kompres gambar jika perlu |

---

## 8. Di Luar Scope (Sengaja Ditunda)

| Item | Tambahkan ketika |
|---|---|
| Kirim ke banyak device sekaligus (broadcast ke satu kelas) | Guru meminta distribusi massal ke siswa |
| Nama model HP asli (`device_info_plus`) | Guru kesulitan membedakan perangkat |
| ZIP / transfer per file | Modul mulai berisi video atau > 100 MB |
| Dialog konflik modul (ganti / salinan) | Guru mulai mengedit dan berbagi versi berbeda |
| Riwayat transfer | Ada kebutuhan audit / laporan |
| Persistensi murid & riwayat sesi | Masuk planning update terpisah (repository yang sama bisa dipakai ulang) |

---

## 9. Plan B — `bonsoir` + `dart:io` Socket

Dipakai jika `nearby` gagal di Phase 0.

- **Discovery:** `bonsoir` (mDNS / Bonjour, didukung Android & iOS, tidak butuh multicast entitlement Apple karena memakai Bonjour resmi).
  - Penerima: `BonsoirBroadcast` service `_gyntec._tcp` dengan port `ServerSocket`.
  - Pengirim: `BonsoirDiscovery` → daftar device.
- **Transfer:** `dart:io` `ServerSocket` / `Socket` (stdlib). Protokol sama persis (offer/accept/reject/payload/done), frame = 4 byte panjang + isi.
- **Progress:** dihitung manual dari byte terkirim / `sizeBytes`.
- **Kekurangan dibanding `nearby`:** tidak ada cadangan BLE (wajib satu Wi-Fi/hotspot), tidak ada enkripsi bawaan.
- **Dampak ke rencana:** hanya `nearby_sharing_service.dart` yang ditulis ulang (~+150 baris). Phase 1, 3, 4, dan 5 tidak berubah karena UI hanya bergantung pada API service di Phase 2.
