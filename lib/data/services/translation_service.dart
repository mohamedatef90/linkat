import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TranslationService {
  GenerativeModel? _model;

  TranslationService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    }
  }

  bool get isAvailable => _model != null;

  Future<String?> translate({
    required String text,
    required String targetLanguage,
  }) async {
    if (_model == null) {
      return null;
    }

    try {
      final prompt = '''
Translate the following text to $targetLanguage.
Only return the translated text, nothing else.
Keep the same formatting and tone.

Text to translate:
$text
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    } catch (e) {
      return null;
    }
  }
}
