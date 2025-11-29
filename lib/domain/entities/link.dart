import 'platform_type.dart';
import 'topic_type.dart';

class Link {
  final int? id;
  final String url;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? publisherName;
  final String? aiDescription;
  final PlatformType platform;
  final TopicType topic;
  final List<String> tags;
  final DateTime createdAt;

  Link({
    this.id,
    required this.url,
    required this.title,
    this.description,
    this.imageUrl,
    this.publisherName,
    this.aiDescription,
    required this.platform,
    this.topic = TopicType.other,
    this.tags = const [],
    required this.createdAt,
  });

  Link copyWith({
    int? id,
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    String? publisherName,
    String? aiDescription,
    PlatformType? platform,
    TopicType? topic,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return Link(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      publisherName: publisherName ?? this.publisherName,
      aiDescription: aiDescription ?? this.aiDescription,
      platform: platform ?? this.platform,
      topic: topic ?? this.topic,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
