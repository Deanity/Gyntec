import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyntec/features/module/models/module_model.dart';
import 'package:gyntec/features/module/models/module_detail_model.dart';
import 'package:gyntec/features/session/models/session_model.dart';
import 'package:gyntec/features/session/models/student_model.dart';

void main() {
  group('Mock Data & Model Validation Tests (Plan 3)', () {
    late Map<String, dynamic> rawJson;

    setUpAll(() {
      final file = File('assets/data/mock_data.json');
      expect(file.existsSync(), isTrue, reason: 'assets/data/mock_data.json must exist');
      final content = file.readAsStringSync();
      rawJson = jsonDecode(content) as Map<String, dynamic>;
    });

    test('Old singular modulDetail key is removed (Phase 5 Contract)', () {
      expect(rawJson.containsKey('modulDetail'), isFalse,
          reason: 'Legacy modulDetail key must be removed in favor of modulDetails');
    });

    test('All modules parse to ModuleModel', () {
      final modulesRaw = rawJson['modules'] as List<dynamic>;
      expect(modulesRaw, isNotEmpty);

      final modules = modulesRaw
          .map((e) => ModuleModel.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(modules.length, equals(modulesRaw.length));
      for (final m in modules) {
        expect(m.id, isNotEmpty);
        expect(m.title, isNotEmpty);
        expect(m.level, isNotEmpty);
      }
    });

    test('All entries in modulDetails match modules list and are valid', () {
      final modulesRaw = rawJson['modules'] as List<dynamic>;
      final moduleIds = modulesRaw.map((e) => (e as Map<String, dynamic>)['id'] as String).toList();

      final detailsMap = rawJson['modulDetails'] as Map<String, dynamic>;
      expect(detailsMap, isNotNull);

      // Every module in modules list has a detail entry
      for (final id in moduleIds) {
        expect(detailsMap.containsKey(id), isTrue,
            reason: 'Module "$id" must have an entry in modulDetails');
        final detailRaw = detailsMap[id] as Map<String, dynamic>;
        final detail = ModuleDetailModel.fromJson(detailRaw);

        // modulDetails[x].id == x
        expect(detail.id, equals(id));
        expect(detail.title, isNotEmpty);
        expect(detail.materi, isNotEmpty);

        // Verify images exist on disk
        for (final block in detail.materi) {
          if (block.imageAsset != null) {
            final imgFile = File(block.imageAsset!);
            expect(imgFile.existsSync(), isTrue,
                reason: 'Image file "${block.imageAsset}" in module "$id" must exist in assets');
          }
        }

        // Verify quiz correctIndex is within options range
        for (final q in detail.quiz) {
          expect(q.correctIndex, greaterThanOrEqualTo(0));
          expect(q.correctIndex, lessThan(q.options.length),
              reason: 'Quiz question "${q.id}" correctIndex out of range');
        }
      }
    });

    test('Other mock sections (students, recentSessions, sessionHistory) parse cleanly', () {
      final studentsRaw = rawJson['students'] as List<dynamic>? ?? [];
      final students = studentsRaw
          .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(students, isNotEmpty);

      final recentSessionsRaw = rawJson['recentSessions'] as List<dynamic>? ?? [];
      final recentSessions = recentSessionsRaw
          .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(recentSessions, isNotEmpty);

      final sessionHistoryRaw = rawJson['sessionHistory'] as List<dynamic>? ?? [];
      final sessionHistory = sessionHistoryRaw
          .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(sessionHistory, isNotEmpty);
    });

    test('Round-trip serialization: fromJson(toJson()) equals original', () {
      final modulesRaw = rawJson['modules'] as List<dynamic>;
      for (final mRaw in modulesRaw) {
        final original = ModuleModel.fromJson(mRaw as Map<String, dynamic>);
        final serialized = original.toJson();
        final reconstructed = ModuleModel.fromJson(serialized);

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.title, equals(original.title));
        expect(reconstructed.level, equals(original.level));
        expect(reconstructed.subject, equals(original.subject));
        expect(reconstructed.totalQuestions, equals(original.totalQuestions));
        expect(reconstructed.discussionCount, equals(original.discussionCount));
      }

      final detailsMap = rawJson['modulDetails'] as Map<String, dynamic>;
      for (final dRaw in detailsMap.values) {
        final original = ModuleDetailModel.fromJson(dRaw as Map<String, dynamic>);
        final serialized = original.toJson();
        final reconstructed = ModuleDetailModel.fromJson(serialized);

        expect(reconstructed.id, equals(original.id));
        expect(reconstructed.title, equals(original.title));
        expect(reconstructed.materi.length, equals(original.materi.length));
        expect(reconstructed.quiz.length, equals(original.quiz.length));
      }
    });
  });
}
