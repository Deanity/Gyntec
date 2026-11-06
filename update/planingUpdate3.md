# Planning Update 3 — Migrasi Struktur Data Modul

> Status: **Draft / belum dieksekusi**
> Tanggal: 6 November 2026
> Dikerjakan: **sebelum** Phase 2–5 di `planingUpdate2.md`
> Menggantikan: Phase 1 langkah 3–8 di `planingUpdate2.md` (model `toJson`, mock data, `ModuleRepository`, gambar). Phase 1 di Plan 2 jadi tinggal dependency + manifest Android.

---

## 1. Kenapa Perlu Plan Terpisah?

Fitur sharing (Plan 2) butuh tiga hal yang mengubah **fondasi data** app:

1. Setiap modul punya detail **sendiri** (sekarang semua modul memakai satu `modulDetail` yang sama).
2. Modul bisa **ditulis** ke penyimpanan HP (sekarang hanya dibaca dari asset yang read-only).
3. Gambar bisa berasal dari **asset** atau **file di HP**.

Kalau ketiganya dikerjakan sekaligus bersama fitur sharing, kesalahan kecil di struktur data bisa membuat layar Modul, Detail Modul, Peserta, dan Sesi Belajar tidak bisa dibuka. Jadi migrasi ini dipisah, dikerjakan bertahap, dan diuji per langkah.

---

## 2. Kondisi Sekarang (Hasil Pengecekan Kode)

### 2.1 Siapa yang membaca `mock_data.json`

Ada 8 layar yang membaca file ini langsung lewat `rootBundle.loadString(...)`, tetapi **tidak semuanya** terdampak migrasi:

| File | Key yang dibaca | Terdampak? |
|---|---|---|
| `features/module/screens/module_detail_screen.dart` | `offlineBanner`, **`modulDetail`** | **Ya — inti** |
| `features/session/screens/participant_selection_screen.dart` | `students`, **`modulDetail`** (fallback) | **Ya** |
| `features/module/screens/module_list_screen.dart` | `modules` | Ya (sumber daftar modul + navigasi ke detail) |
| `features/home/screens/home_screen.dart` | `user`, `offlineBanner`, `recentSessions`, `modules` | Ya (sumber daftar modul + navigasi ke detail) |
| `features/sharing/screens/sharing_hub_screen.dart` | `modules` | Ya (sumber daftar modul) |
| `features/sharing/screens/select_module_to_send_screen.dart` | `modules` | Ya (sumber daftar modul) |
| `features/session/screens/session_history_screen.dart` | `sessionHistory` | **Tidak** |
| `features/student/screens/student_screen.dart` | `students` | **Tidak** |

> Koreksi dari diskusi sebelumnya: yang benar-benar membaca `modulDetail` hanya **2 file**. Enam lainnya hanya membaca `modules` atau key lain.

### 2.2 Temuan penting

| # | Temuan | Lokasi | Dampak |
|---|---|---|---|
| 1 | `ModuleDetailScreen` **tidak menerima id modul** — constructor-nya `const ModuleDetailScreen({super.key})` | `module_detail_screen.dart:11` | Tap modul mana pun selalu menampilkan m1 |
| 2 | Pemanggil detail tidak mengirim modul yang di-tap | `module_list_screen.dart:138`, `home_screen.dart:183` | Harus diubah bersamaan dengan #1 |
| 3 | Fallback `modulDetail` di `ParticipantSelectionScreen` **tidak pernah terpakai** — satu-satunya pemanggil (`module_detail_screen.dart:100`) selalu mengirim `modul` | `participant_selection_screen.dart:73–80` | Bisa **dihapus**, tidak perlu dimigrasi |
| 4 | Gambar hanya bisa dari asset (`Image.asset`) | `image_block_view.dart:14` | Dipakai di **Detail Modul** dan **Sesi Belajar** (`learning_session_screen.dart:254`) |
| 5 | Model hanya punya `fromJson`, belum ada `toJson` | 5 model | Tidak bisa menyimpan modul ke HP |
| 6 | Belum ada folder `test/` sama sekali | — | Tidak ada pengaman regresi otomatis |

