import '../../domain/entities/topic_type.dart';

/// Service for classifying link content into topic categories using keyword matching
class TopicClassificationService {
  // Keywords for each topic category
  static final Map<TopicType, List<String>> _topicKeywords = {
    TopicType.aiTech: [
      'ai',
      'artificial intelligence',
      'machine learning',
      'ml',
      'deep learning',
      'neural',
      'data science',
      'chatgpt',
      'gpt',
      'llm',
      'transformer',
      'nlp',
      'computer vision',
      'tensorflow',
      'pytorch',
    ],
    TopicType.development: [
      'programming',
      'developer',
      'development',
      'software',
      'code',
      'coding',
      'engineering',
      'computer',
      'algorithm',
      'api',
      'cloud',
      'devops',
      'frontend',
      'backend',
      'fullstack',
      'javascript',
      'python',
      'java',
      'kotlin',
      'swift',
      'flutter',
      'react',
      'angular',
      'vue',
      'node',
      'database',
      'sql',
      'git',
      'github',
      'framework',
      'library',
      'web development',
      'mobile development',
      'app development',
    ],
    TopicType.productUX: [
      'ux',
      'ui',
      'user experience',
      'user interface',
      'product design',
      'product management',
      'product',
      'usability',
      'interaction',
      'wireframe',
      'prototype',
      'figma',
      'sketch',
      'design thinking',
      'user research',
      'persona',
      'journey map',
      'accessibility',
      'mobile app',
      'web app',
      'interface design',
    ],
    TopicType.design: [
      'graphic design',
      'branding',
      'brand',
      'creative',
      'illustration',
      'typography',
      'font',
      'logo',
      'visual',
      'art',
      'aesthetic',
      'photoshop',
      'illustrator',
      'design',
      'color',
      'layout',
      'poster',
      'portfolio',
      'motion graphics',
      'animation',
    ],
    TopicType.business: [
      'business',
      'startup',
      'entrepreneur',
      'marketing',
      'finance',
      'investment',
      'strategy',
      'growth',
      'sales',
      'revenue',
      'management',
      'leadership',
      'productivity',
      'corporate',
      'enterprise',
      'b2b',
      'b2c',
      'saas',
      'market',
      'customer',
      'analytics',
      'metrics',
      'kpi',
      'roi',
    ],
    TopicType.science: [
      'science',
      'research',
      'study',
      'academic',
      'paper',
      'journal',
      'experiment',
      'theory',
      'hypothesis',
      'discovery',
      'scientific',
      'biology',
      'chemistry',
      'physics',
      'astronomy',
      'medicine',
      'health',
      'psychology',
      'neuroscience',
      'education',
      'learning',
    ],
    TopicType.entertainment: [
      'movie',
      'film',
      'cinema',
      'music',
      'song',
      'album',
      'artist',
      'game',
      'gaming',
      'video game',
      'entertainment',
      'tv',
      'show',
      'series',
      'netflix',
      'spotify',
      'youtube',
      'video',
      'stream',
      'sport',
      'football',
      'basketball',
      'soccer',
      'celebrity',
    ],
  };

  /// Classifies content into a topic category based on keyword matching
  ///
  /// Analyzes [title] and [description] (if provided) and returns the
  /// topic with the highest keyword match count.
  /// Returns [TopicType.other] if no strong matches are found.
  TopicType classifyContent({required String title, String? description}) {
    // Combine title and description into searchable text
    final searchText =
        '${title.toLowerCase()} ${description?.toLowerCase() ?? ''}'.trim();

    if (searchText.isEmpty) {
      return TopicType.other;
    }

    // Count keyword matches for each topic
    final Map<TopicType, int> matchCounts = {};

    for (final entry in _topicKeywords.entries) {
      final topic = entry.key;
      final keywords = entry.value;

      int matchCount = 0;
      for (final keyword in keywords) {
        if (searchText.contains(keyword)) {
          matchCount++;
        }
      }

      if (matchCount > 0) {
        matchCounts[topic] = matchCount;
      }
    }

    // Return topic with highest match count
    if (matchCounts.isEmpty) {
      return TopicType.other;
    }

    // Find the topic with maximum matches
    TopicType bestTopic = TopicType.other;
    int maxMatches = 0;

    matchCounts.forEach((topic, count) {
      if (count > maxMatches) {
        maxMatches = count;
        bestTopic = topic;
      }
    });

    return bestTopic;
  }
}
