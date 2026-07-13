import 'package:flutter_test/flutter_test.dart';
import 'package:linkat/data/services/sync_service.dart';
import 'package:linkat/domain/entities/link.dart';
import 'package:linkat/domain/entities/platform_type.dart';
import 'package:linkat/domain/entities/sync_types.dart';

class FakeLocalStore implements SyncLocalStore {
  final Map<int, Link> rows = {};
  int _nextId = 1;
  DateTime? lastSyncAt;

  @override
  Future<Link?> getByRemoteId(String remoteId) async {
    for (final link in rows.values) {
      if (link.remoteId == remoteId) return link;
    }
    return null;
  }

  @override
  Future<List<Link>> getAllSynced() async =>
      rows.values.where((l) => l.remoteId != null).toList();

  @override
  Future<List<Link>> getPendingOps() async =>
      rows.values.where((l) => l.pendingOp != PendingOp.none).toList();

  @override
  Future<Link> put(Link link) async {
    final id = link.id ?? _nextId++;
    final saved = link.copyWith(id: id);
    rows[id] = saved;
    return saved;
  }

  @override
  Future<void> deleteLocal(int id) async => rows.remove(id);

  @override
  Future<DateTime?> getLastSyncAt() async => lastSyncAt;

  @override
  Future<void> setLastSyncAt(DateTime value) async => lastSyncAt = value;
}

class FakeRemoteStore implements SyncRemoteStore {
  bool online = true;
  List<Link> serverItems = [];
  DateTime? lastFetchSince;

  final List<String> savedUrls = [];
  final Map<String, Map<String, dynamic>> updates = {};
  final List<String> deletes = [];
  SaveUrlResult Function(String url)? onSaveUrl;

  void _requireOnline() {
    if (!online) throw Exception('offline');
  }

  @override
  Future<List<Link>> fetchItemsSince(DateTime? since) async {
    _requireOnline();
    lastFetchSince = since;
    if (since == null) return List.of(serverItems);
    return serverItems
        .where((i) =>
            i.updatedAt != null &&
            (i.updatedAt!.isAfter(since) ||
                i.updatedAt!.isAtSameMomentAs(since)))
        .toList();
  }

  @override
  Future<Set<String>> fetchAllItemIds() async {
    _requireOnline();
    return serverItems.map((i) => i.remoteId!).toSet();
  }

  @override
  Future<SaveUrlResult> saveUrl(String url, {String? folderId}) async {
    _requireOnline();
    savedUrls.add(url);
    final result = onSaveUrl != null
        ? onSaveUrl!(url)
        : SaveUrlResult(
            remoteId: 'remote-${savedUrls.length}',
            duplicate: false,
            status: ItemStatus.pending,
          );
    // Mirror the real backend: save-item inserts the row server-side.
    if (!result.duplicate) {
      serverItems.add(makeLink(
        url: url,
        remoteId: result.remoteId,
        status: result.status,
        updatedAt: DateTime.utc(2026, 7, 10),
      ));
    }
    return result;
  }

  @override
  Future<void> updateItem(String remoteId, Map<String, dynamic> fields) async {
    _requireOnline();
    updates[remoteId] = fields;
  }

  @override
  Future<void> deleteItem(String remoteId) async {
    _requireOnline();
    deletes.add(remoteId);
    serverItems.removeWhere((i) => i.remoteId == remoteId);
  }
}

Link makeLink({
  int? id,
  String url = 'https://example.com/a',
  String title = 'A',
  String? remoteId,
  PendingOp pendingOp = PendingOp.none,
  DateTime? updatedAt,
  ItemStatus status = ItemStatus.ready,
  bool isStarred = false,
}) {
  return Link(
    id: id,
    url: url,
    title: title,
    platform: PlatformType.other,
    createdAt: DateTime.utc(2026, 1, 1),
    remoteId: remoteId,
    pendingOp: pendingOp,
    updatedAt: updatedAt,
    status: status,
    isStarred: isStarred,
  );
}