### 2.3 Struktur data sekarang

```json
{
  "modules": [ { "id": "m1", ... }, { "id": "m2", ... }, { "id": "m3", ... }, { "id": "m4", ... } ],
  "modulDetail": { "id": "m1", "materi": [...], "groupQuestion": {...}, "quiz": [...] }
}
```

---

## 3. Struktur Data Tujuan

### 3.1 Asset (`assets/data/mock_data.json`)

```json
{
  "modules": [ { "id": "m1", ... }, { "id": "m2", ... }, ... ],
  "modulDetails": {
    "m1": { "id": "m1", "materi": [...], "groupQuestion": {...}, "quiz": [...] },
    "m2": { "id": "m2", ... },
    "m3": { "id": "m3", ... },
    "m4": { "id": "m4", ... }
  }
}
```

Aturan yang harus selalu benar (dicek otomatis oleh tes di Phase 2):
- Setiap `id` di `modules` **punya** entri di `modulDetails`.
- `modulDetails[x].id == x`.
- Setiap `imageAsset` di `materi` menunjuk file yang **ada** di `assets/`.
- `quiz[].correctIndex` berada di dalam rentang `options`.

Dipilih **map berdasarkan id** (bukan list) supaya pencarian detail cukup `modulDetails[id]` dan duplikat id tidak mungkin terjadi.

### 3.2 Penyimpanan di HP (untuk modul yang diterima lewat sharing)

```
<app documents dir>/modules/
├── index.json
└── m1/
    ├── detail.json
    └── images/
        ├── Materi1.png
        └── Materi2.png
```

`index.json`:
```json
{
  "schemaVersion": 1,
  "modules": [ { "id": "m1", "level": "SMA", "title": "...", "...": "..." } ]
}
```

- `schemaVersion` disiapkan **dari awal**. Kalau struktur berubah lagi di masa depan, app bisa mendeteksi versi lama dan memigrasikannya, bukan crash. Ini satu-satunya "persiapan masa depan" yang dibuat, karena data di HP pengguna tidak bisa diperbaiki dari jauh.
- Di `detail.json`, `imageAsset` berisi **path file lokal** (contoh `/data/user/0/.../modules/m1/images/Materi1.png`).
- Aturan baca: modul di HP **menimpa** modul asset jika `id` sama.

---

## 4. Strategi: Expand → Migrate → Contract

Pola standar untuk mengubah struktur data tanpa merusak app:

| Tahap | Isi | Kondisi app |
|---|---|---|
| **Expand** | Tambahkan struktur baru (`modulDetails`) **di samping** struktur lama (`modulDetail`) | Kode lama tetap jalan karena `modulDetail` masih ada |
| **Migrate** | Pindahkan pembaca ke struktur baru, **satu layar per commit** | Setiap commit bisa dijalankan dan diuji |
| **Contract** | Hapus struktur lama setelah tidak ada lagi yang membacanya | Bersih |

Keuntungannya: di tahap mana pun, kalau ada yang rusak, cukup **revert satu commit** — layar lain tidak ikut rusak.

---

## 5. Phase Eksekusi

Aturan umum untuk semua phase:
- Kerjakan di branch `feat/data-migration`.
- **Satu langkah = satu commit**, dengan pesan yang jelas (contoh: `migrate: module_list_screen pakai ModuleRepository`).
- Setelah setiap commit: `flutter analyze` 0 issue + `flutter test` lulus + cek manual layar yang disentuh.

---

### Phase 0 — Baseline & Jaring Pengaman (0.5 hari)

**Tujuan:** Punya acuan "app yang benar" sebelum ada yang diubah.

