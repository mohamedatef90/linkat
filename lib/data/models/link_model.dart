import 'package:isar/isar.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/platform_type.dart';
import '../../domain/entities/topic_type.dart';

part 'link_model.g.dart';

@collection
class LinkModel {
  Id id = Isar.autoIncrement;

  late String url;
  late String title;
  String? description;
  String? imageUrl;
  String? publisherName;
  String? aiDescription;

  @enumerated
  late PlatformType platform;

  @enumerated
  late TopicType topic;

  List<String> tags = [];

  late DateTime createdAt;

  Link toEntity() {
    return Link(
      id: id,
      url: url,
      title: title,
      description: description,
      imageUrl: imageUrl,
      publisherName: publisherName,
      aiDescription: aiDescription,
      platform: platform,
      topic: topic,
      tags: tags,
      createdAt: createdAt,
    );
  }

  static LinkModel fromEntity(Link link) {
    return LinkModel()
      ..id = link.id ?? Isar.autoIncrement
      ..url = link.url
      ..title = link.title
      ..description = link.description
      ..imageUrl = link.imageUrl
      ..publisherName = link.publisherName
      ..aiDescription = link.aiDescription
      ..platform = link.platform
      ..topic = link.topic
      ..tags = link.tags
      ..createdAt = link.createdAt;
  }
}
