import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/entities/topic_type.dart';

class AiClassificationResult {
  final TopicType category;
  final List<String> tags;

  AiClassificationResult({
    required this.category,
    required this.tags,
  });
}

class AiClassificationService {
  GenerativeModel? _model;

  AiClassificationService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    }
  }

  bool get isAvailable => _model != null;

  /// Classifies content and generates tags using AI
  Future<AiClassificationResult?> classifyContent({
    required String url,
    String? title,
    String? description,
  }) async {
    if (_model == null) {
      return null;
    }

    try {
      final prompt = '''
Analyze this link and classify it.

URL: $url
${title != null ? 'Title: $title' : ''}
${description != null ? 'Description: $description' : ''}

Available categories (choose exactly one):
- aiTech: AI, Machine Learning, Data Science, Neural Networks, LLM, GPT
- development: Programming, Software Development, Coding, Web Development, Mobile Development, DevOps, APIs, Frameworks, Libraries
- productUX: Product Design, UX/UI, User Experience, Prototyping
- design: Graphic Design, Creative, Branding, Illustration, Animation
- business: Business, Marketing, Finance, Startup, Entrepreneurship
- science: Science, Research, Education, Academic, Medicine, Health
- entertainment: Movies, Music, Gaming, Sports, Videos, Streaming
- other: If none of the above fit well

Return a JSON object with:
1. "category": one of the category names above (lowercase, exactly as written)
2. "tags": array of 3-5 relevant lowercase tags (single words or short phrases, no hashtags)

Example response:
{"category": "aiTech", "tags": ["machine-learning", "python", "neural-networks", "deep-learning"]}

Return ONLY the JSON object, no other text.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();

      if (text == null || text.isEmpty) {
        return null;
      }

      // Parse JSON response
      // Remove markdown code blocks if present
      String jsonText = text;
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.replaceAll(RegExp(r'^```json?\n?'), '');
        jsonText = jsonText.replaceAll(RegExp(r'\n?```$'), '');
      }

      final Map<String, dynamic> parsed = jsonDecode(jsonText.trim());

      final categoryStr = parsed['category'] as String;
      final tagsRaw = parsed['tags'] as List<dynamic>;
      final tags = tagsRaw.map((t) => t.toString().toLowerCase().trim()).toList();

      // Map category string to TopicType
      final category = _parseCategory(categoryStr);

      return AiClassificationResult(
        category: category,
        tags: tags,
      );
    } catch (e) {
      return null;
    }
  }

  TopicType _parseCategory(String category) {
    switch (category.toLowerCase()) {
      case 'aitech':
        return TopicType.aiTech;
      case 'development':
        return TopicType.development;
      case 'productux':
        return TopicType.productUX;
      case 'design':
        return TopicType.design;
      case 'business':
        return TopicType.business;
      case 'science':
        return TopicType.science;
      case 'entertainment':
        return TopicType.entertainment;
      default:
        return TopicType.other;
    }
  }
}
