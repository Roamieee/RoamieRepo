import 'package:flutter/material.dart';

class TranslatePage extends StatelessWidget {
  final VoidCallback onNavigateHome;

  const TranslatePage({super.key, required this.onNavigateHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: onNavigateHome,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Translation",
              style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Communicate anywhere",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: TranslationTool(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// COMPONENT: Translation Tool (Styled UI + mock translation logic)
// ---------------------------------------------------------------------------

class TranslationTool extends StatefulWidget {
  const TranslationTool({super.key});

  @override
  State<TranslationTool> createState() => _TranslationToolState();
}

class _TranslationToolState extends State<TranslationTool> {
  static const _gradientStart = Color(0xFFE5A489);
  static const _gradientEnd = Color(0xFF7DD6E4);
  final TextEditingController _inputController = TextEditingController();

  String _translatedText = "Translation will appear here (Connect translation API)";
  String _selectedLanguage = "Spanish";

  final List<String> _languages = const ["Spanish", "French", "Japanese", "German", "Korean", "Mandarin"];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleTranslate() {
    final input = _inputController.text.trim();
    setState(() {
      if (input.isEmpty) {
        _translatedText = "Please enter text to translate.";
      } else {
        _translatedText = "Simulated $_selectedLanguage translation of: $input";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        const Text(
          "Real-Time Translation",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          "Translate text, voice, and images instantly",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    "Translator",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  _buildLanguageDropdown(),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                "Your Text",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.mic_outlined),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo_camera_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _inputController,
                        maxLines: 6,
                        minLines: 4,
                        decoration: const InputDecoration(
                          hintText: "Enter text to translate...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _handleTranslate,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_gradientStart, _gradientEnd]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Translate",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Text(
                    "Translation",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.volume_up_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  _translatedText,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "Quick Phrases",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _QuickPhraseButton(label: "Hello", onTap: () => _setPhrase("Hello")),
            _QuickPhraseButton(label: "Thank you", onTap: () => _setPhrase("Thank you")),
            _QuickPhraseButton(label: "Where is...?", onTap: () => _setPhrase("Where is...?")),
            _QuickPhraseButton(label: "How much?", onTap: () => _setPhrase("How much?")),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          icon: const Icon(Icons.expand_more),
          items: _languages.map((lang) => DropdownMenuItem(value: lang, child: Text(lang))).toList(),
          onChanged: (val) => setState(() => _selectedLanguage = val!),
        ),
      ),
    );
  }

  void _setPhrase(String phrase) {
    setState(() {
      _inputController.text = phrase;
    });
  }
}

class _QuickPhraseButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickPhraseButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}