# Planning Update 2 — P2P Module Sharing Android ↔ Android (Offline)

> Status: **Draft / belum dieksekusi**
> Tanggal: 6 November 2026
> Menggantikan: pilihan teknologi di `planingUpdate1.md` (lintas platform)
> Scope: Mengganti simulasi sharing modul (timer + nama device palsu) menjadi transfer **asli** antar HP **Android**, tanpa internet, tanpa router, dan tanpa hotspot.

---

## 1. Kenapa Ada Update 2?

`planingUpdate1.md` mengejar **Android ↔ iOS**. Akibatnya:
- Transfer cepat **wajib** satu Wi-Fi/hotspot, karena Android dan iOS tidak punya Wi-Fi peer-to-peer yang sama.
- Butuh Mac + iPhone untuk build dan uji.
- Package `nearby` (Navideck) yang dipilih masih sangat baru.

Target pengguna Gyntec adalah guru dan siswa di **daerah 3T**. Di sana kepemilikan HP didominasi Android, iPhone sangat jarang. Kalau scope dipersempit ke **Android ↔ Android**:

| Aspek | Update 1 (lintas platform) | **Update 2 (Android saja)** |
|---|---|---|
| Butuh Wi-Fi / hotspot bersama | Ya, untuk transfer cepat | **Tidak** |
| Cara kerja | mDNS + TCP via LAN, cadangan BLE | **Google Nearby Connections** (Bluetooth + Wi-Fi Direct otomatis, mesin yang sama dengan Quick Share) |
| Package | `nearby` (v0.2.0, baru) | **`nearby_connections`** (v4.3.0, matang, ±12rb unduhan) |
| Butuh Mac / iPhone | Ya | **Tidak** |
| Setup iOS | Ada | **Tidak ada** |
| Estimasi | 5.5–6.5 hari | **4–5 hari** |

---

## 2. Kondisi Sekarang (Yang Akan Diganti)

| Bagian | Kondisi sekarang |
|---|---|
| Terima modul (`sharing_hub_screen.dart`) | `Timer` 2200ms memunculkan request palsu dari `"Rama (SM-2BXX)"` |
| Kirim modul (`send_module_screen.dart`) | `Timer` 1800ms memunculkan device palsu `"Rama (SM-1980)"` dan `"iPad Olivia"` |
| Progress transfer | `Timer.periodic(60ms)` +0.015 per tick (~4 detik), bukan progress asli |
| Hasil terima | Tidak disimpan, langsung kembali ke Home |
| Data modul | Hanya `assets/data/mock_data.json` (read-only), dan hanya ada **1** `modulDetail` untuk semua modul |
| Inkonsistensi | Nama pengirim `SM-2BXX` vs `SM-1980` di layar yang sama |

---

## 3. Pemilihan Teknologi

### 3.1 Perbandingan (Android ↔ Android)

| Package | Transport | Butuh Wi-Fi bersama | Butuh Google Play Services | Kematangan | Catatan |
|---|---|---|---|---|---|
| **`nearby_connections` ^4.3.0** | Nearby Connections: Bluetooth, BLE, Wi-Fi Direct/hotspot otomatis | Tidak | **Ya** | Tinggi (144 likes, ±12rb unduhan, publisher terverifikasi) | File payload + progress di **kedua** sisi |
| `flutter_nearby_connections_plus` ^1.2.2 | Sama (Nearby Connections) | Tidak | Ya | Rendah (±114 unduhan, uploader tidak terverifikasi) | API berorientasi pesan, dukungan file kurang jelas |
| `nearby_service` ^0.2.1 | Wi-Fi Direct murni | Tidak (Wi-Fi harus menyala) | **Tidak** | Sedang | Cocok sebagai **Plan B** untuk HP tanpa Google Play |
| `nearby` (Navideck) | LAN + BLE | Ya, untuk transfer cepat | Tidak | Baru | Kelebihannya (lintas platform) tidak dipakai di sini |

> Catatan koreksi: saat diskusi sebelumnya `flutter_nearby_connections_plus` sempat disebut sebagai pilihan. Setelah dicek di pub.dev, **`nearby_connections`** memakai mesin yang sama, tetapi jauh lebih matang dan dukungan file + progress-nya terdokumentasi jelas. Jadi yang dipakai `nearby_connections`.

### 3.2 Keputusan: `nearby_connections`

1. **Tanpa infrastruktur apa pun.** Tidak perlu router, hotspot, atau kuota. Cukup Bluetooth + Lokasi menyala.
2. **Mesin Quick Share.** Koneksi dimulai lewat Bluetooth, lalu otomatis naik ke Wi-Fi Direct untuk transfer cepat.
3. **API cocok dengan alur UI yang sudah ada:**