**Langkah:**
1. Pastikan `main` bersih, lalu beri tag: `git tag pre-data-migration`. Ini titik kembali kalau semuanya harus dibatalkan.
2. Buat branch `feat/data-migration`.
3. **Rekam baseline manual:** jalankan app, ambil screenshot setiap layar di checklist Bagian 6. Simpan di `update/baseline/` (atau cukup di HP, yang penting bisa dibandingkan).
4. Buat folder `test/` dan file pertama `test/mock_data_test.dart` yang memastikan **data sekarang** bisa di-parse:
   - `modules` → semua bisa jadi `ModuleModel`
   - `modulDetail` → bisa jadi `ModuleDetailModel`
   - `students`, `sessionHistory`, `recentSessions` → bisa di-parse oleh model masing-masing
   - Baca file langsung via `File('assets/data/mock_data.json')` (stdlib), tanpa perlu `rootBundle`.

**DoD:** `flutter test` lulus di kode yang **belum diubah sama sekali**. Tes ini akan menjaga semua phase berikutnya.

---

### Phase 1 — Model: Tambah `toJson()` (0.5 hari)

**Tujuan:** Semua model bisa diubah kembali ke JSON. **Tidak ada perubahan perilaku app.**

**Langkah:**
1. Tambahkan `Map<String, dynamic> toJson()` di:
   - `ModuleModel` (`features/module/models/module_model.dart`)
   - `MateriBlockModel`, `GroupQuestionModel`, `ModuleDetailModel` (`features/module/models/module_detail_model.dart`)
   - `QuizQuestionModel` (`features/session/models/quiz_question_model.dart`)
2. Nama key **harus sama persis** dengan yang dibaca `fromJson` (`imageAsset`, `correctIndex`, `totalQuestions`, dst).
3. `imageAsset` yang `null` tidak perlu ditulis (supaya JSON tetap sama dengan aslinya).
4. Tambahkan ke `test/mock_data_test.dart`: **round-trip** — untuk setiap modul dan detail, `fromJson(x.toJson())` menghasilkan nilai yang sama dengan `x` (bandingkan via `jsonEncode`).

**DoD:** Tes round-trip lulus. App berjalan identik dengan baseline.

---

### Phase 2 — Expand: Tambah `modulDetails` di Mock Data (0.5 hari)

**Tujuan:** Struktur baru tersedia, struktur lama **tetap ada**.

**Langkah:**
1. Di `assets/data/mock_data.json`, tambahkan key `modulDetails` **tanpa menghapus** `modulDetail`.
2. Isi `modulDetails.m1` = salinan persis `modulDetail` sekarang.
3. Isi `m2`, `m3`, `m4`:
   - Idealnya konten asli dari tim (UI/UX & PM menyiapkan materi, diskusi, quiz).
   - Kalau belum ada: salin m1, lalu ganti `id`, `title`, `level`, `subject` agar sesuai daftar `modules`. Tandai di catatan tim bahwa konten ini placeholder.
   - Jumlah `quiz` dan `totalQuestions` harus konsisten dengan data di `modules` (atau sesuaikan `modules`-nya).
4. Tambahkan tes validasi di `test/mock_data_test.dart` (aturan dari Bagian 3.1):
   - Setiap id di `modules` ada di `modulDetails`
   - `modulDetails[x].id == x`
   - Setiap `imageAsset` file-nya ada (`File(path).existsSync()`)
   - `correctIndex` valid

**DoD:** Tes validasi lulus. App berjalan identik dengan baseline (belum ada kode yang membaca `modulDetails`).

---

### Phase 3 — `ModuleRepository` (Baca Saja) (0.5 hari)

**Tujuan:** Satu pintu untuk membaca data modul. Belum dipakai oleh layar mana pun.

**File baru:** `lib/core/services/module_repository.dart`, singleton dengan pola yang sama seperti `ConnectivityService`.

**API di phase ini:**
```dart
class ModuleRepository {
  static final instance = ModuleRepository._();

  Future<List<ModuleModel>> loadModules();          // dari asset `modules`
  Future<ModuleDetailModel> loadDetail(String id);  // dari asset `modulDetails[id]`
}
```

