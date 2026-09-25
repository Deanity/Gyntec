import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyntec/mainScreen/discussion_timer_screen.dart';
import 'package:gyntec/mainScreen/session_learning_screen.dart';
import 'package:gyntec/utils/models.dart';

void main() {
  final sampleModul = ModulDetailModel(
    id: 'm1',
    title: 'Anggota Tubuh Manusia',
    level: 'SMA',
    subject: 'IPA',
    totalQuestions: 30,
    materi: const [
      MateriBlockModel(
        id: 'b1',
        heading: 'Bagian 1 : Kenapa ada Organ Tubuh?',
        body: 'Materi pembuka tentang organ tubuh.',
      ),
    ],
    groupQuestion: const GroupQuestionModel(
      title: 'Apa yang membuat manusia memerlukan organ?',
      instructions: ['Petunjuk 1', 'Petunjuk 2'],
      indicators: ['Indikator 1', 'Indikator 2'],
    ),
    quiz: const [
      QuizQuestionModel(
        id: 'q1',
        number: 1,
        totalQuestions: 30,
        question:
            'Apa fungsi utama dari sistem muskuloskeletal (rangka dan otot) pada tubuh manusia?',
        options: [
          'Menopang struktur tubuh dan memfasilitasi pergerakan aktif',
          'Memompa darah dan mengedarkan oksigen ke seluruh sel tubuh',
          'Mengatur produksi hormon serta metabolisme tubuh',
          'Menyaring racun dan zat sisa hasil metabolisme dari darah',
        ],
        correctIndex: 0,
      ),
    ],
  );

  final sampleParticipants = [
    const StudentModel(id: 's1', name: 'Reza Oktovian'),
    const StudentModel(id: 's2', name: 'Dian Prasetya'),
    const StudentModel(id: 's3', name: 'Lina Marlina'),
  ];

  testWidgets('SessionLearningScreen loads step 1 and navigates to step 2',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionLearningScreen(
          modul: sampleModul,
          participants: sampleParticipants,
        ),
      ),
    );

    // Step 1: Materi Umum
    expect(find.text('Bagian 1: Materi Umum'), findsOneWidget);
    expect(find.text('Sesi Selanjutnya'), findsOneWidget);
    expect(find.text('Bagian 1 : Kenapa ada Organ Tubuh?'), findsOneWidget);

    // Tap "Sesi Selanjutnya" to go to step 2
    await tester.tap(find.text('Sesi Selanjutnya'));
    await tester.pumpAndSettle();

    // Step 2: Diskusi Kelompok
    expect(find.text('Bagian 2 : Diskusi Kelompok'), findsOneWidget);
    expect(find.text('Mulai diskusi kelompok'), findsOneWidget);
    expect(find.text('Pembagian Kelompok Otomatis'), findsOneWidget);
    expect(find.text('Kelompok Rajawali'), findsOneWidget);
  });

  testWidgets('DiscussionTimerScreen renders timer and Selesai button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DiscussionTimerScreen(initialMinutes: 20),
      ),
    );

    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
  });

  testWidgets('SessionLearningScreen can switch to Step 3 Quiz and interact',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SessionLearningScreen(
          modul: sampleModul,
          participants: sampleParticipants,
        ),
      ),
    );

    // Tap tab Quiz
    await tester.tap(find.text('Quiz'));
    await tester.pumpAndSettle();

    // Step 3: Quiz Kelompok
    expect(find.text('Bagian 3: Quiz Kelompok'), findsOneWidget);
    expect(
        find.text(
            'Apa fungsi utama dari sistem muskuloskeletal (rangka dan otot) pada tubuh manusia?'),
        findsOneWidget);
    expect(find.text('Kelompok yang Benar'), findsOneWidget);
    expect(find.text('Selesaikan quiz'), findsOneWidget);

    // Tap an option
    await tester.tap(
        find.text('Menopang struktur tubuh dan memfasilitasi pergerakan aktif'));
    await tester.pumpAndSettle();

    // Scroll and tap a group
    await tester.ensureVisible(find.text('Kelompok Rajawali'));
    await tester.tap(find.text('Kelompok Rajawali'));
    await tester.pumpAndSettle();

    // Tap "Selesaikan quiz" -> Muncul custom modal QuizFinishModal
    await tester.tap(find.text('Selesaikan quiz'));
    await tester.pumpAndSettle();

    expect(find.text('Selesaikan Quiz?'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);

    // Tap "Selesai" pada modal untuk menuju PostQuizScreen
    await tester.tap(find.widgetWithText(OutlinedButton, 'Selesai'));
    await tester.pumpAndSettle();

    // Verifikasi berada di PostQuizScreen
    expect(find.text('Post Quiz'), findsOneWidget);
    expect(find.text('Anggota Tubuh Manusia'), findsOneWidget);
    expect(find.text('Kembali ke Beranda'), findsOneWidget);
  });
}
