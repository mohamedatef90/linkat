import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiDescriptionService {
  GenerativeModel? _model;

  AiDescriptionService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    }
  }

  /// Generate a concise description for a link based on its title and existing description
  Future<String?> generateDescription({
    required String url,
    String? title,
    String? existingDescription,
  }) async {
    // If AI service is not configured, return null
    if (_model == null) {
      return null;
    }

    try {
      // Build the prompt for the AI
      final prompt = _buildPrompt(
        url: url,
        title: title,
        existingDescription: existingDescription,
      );

      // Generate content
      final response = await _model!.generateContent([Content.text(prompt)]);
      final generatedText = response.text?.trim();

      // Return the generated description or null if empty
      return (generatedText != null && generatedText.isNotEmpty)
          ? generatedText
          : null;
    } catch (e) {
      // Log error and return null on failure
      print('AI description generation failed: $e');
      return null;
    }
  }

  String _buildPrompt({
    required String url,
    String? title,
    String? existingDescription,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(
      'Generate a concise, informative description (2-3 sentences) for this link:',
    );
    buffer.writeln();
    buffer.writeln('URL: $url');

    if (title != null && title.isNotEmpty) {
      buffer.writeln('Title: $title');
    }

    if (existingDescription != null && existingDescription.isNotEmpty) {
      buffer.writeln('Existing Description: $existingDescription');
    }

    buffer.writeln();
    buffer.writeln('Requirements:');
    buffer.writeln('- Be concise (2-3 sentences maximum)');
    buffer.writeln('- Focus on what the content is about');
    buffer.writeln('- Make it informative and engaging');
    buffer.writeln('- Do not include promotional language');
    buffer.writeln('- Return only the description, no additional text');

    return buffer.toString();
  }
}