| UI sekarang | API `nearby_connections` |
|---|---|
| Tab **Terima** (radar menunggu) | `startAdvertising()` |
| Daftar device di layar **Kirim** | `startDiscovery()` → `onEndpointFound` / `onEndpointLost` |
| Tap "Kirim" ke device | `requestConnection()` |
| Konfirmasi sambungan | `onConnectionInitiated` → `acceptConnection()` (ada `authenticationToken` untuk verifikasi) |
| Kirim pesan kecil (offer/accept/done) | `sendBytesPayload()` |
| Kirim modul | `sendFilePayload()` |
| Progress bar | `onPayloadTransferUpdate` (`bytesTransferred / totalBytes`) — **asli di kedua sisi** |

4. **Strategy:** `Strategy.P2P_POINT_TO_POINT` — koneksi 1:1, bandwidth tertinggi, sesuai alur "kirim ke satu penerima".
   `ponytail:` untuk kirim ke satu kelas sekaligus, ganti ke `P2P_STAR` dengan pengirim sebagai advertiser.

### 3.3 Syarat di HP pengguna (wajib dipahami tim)

| Syarat | Kenapa | Penanganan di UI |
|---|---|---|
| **Google Play Services** terpasang | Nearby Connections adalah bagian dari Play Services | HP Huawei keluaran 2019 ke atas (tanpa Google) **tidak bisa**. Tampilkan pesan + gunakan Plan B jika jumlahnya signifikan |
| **Lokasi (GPS) menyala** | Ketentuan Android untuk scan Bluetooth/Wi-Fi. Kalau mati, koneksi sering putus | Cek sebelum mulai, tampilkan kartu "Nyalakan Lokasi" |
| **Bluetooth menyala** | Untuk discovery awal | Cek sebelum mulai, tampilkan kartu "Nyalakan Bluetooth" |
| Izin runtime diberikan | Android 6+ wajib minta izin saat app berjalan | Minta izin saat pertama membuka tab sharing |
| HP fisik | Emulator **tidak** mendukung Nearby Connections | — |

Lokasi hanya dipakai untuk syarat teknis scan perangkat. **Tidak ada** data lokasi yang dibaca atau disimpan. Kalimat ini perlu ditampilkan di layar izin supaya guru tidak curiga.

---

## 4. Arsitektur Solusi

### 4.1 Alur

```
 PENGIRIM (tab "Kirim")                         PENERIMA (tab "Terima")
 ────────────────────────                       ─────────────────────────
 SelectModuleToSendScreen                       SharingHubScreen
   pilih modul                                    startAdvertising()
        │                                              │ stage: scanning
 SendModuleScreen                                      │
   startDiscovery() ─────── Bluetooth ───────────▶ terdeteksi
   onEndpointFound → daftar device ASLI                │
   tap "Kirim"                                         │
   requestConnection(id) ───────────────────────▶ onConnectionInitiated
   onConnectionInitiated → acceptConnection        acceptConnection (otomatis)
        │◀──────────── terhubung (naik ke Wi-Fi Direct) ──────▶│
   sendBytesPayload(OFFER) ─────────────────────▶ stage: requestReceived
                                                   tampilkan nama ASLI + daftar modul ASLI
                                                   user tap "Terima File"
   ◀──────────────────────────────────────────── sendBytesPayload(ACCEPT)
   tulis payload ke file temp
   sendBytesPayload(FILE_META: payloadId)  ─────▶ catat payloadId
   sendFilePayload(file) ───────────────────────▶ stage: inProgress
   onPayloadTransferUpdate (progress ASLI)         onPayloadTransferUpdate (progress ASLI)
                                                   SUCCESS → copyFileAndDeleteOriginal
                                                   ModuleRepository.saveReceived()
   ◀──────────────────────────────────────────── sendBytesPayload(DONE)
   stage: success                                  stage: done
   disconnectFromEndpoint                          modul muncul di tab Modul
```

Kalau penerima menekan **Batal** pada `requestReceived`, penerima mengirim `REJECT`, lalu pengirim menampilkan *"Ditolak oleh {nama}"*.

### 4.2 Protokol pesan (bytes payload, JSON UTF-8)

Bytes payload Nearby dibatasi ±32 KB, jadi hanya untuk pesan kontrol. Modul dikirim sebagai **file payload**.

```json
{ "type": "offer",     "v": 1, "sender": "Gisa", "modules": [ {ModuleModel...} ], "sizeBytes": 2483112 }
{ "type": "accept",    "v": 1 }
{ "type": "reject",    "v": 1 }
{ "type": "file_meta", "v": 1, "payloadId": 123456789 }
{ "type": "done",      "v": 1, "savedIds": ["m1", "m3"] }
```

