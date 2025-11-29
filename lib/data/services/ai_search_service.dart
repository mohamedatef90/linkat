import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/entities/link.dart';

class AiSearchResult {
  final List<Link> results;
  final String? explanation;

  AiSearchResult({
    required this.results,
    this.explanation,
  });
}

class AiSearchService {
  GenerativeModel? _model;

  AiSearchService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    }
  }

  bool get isAvailable => _model != null;

  /// Uses AI to understand search intent and find matching links
  Future<AiSearchResult> smartSearch({
    required String query,
    required List<Link> allLinks,
  }) async {
    if (_model == null || allLinks.isEmpty) {
      // Fall back to basic search
      return _basicSearch(query, allLinks);
    }

    try {
      // Build link descriptions for AI
      final linkDescriptions = allLinks.asMap().entries.map((entry) {
        final index = entry.key;
        final link = entry.value;
        return '''
[$index] Title: ${link.title}
URL: ${link.url}
Category: ${link.topic.displayName}
Tags: ${link.tags.join(', ')}
${link.description != null ? 'Description: ${link.description}' : ''}
${link.aiDescription != null ? 'AI Summary: ${link.aiDescription}' : ''}
''';
      }).join('\n---\n');

      final prompt = '''
You are a smart search assistant. The user is searching for links.

User query: "$query"

Available links:
$linkDescriptions

Analyze the user's search intent. They might be searching by:
- Topic (e.g., "AI stuff", "design inspiration", "business articles")
- Tag (e.g., "machine-learning", "figma")
- Keywords in title or description
- Semantic meaning (e.g., "things about coding" should match programming links)

Return a JSON object with:
1. "indices": array of link indices (numbers) that match the query, ordered by relevance (best first)
2. "explanation": brief explanation of why these links match (1 sentence)

Example: {"indices": [2, 5, 1], "explanation": "Found 3 articles about machine learning and AI development."}

Return ONLY the JSON, no other text. If no matches, return {"indices": [], "explanation": "No matching links found."}
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text?.trim();

      if (text == null || text.isEmpty) {
        return _basicSearch(query, allLinks);
      }

      // Parse response
      String jsonText = text;
      if (jsonText.startsWith('```')) {
        jsonText = jsonText.replaceAll(RegExp(r'^```json?\n?'), '');
        jsonText = jsonText.replaceAll(RegExp(r'\n?```$'), '');
      }

      final Map<String, dynamic> parsed = jsonDecode(jsonText.trim());
      final indices = (parsed['indices'] as List<dynamic>).cast<int>();
      final explanation = parsed['explanation'] as String?;

      // Get matching links in order
      final results = <Link>[];
      for (final index in indices) {
        if (index >= 0 && index < allLinks.length) {
          results.add(allLinks[index]);
        }
      }

      return AiSearchResult(
        results: results,
        explanation: explanation,
      );
    } catch (e) {
      return _basicSearch(query, allLinks);
    }
  }

  AiSearchResult _basicSearch(String query, List<Link> allLinks) {
    final queryLower = query.toLowerCase();
    final results = allLinks.where((link) {
      return link.title.toLowerCase().contains(queryLower) ||
          link.url.toLowerCase().contains(queryLower) ||
          (link.description?.toLowerCase().contains(queryLower) ?? false) ||
          (link.aiDescription?.toLowerCase().contains(queryLower) ?? false) ||
          link.tags.any((tag) => tag.toLowerCase().contains(queryLower)) ||
          link.topic.displayName.toLowerCase().contains(queryLower);
    }).toList();

    return AiSearchResult(
      results: results,
      explanation: null,
    );
  }
}
