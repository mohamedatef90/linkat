import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/remote/supabase_datasource.dart';
import '../../data/repositories/isar_sync_local_store.dart';
import '../../data/services/platform_detection_service.dart';
import '../../data/services/sync_service.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/sync_types.dart';
import 'auth_providers.dart';
import 'link_providers.dart';

final supabaseDatasourceProvider = Provider<SupabaseDatasource>((ref) {
  return SupabaseDatasource(
    ref.watch(supabaseClientProvider),
    PlatformDetectionService(),
  );
});

final syncLocalStoreProvider = Provider<IsarSyncLocalStore>((ref) {
  return IsarSyncLocalStore();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    remote: ref.watch(supabaseDatasourceProvider),
    local: ref.watch(syncLocalStoreProvider),
  );
});

/// Orchestrates when sync runs: app start/resume, connectivity regained, and
/// Supabase Realtime changes on content_items. Also the single entry point
/// screens use for writes so providers get refreshed afterwards.
final syncControllerProvider = Provider<SyncController>((ref) {
  final controller = SyncController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

class SyncController {
  final Ref _ref;
  RealtimeChannel? _channel;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _started = false;
  bool _syncing = false;

  SyncController(this._ref);

  /// Idempotent; called once the user is signed in and the home screen loads.
  void start() {
    if (_started) return;
    _started = true;
    syncNow();
    _channel = _ref.read(supabaseDatasourceProvider).subscribeToItems(() {
      // Enrichment landed (pending -> ready etc.): pull the fresh row.
      syncNow();
    });
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) syncNow(); // flush queued ops on reconnect
    });
  }

  Future<void> syncNow() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await _ref.read(syncServiceProvider).sync();
    } catch (e) {
      debugPrint('SyncController: sync failed: $e');
    } finally {
      _syncing = false;
    }
    refreshLinkProviders();
  }

  /// "Sync all links": queue every never-uploaded local row as a create, then
  /// run a full push + pull. Returns how many old links were queued for upload.
  Future<int> syncAllLinks() async {
    final queued =
        await _ref.read(syncServiceProvider).requeueLocalOnly();
    await syncNow();
    return queued;
  }

  /// Save a URL through save-item with an instant local metadata preview.
  Future<Link> saveUrl(
    String url, {
    String? folderId,
    String? fallbackTitle,
  }) async {
    final preview = await _buildPreview(url, fallbackTitle: fallbackTitle);
    final saved = await _ref
        .read(syncServiceProvider)
        .saveNewUrl(url, folderId: folderId, localPreview: preview);
    refreshLinkProviders();
    return saved;
  }

  /// Optimistic edit of the pushable fields (title/pin/star/read).
  Future<Link> updateLink(Link link) async {
    final updated = await _ref.read(syncServiceProvider).updateLink(link);
    refreshLinkProviders();
    return updated;
  }

  Future<void> deleteLink(Link link) async {
    await _ref.read(syncServiceProvider).deleteLink(link);
    refreshLinkProviders();
  }

  Future<Link> _buildPreview(String url, {String? fallbackTitle}) async {
    final platform =
        _ref.read(platformDetectionServiceProvider).detectPlatform(url);
    var title = fallbackTitle ?? '';
    String? description;
    String? imageUrl;
    String? publisher;
    try {
      final metadata = await _ref
          .read(metadataServiceProvider)
          .fetchMetadata(url)
          .timeout(const Duration(seconds: 6));
      if ((metadata['title'] ?? '').trim().isNotEmpty) {
        title = metadata['title']!.trim();
      }
      description = metadata['description'];
      imageUrl = metadata['image'];
      publisher = metadata['publisher'];
    } catch (_) {
      // Preview only — the server parse fills the real metadata.
    }
    if (title.isEmpty) {
      title = Uri.tryParse(url)?.host ?? url;
    }
    final contentType = _ref
        .read(contentTypeDetectionServiceProvider)
        .detectContentType(url, platform, null);
    return Link(
      url: url,
      title: title,
      description: description,
      imageUrl: imageUrl,
      publisherName: publisher,
      platform: platform,
      contentType: contentType,
      createdAt: DateTime.now(),
      status: ItemStatus.pending,
    );
  }

  void refreshLinkProviders() {
    _ref.invalidate(allLinksProvider);
    _ref.invalidate(linksProvider);
    _ref.invalidate(allTagsProvider);
    _ref.invalidate(linksByTagProvider);
    _ref.invalidate(linksByTopicProvider);
    _ref.invalidate(searchLinksProvider);
  }

  void dispose() {
    _channel?.unsubscribe();
    _connectivitySub?.cancel();
  }
}

// ---- folders / reader ----

final foldersProvider = FutureProvider<List<RemoteFolder>>((ref) async {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseDatasourceProvider).fetchFolders();
});

final linksByFolderProvider =
    FutureProvider.family<List<Link>, String>((ref, folderId) async {
  final all = await ref.watch(allLinksProvider.future);
  return all.where((l) => l.folderRemoteIds.contains(folderId)).toList();
});

/// content_text is large; fetched only when the reader opens.
final contentTextProvider =
    FutureProvider.family<String?, String>((ref, remoteId) {
  return ref.watch(supabaseDatasourceProvider).fetchContentText(remoteId);
});
