import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

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
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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

  String _translatedText =
      "Translation will appear here (Powered by Azure REST)";
  String _selectedLanguage = "Spanish";

  final ImagePicker _picker = ImagePicker();
  final List<String> _languages = const [
    "Spanish",
    "French",
    "Japanese",
    "German",
    "Korean",
    "Mandarin",
  ];

  // Speech recognition state
  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  // Text-to-speech state
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void dispose() {
    _inputController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // Speak translated text using text-to-speech
  Future<void> _speakTranslation() async {
    if (_translatedText.isEmpty ||
        _translatedText ==
            "Translation will appear here (Powered by Azure REST)" ||
        _translatedText.contains("Error") ||
        _translatedText.contains("failed") ||
        _translatedText.contains("Translating...")) {
      return;
    }

    try {
      // Use the full locale (e.g., 'ja_JP') for better TTS compatibility
      final locale = _getLocaleForSpeech(_selectedLanguage);
      print('TTS: Setting language to $locale');

      await _flutterTts.setLanguage(locale);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0); // Force max volume

      print('TTS: Speaking "$_translatedText"');
      var result = await _flutterTts.speak(_translatedText);

      if (result == 1) {
        print("TTS: Speak command accepted");
      } else {
        print("TTS: Speak command failed");
      }
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  // Voice recording handler - initializes and requests permission on first use
  Future<void> _handleVoiceRecording() async {
    // Check for unsupported platforms (Windows/Linux)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      setState(() {
        _translatedText =
            "Voice recognition is not supported on Desktop (Windows/Linux). Please use Android/iOS or Web.";
      });
      return;
    }

    // Initialize speech recognition on first use (lazy initialization)
    if (_speech == null || !_speechAvailable) {
      _speech = stt.SpeechToText();

      setState(() {
        _translatedText = "Initializing speech recognition...";
      });

      _speechAvailable = await _speech!.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          setState(() {
            _translatedText =
                "Speech error: ${error.errorMsg}. Please grant microphone permission in settings.";
            _isListening = false;
          });
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'notListening' && _isListening) {
            setState(() {
              _isListening = false;
            });
          }
        },
        debugLogging: true, // Enable debug logging for troubleshooting
      );

      if (!_speechAvailable) {
        setState(() {
          _translatedText =
              "Speech recognition not available. Please grant microphone permission.";
        });
        return;
      }
    }

    if (_isListening) {
      // Stop listening
      await _speech!.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      // Check if speech recognition is available
      if (!_speech!.isAvailable) {
        setState(() {
          _translatedText = "Speech recognition not available on this device.";
        });
        return;
      }

      final localeId = _getLocaleForSpeech(_selectedLanguage);
      print('Starting listen with locale: $localeId');

      // Start listening
      setState(() {
        _isListening = true;
        _translatedText = "Listening ($localeId)... Speak now!";
      });

      await _speech!.listen(
        onResult: (result) {
          print('Speech result: ${result.recognizedWords}');
          setState(() {
            _inputController.text = result.recognizedWords;
            if (result.finalResult) {
              _isListening = false;
              _translatedText = "Processing speech...";
              // Automatically translate once speech is finalized
              _handleTranslate();
            }
          });
        },
        onSoundLevelChange: (level) {
          // Use this to check if the microphone is receiving input
          if (level > 0) {
            // print('Sound level: $level');
          }
        },
        // ADD THIS: Map your selected language to a locale code (e.g., 'en_US', 'es_ES')
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    }
  }

  // Function to show the image source options (Camera or Gallery)
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Use Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleOcr(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Upload from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handleOcr(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // OCR Function: Handles image capture/selection and text extraction
  Future<void> _handleOcr(ImageSource source) async {
    setState(() {
      _translatedText =
          "Accessing ${source == ImageSource.camera ? 'Camera' : 'Gallery'}...";
    });

    try {
      // 1. Capture the Image or pick from Gallery
      final XFile? image = await _picker.pickImage(source: source);

      if (image == null) {
        setState(() {
          _translatedText =
              "${source == ImageSource.camera ? 'Capture' : 'Selection'} cancelled.";
        });
        return;
      }

      setState(() {
        _translatedText = "Image selected. Performing OCR...";
      });

      // 2. Initialize and Process Image with ML Kit
      // NOTE: Using 'latin' for common Western languages.
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final InputImage inputImage = InputImage.fromFilePath(image.path);

      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      await textRecognizer.close();

      final String extractedText = recognizedText.text.trim();

      if (extractedText.isEmpty) {
        setState(() {
          _translatedText = "No readable text detected in the image.";
        });
        return;
      }

      // 3. Hand Off Text to Translator
      _inputController.text = extractedText;
      _handleTranslate(); // Proceed to Step 2: Translation
    } catch (e) {
      print("OCR/Image Picker Error: $e");
      setState(() {
        _translatedText =
            "Error during image processing. Check permissions and native setup: $e";
      });
    }
  }

  String _getLocaleForSpeech(String language) {
    switch (language) {
      case 'Spanish':
        return 'es_ES';
      case 'French':
        return 'fr_FR';
      case 'Japanese':
        return 'ja_JP';
      case 'German':
        return 'de_DE';
      case 'Korean':
        return 'ko_KR';
      case 'Mandarin':
        return 'zh_CN';
      default:
        return 'en_US';
    }
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
      final endpoint =
          dotenv.env['AZURE_ENDPOINT'] ??
          'https://api.cognitive.microsofttranslator.com';

      if (subscriptionKey == null || subscriptionRegion == null) {
        setState(() {
          _translatedText =
              "Missing AZURE_KEY or AZURE_REGION in .env. Please set them and restart the app.";
        });
        return;
      }

      final uri = Uri.parse(
        '$endpoint/translate',
      ).replace(queryParameters: {'api-version': '3.0', 'to': targetCode});

      final headers = {
        'Ocp-Apim-Subscription-Key': subscriptionKey,
        'Ocp-Apim-Subscription-Region': subscriptionRegion,
        'Content-Type': 'application/json',
      };

      final response = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode([
              {'Text': input},
            ]),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        String translatedText = "No translation returned.";

        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is Map &&
              first['translations'] is List &&
              (first['translations'] as List).isNotEmpty) {
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
          _translatedText =
              "Translation failed (status ${response.statusCode}): ${response.body}";
        });
      }
    } catch (e) {
      print('Azure Translation Error: $e');
      setState(() {
        _translatedText =
            "Error translating: ${e.runtimeType}: $e\nCheck your .env setup, API key/region, and endpoint.";
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
                  const Icon(
                    Icons.auto_awesome,
                    color: Colors.orange,
                    size: 20,
                  ),
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
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_outlined,
                            color: _isListening ? Colors.red : null,
                          ),
                          onPressed: _handleVoiceRecording,
                        ),
                        IconButton(
                          icon: const Icon(Icons.photo_camera_outlined),
                          onPressed:
                              _showImageSourcePicker, // Calls the picker sheet
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
                    gradient: const LinearGradient(
                      colors: [_gradientStart, _gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Translate",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 18,
                        ),
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
                    onPressed: _speakTranslation,
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
            _QuickPhraseButton(
              label: "Hello",
              onTap: () => _setPhraseAndTranslate("Hello"),
            ),
            _QuickPhraseButton(
              label: "Thank you",
              onTap: () => _setPhraseAndTranslate("Thank you"),
            ),
            _QuickPhraseButton(
              label: "Where is...?",
              onTap: () => _setPhraseAndTranslate("Where is...?"),
            ),
            _QuickPhraseButton(
              label: "How much?",
              onTap: () => _setPhraseAndTranslate("How much?"),
            ),
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
          items: _languages
              .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
              .toList(),
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
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
