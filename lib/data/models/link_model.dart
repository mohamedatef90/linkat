import 'package:isar/isar.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/platform_type.dart';
import '../../domain/entities/topic_type.dart';
import '../../domain/entities/content_type.dart';
import '../../domain/entities/sync_types.dart';

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

  @enumerated
  ContentType contentType = ContentType.other;

  List<String> tags = [];

  late DateTime createdAt;

  int? customCategoryId;

  // Sync fields (server = Supabase content_items)
  @Index(unique: false)
  String? remoteId;

  DateTime? updatedAt;

  @enumerated
  PendingOp pendingOp = PendingOp.none;

  String? summary;
  List<String> keyPoints = [];
  String? topicLabel;

  @enumerated
  ItemStatus status = ItemStatus.ready;

  String readStatus = 'unread';
  bool isStarred = false;
  bool isPinned = false;
  List<String> folderRemoteIds = [];

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
      contentType: contentType,
      tags: tags,
      createdAt: createdAt,
      customCategoryId: customCategoryId,
      remoteId: remoteId,
      updatedAt: updatedAt,
      pendingOp: pendingOp,
      summary: summary,
      keyPoints: keyPoints,
      topicLabel: topicLabel,
      status: status,
      readStatus: readStatus,
      isStarred: isStarred,
      isPinned: isPinned,
      folderRemoteIds: folderRemoteIds,
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
      ..contentType = link.contentType
      ..tags = link.tags
      ..createdAt = link.createdAt
      ..customCategoryId = link.customCategoryId
      ..remoteId = link.remoteId
      ..updatedAt = link.updatedAt
      ..pendingOp = link.pendingOp
      ..summary = link.summary
      ..keyPoints = link.keyPoints
      ..topicLabel = link.topicLabel
      ..status = link.status
      ..readStatus = link.readStatus
      ..isStarred = link.isStarred
      ..isPinned = link.isPinned
      ..folderRemoteIds = link.folderRemoteIds;
  }
}
