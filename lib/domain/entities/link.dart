import 'platform_type.dart';
import 'topic_type.dart';
import 'content_type.dart';
import 'sync_types.dart';

class Link {
  final int? id;
  final String url;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? faviconUrl;
  final String? publisherName;
  final String? aiDescription;
  final PlatformType platform;
  final TopicType topic;
  final ContentType contentType;
  final List<String> tags;
  final DateTime createdAt;
  final int? customCategoryId;

  // Sync fields (server = Supabase content_items)
  final String? remoteId;
  final DateTime? updatedAt;
  final PendingOp pendingOp;
  final String? summary;
  final List<String> keyPoints;
  final String? topicLabel;
  final ItemStatus status;
  final String readStatus;
  final bool isStarred;
  final bool isPinned;
  final List<String> folderRemoteIds;

  /// 'bookmark' (plain website link) or 'content' (readable article/video/
  /// post/PDF) — server-generated column, drives the Vault Hub vs Library
  /// split just like the web app.
  final String itemKind;

  /// Client that saved the item: web / mobile / extension / import / rss / mcp.
  final String? savedVia;

  /// Original publish date of the source content, when known.
  final DateTime? publishedAt;

  Link({
    this.id,
    required this.url,
    required this.title,
    this.description,
    this.imageUrl,
    this.faviconUrl,
    this.publisherName,
    this.aiDescription,
    required this.platform,
    this.topic = TopicType.other,
    this.contentType = ContentType.other,
    this.tags = const [],
    required this.createdAt,
    this.customCategoryId,
    this.remoteId,
    this.updatedAt,
    this.pendingOp = PendingOp.none,
    this.summary,
    this.keyPoints = const [],
    this.topicLabel,
    this.status = ItemStatus.ready,
    this.readStatus = 'unread',
    this.isStarred = false,
    this.isPinned = false,
    this.folderRemoteIds = const [],
    this.itemKind = 'bookmark',
    this.savedVia,
    this.publishedAt,
  });

  Link copyWith({
    int? id,
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    String? faviconUrl,
    String? publisherName,
    String? aiDescription,
    PlatformType? platform,
    TopicType? topic,
    ContentType? contentType,
    List<String>? tags,
    DateTime? createdAt,
    int? customCategoryId,
    String? remoteId,
    DateTime? updatedAt,
    PendingOp? pendingOp,
    String? summary,
    List<String>? keyPoints,
    String? topicLabel,
    ItemStatus? status,
    String? readStatus,
    bool? isStarred,
    bool? isPinned,
    List<String>? folderRemoteIds,
    String? itemKind,
    String? savedVia,
    DateTime? publishedAt,
  }) {
    return Link(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      publisherName: publisherName ?? this.publisherName,
      aiDescription: aiDescription ?? this.aiDescription,
      platform: platform ?? this.platform,
      topic: topic ?? this.topic,
      contentType: contentType ?? this.contentType,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      customCategoryId: customCategoryId ?? this.customCategoryId,
      remoteId: remoteId ?? this.remoteId,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingOp: pendingOp ?? this.pendingOp,
      summary: summary ?? this.summary,
      keyPoints: keyPoints ?? this.keyPoints,
      topicLabel: topicLabel ?? this.topicLabel,
      status: status ?? this.status,
      readStatus: readStatus ?? this.readStatus,
      isStarred: isStarred ?? this.isStarred,
      isPinned: isPinned ?? this.isPinned,
      folderRemoteIds: folderRemoteIds ?? this.folderRemoteIds,
      itemKind: itemKind ?? this.itemKind,
      savedVia: savedVia ?? this.savedVia,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
