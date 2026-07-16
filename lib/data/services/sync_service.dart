import 'package:flutter/foundation.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/sync_types.dart';
import 'platform_detection_service.dart';

/// Result of calling the save-item Edge Function.
class SaveUrlResult {
  final String remoteId;
  final bool duplicate;
  final ItemStatus status;
  final String? title;

  const SaveUrlResult({
    required this.remoteId,
    required this.duplicate,
    required this.status,
    this.title,
  });
}

/// Remote side of sync (implemented by SupabaseDatasource).
abstract class SyncRemoteStore {
  Future<List<Link>> fetchItemsSince(DateTime? since);
  Future<Set<String>> fetchAllItemIds();
  Future<SaveUrlResult> saveUrl(String url, {String? folderId});
  Future<void> updateItem(String remoteId, Map<String, dynamic> fields);
  Future<void> deleteItem(String remoteId);
}

/// Local side of sync (implemented on top of Isar).
abstract class SyncLocalStore {
  Future<Link?> getByRemoteId(String remoteId);
  Future<List<Link>> getAllSynced();
  Future<List<Link>> getPendingOps();

  /// Rows that never reached the server AND aren't queued (remoteId == null,
  /// pendingOp == none) — e.g. links saved before the sync engine existed.
  Future<List<Link>> getLocalOnly();

  /// Insert or update; when [link.id] is set, the existing row is replaced.
  Future<Link> put(Link link);
  Future<void> deleteLocal(int id);

  Future<DateTime?> getLastSyncAt();
  Future<void> setLastSyncAt(DateTime value);
}

/// Deliberately simple sync: server wins.
///
/// - PULL: content_items with updated_at >= lastSyncAt are upserted into Isar
///   by remoteId. Rows carrying an unpushed pendingOp are left alone until the
///   next flush; every other local row is overwritten with server state.
/// - PUSH: local writes are applied optimistically with a pendingOp flag;
///   [push] flushes them (create -> save-item, update -> PATCH,
///   delete -> DELETE) and clears the flag. A failed op stays queued.
/// - Remote deletions are detected by pruning local synced rows whose id no
///   longer exists server-side.
class SyncService {
  final SyncRemoteStore remote;
  final SyncLocalStore local;

  SyncService({required this.remote, required this.local});

  /// Only these item fields are pushed on update; everything else is
  /// server-owned enrichment data.
  static Map<String, dynamic> pushableFields(Link link) => {
        'title': link.title,
        'is_pinned': link.isPinned,
        'is_starred': link.isStarred,
        'read_status': link.readStatus,
      };

  /// Push queued ops, then pull server state. Safe to call repeatedly,
  /// including while offline (everything stays queued for the next attempt).
  Future<void> sync() async {
    await push();
    try {
      await pull();
    } catch (e) {
      debugPrint('SyncService: pull failed (probably offline): $e');
    }
  }

  /// Backfill for "Sync all links": local rows that never reached the server
  /// (saved before the sync engine existed, or whose create was lost) are
  /// re-queued as pending creates. Returns how many were queued; the caller
  /// then runs [sync] to flush them through save-item.
  Future<int> requeueLocalOnly() async {
    final orphans = await local.getLocalOnly();
    for (final link in orphans) {
      await local.put(link.copyWith(pendingOp: PendingOp.create));
    }
    return orphans.length;
  }

  /// Flush all pending local ops to the server. A failing op is kept queued
  /// (typical cause: offline); remaining ops are still attempted.
  Future<void> push() async {
    final pending = await local.getPendingOps();
    for (final link in pending) {
      try {
        switch (link.pendingOp) {
          case PendingOp.create:
            await _pushCreate(link);
          case PendingOp.update:
            await _pushUpdate(link);
          case PendingOp.delete:
            await _pushDelete(link);
          case PendingOp.none:
            break;
        }
      } catch (e) {
        debugPrint('SyncService: push failed for ${link.url}: $e');
      }
    }
  }

  Future<void> _pushCreate(Link link) async {
    if (link.remoteId != null) {
      // Already created on a previous partially-failed flush.
      await local.put(link.copyWith(pendingOp: PendingOp.none));
      return;
    }
    final result = await remote.saveUrl(
      link.url,
      folderId: link.folderRemoteIds.isNotEmpty
          ? link.folderRemoteIds.first
          : null,
    );
    await local.put(link.copyWith(
      remoteId: result.remoteId,
      status: result.status,
      pendingOp: PendingOp.none,
    ));
  }

