import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;


// ---------------------------------------------------------------------------
// PAGE: TranslatePage (The main screen container)
// ---------------------------------------------------------------------------

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
              "Communicate anywhere (Azure API)",
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
// COMPONENT: Translation Tool (Stateful widget with API logic)
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

  String _translatedText = "Translation will appear here (Powered by Azure REST)";
  String _selectedLanguage = "Spanish";

  final List<String> _languages = const ["Spanish", "French", "Japanese", "German", "Korean", "Mandarin"];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
  
  // 2. Helper function to map display name to Azure's ISO 639-1 language code
  String _getLanguageCode(String languageName) {
    final codeMap = {
      "Spanish": "es", 
      "French": "fr", 
      "Japanese": "ja", 
      "German": "de", 
      "Korean": "ko",
      "Mandarin": "zh-Hans", // Simplified Chinese
    };
    return codeMap[languageName] ?? "en"; // Default to English
  }


  // 3. Core function to make the Azure API call via REST
  void _handleTranslate() async {
    final input = _inputController.text.trim();
    final targetCode = _getLanguageCode(_selectedLanguage);

    if (input.isEmpty) {
      setState(() {
        _translatedText = "Please enter text to translate.";
      });
      return;
    }
    
    setState(() {
      _translatedText = "Translating..."; // Show loading state
    });

    try {
      // 4. Load credentials securely from the .env file
      final subscriptionKey = dotenv.env['AZURE_KEY'];
      final subscriptionRegion = dotenv.env['AZURE_REGION'];
      final endpoint = dotenv.env['AZURE_ENDPOINT'] ?? 'https://api.cognitive.microsofttranslator.com';

      if (subscriptionKey == null || subscriptionRegion == null) {
        setState(() {
          _translatedText = "Missing AZURE_KEY or AZURE_REGION in .env. Please set them and restart the app.";
        });
        return;
      }

      final uri = Uri.parse('$endpoint/translate').replace(queryParameters: {
        'api-version': '3.0',
        'to': targetCode,
        // Add 'from': 'en' to force a source language if needed
      });

      final headers = {
        'Ocp-Apim-Subscription-Key': subscriptionKey,
        'Ocp-Apim-Subscription-Region': subscriptionRegion,
        'Content-Type': 'application/json',
      };

      final response = await http
          .post(uri, headers: headers, body: jsonEncode([
            {'Text': input}
          ]))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        String translatedText = "No translation returned.";

        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is Map && first['translations'] is List && (first['translations'] as List).isNotEmpty) {
            final firstTranslation = first['translations'][0];
            if (firstTranslation is Map && firstTranslation['text'] is String) {
              translatedText = firstTranslation['text'] as String;
            }
          }
        }

        setState(() {
          _translatedText = translatedText;
        });
      } else {
        setState(() {
          _translatedText = "Translation failed (status ${response.statusCode}): ${response.body}";
        });
      }
    } catch (e) {
      print('Azure Translation Error: $e');
      setState(() {
        _translatedText = "Error translating: ${e.runtimeType}: $e\nCheck your .env setup, API key/region, and endpoint.";
      });
    }
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
            _QuickPhraseButton(label: "Hello", onTap: () => _setPhraseAndTranslate("Hello")),
            _QuickPhraseButton(label: "Thank you", onTap: () => _setPhraseAndTranslate("Thank you")),
            _QuickPhraseButton(label: "Where is...?", onTap: () => _setPhraseAndTranslate("Where is...?")),
            _QuickPhraseButton(label: "How much?", onTap: () => _setPhraseAndTranslate("How much?")),
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

  // Modified function to set phrase AND trigger translation
  void _setPhraseAndTranslate(String phrase) {
    setState(() {
      _inputController.text = phrase;
    });
    // Automatically trigger translation when a quick phrase is tapped
    _handleTranslate(); 
  }

  // Original function kept for dropdown compatibility
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