**Detail:**
1. JSON asset dibaca **sekali** lalu disimpan di memori (`Future` yang di-cache). Delapan layar yang sekarang membaca ulang file yang sama tidak perlu ikut diubah kalau mereka tidak terdampak.
2. `loadDetail(id)` urutan pencarian:
   - `modulDetails[id]`
   - Fallback sementara: `modulDetail` jika `modulDetail.id == id` (hanya selama tahap Migrate, dihapus di Phase 5)
   - Tidak ketemu → lempar `StateError('Modul $id tidak ditemukan')`. **Jangan** diam-diam mengembalikan m1, karena itu justru bug yang sedang diperbaiki.
3. Belum ada penyimpanan ke HP di phase ini (masuk Phase 6).
4. Tes `test/module_repository_test.dart`:
   - `loadModules()` mengembalikan 4 modul
   - `loadDetail('m2').id == 'm2'`
   - `loadDetail('tidak-ada')` melempar error

   Catatan: repository memakai `rootBundle`, jadi tes perlu `TestWidgetsFlutterBinding.ensureInitialized()`. Asset yang terdaftar di `pubspec.yaml` otomatis tersedia di `flutter test`.

**DoD:** Tes lulus. App identik dengan baseline.

---

### Phase 4 — Migrate: Pindahkan Layar Satu per Satu (1 hari)

**Tujuan:** Semua pembaca data modul memakai `ModuleRepository`. **Satu langkah = satu commit**, urut dari yang paling aman.

| Urutan | File | Perubahan | Cek manual setelah commit |
|---|---|---|---|
| 4.1 | `image_block_view.dart` | Path diawali `assets/` → `Image.asset`, selain itu → `Image.file(File(path))`. `errorBuilder` tetap. | Detail Modul + Sesi Belajar: gambar tetap tampil |
| 4.2 | `select_module_to_send_screen.dart` | `json['modules']` → `ModuleRepository.instance.loadModules()` | Kirim Modul: daftar 4 modul tampil |
| 4.3 | `sharing_hub_screen.dart` | Sama seperti 4.2 (simulasi lain **jangan** disentuh dulu — itu tugas Plan 2) | Sharing Hub: alur simulasi tetap jalan |
| 4.4 | `module_detail_screen.dart` | Tambah parameter wajib `final String moduleId`; `_loadData` memakai `loadDetail(widget.moduleId)`. `offlineBanner` tetap dibaca seperti sebelumnya. Tambah tampilan error kalau modul tidak ditemukan. | — (belum bisa dibuka sampai 4.5 & 4.6 selesai; gabungkan 4.4–4.6 dalam **satu commit** agar build tidak rusak) |
| 4.5 | `module_list_screen.dart` | `json['modules']` → `loadModules()`; navigasi: `ModuleDetailScreen(moduleId: module.id)` | Tab Modul: tap m1, m2, m3, m4 → **detail berbeda-beda** |
| 4.6 | `home_screen.dart` | Bagian `modules` → `loadModules()`; navigasi: `ModulMateriScreen(moduleId: _modules[index].id)`. `user`, `offlineBanner`, `recentSessions` **tetap** dibaca seperti sebelumnya | Beranda: tap modul → detail yang benar |
| 4.7 | `participant_selection_screen.dart` | Ubah `this.modul` menjadi **required**, hapus fallback `modulDetail` (baris 73–80). `students` tetap dibaca seperti sebelumnya | Detail m2 → Mulai Sesi → Peserta → Sesi Belajar: semua konten m2 |

**Yang sengaja TIDAK diubah:**
- `session_history_screen.dart` dan `student_screen.dart` — tidak membaca data modul. Memindahkan mereka ke repository tidak menambah manfaat apa pun untuk sharing.
- `user`, `offlineBanner`, `recentSessions`, `students` — tetap dibaca langsung. Masuk planning terpisah kalau nanti persistensi murid/sesi dikerjakan.

**DoD:** Semua item checklist Bagian 6 lulus. `grep -r "modulDetail'" lib/` hanya menyisakan fallback di `module_repository.dart`.

---

### Phase 5 — Contract: Hapus Struktur Lama (0.25 hari)

