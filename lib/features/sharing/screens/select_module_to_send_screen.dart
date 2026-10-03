import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/core.dart';
import '../widgets/sharing_widgets.dart';
import '../../../utils/models.dart';
import 'send_module_screen.dart';

/// Screen "Pilih Module" / Select Module To Send Screen
/// Muncul ketika user menekan tab "Kirim" di SharingHubScreen,
/// lalu berpindah ke screen ini.
///
/// User bisa memilih satu atau lebih modul yang akan dikirim.
/// Tombol "Kirim Module" aktif (biru) hanya jika minimal 1 modul dipilih.
class SelectModuleToSendScreen extends StatefulWidget {
  const SelectModuleToSendScreen({super.key});

  @override
  State<SelectModuleToSendScreen> createState() =>
      _SelectModuleToSendScreenState();
}

class _SelectModuleToSendScreenState extends State<SelectModuleToSendScreen> {
  List<ModuleModel> _modules = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    final raw = await rootBundle.loadString('assets/data/mock_data.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;

    final modules = (json['modules'] as List)
        .map((e) => ModuleModel.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _modules = modules;
      _isLoading = false;
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  bool get _hasSelection => _selectedIds.isNotEmpty;

  void _onKirimPressed() {
    if (!_hasSelection) return;

    final selectedModules = _modules
        .where((m) => _selectedIds.contains(m.id))
        .toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SendModuleScreen(selectedModules: selectedModules),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F4FF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          //  Soft background gradient di atas
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE8F1FF), Color(0x00E8F1FF)],
                ),
              ),
            ),
          ),

          //  Konten utama
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //  Top Bar
              _TopBar(onBack: () => Navigator.of(context).maybePop()),

              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: AppOfflineBanner(padding: EdgeInsets.zero),
              ),

              //  Header "Modul Tersedia"
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Text(
                  'Modul Tersedia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              //  Daftar modul
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 100, // ruang floating button
                  ),
                  itemCount: _modules.length,
                  separatorBuilder: (a, b) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final module = _modules[index];
                    return ModuleSelectCard(
                      module: module,
                      isSelected: _selectedIds.contains(module.id),
                      onTap: () => _toggleSelect(module.id),
                    );
                  },
                ),
              ),
            ],
          ),

          //  Floating "Kirim Module" button
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _KirimButton(
                  isEnabled: _hasSelection,
                  onPressed: _onKirimPressed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─
// Top Bar — "< Pilih Module"
// ─

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(
                LucideIcons.chevronLeft,
                size: 22,
                color: Color(0xFF0F172A),
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            const Text(
              'Pilih Module',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─
// Tombol "Kirim Module" — disabled (abu-abu) jika tidak ada yang dipilih,
// aktif (biru + glow) jika ada minimal 1 modul dipilih.
// ─

class _KirimButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const _KirimButton({required this.isEnabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: isEnabled ? const Color(0xFF0066FF) : const Color(0xFFD4D4D8),
        boxShadow: isEnabled
            ? const [
                BoxShadow(
                  color: Color(0x330066FF),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isEnabled ? Colors.white : const Color(0xFF9CA3AF),
              ),
              child: const Text('Kirim Module'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility aliases
typedef SelectModuleScreen = SelectModuleToSendScreen;
typedef PilihModulScreen = SelectModuleToSendScreen;