void main() {
  late FakeLocalStore local;
  late FakeRemoteStore remote;
  late SyncService sync;

  setUp(() {
    local = FakeLocalStore();
    remote = FakeRemoteStore();
    sync = SyncService(remote: remote, local: local);
  });

  group('push — pendingOp transitions', () {
    test('create goes through save-item, stores remoteId, clears op',
        () async {
      await local.put(makeLink(pendingOp: PendingOp.create));

      await sync.push();

      expect(remote.savedUrls, ['https://example.com/a']);
      final row = local.rows.values.single;
      expect(row.remoteId, 'remote-1');
      expect(row.pendingOp, PendingOp.none);
      expect(row.status, ItemStatus.pending);
    });

    test('create with duplicate response adopts the existing remote id',
        () async {
      remote.onSaveUrl = (_) => const SaveUrlResult(
            remoteId: 'existing-id',
            duplicate: true,
            status: ItemStatus.ready,
          );
      await local.put(makeLink(pendingOp: PendingOp.create));

      await sync.push();

      final row = local.rows.values.single;
      expect(row.remoteId, 'existing-id');
      expect(row.pendingOp, PendingOp.none);
    });

    test('create while offline keeps the op queued', () async {
      remote.online = false;
      await local.put(makeLink(pendingOp: PendingOp.create));

      await sync.push();

      expect(local.rows.values.single.pendingOp, PendingOp.create);
      expect(local.rows.values.single.remoteId, isNull);
    });

    test('update pushes only the whitelisted fields and clears op', () async {
      await local.put(makeLink(
        remoteId: 'r1',
        pendingOp: PendingOp.update,
        isStarred: true,
        title: 'Edited',
      ));

      await sync.push();

      expect(remote.updates['r1'], {
        'title': 'Edited',
        'is_pinned': false,
        'is_starred': true,
        'read_status': 'unread',
      });
      expect(local.rows.values.single.pendingOp, PendingOp.none);
    });

    test('update without a remoteId falls back to create', () async {
      await local.put(makeLink(pendingOp: PendingOp.update));

      await sync.push();

      expect(remote.savedUrls, ['https://example.com/a']);
      expect(remote.updates, isEmpty);
      final row = local.rows.values.single;
      expect(row.remoteId, 'remote-1');
      expect(row.pendingOp, PendingOp.none);
    });

    test('delete removes remotely then locally', () async {
      remote.serverItems = [makeLink(remoteId: 'r1')];
      await local.put(makeLink(remoteId: 'r1', pendingOp: PendingOp.delete));

      await sync.push();

      expect(remote.deletes, ['r1']);
      expect(local.rows, isEmpty);
    });

    test('delete of a never-synced row is local-only', () async {
      await local.put(makeLink(pendingOp: PendingOp.delete));

      await sync.push();

      expect(remote.deletes, isEmpty);
      expect(local.rows, isEmpty);
    });

    test('delete while offline stays queued', () async {
      remote.online = false;
      await local.put(makeLink(remoteId: 'r1', pendingOp: PendingOp.delete));

      await sync.push();

      expect(local.rows.values.single.pendingOp, PendingOp.delete);
    });

    test('one failing op does not block the others', () async {
      remote.onSaveUrl = (url) {
        if (url.endsWith('/bad')) throw Exception('boom');
        return const SaveUrlResult(
            remoteId: 'ok-id', duplicate: false, status: ItemStatus.pending);
      };
      await local.put(
          makeLink(url: 'https://example.com/bad', pendingOp: PendingOp.create));
      await local.put(
          makeLink(url: 'https://example.com/ok', pendingOp: PendingOp.create));

      await sync.push();

      final byUrl = {for (final l in local.rows.values) l.url: l};
      expect(byUrl['https://example.com/bad']!.pendingOp, PendingOp.create);
      expect(byUrl['https://example.com/ok']!.pendingOp, PendingOp.none);
    });
  });

  group('pull — server wins', () {
    test('inserts new server items', () async {
      remote.serverItems = [
        makeLink(remoteId: 'r1', updatedAt: DateTime.utc(2026, 7, 1)),
      ];

      await sync.pull();

      expect(local.rows.values.single.remoteId, 'r1');
      expect(local.rows.values.single.pendingOp, PendingOp.none);
    });

    test('overwrites clean local rows, preserving the local Isar id',
        () async {
      final existing = await local.put(makeLink(
          remoteId: 'r1', title: 'Old local', isStarred: false));
      remote.serverItems = [
        makeLink(
          remoteId: 'r1',
          title: 'Server title',
          isStarred: true,
          updatedAt: DateTime.utc(2026, 7, 1),
        ),
      ];

      await sync.pull();

      final row = local.rows.values.single;
      expect(row.id, existing.id);
      expect(row.title, 'Server title');
      expect(row.isStarred, true);
    });

    test('leaves rows with unpushed local ops untouched', () async {
      await local.put(makeLink(
          remoteId: 'r1', title: 'Local edit', pendingOp: PendingOp.update));
      remote.serverItems = [
        makeLink(
            remoteId: 'r1',
            title: 'Server title',
            updatedAt: DateTime.utc(2026, 7, 1)),
      ];

      await sync.pull();

      expect(local.rows.values.single.title, 'Local edit');
      expect(local.rows.values.single.pendingOp, PendingOp.update);
    });

    test('prunes local rows deleted on the server, keeps pending and unsynced',
        () async {
      await local.put(makeLink(remoteId: 'gone'));
      await local.put(makeLink(
          remoteId: 'gone-but-pending', pendingOp: PendingOp.update));
      await local.put(makeLink(url: 'https://example.com/local-only'));
      remote.serverItems = [];

      await sync.pull();

      final remaining = local.rows.values.map((l) => l.remoteId).toList();
      expect(remaining, isNot(contains('gone')));
      expect(remaining, contains('gone-but-pending'));
      expect(local.rows.values.any((l) => l.remoteId == null), isTrue);
    });

    test('advances lastSyncAt to the newest updated_at and passes it back',
        () async {
      remote.serverItems = [
        makeLink(remoteId: 'r1', updatedAt: DateTime.utc(2026, 7, 1)),
        makeLink(remoteId: 'r2', updatedAt: DateTime.utc(2026, 7, 5)),
      ];

      await sync.pull();
      expect(local.lastSyncAt, DateTime.utc(2026, 7, 5));

      await sync.pull();
      expect(remote.lastFetchSince, DateTime.utc(2026, 7, 5));
    });

    test('keeps lastSyncAt when nothing changed', () async {
      local.lastSyncAt = DateTime.utc(2026, 6, 1);
      remote.serverItems = [];

      await sync.pull();

      expect(local.lastSyncAt, DateTime.utc(2026, 6, 1));
    });
  });

  group('saveNewUrl', () {
    test('online: placeholder gets its remoteId immediately, no direct insert',
        () async {
      final saved = await sync.saveNewUrl('https://example.com/new');

      expect(remote.savedUrls, ['https://example.com/new']);
      expect(saved.remoteId, 'remote-1');
      expect(saved.pendingOp, PendingOp.none);
      expect(saved.status, ItemStatus.pending);
      expect(local.rows.values.single.remoteId, 'remote-1');
    });

    test('offline: row parks as a pending create and flushes on reconnect',
        () async {
      remote.online = false;
      final saved = await sync.saveNewUrl('https://example.com/offline');

      expect(saved.pendingOp, PendingOp.create);
      expect(saved.remoteId, isNull);
      expect(saved.status, ItemStatus.pending);

      remote.online = true;
      await sync.sync();

      final row = local.rows.values.single;
      expect(row.remoteId, isNotNull);
      expect(row.pendingOp, PendingOp.none);
    });
  });

  group('sync() end-to-end', () {
    test('pushes before pulling so server-enriched state lands locally',
        () async {
      // Local starred edit queued while the server enriched the same item.
      await local.put(makeLink(
        remoteId: 'r1',
        isStarred: true,
        pendingOp: PendingOp.update,
      ));
      remote.serverItems = [
        makeLink(
          remoteId: 'r1',
          title: 'Enriched title',
          status: ItemStatus.ready,
          updatedAt: DateTime.utc(2026, 7, 1),
        ),
      ];

      await sync.sync();

      // Update was pushed…
      expect(remote.updates['r1']!['is_starred'], true);
      // …and the server row (server wins) overwrote local afterwards.
      final row = local.rows.values.single;
      expect(row.pendingOp, PendingOp.none);
      expect(row.title, 'Enriched title');
    });

    test('offline delete survives a failed sync and applies on the next one',
        () async {
      remote.serverItems = [
        makeLink(remoteId: 'r1', updatedAt: DateTime.utc(2026, 7, 1)),
      ];
      await local.put(makeLink(remoteId: 'r1', pendingOp: PendingOp.delete));

      remote.online = false;
      await sync.sync();
      expect(local.rows.values.single.pendingOp, PendingOp.delete);

      remote.online = true;
      await sync.sync();
      expect(remote.deletes, ['r1']);
      expect(local.rows, isEmpty);
    });
  });
}