- `v` = versi protokol. Versi app di HP guru/siswa bisa berbeda, jadi versi yang tidak dikenal ditolak dengan pesan jelas.
- `file_meta` diperlukan karena Nearby menyimpan file masuk dengan nama generik. `payloadId` dipakai untuk mencocokkan file yang datang.

### 4.3 Format payload (file yang dikirim)

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

- Base64 menambah ukuran ±33%, masih aman untuk target < 50 MB.
- Satu file = satu progress bar = sederhana.
- `ponytail:` kalau modul nanti berisi video / > 100 MB, ganti ke ZIP (`archive`) atau kirim per file.

### 4.4 Penyimpanan modul yang diterima

Sekarang 8 layar membaca langsung `rootBundle.loadString('assets/data/mock_data.json')`. Asset read-only, jadi modul yang diterima **tidak bisa** ditulis ke sana. Solusinya satu `ModuleRepository`:

```
<app documents dir>/modules/
├── index.json                 ← daftar ModuleModel yang diterima
└── m1/
    ├── detail.json            ← ModuleDetailModel (imageAsset diganti path file lokal)
    └── images/
        ├── Materi1.png
        └── Materi2.png
```

- `loadModules()` = modul asset + `index.json` (modul diterima menimpa modul asset jika `id` sama).
- `loadDetail(id)` = folder lokal dulu, lalu fallback ke asset.
- Hanya `dart:io` + `path_provider`. **Tanpa database.**

### 4.5 File yang baru / diubah

```
lib/
├── core/services/
│   ├── nearby_sharing_service.dart     ← BARU: wrapper nearby_connections + protokol
│   └── module_repository.dart          ← BARU: baca asset + baca/tulis modul lokal
├── features/module/
│   ├── models/module_model.dart        ← UBAH: tambah toJson()
│   ├── models/module_detail_model.dart ← UBAH: tambah toJson()
│   ├── screens/module_list_screen.dart ← UBAH: pakai ModuleRepository
│   ├── screens/module_detail_screen.dart ← UBAH: load detail sesuai id modul
│   └── widgets/image_block_view.dart   ← UBAH: Image.asset vs Image.file
├── features/home/screens/home_screen.dart ← UBAH: daftar modul dari ModuleRepository
├── features/session/
│   ├── models/quiz_question_model.dart ← UBAH: tambah toJson()
│   └── screens/participant_selection_screen.dart ← UBAH: detail dari ModuleRepository
├── features/sharing/
│   ├── screens/sharing_hub_screen.dart        ← UBAH: hapus Timer, pakai service
│   ├── screens/select_module_to_send_screen.dart ← UBAH: pakai ModuleRepository
│   ├── screens/send_module_screen.dart        ← UBAH: hapus Timer, pakai service
│   └── widgets/device_select_card.dart        ← UBAH: single-select, data peer asli
assets/data/mock_data.json              ← UBAH: modulDetail → modulDetails (per id)
android/app/src/main/AndroidManifest.xml ← UBAH: permission
pubspec.yaml                            ← UBAH: nearby_connections, permission_handler, path_provider
test/module_repository_test.dart        ← BARU: self-check
test/sharing_protocol_test.dart         ← BARU: self-check
```

Tidak ada state management baru: layar tetap `StatefulWidget`, service mengekspos `Stream`, UI cukup `listen` lalu `setState`. **Tidak ada perubahan di folder `ios/`.**

---

## 5. Phase Eksekusi

Urutan disusun supaya **risiko terbesar dicek paling awal**. Setiap phase punya *Definition of Done* (DoD) yang harus lolos sebelum lanjut.

---

### Phase 0 — Spike / Proof of Concept (0.5 hari) — **WAJIB**

**Tujuan:** Membuktikan `nearby_connections` bisa mengirim file antar HP Android yang **mewakili kondisi 3T** (HP murah, Android lama) sebelum menyentuh UI.

**Prasyarat:**
- Minimal **2 HP Android fisik**. Usahakan salah satunya HP entry-level / Android 8–10, karena itu yang umum di lapangan.
- Kabel USB + mode developer aktif.

