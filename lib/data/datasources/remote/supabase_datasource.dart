import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/content_type.dart';
import '../../../domain/entities/link.dart';
import '../../../domain/entities/sync_types.dart';
import '../../../domain/entities/topic_type.dart';
import '../../services/platform_detection_service.dart';
import '../../services/sync_service.dart';

/// A folder row from the `folders` table.
class RemoteFolder {
  final String id;
  final String name;
  final String? color;
  final String? icon;
  final String? parentId;

  const RemoteFolder({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    this.parentId,
  });

  factory RemoteFolder.fromJson(Map<String, dynamic> json) {
    return RemoteFolder(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Untitled',
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      parentId: json['parent_id'] as String?,
    );
  }
}

/// Result of the `translate` Edge Function.
class TranslationResult {
  final String? title;
  final String? summary;
  final List<String> keyPoints;
  final String? body;

  const TranslationResult({
    this.title,
    this.summary,
    this.keyPoints = const [],
    this.body,
  });
}

/// Remote data access for the RefVault Supabase backend
/// (content_items / folders tables + save-item Edge Function).
class SupabaseDatasource implements SyncRemoteStore {
  final SupabaseClient _client;
  final PlatformDetectionService _platformDetection;

  SupabaseDatasource(this._client, this._platformDetection);

  // ---- content_items ----

