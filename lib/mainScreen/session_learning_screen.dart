import 'package:flutter/material.dart';
import '../components/materi/group_question_card.dart';
import '../components/materi/materi_content_block.dart';
import '../components/materi/materi_image_block.dart';
import '../components/session/discussion_group_card.dart';
import '../components/session/quiz_group_select_card.dart';
import '../components/session/quiz_interactive_card.dart';
import '../components/session/session_bottom_nav.dart';
import '../components/session/session_stepper_header.dart';
import '../components/session/quiz_finish_modal.dart';
import '../utils/models.dart';
import 'discussion_timer_screen.dart';
import 'post_quiz_screen.dart';

/// Screen utama untuk alur Sesi Pembelajaran:
/// Step 1: Materi Umum
/// Step 2: Diskusi Kelompok
/// Step 3: Quiz Kelompok
class SessionLearningScreen extends StatefulWidget {
  final ModulDetailModel modul;
  final List<StudentModel> participants;

  const SessionLearningScreen({
    super.key,
    required this.modul,
    required this.participants,
  });

  @override
  State<SessionLearningScreen> createState() => _SessionLearningScreenState();
}

class _SessionLearningScreenState extends State<SessionLearningScreen> {
  int _currentStep = 1; // 1: Materi, 2: Diskusi, 3: Quiz

  // State untuk Quiz
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _correctGroupIndices = {}; // kelompok yang benar per pertanyaan

  // Kelompok diskusi
  late List<DiscussionGroupModel> _groups;

  @override
  void initState() {
    super.initState();
    _initGroups();
  }

  void _initGroups() {
    // Default nama kelompok sesuai UI mockup
    const groupNames = [
      'Kelompok Rajawali',
      'Kelompok Garuda',
      'Kelompok Merpati',
    ];

    // Jika peserta dari ParticipantScreen tersedia cukup, bagi otomatis
    if (widget.participants.length >= 3) {
      final List<List<StudentModel>> divided = [[], [], []];
      for (int i = 0; i < widget.participants.length; i++) {
        divided[i % 3].add(widget.participants[i]);
      }

      _groups = List.generate(3, (index) {
        return DiscussionGroupModel(
          number: index + 1,
          name: groupNames[index],
          members: divided[index],
        );
      });
    } else {
      // Fallback data demo persis seperti mockup gambar
      _groups = [
        const DiscussionGroupModel(
          number: 1,
          name: 'Kelompok Rajawali',
          members: [
            StudentModel(id: 'r1', name: 'Reza Oktovian'),
            StudentModel(id: 'r2', name: 'Reza Ismail'),
            StudentModel(id: 'r3', name: 'Reza Supri'),
            StudentModel(id: 'r4', name: 'Reza Kecap'),
          ],
        ),
        const DiscussionGroupModel(
          number: 2,
          name: 'Kelompok Garuda',
          members: [
            StudentModel(id: 'g1', name: 'Dian Prasetya'),
            StudentModel(id: 'g2', name: 'Fajar Nugroho'),
            StudentModel(id: 'g3', name: 'Siti Amalia'),
            StudentModel(id: 'g4', name: 'Andi Saputra'),
          ],
        ),
        const DiscussionGroupModel(
          number: 3,
          name: 'Kelompok Merpati',
          members: [
            StudentModel(id: 'm1', name: 'Lina Marlina'),
            StudentModel(id: 'm2', name: 'Rizky Hidayat'),
            StudentModel(id: 'm3', name: 'Putri Wulandari'),
            StudentModel(id: 'm4', name: 'Budi Santoso'),
          ],
        ),
      ];
    }
  }

  String get _headerTitle {
    return switch (_currentStep) {
      1 => 'Bagian 1: Materi Umum',
      2 => 'Bagian 2 : Diskusi Kelompok',
      3 => 'Bagian 3: Quiz Kelompok',
      _ => 'Sesi Pembelajaran',
    };
  }

  String get _actionButtonLabel {
    return switch (_currentStep) {
      1 => 'Sesi Selanjutnya',
      2 => 'Mulai diskusi kelompok',
      3 => 'Selesaikan quiz',
      _ => 'Lanjut',
    };
  }

  void _onBottomActionPressed() {
    if (_currentStep == 1) {
      // Lanjut ke Step 2: Diskusi Kelompok
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      // Buka fullscreen timer diskusi
      _startDiscussionTimer();
    } else if (_currentStep == 3) {
      // Selesaikan quiz dan sesi
      _finishQuizSession();
    }
  }