**Langkah:**
1. Buat branch `spike/nearby-connections`.
2. Tambahkan dependency (lihat Phase 1 langkah 1) dan permission manifest (Phase 1 langkah 2), lalu `flutter pub get`.
3. Buat layar tes sementara `lib/spike_screen.dart` (**dihapus setelah spike**), arahkan `main.dart` ke layar ini sementara:
   - Tombol "Minta Izin" → minta semua izin via `permission_handler`
   - Tombol "Advertise" → `Nearby().startAdvertising('HP-A', Strategy.P2P_POINT_TO_POINT, serviceId: 'com.gyntec.share', ...)`
   - Tombol "Discover" → `startDiscovery(...)`, tampilkan list endpoint
   - Tap endpoint → `requestConnection` → kedua sisi `acceptConnection` → kirim file dummy 10 MB via `sendFilePayload`
   - Tampilkan persen dari `onPayloadTransferUpdate` di kedua HP
   - Di penerima: `copyFileAndDeleteOriginal(uri, path)` lalu tampilkan ukuran file hasil salinan
4. Uji dan catat:

| # | Skenario | Hasil | Waktu 10 MB |
|---|---|---|---|
| 1 | Wi-Fi menyala (tidak terhubung ke jaringan apa pun), Bluetooth + Lokasi menyala | | |
| 2 | Wi-Fi **mati**, hanya Bluetooth + Lokasi | | |
| 3 | Mode pesawat + Bluetooth dinyalakan manual | | |
| 4 | HP entry-level / Android lama sebagai penerima | | |
| 5 | Lokasi dimatikan | (harusnya gagal → konfirmasi pesan error yang muncul) | |
| 6 | Jarak ±5 m dan ±10 m | | |

**DoD / Decision gate:**
- ✅ Skenario 1, 2, 4 berhasil → **lanjut Phase 1**.
- ❌ Gagal di HP tertentu karena tidak ada Google Play Services → catat merek/tipe; jika banyak dipakai di lapangan, rencanakan **Plan B** (Bagian 9) sebagai jalur tambahan.
- Catat file masuk tersimpan di mana (`uri` vs path) di Android lama vs baru, karena ini menentukan implementasi di Phase 2.

---

### Phase 1 — Fondasi: Data Layer & Konfigurasi Android (1 hari)

**Tujuan:** Modul bisa diserialisasi, disimpan, dan dibaca ulang; permission siap. Belum ada perubahan di UI sharing.

**Langkah:**

1. **Dependency** — `pubspec.yaml`:
   ```yaml
   dependencies:
     nearby_connections: ^4.3.0
     permission_handler: ^12.0.0   # cek versi terbaru saat eksekusi
     path_provider: ^2.1.5
   ```
   `permission_handler` dipakai karena izin yang diminta ada beberapa dan berbeda per versi Android; menulis platform channel sendiri jauh lebih panjang.

2. **Android** — `android/app/src/main/AndroidManifest.xml` (di atas `<application>`), sesuai README `nearby_connections`:
   ```xml
   <uses-permission android:maxSdkVersion="31" android:name="android.permission.ACCESS_WIFI_STATE" />
   <uses-permission android:maxSdkVersion="31" android:name="android.permission.CHANGE_WIFI_STATE" />
   <uses-permission android:maxSdkVersion="30" android:name="android.permission.BLUETOOTH" />
   <uses-permission android:maxSdkVersion="30" android:name="android.permission.BLUETOOTH_ADMIN" />
   <uses-permission android:maxSdkVersion="28" android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:minSdkVersion="29" android:maxSdkVersion="31" android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:minSdkVersion="31" android:name="android.permission.BLUETOOTH_ADVERTISE" />
   <uses-permission android:minSdkVersion="31" android:name="android.permission.BLUETOOTH_CONNECT" />
   <uses-permission android:minSdkVersion="31" android:name="android.permission.BLUETOOTH_SCAN" />
   <uses-permission android:minSdkVersion="32" android:name="android.permission.NEARBY_WIFI_DEVICES" />
   ```
   Nearby Connections **tidak** butuh izin `INTERNET`.

3. **Model** — tambahkan `toJson()` (pasangan dari `fromJson()` yang sudah ada) di:
   - `ModuleModel`
   - `ModuleDetailModel`, `MateriBlockModel`, `GroupQuestionModel`
   - `QuizQuestionModel`

4. **Mock data** — `assets/data/mock_data.json`: ubah `"modulDetail": {...}` menjadi `"modulDetails": { "m1": {...}, "m2": {...}, "m3": {...}, "m4": {...} }`, supaya setiap modul punya detail sendiri (sekaligus memperbaiki bug "detail modul selalu m1"). Modul yang belum punya konten boleh menyalin isi m1 dulu dengan judul diganti.

