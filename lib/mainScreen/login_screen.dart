import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/components.dart';
import '../utils/keyboard_utils.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Passkey yang valid — ubah sesuai kebutuhan production
  static const String _validPasskey = '123456';

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _enteredPasskey =>
      _controllers.map((c) => c.text).join();

  bool get _isComplete => _enteredPasskey.length == 6;

  void _handleLogin() {
    if (!_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan 6 digit passkey Anda terlebih dahulu'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_enteredPasskey != _validPasskey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passkey tidak valid. Silakan coba lagi.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      // Kosongkan semua field & kembali ke digit pertama
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  void _handleForgotPasskey() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lupa Passkey tapped')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment(0.0, -0.5),
            colors: [
              Color(0xFFEAF2FE),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: DismissKeyboard(
            child: CustomScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Ilustrasi ──
                        const Center(
                          child: SvgPicture(
                            SvgAssetLoader('assets/oc-thinking.svg'),
                            height: 220,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Judul ──
                        const Text(
                          'Selamat datang kembali',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Masuk ke akun Anda untuk mulai mengajar',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Form Passkey ──
                        _PasskeyForm(
                          controllers: _controllers,
                          focusNodes: _focusNodes,
                          isLoading: _isLoading,
                          onLogin: _handleLogin,
                          onForgotPasskey: _handleForgotPasskey,
                          onChanged: () => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget form passkey terpisah agar rebuild lebih efisien
// ─────────────────────────────────────────────────────────────────────────────

class _PasskeyForm extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onForgotPasskey;
  final VoidCallback onChanged;

  const _PasskeyForm({
    required this.controllers,
    required this.focusNodes,
    required this.isLoading,
    required this.onLogin,
    required this.onForgotPasskey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text(
          'Kode Passkey',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 14),

        // 6 digit input circles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return _PasskeyDigitField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              nextFocus: index < 5 ? focusNodes[index + 1] : null,
              prevFocus: index > 0 ? focusNodes[index - 1] : null,
              onChanged: onChanged,
            );
          }),
        ),
        const SizedBox(height: 10),

        // Hint text
        const Text(
          'Masukkan 6 digit passkey Anda',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 12),

        // Lupa Passkey
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: onForgotPasskey,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'Lupa Passkey?',
                style: TextStyle(
                  color: Color(0xFF0066FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Tombol Masuk
        CustomButton(
          label: 'Masuk',
          isLoading: isLoading,
          onPressed: onLogin,
          backgroundColor: const Color(0xFF0066FF),
          borderRadius: 28,
          height: 52,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Satu digit circle field
// ─────────────────────────────────────────────────────────────────────────────

class _PasskeyDigitField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final FocusNode? prevFocus;
  final VoidCallback onChanged;

  const _PasskeyDigitField({
    required this.controller,
    required this.focusNode,
    required this.nextFocus,
    required this.prevFocus,
    required this.onChanged,
  });

  @override
  State<_PasskeyDigitField> createState() => _PasskeyDigitFieldState();
}

class _PasskeyDigitFieldState extends State<_PasskeyDigitField> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _hasFocus = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final bool isFilled = widget.controller.text.isNotEmpty;

    return SizedBox(
      width: 48,
      height: 48,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              widget.controller.text.isEmpty &&
              widget.prevFocus != null) {
            widget.prevFocus!.requestFocus();
          }
        },
        child: TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: _hasFocus
                ? const Color(0xFFEFF6FF)
                : isFilled
                    ? const Color(0xFFF1F5F9)
                    : Colors.white,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide(
                color: isFilled
                    ? const Color(0xFF0066FF)
                    : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: const BorderSide(
                color: Color(0xFF0066FF),
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty && widget.nextFocus != null) {
              widget.nextFocus!.requestFocus();
            }
            widget.onChanged();
          },
        ),
      ),
    );
  }
}