**Tujuan:** Tidak ada lagi jejak `modulDetail` (singular).

**Langkah:**
1. Hapus key `modulDetail` dari `assets/data/mock_data.json`.
2. Hapus fallback `modulDetail` di `ModuleRepository.loadDetail`.
3. Hapus tes Phase 0 yang mem-parse `modulDetail`.
4. Cek: pencarian `modulDetail'` dan `"modulDetail"` di seluruh repo → **0 hasil** (kecuali dokumen `update/`).

**DoD:** `flutter analyze` 0 issue, `flutter test` lulus, checklist Bagian 6 lulus sekali lagi.

---

### Phase 6 — Penyimpanan Modul di HP (0.5–1 hari)

**Tujuan:** `ModuleRepository` bisa **menulis** modul ke HP dan membacanya kembali. Fitur ini baru dipakai oleh Plan 2 (sharing), tetapi struktur penyimpanannya ditetapkan di sini.

**Dependency:** `path_provider` (untuk lokasi folder dokumen app; tidak ada di stdlib Dart).

**API tambahan:**
```dart
Future<void> saveModule(
  ModuleModel module,
  ModuleDetailModel detail,
  Map<String, Uint8List> images,   // nama file → isi
);
Future<Uint8List> readImageBytes(String path);   // asset atau file; dipakai Plan 2 saat merakit payload
```