5. **`ModuleRepository`** (`lib/core/services/module_repository.dart`), singleton seperti `ConnectivityService`:
   - `Future<List<ModuleModel>> loadModules()` — modul asset + `index.json` lokal
   - `Future<ModuleDetailModel> loadDetail(String id)` — lokal dulu, lalu asset
   - `Future<Uint8List> readImageBytes(String path)` — dari asset (`rootBundle.load`) atau file
   - `Future<File> buildPayloadFile(List<ModuleModel> modules)` — rakit JSON payload (Bagian 4.3) ke folder temp
   - `Future<List<String>> saveReceived(File payloadFile)` — parse, tulis `detail.json`, decode gambar ke `images/`, ganti `imageAsset` jadi path lokal, update `index.json`
   - Tulis ke file `.tmp` lalu `rename()`, supaya `index.json` tidak korup kalau app mati di tengah proses (**mencegah kehilangan data**).

6. **Pakai repository** di `module_list_screen.dart`, `module_detail_screen.dart` (load sesuai `module.id`), `home_screen.dart` (bagian modul), dan `participant_selection_screen.dart` (bagian detail modul).

7. **Gambar** — `image_block_view.dart`: path diawali `assets/` → `Image.asset`, selain itu → `Image.file(File(path))`.

8. **Self-check** — `test/module_repository_test.dart`:
   - Round-trip `ModuleDetailModel → toJson → fromJson` menghasilkan data yang sama.
   - `buildPayloadFile` lalu `saveReceived` lalu `loadDetail` mengembalikan modul yang sama.

**DoD:**
- `flutter analyze` 0 issue, `flutter test` lulus.
- Semua layar tetap berjalan seperti sebelumnya (regresi nol).
- Tap modul m2 menampilkan detail m2, bukan m1.

---

### Phase 2 — `NearbySharingService` (1 hari)

**Tujuan:** Semua logika P2P ada di **satu file**. UI tidak menyentuh `nearby_connections` secara langsung, jadi kalau nanti pindah ke Plan B cukup file ini yang diganti.

**File:** `lib/core/services/nearby_sharing_service.dart`

**API publik (minimum):**

```dart
class NearbySharingService {
  static final instance = NearbySharingService._();

  // Persiapan
  Future<SharingReadiness> checkReadiness();         // izin, Bluetooth, Lokasi
  Future<bool> requestPermissions();

  // Penerima
  Future<void> startReceiving();                     // startAdvertising
  Stream<IncomingOffer> get offers;                  // nama pengirim + List<ModuleModel> + sizeBytes
  Future<void> acceptOffer(IncomingOffer offer);     // kirim "accept"
  Future<void> rejectOffer(IncomingOffer offer);     // kirim "reject"
  Stream<List<String>> get received;                 // id modul yang berhasil disimpan

  // Pengirim
  Future<void> startDiscovery();
  Stream<List<TargetDeviceModel>> get devices;       // dari onEndpointFound / onEndpointLost
  Future<SendResult> send(TargetDeviceModel device, List<ModuleModel> modules);
      // requestConnection → offer → tunggu accept/reject → file_meta → sendFilePayload → tunggu done

  // Bersama
  Stream<double> get progress;                       // 0.0–1.0 dari onPayloadTransferUpdate
  Future<void> stop();                               // stopAdvertising, stopDiscovery, stopAllEndpoints
}
```

`SharingReadiness` cukup enum: `ready`, `permissionDenied`, `bluetoothOff`, `locationOff`, `unsupported`.

**Detail implementasi:**
1. `serviceId: 'com.gyntec.share'`, `Strategy.P2P_POINT_TO_POINT`.
2. **Nama perangkat** = nama user (`user.name` di data) + 4 karakter acak yang disimpan sekali, contoh `"Gisa · 7K2Q"`. Ini membantu membedakan dua guru bernama sama.
   `ponytail:` nama model HP asli butuh `device_info_plus`; tambahkan kalau guru masih kesulitan membedakan perangkat.
3. **Koneksi:** kedua sisi memanggil `acceptConnection` otomatis di `onConnectionInitiated`. Konfirmasi manusia ada di level **offer** ("Terima File"), karena di situ penerima sudah bisa melihat nama pengirim dan daftar modul.
   - `authenticationToken` dari `ConnectionInfo` ditampilkan kecil di kedua layar ("Kode: 4F2A") supaya guru bisa memastikan HP yang terhubung benar, terutama di kelas yang ramai.
4. **Penerimaan file:**
   - Simpan `payloadId` dari pesan `file_meta`.
   - Di `onPayloadTransferUpdate` dengan status `SUCCESS` untuk `payloadId` tersebut: ambil `uri` file dari payload, `copyFileAndDeleteOriginal(uri, tempPath)`, lalu `ModuleRepository.saveReceived(File(tempPath))`, kirim `done`, hapus file temp.