  @override
  Future<List<Link>> fetchItemsSince(DateTime? since) async {
    var query = _client
        .from('content_items')
        .select('*, item_folders(folder_id)');
    if (since != null) {
      query = query.gte('updated_at', since.toUtc().toIso8601String());
    }
    final rows = await query.order('updated_at', ascending: true);
    return (rows as List)
        .map((row) => linkFromRow(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Set<String>> fetchAllItemIds() async {
    final rows = await _client.from('content_items').select('id');
    return (rows as List)
        .map((row) => (row as Map<String, dynamic>)['id'] as String)
        .toSet();
  }

  @override
  Future<SaveUrlResult> saveUrl(String url, {String? folderId}) async {
    final response = await _client.functions.invoke(
      'save-item',
      body: {
        'url': url,
        'saved_via': 'mobile',
        if (folderId != null) 'folder_id': folderId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return SaveUrlResult(
      remoteId: data['id'] as String,
      duplicate: data['duplicate'] as bool? ?? false,
      status: ItemStatus.fromString(data['status'] as String?),
      title: data['title'] as String?,
    );
  }

  @override
  Future<void> updateItem(String remoteId, Map<String, dynamic> fields) async {
    await _client.from('content_items').update(fields).eq('id', remoteId);
  }

  @override
  Future<void> deleteItem(String remoteId) async {
    await _client.from('content_items').delete().eq('id', remoteId);
  }

  /// Full text is large, so it is fetched only when the reader opens.
  Future<String?> fetchContentText(String remoteId) async {
    final row = await _client
        .from('content_items')
        .select('content_text')
        .eq('id', remoteId)
        .maybeSingle();
    return row?['content_text'] as String?;
  }

  /// AI translation of the item's title/summary/key points/body via the
  /// `translate` Edge Function (NVIDIA fast model + Gemini fallback, cached
  /// server-side). Defaults to Arabic.
  Future<TranslationResult> translate(String remoteId, {String lang = 'ar'}) async {
    final response = await _client.functions.invoke(
      'translate',
      body: {'item_id': remoteId, 'target_lang': lang},
    );
    final data = response.data as Map<String, dynamic>;
    return TranslationResult(
      title: data['title'] as String?,
      summary: data['summary'] as String?,
      keyPoints:
          (data['key_points'] as List?)?.map((e) => e.toString()).toList() ??
              const <String>[],
      body: data['body'] as String?,
    );
  }

  // ---- folders ----

  Future<List<RemoteFolder>> fetchFolders() async {
    final rows = await _client
        .from('folders')
        .select()
        .order('position', ascending: true);
    return (rows as List)
        .map((row) => RemoteFolder.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<RemoteFolder> createFolder(String name,
      {String? color, String? icon}) async {
    final row = await _client
        .from('folders')
        .insert({
          'name': name,
          'user_id': _client.auth.currentUser!.id,
          if (color != null) 'color': color,
          if (icon != null) 'icon': icon,
        })
        .select()
        .single();
    return RemoteFolder.fromJson(row);
  }

  Future<void> renameFolder(String folderId, String name) async {
    await _client.from('folders').update({'name': name}).eq('id', folderId);
  }

  Future<void> deleteFolder(String folderId) async {
    await _client.from('folders').delete().eq('id', folderId);
  }

  // ---- realtime ----

  /// Subscribes to any change on the user's content_items.
  /// The caller typically triggers a sync pull in [onChange].
  RealtimeChannel subscribeToItems(void Function() onChange) {
    return _client
        .channel('content_items_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'content_items',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  // ---- row mapping ----

  Link linkFromRow(Map<String, dynamic> row) {
    final url = row['url'] as String? ?? '';
    final tags = (row['tags'] as List?)?.cast<String>() ?? const <String>[];
    final keyPoints =
        (row['key_points'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final folderIds = (row['item_folders'] as List?)
            ?.map((f) => (f as Map<String, dynamic>)['folder_id'] as String)
            .toList() ??
        const <String>[];
    final topicLabel = row['topic'] as String?;

    return Link(
      url: url,
      title: row['title'] as String? ?? url,
      description: row['description'] as String?,
      imageUrl: row['thumbnail_url'] as String?,
      faviconUrl: row['favicon_url'] as String?,
      publisherName: row['site_name'] as String?,
      aiDescription: row['summary'] as String?,
      platform: _platformDetection.detectPlatform(url),
      topic: topicTypeFromLabel(topicLabel),
      contentType: _contentTypeFromSourceType(row['source_type'] as String?),
      tags: tags,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      remoteId: row['id'] as String,
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String? ?? '')?.toUtc(),
      pendingOp: PendingOp.none,
      summary: row['summary'] as String?,
      keyPoints: keyPoints,
      topicLabel: topicLabel,
      status: ItemStatus.fromString(row['status'] as String?),
      readStatus: row['read_status'] as String? ?? 'unread',
      isStarred: row['is_starred'] as bool? ?? false,
      isPinned: row['is_pinned'] as bool? ?? false,
      folderRemoteIds: folderIds,
    );
  }

  ContentType _contentTypeFromSourceType(String? sourceType) {
    switch (sourceType) {
      case 'article':
      case 'rss':
        return ContentType.article;
      case 'youtube':
        return ContentType.video;
      case 'reel':
        return ContentType.reel;
      case 'tweet':
      case 'reddit':
        return ContentType.post;
      case 'podcast':
        return ContentType.podcast;
      default:
        return ContentType.other;
    }
  }
}

/// Best-effort mapping of the server's free-text topic to the local enum
/// used for browse UI colors/icons.
TopicType topicTypeFromLabel(String? label) {
  if (label == null || label.isEmpty) return TopicType.other;
  final l = label.toLowerCase();
  if (l.contains('artificial') ||
      l.contains('machine learning') ||
      l.contains('tech') ||
      RegExp(r'\bai\b').hasMatch(l)) {
    return TopicType.aiTech;
  }
  if (l.contains('develop') ||
      l.contains('program') ||
      l.contains('coding') ||
      l.contains('software')) {
    return TopicType.development;
  }
  if (l.contains('product') || l.contains('ux') || l.contains('ui')) {
    return TopicType.productUX;
  }
  if (l.contains('design') || l.contains('creative') || l.contains('brand')) {
    return TopicType.design;
  }
  if (l.contains('business') ||
      l.contains('market') ||
      l.contains('financ') ||
      l.contains('startup')) {
    return TopicType.business;
  }
  if (l.contains('science') ||
      l.contains('research') ||
      l.contains('education')) {
    return TopicType.science;
  }
  if (l.contains('entertain') ||
      l.contains('movie') ||
      l.contains('music') ||
      l.contains('gaming') ||
      l.contains('sport')) {
    return TopicType.entertainment;
  }
  return TopicType.other;
}
