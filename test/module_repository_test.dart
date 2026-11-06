import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyntec/core/services/module_repository.dart';
import 'package:gyntec/features/module/models/module_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Module Models & Repository Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('gyntec_test_');
      ModuleRepository.instance.setBaseDirForTest(tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('ModuleModel and ModuleDetailModel toJson and fromJson round-trip', () {
      const module = ModuleModel(
        id: 'test_1',
        level: 'SMA',
        title: 'Fisika Kuantum',
        description: 'Materi pengantar kuantum',
        subject: 'Fisika',
        totalQuestions: 15,
        discussionCount: 2,
      );

      final json = module.toJson();
      final parsed = ModuleModel.fromJson(json);

      expect(parsed.id, equals(module.id));
      expect(parsed.title, equals(module.title));
      expect(parsed.subject, equals('Fisika'));
      expect(parsed.totalQuestions, equals(15));
    });

    test('ModuleRepository saveReceived saves modules and images atomically', () async {
      // Buat file dummy payload JSON
      final dummyPayload = {
        'v': 1,
        'modules': [
          {
            'module': {
              'id': 'p2p_m1',
              'level': 'SMK',
              'title': 'Jaringan Komputer',
              'description': 'Materi IP Address & Subnetting',
              'subject': 'TKJ',
              'totalQuestions': 10,
              'discussionCount': 1,
            },
            'detail': {
              'id': 'p2p_m1',
              'title': 'Jaringan Komputer',
              'level': 'SMK',
              'subject': 'TKJ',
              'totalQuestions': 10,
              'discussionCount': 1,
              'materi': [
                {
                  'id': 'mat_1',
                  'heading': 'Subnetting IPv4',
                  'body': 'Penjelasan CIDR /24 dan network broadcast.',
                  'imageAsset': 'assets/MateriImage/Materi1.png',
                }
              ],
              'groupQuestion': {
                'title': 'Hitung range IP host /26',
                'instructions': ['Hitung bersama kelompok'],
                'indicators': ['Ketepatan kalkulasi'],
              },
              'quiz': [
                {
                  'id': 'qz_1',
                  'number': 1,
                  'totalQuestions': 10,
                  'question': 'Berapa subnet mask /24?',
                  'options': ['255.255.255.0', '255.255.0.0'],
                  'correctIndex': 0,
                }
              ]
            },
            'images': {
              'Materi1.png': base64Encode(Uint8List.fromList([1, 2, 3, 4, 5])),
            }
          }
        ]
      };

      final payloadFile = File('${tempDir.path}/test_payload.json');
      await payloadFile.writeAsString(jsonEncode(dummyPayload));

      final savedIds = await ModuleRepository.instance.saveReceived(payloadFile);
      expect(savedIds, contains('p2p_m1'));

      final detail = await ModuleRepository.instance.loadDetail('p2p_m1');
      expect(detail.id, equals('p2p_m1'));
      expect(detail.title, equals('Jaringan Komputer'));
      expect(detail.materi.first.imageAsset, contains('Materi1.png'));
      expect(File(detail.materi.first.imageAsset!).existsSync(), isTrue);
    });
  });
}