5. **Validasi input di sisi penerima** (trust boundary — data datang dari perangkat lain):
   - Tolak pesan dengan `v` tidak dikenal.
   - Tolak payload yang `totalBytes`-nya lebih besar dari `sizeBytes` yang diumumkan atau lebih dari 100 MB (batalkan via `cancelPayload`).
   - Sanitasi nama file gambar (buang `/`, `\`, `..`) supaya tidak bisa menulis di luar folder modul (**path traversal**).
   - Sanitasi `id` modul dengan aturan yang sama, karena dipakai sebagai nama folder.
   - Bungkus semua `jsonDecode` / `fromJson` dengan `try/catch`; payload rusak ditampilkan sebagai error, app tidak crash.
6. **Konflik `id`:** modul dengan `id` sama menimpa modul lama.
   `ponytail:` tambahkan dialog "Ganti / Simpan sebagai salinan" kalau guru mulai mengedit modul.
7. **Timeout:** offer tanpa jawaban 60 detik → batal; transfer tanpa progress 30 detik → gagal; endpoint tidak bisa disambung 20 detik → gagal.
8. Hentikan discovery setelah `requestConnection` dipanggil (rekomendasi README: mengurangi risiko putus).
9. File temp payload di pengirim dihapus setelah selesai atau gagal.

**Self-check:** `test/sharing_protocol_test.dart` — encode/decode semua tipe pesan, penolakan versi salah, penolakan nama file `../evil.png` dan `id` `../../x`.

**DoD:** Tes lulus; dari layar spike, service berhasil mengirim **modul asli** dan modul tersebut muncul via `ModuleRepository.loadModules()` di HP penerima.

---

### Phase 3 — Integrasi Alur Terima / `SharingHubScreen` (0.5–1 hari)

**Tujuan:** Mengganti simulasi di layar Terima dengan service asli **tanpa mengubah tampilan**.

**Langkah:**
1. Hapus `_incomingSimTimer`, `_progressTimer`, `.take(3)`, dan semua string hardcoded `"Rama (...)"` serta `"3 module"`.
2. `initState`:
   - `checkReadiness()`. Kalau belum siap, tampilkan kartu sesuai kondisi (lihat Phase 5) dan **jangan** tampilkan radar berputar.
   - Kalau siap: `startReceiving()`, lalu subscribe ke `offers`, `progress`, dan `received`.
3. Pemetaan stage (enum `ReceiveStage` tetap dipakai):

| Stage | Pemicu (dulu → sekarang) | Data yang ditampilkan |
|---|---|---|
| `scanning` | default → setelah `startReceiving()` | "Menunggu pengirim di sekitar..." |
| `requestReceived` | Timer 2200ms → event dari `offers` | `offer.senderName`, `offer.modules`, jumlah modul asli, kode verifikasi |
| `inProgress` | tap "Terima File" → `acceptOffer()` | `progress` asli |
| `done` | progress 1.0 → event dari `received` | jumlah modul yang tersimpan |

4. **Batal** di `requestReceived` → `rejectOffer()`. Batal di `inProgress` → `stop()` lalu `startReceiving()` lagi.
5. `dispose()` → cancel semua subscription + `stop()`. Wajib, kalau tidak HP tetap advertising dan menguras baterai.
6. "Kembali" di `done` → `popUntil(isFirst)`. Daftar modul di Home/Modul harus ter-refresh: panggil ulang `loadModules()` setelah `Navigator.push` ke Sharing Hub selesai (`await` hasil push).
7. Pindah ke tab "Kirim" → `stop()` dulu sebelum push ke `SelectModuleToSendScreen`.

**DoD:** Dua HP fisik: B membuka Terima, A mengirim lewat layar spike. B melihat nama A asli, modul asli, progress asli. Setelah selesai, modul muncul di tab Modul B dan bisa dibuka (teks + gambar tampil).

---

### Phase 4 — Integrasi Alur Kirim / `SelectModuleToSendScreen` + `SendModuleScreen` (0.5–1 hari)

**Langkah:**
1. `SelectModuleToSendScreen`: ganti `rootBundle` dengan `ModuleRepository.loadModules()`, supaya modul hasil terima juga bisa diteruskan ke guru/siswa lain.
2. `SendModuleScreen`:
   - Hapus `_discoveryTimer` dan device hardcoded `dev_1` / `dev_2`.
   - `initState` → `checkReadiness()` → `startDiscovery()`, subscribe `devices` → `setState`.
   - Jangan auto-select device pertama; guru memilih sendiri.
   - **Satu penerima per kiriman** (`P2P_POINT_TO_POINT`). Ubah `DeviceSelectCard` dari multi-select menjadi single-select.
     `ponytail:` kirim ke banyak siswa = loop `send()` berurutan per device, atau pindah ke `P2P_STAR`. Tambahkan saat guru perlu membagikan ke satu kelas.
   - Tap "Kirim" → `send(device, modules)`, dengan stage:
     - "Menghubungkan ke {nama}..." (setelah `requestConnection`)
     - "Menunggu konfirmasi dari {nama}..." (setelah offer terkirim)
     - Progress asli (setelah accept)
     - Sukses (setelah `done`)
     - "Ditolak oleh {nama}" (setelah reject) → kembali ke daftar device
3. Daftar device kosong 15 detik → tampilkan bantuan:
   - Pastikan penerima sudah membuka tab **Terima** di Gyntec
   - Pastikan Bluetooth dan Lokasi menyala di **kedua** HP
   - Dekatkan kedua HP (< 5 meter)
   - Tombol "Cari Ulang"
4. `dispose()` → `stop()`.
5. `TargetDeviceModel` tetap dipakai (`id` = endpointId, `name` = endpointName dari Nearby) supaya diff kecil.
6. Hapus `lib/spike_screen.dart` dan kembalikan `main.dart`.

**DoD:** Alur end-to-end tanpa layar spike: A (Kirim) → B (Terima) berhasil. Lalu B meneruskan modul yang sama ke C dan gambar ikut terkirim.

---

### Phase 5 — Error Handling, Izin & Polish (1 hari)

**Langkah:**
1. **Alur izin** (pertama kali membuka Sharing Hub):
   - Kartu penjelasan singkat sebelum dialog sistem muncul: *"Gyntec butuh izin Perangkat Sekitar dan Lokasi untuk menemukan HP lain. Lokasi Anda tidak dibaca atau disimpan."*
   - Ditolak → kartu + tombol **Buka Pengaturan** (`openAppSettings()` dari `permission_handler`).
   - Ditolak permanen → sama, tanpa minta ulang.
2. **Bluetooth / Lokasi mati** → kartu "Nyalakan Bluetooth" / "Nyalakan Lokasi", cek ulang otomatis saat app kembali aktif (`AppLifecycleState.resumed`).
3. **Google Play Services tidak tersedia** (error saat `startAdvertising`/`startDiscovery`) → pesan: *"Perangkat ini tidak mendukung berbagi langsung."* Jangan crash.
4. **Putus di tengah transfer** (HP menjauh, layar dikunci, `onDisconnected`):
   - Pengirim: "Koneksi terputus" + tombol "Coba Lagi".
   - Penerima: hapus file parsial, kembali ke `scanning`. Data lama aman karena pola `.tmp` → `rename`.
5. **App lifecycle:** `paused` → `stop()`; `resumed` → mulai ulang sesuai layar aktif.
6. **Layar tetap menyala** selama transfer: cukup tampilkan teks "Jangan kunci layar selama pengiriman".
   `ponytail:` pakai `wakelock_plus` kalau di lapangan transfer sering putus karena layar mati.
7. **Teks UI:** pastikan tidak ada sisa string hardcoded. Ubah `offlineBanner.description` di `mock_data.json` agar menyebut "Bluetooth" secara akurat.
8. `flutter analyze` 0 issue, `flutter build apk --release` lalu uji ulang di HP fisik.

**DoD:** Semua skenario di Bagian 6 lulus.

---

## 6. Checklist Pengujian (HP Fisik)

| # | Skenario | Diharapkan |
|---|---|---|
| 1 | A → B, 1 modul, Wi-Fi tidak terhubung ke jaringan apa pun | Berhasil, modul bisa dibuka |
| 2 | A → B, 3 modul sekaligus, Wi-Fi mati | Berhasil (mungkin lebih lambat) |
| 3 | Penerima HP entry-level / Android 8–10 | Berhasil |
| 4 | Penerima tap Batal saat `requestReceived` | Pengirim melihat "Ditolak" |
| 5 | HP dijauhkan / Bluetooth dimatikan saat transfer | Keduanya menampilkan error, tidak crash, data lama aman |
| 6 | Kirim modul dengan `id` yang sudah ada di penerima | Modul lama tertimpa, tidak duplikat |
| 7 | Izin ditolak | Muncul penjelasan + tombol Buka Pengaturan |
| 8 | Lokasi dimatikan sebelum membuka Sharing Hub | Muncul kartu "Nyalakan Lokasi", tidak ada radar berputar selamanya |
| 9 | App ke background saat menunggu | Berhenti; kembali ke app → mulai lagi |
| 10 | Restart app penerima setelah menerima | Modul yang diterima masih ada |
| 11 | B meneruskan modul hasil terima ke C | Berhasil, gambar ikut terkirim |
| 12 | Build **release** (`flutter build apk --release`) | Sharing tetap jalan |
| 13 | Dua HP penerima menyala sekaligus | Pengirim melihat dua nama berbeda (akhiran kode acak) |

---

## 7. Ringkasan Timeline

| Phase | Isi | Estimasi | Paralel? |
|---|---|---|---|
| 0 | Spike `nearby_connections` di HP fisik | 0.5 hari | — (gate) |
| 1 | Data layer, `toJson`, repository, manifest | 1 hari | UI/UX bisa mulai desain kartu izin & bantuan |
| 2 | `NearbySharingService` + protokol | 1 hari | — |
| 3 | Alur Terima | 0.5–1 hari | Phase 3 & 4 bisa paralel oleh 2 orang |
| 4 | Alur Kirim | 0.5–1 hari | ↑ |
| 5 | Error handling, izin, polish | 1 hari | — |
| **Total** | | **4.5–5.5 hari** (≈ 4 hari jika 3 & 4 paralel) | |

---

## 8. Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| HP tanpa Google Play Services (Huawei baru, sebagian HP non-resmi) | Sedang | Deteksi + pesan jelas; Plan B (`nearby_service`, Wi-Fi Direct tanpa Google) jika banyak di lapangan |
| Guru lupa menyalakan Lokasi | Tinggi (koneksi gagal/putus) | Cek otomatis + kartu "Nyalakan Lokasi" sebelum mulai |
| HP Android lama / RAM kecil lambat memproses base64 gambar besar | Rendah–Sedang | Target < 50 MB; parsing di `compute()` (isolate) agar UI tidak macet; `ponytail:` kompres gambar jika perlu |
| Banyak HP di kelas, salah pilih penerima | Sedang | Nama + akhiran kode acak + kode verifikasi di kedua layar + konfirmasi "Terima File" |
| Data dari HP lain berbahaya / rusak | Sedang | Validasi versi & ukuran, sanitasi nama file & `id`, `try/catch` parsing |
| Package `nearby_connections` jarang update (rilis terakhir Feb 2025) | Rendah | API Nearby Connections Google stabil; semua kode P2P terisolasi di 1 file service |
| Layar terkunci saat transfer | Rendah | Pesan "Jangan kunci layar"; `ponytail:` `wakelock_plus` |

---

## 9. Plan B — `nearby_service` (Wi-Fi Direct, tanpa Google Play Services)

Dipakai jika spike Phase 0 gagal, atau sebagai jalur tambahan kalau banyak HP tanpa Google Play di lapangan.

- **Transport:** Wi-Fi Direct murni (`android.net.wifi.p2p`), bawaan Android, tidak butuh Google Play Services.
- **Syarat:** Wi-Fi harus **menyala** (tidak perlu terhubung ke jaringan), izin Lokasi + `NEARBY_WIFI_DEVICES` (Android 13+). Package sudah menyertakan permission di manifest-nya.
- **Pemetaan API:** `discover()` + `getPeersStream()` → daftar device; `connect()` → sambung; `startCommunicationChannel()` → kanal data; `NearbyMessageTextRequest` → pesan kontrol; `NearbyMessageFilesRequest` / `NearbyMessageFilesResponse(isAccepted)` → kirim modul dengan konfirmasi bawaan (cocok dengan tombol "Terima File").
- **Kekurangan:** tidak ada progress transfer per byte (progress bar menjadi indeterminate), discovery Wi-Fi Direct kadang lebih lambat, dan kadang muncul dialog sistem "Undangan Wi-Fi Direct".
- **Dampak ke rencana:** hanya `nearby_sharing_service.dart` yang ditulis ulang. Phase 1, 3, 4, dan 5 tidak berubah karena UI hanya bergantung pada API service di Phase 2.

---

## 10. Di Luar Scope (Sengaja Ditunda)

| Item | Tambahkan ketika |
|---|---|
| Dukungan iOS | Ada pengguna iPhone di lapangan → lihat `planingUpdate1.md`, tambahkan implementasi iOS di service yang sama |
| Kirim ke satu kelas sekaligus (`P2P_STAR`) | Guru meminta distribusi massal ke siswa |
| Nama model HP asli (`device_info_plus`) | Guru masih kesulitan membedakan perangkat |
| `wakelock_plus` | Transfer sering putus karena layar terkunci |
| ZIP / transfer per file | Modul mulai berisi video atau > 100 MB |
| Dialog konflik modul (ganti / salinan) | Guru mulai mengedit dan berbagi versi berbeda |
| Riwayat transfer | Ada kebutuhan audit / laporan |
| Persistensi murid & riwayat sesi | Planning update terpisah (`ModuleRepository` bisa jadi pola yang sama) |