**Detail:**
1. **Gabungan baca:** `loadModules()` = asset + `index.json`; modul di HP menimpa modul asset jika `id` sama. `loadDetail(id)` cek `modules/<id>/detail.json` dulu, baru asset.
2. **Tulis atomik (mencegah kehilangan data):** setiap file ditulis ke `nama.tmp` lalu `rename()` ke nama asli. Kalau app mati di tengah proses, file lama tetap utuh.
3. **Urutan tulis:** gambar → `detail.json` → `index.json` **paling akhir**. Jadi modul baru "terlihat" hanya setelah semua file lengkap.
4. **Path gambar:** sebelum `detail.json` ditulis, setiap `imageAsset` diganti menjadi path lokal `modules/<id>/images/<nama>`.
5. **Validasi** (data akan datang dari HP lain lewat Plan 2):
   - `id` modul dan nama file gambar hanya boleh huruf, angka, `-`, `_`, `.` — tolak `/`, `\`, `..` (mencegah **path traversal**).
   - `schemaVersion` di `index.json` lebih besar dari yang dikenal → jangan ditimpa, tampilkan pesan "Perbarui aplikasi".
   - `index.json` rusak (gagal di-parse) → log error, app tetap jalan dengan modul asset saja. **Jangan** menimpa file rusak itu secara otomatis.
6. Tes di `test/module_repository_test.dart` (pakai folder temp via `Directory.systemTemp.createTemp()`; repository menerima folder root lewat parameter opsional supaya bisa dites tanpa `path_provider`):
   - `saveModule` lalu `loadModules` → modul baru muncul
   - `saveModule` lalu `loadDetail` → data sama, `imageAsset` menunjuk file yang ada
   - Simpan modul dengan id yang sama dua kali → tidak duplikat
   - id `../evil` atau gambar `../x.png` → ditolak
   - `index.json` rusak → `loadModules()` tetap mengembalikan 4 modul asset

**DoD:** Tes lulus. App identik dengan hasil Phase 5 (belum ada yang memanggil `saveModule` dari UI).

---

## 6. Checklist Regresi Manual

Jalankan setelah **setiap commit di Phase 4**, dan sekali lagi setelah Phase 5 dan Phase 6. Bandingkan dengan screenshot baseline.

| # | Layar / Alur | Yang dicek |
|---|---|---|
| 1 | Login | Passkey `123456` masuk ke Beranda |
| 2 | Beranda | Nama user, banner, sesi terbaru, 4 modul tampil |
| 3 | Beranda → tap modul m2 | Detail menampilkan **m2** |
| 4 | Tab Modul | 4 modul, pencarian berfungsi |
| 5 | Tab Modul → tap m1, m2, m3, m4 | Setiap detail berbeda sesuai modul |
| 6 | Detail Modul → tab Materi | Teks + **gambar** tampil |
| 7 | Detail Modul → tab Diskusi & Quiz | Konten sesuai modul |
| 8 | Detail → Mulai Sesi → Peserta | Info modul benar, bisa tambah murid |
| 9 | Sesi Belajar: Materi → Diskusi → Timer → Quiz → Ringkasan | Semua langkah jalan, gambar materi tampil |
| 10 | Tab Sesi Belajar → Riwayat → Detail | Tidak berubah dari baseline |
| 11 | Tab Murid → Detail → Tambah | Tidak berubah dari baseline |
| 12 | Sharing Hub (Terima) | Simulasi tetap jalan |
| 13 | Kirim Modul → pilih → kirim | Simulasi tetap jalan, daftar modul benar |
| 14 | Mode pesawat | Banner offline tetap muncul, semua layar tetap bisa dibuka |

---

## 7. Rollback

| Situasi | Tindakan |
|---|---|
| Satu layar rusak setelah commit di Phase 4 | `git revert <commit>` — layar lain tidak terpengaruh karena setiap langkah terpisah |
| Struktur `modulDetails` ternyata salah | Selama belum Phase 5, `modulDetail` lama masih ada; revert commit layar yang bermasalah |
| Semua harus dibatalkan | `git checkout pre-data-migration` (tag dari Phase 0) |
| Bug di penyimpanan HP setelah rilis | Struktur file punya `schemaVersion`; rilis perbaikan yang membaca versi lama. Folder `modules/` bisa dihapus tanpa merusak modul asset |

---

## 8. Ringkasan Timeline

| Phase | Isi | Estimasi |
|---|---|---|
| 0 | Baseline, tag, tes parsing data sekarang | 0.5 hari |
| 1 | `toJson()` di 5 model + tes round-trip | 0.5 hari |
| 2 | Expand: tambah `modulDetails` + tes validasi data | 0.5 hari |
| 3 | `ModuleRepository` (baca) + tes | 0.5 hari |
| 4 | Migrate 7 file, satu per commit | 1 hari |
| 5 | Contract: hapus `modulDetail` | 0.25 hari |
| 6 | Penyimpanan modul di HP + tes | 0.5–1 hari |
| **Total** | | **3.75–4.25 hari** |

Phase 2 bisa dikerjakan paralel oleh UI/UX & PM (menyiapkan konten m2–m4) sementara developer mengerjakan Phase 1.

---

## 9. Hubungan dengan Plan Lain

```
planingUpdate3 (ini)                      planingUpdate2 (sharing Android)
────────────────────                      ───────────────────────────────
Phase 0–5  struktur data asset   ──┐
Phase 6    penyimpanan di HP     ──┼──▶   Phase 0  spike (boleh paralel dengan Update 3)
                                   │      Phase 1  tinggal dependency + manifest
                                   └──▶   Phase 2  NearbySharingService memakai
                                                   ModuleRepository.saveModule / readImageBytes
                                          Phase 3–5 alur Terima, Kirim, polish
```

- **Spike Plan 2 (Phase 0)** tidak bergantung pada Update 3, jadi bisa jalan paralel untuk menghemat waktu.
- **Plan 2 Phase 2 ke atas** harus menunggu Update 3 selesai.

---

## 10. Di Luar Scope

| Item | Tambahkan ketika |
|---|---|
| Pindahkan `students`, `sessionHistory`, `recentSessions` ke penyimpanan HP | Planning persistensi murid & sesi (pola `ModuleRepository` bisa dipakai ulang) |
| Database (SQLite / Hive / Isar) | Data mulai butuh query (filter, relasi, ribuan baris). Untuk puluhan modul, file JSON sudah cukup |
| Hapus / edit modul dari UI | Guru meminta fitur kelola modul |
| Migrasi otomatis `schemaVersion` 1 → 2 | Saat struktur penyimpanan benar-benar berubah lagi |