  Future<void> _startDiscussionTimer() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const DiscussionTimerScreen(
          initialMinutes: 20,
        ),
      ),
    );

    // Jika timer selesai atau ditutup, otomatis pindah ke step 3 (Quiz)
    if (result == true || mounted) {
      setState(() {
        _currentStep = 3;
      });
    }
  }

  Future<void> _finishQuizSession() async {
    final unansweredCount =
        widget.modul.totalQuestions - _selectedAnswers.length;

    final shouldFinish = await QuizFinishModal.show(
      context,
      unansweredCount: unansweredCount > 0 ? unansweredCount : 0,
    );

    if (shouldFinish == true && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PostQuizScreen(
            modul: widget.modul,
            groups: _groups,
            participants: widget.participants,
          ),
        ),
      );
    }
  }

  void _handleBackNavigation() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── 1. Top Header dengan Stepper ──
          SessionStepperHeader(
            currentStep: _currentStep,
            title: _headerTitle,
            onBack: _handleBackNavigation,
          ),

          // ── 2. Konten Dinamis Sesuai Step ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildStepContent(),
            ),
          ),

          // ── 3. Bottom Navigation (Pill Tabs + Tombol Aksi) ──
          SessionBottomNav(
            currentStep: _currentStep,
            onStepChanged: (step) => setState(() => _currentStep = step),
            onActionPressed: _onBottomActionPressed,
            actionLabel: _actionButtonLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_currentStep) {
      1 => _buildMateriStep(),
      2 => _buildDiskusiStep(),
      3 => _buildQuizStep(),
      _ => const SizedBox.shrink(),
    };
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 1: MATERI UMUM
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMateriStep() {
    final List<Widget> blocks = [];

    for (final item in widget.modul.materi) {
      if (item.imageAsset != null) {
        blocks.add(MateriImageBlock(assetPath: item.imageAsset!));
        blocks.add(const SizedBox(height: 16));
      }
      blocks.add(MateriContentBlock(heading: item.heading, body: item.body));
      blocks.add(const SizedBox(height: 24));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 2: DISKUSI KELOMPOK
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDiskusiStep() {
    final gq = widget.modul.groupQuestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Pertanyaan Kelompok
        GroupQuestionCard(
          title: gq.title,
          instructions: gq.instructions,
          indicators: gq.indicators,
        ),
        const SizedBox(height: 24),

        // Section Title: Pembagian Kelompok Otomatis
        const Text(
          'Pembagian Kelompok Otomatis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),

        // Daftar Kelompok
        ..._groups.map(
          (group) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DiscussionGroupCard(
              groupNumber: group.number,
              groupName: group.name,
              members: group.members,
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // STEP 3: QUIZ KELOMPOK
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildQuizStep() {
    final quizList = widget.modul.quiz;
    final currentQ = quizList.isNotEmpty
        ? quizList[_currentQuestionIndex % quizList.length]
        : const QuizQuestionModel(
            id: 'mock_q',
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
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Soal Interaktif
        QuizInteractiveCard(
          question: currentQ,
          currentIndex: _currentQuestionIndex,
          totalQuestions: widget.modul.totalQuestions,
          selectedOptionIndex: _selectedAnswers[_currentQuestionIndex],
          onSelectOption: (idx) {
            setState(() {
              _selectedAnswers[_currentQuestionIndex] = idx;
            });
          },
          onPrevious: _currentQuestionIndex > 0
              ? () {
                  setState(() => _currentQuestionIndex--);
                }
              : null,
          onNext: _currentQuestionIndex < quizList.length - 1
              ? () {
                  setState(() => _currentQuestionIndex++);
                }
              : null,
        ),
        const SizedBox(height: 24),

        // Heading: Kelompok yang Benar
        const Text(
          'Kelompok yang Benar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Silahkan pilih satu atau lebih kelompok yang menjawab dengan benar',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),

        // Daftar Kelompok yang Benar
        ..._groups.map(
          (group) {
            final isSelected = _correctGroupIndices.contains(group.number);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: QuizGroupSelectCard(
                groupNumber: group.number,
                groupName: group.name,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _correctGroupIndices.remove(group.number);
                    } else {
                      _correctGroupIndices.add(group.number);
                    }
                  });
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