  Future<void> _pushUpdate(Link link) async {
    if (link.remoteId == null) {
      // Never reached the server; treat as a create instead.
      await _pushCreate(link.copyWith(pendingOp: PendingOp.create));
      return;
    }
    await remote.updateItem(link.remoteId!, pushableFields(link));
    await local.put(link.copyWith(pendingOp: PendingOp.none));
  }

  Future<void> _pushDelete(Link link) async {
    if (link.remoteId != null) {
      await remote.deleteItem(link.remoteId!);
    }
    if (link.id != null) {
      await local.deleteLocal(link.id!);
    }
  }

  /// Pull server changes since the last sync and upsert them into Isar.
  /// Server wins: any local row without a queued op is overwritten.
  Future<void> pull() async {
    final since = await local.getLastSyncAt();
    final items = await remote.fetchItemsSince(since);

    DateTime? maxUpdatedAt = since;
    for (final item in items) {
      final existing = await local.getByRemoteId(item.remoteId!);
      if (existing == null) {
        await local.put(item);
      } else if (existing.pendingOp == PendingOp.none) {
        await local.put(item.copyWith(id: existing.id));
      }
      // else: unpushed local op — leave it; next push + pull reconciles.

      final updatedAt = item.updatedAt;
      if (updatedAt != null &&
          (maxUpdatedAt == null || updatedAt.isAfter(maxUpdatedAt))) {
        maxUpdatedAt = updatedAt;
      }
    }

    await _pruneRemotelyDeleted();

    if (maxUpdatedAt != null) {
      await local.setLastSyncAt(maxUpdatedAt);
    }
  }

  /// Remove local synced rows whose item no longer exists on the server.
  Future<void> _pruneRemotelyDeleted() async {
    final remoteIds = await remote.fetchAllItemIds();
    final localSynced = await local.getAllSynced();
    for (final link in localSynced) {
      if (link.pendingOp == PendingOp.none &&
          !remoteIds.contains(link.remoteId) &&
          link.id != null) {
        await local.deleteLocal(link.id!);
      }
    }
  }

  // ---- optimistic local writes ----

  /// Save a new URL. Online it goes through save-item and the placeholder row
  /// gets its remoteId immediately; offline the row is queued as a pending
  /// create and flushed on reconnect. Never inserts into content_items
  /// directly.
  Future<Link> saveNewUrl(
    String url, {
    String? folderId,
    Link? localPreview,
  }) async {
    final placeholder = (localPreview ?? _bareLink(url)).copyWith(
      status: ItemStatus.pending,
      pendingOp: PendingOp.create,
      folderRemoteIds: folderId != null ? [folderId] : null,
    );
    final saved = await local.put(placeholder);
    try {
      final result = await remote.saveUrl(url, folderId: folderId);
      return local.put(saved.copyWith(
        remoteId: result.remoteId,
        status: result.status,
        pendingOp: PendingOp.none,
      ));
    } catch (e) {
      debugPrint('SyncService: saveNewUrl queued offline for $url: $e');
      return saved;
    }
  }

  /// Apply an edit locally and queue it for push, then try to flush.
  Future<Link> updateLink(Link link) async {
    final queued = await local.put(link.copyWith(
      pendingOp:
          link.pendingOp == PendingOp.create ? PendingOp.create : PendingOp.update,
      updatedAt: DateTime.now().toUtc(),
    ));
    await push();
    return (await local.getByRemoteId(queued.remoteId ?? '')) ?? queued;
  }

  /// Delete locally right away (optimistic) by queueing a pending delete,
  /// then try to flush. Offline deletes stay queued.
  Future<void> deleteLink(Link link) async {
    if (link.remoteId == null) {
      // Never synced: nothing to tell the server.
      if (link.id != null) await local.deleteLocal(link.id!);
      return;
    }
    await local.put(link.copyWith(pendingOp: PendingOp.delete));
    await push();
  }

  Link _bareLink(String url) {
    final host = Uri.tryParse(url)?.host;
    return Link(
      url: url,
      title: (host == null || host.isEmpty) ? url : host,
      platform: PlatformDetectionService().detectPlatform(url),
      createdAt: DateTime.now(),
    );
  }
}
