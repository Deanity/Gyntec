import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/module/models/module_model.dart';
import '../../features/module/models/module_detail_model.dart';

/// Repository tunggal untuk mengelola pembacaan & penyimpanan modul.
/// Menggabungkan modul bawaan (assets) dan modul hasil terima P2P (dokumen lokal).
class ModuleRepository {
  static final ModuleRepository instance = ModuleRepository._();
  ModuleRepository._();

  Directory? _customBaseDir;

  /// Setter untuk unit testing agar bisa mengarahkan ke direktori temporary
  void setBaseDirForTest(Directory dir) {
    _customBaseDir = dir;
  }

  Future<Directory> _getModulesDirectory() async {
    if (_customBaseDir != null) {
      final dir = Directory('${_customBaseDir!.path}/modules');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    }
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/modules');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  File _getIndexFile(Directory modulesDir) => File('${modulesDir.path}/index.json');

  /// Memuat daftar semua modul: menggabungkan modul bawaan dari assets dan modul tersimpan di local storage.
  /// Modul local dengan ID yang sama akan menimpa modul bawaan.
  Future<List<ModuleModel>> loadModules() async {
    final Map<String, ModuleModel> moduleMap = {};

    // 1. Baca modul dari assets/data/mock_data.json
    try {
      final raw = await rootBundle.loadString('assets/data/mock_data.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final assetModules = (json['modules'] as List? ?? [])
          .map((e) => ModuleModel.fromJson(e as Map<String, dynamic>));
      for (final m in assetModules) {
        moduleMap[m.id] = m;
      }
    } catch (e) {
      // Abaikan jika running di test tanpa rootBundle yang valid
    }

    // 2. Baca modul dari index.json local storage
    try {
      final dir = await _getModulesDirectory();
      final indexFile = _getIndexFile(dir);
      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final localList = (json['modules'] as List? ?? [])
            .map((e) => ModuleModel.fromJson(e as Map<String, dynamic>));
        for (final m in localList) {
          moduleMap[m.id] = m; // Timpa atau tambahkan
        }
      }
    } catch (e) {
      // Log/ignore korup
    }

    return moduleMap.values.toList();
  }

  /// Memuat detail modul berdasarkan ID.
  /// Memeriksa direktori lokal terlebih dahulu, jika tidak ada fallback ke assets.
  Future<ModuleDetailModel> loadDetail(String id) async {
    // 1. Cek folder lokal: modules/<id>/detail.json
    try {
      final dir = await _getModulesDirectory();
      final detailFile = File('${dir.path}/$id/detail.json');
      if (await detailFile.exists()) {
        final content = await detailFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        return ModuleDetailModel.fromJson(json);
      }
    } catch (_) {}

    // 2. Cek assets modulDetails[id]
    final raw = await rootBundle.loadString('assets/data/mock_data.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    if (json.containsKey('modulDetails')) {
      final detailsMap = json['modulDetails'] as Map<String, dynamic>;
      if (detailsMap.containsKey(id)) {
        return ModuleDetailModel.fromJson(detailsMap[id] as Map<String, dynamic>);
      }
    }

    // Fallback lama jika ada modulDetail tunggal
    if (json.containsKey('modulDetail')) {
      final single = json['modulDetail'] as Map<String, dynamic>;
      if (single['id'] == id) {
        return ModuleDetailModel.fromJson(single);
      }
    }

    throw StateError('Modul dengan ID "$id" tidak ditemukan.');
  }

  /// Membaca bytes gambar baik dari assets/ maupun file lokal di disk.
  Future<Uint8List> readImageBytes(String imagePath) async {
    if (imagePath.startsWith('assets/')) {
      final data = await rootBundle.load(imagePath);
      return data.buffer.asUint8List();
    } else {
      final file = File(imagePath);
      return await file.readAsBytes();
    }
  }

  /// Menyusun file payload JSON (berisi daftar modul, detail modul, dan gambar base64).
  /// Menggunakan file temporary untuk transfer P2P.
  Future<File> buildPayloadFile(List<ModuleModel> modules) async {
    final List<Map<String, dynamic>> payloadModules = [];

    for (final module in modules) {
      ModuleDetailModel detail;
      try {
        detail = await loadDetail(module.id);
      } catch (_) {
        // Jika detail tidak ditemukan, lewati atau buat fallback
        continue;
      }

      final Map<String, String> imagesBase64 = {};
      for (final block in detail.materi) {
        final path = block.imageAsset;
        if (path != null && path.isNotEmpty) {
          try {
            final fileName = path.split(RegExp(r'[/\\]')).last;
            final bytes = await readImageBytes(path);
            imagesBase64[fileName] = base64Encode(bytes);
          } catch (_) {}
        }
      }

      payloadModules.add({
        'module': module.toJson(),
        'detail': detail.toJson(),
        'images': imagesBase64,
      });
    }

    final payloadMap = {
      'v': 1,
      'modules': payloadModules,
    };

    final tempDir = _customBaseDir ?? await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/payload_${DateTime.now().millisecondsSinceEpoch}.tmp');
    await tempFile.writeAsString(jsonEncode(payloadMap));
    return tempFile;
  }

  /// Menyimpan modul hasil transfer P2P dari file payload yang diterima.
  /// Menulis file dengan pola atomik (.tmp -> rename) untuk mencegah korupsi data.
  Future<List<String>> saveReceived(File payloadFile) async {
    final raw = await payloadFile.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final version = json['v'] as int? ?? 1;
    if (version != 1) {
      throw UnsupportedError('Versi payload ($version) tidak didukung.');
    }

    final modulesList = json['modules'] as List? ?? [];
    final dir = await _getModulesDirectory();
    final List<String> savedIds = [];

    // Baca daftar modul yang sudah tersimpan sebelumnya
    final Map<String, ModuleModel> localModules = {};
    final indexFile = _getIndexFile(dir);
    if (await indexFile.exists()) {
      try {
        final indexContent = await indexFile.readAsString();
        final indexJson = jsonDecode(indexContent) as Map<String, dynamic>;
        final existing = (indexJson['modules'] as List? ?? [])
            .map((e) => ModuleModel.fromJson(e as Map<String, dynamic>));
        for (final m in existing) {
          localModules[m.id] = m;
        }
      } catch (_) {}
    }

    for (final item in modulesList) {
      final moduleMap = item['module'] as Map<String, dynamic>;
      final detailMap = Map<String, dynamic>.from(item['detail'] as Map<String, dynamic>);
      final imagesMap = (item['images'] as Map<String, dynamic>? ?? {});

      final module = ModuleModel.fromJson(moduleMap);
      final moduleId = _sanitizeFileName(module.id);

      final moduleFolder = Directory('${dir.path}/$moduleId');
      final imagesFolder = Directory('${moduleFolder.path}/images');
      if (!imagesFolder.existsSync()) {
        imagesFolder.createSync(recursive: true);
      }

      // 1. Tulis gambar
      final Map<String, String> localImagePaths = {};
      for (final entry in imagesMap.entries) {
        final safeName = _sanitizeFileName(entry.key);
        final bytes = base64Decode(entry.value as String);
        final imgFile = File('${imagesFolder.path}/$safeName');
        await imgFile.writeAsBytes(bytes);
        localImagePaths[entry.key] = imgFile.path;
      }

      // 2. Ganti imageAsset di materi dengan path file lokal
      final materiList = (detailMap['materi'] as List? ?? []);
      for (final m in materiList) {
        final mBlock = m as Map<String, dynamic>;
        final origPath = mBlock['imageAsset'] as String?;
        if (origPath != null) {
          final fileName = origPath.split(RegExp(r'[/\\]')).last;
          if (localImagePaths.containsKey(fileName)) {
            mBlock['imageAsset'] = localImagePaths[fileName];
          }
        }
      }

      // 3. Tulis detail.json secara atomic
      final detailFile = File('${moduleFolder.path}/detail.json');
      final tempDetailFile = File('${moduleFolder.path}/detail.json.tmp');
      await tempDetailFile.writeAsString(jsonEncode(detailMap));
      if (await detailFile.exists()) await detailFile.delete();
      await tempDetailFile.rename(detailFile.path);

      localModules[module.id] = module;
      savedIds.add(module.id);
    }

    // 4. Update index.json secara atomic
    final indexJson = {
      'schemaVersion': 1,
      'modules': localModules.values.map((m) => m.toJson()).toList(),
    };
    final tempIndexFile = File('${dir.path}/index.json.tmp');
    await tempIndexFile.writeAsString(jsonEncode(indexJson));
    if (await indexFile.exists()) await indexFile.delete();
    await tempIndexFile.rename(indexFile.path);

    return savedIds;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
  }
}
