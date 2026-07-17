import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/remote/supabase_datasource.dart';
import '../../domain/entities/link.dart';
import '../providers/sync_providers.dart';
import '../theme/notion_theme.dart';
import '../widgets/magic/magic.dart';
import 'reader_screen.dart';

/// Manage RSS/Atom subscriptions (add / sync / pause / remove) and browse the
/// fresh items ingested from them in the last 48 hours.
class FeedsScreen extends ConsumerStatefulWidget {
  const FeedsScreen({super.key});

  @override
  ConsumerState<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends ConsumerState<FeedsScreen> {
  final _input = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _syncingId;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  SupabaseDatasource get _remote => ref.read(supabaseDatasourceProvider);

  void _refresh() {
    ref.invalidate(feedsProvider);
    ref.invalidate(freshFeedItemsProvider);
  }

  Future<void> _add() async {
    final url = _input.text.trim();
    if (url.isEmpty || _busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      final found = await _remote.discoverFeed(url);
      if (found.isEmpty) {
        setState(() => _error = 'No RSS/Atom feed found at this URL.');
      } else if (found.length == 1) {
        await _subscribe(found.first);
      } else {
        final picked = await _pickCandidate(found);
        if (picked != null) await _subscribe(picked);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _subscribe(FeedCandidate candidate) async {
    // Candidates scraped from <link> tags may not be validated yet.
    var validated = candidate;
    if (!candidate.validated) {
      final found = await _remote.discoverFeed(candidate.feedUrl);
      final ok = found.where((c) => c.validated).firstOrNull;
      if (ok == null) throw Exception('That link is not a valid RSS/Atom feed.');
      validated = ok;
    }
    try {
      final feed = await _remote.subscribeFeed(validated);
      _input.clear();
      _refresh();
      // First fetch in the background, then refresh when it lands.
      _remote.syncFeed(feed.id).then((_) { if (mounted) _refresh(); }).catchError((_) {});
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        setState(() => _error = 'Already subscribed to this feed.');
      } else {
        rethrow;
      }
    }
  }

  Future<FeedCandidate?> _pickCandidate(List<FeedCandidate> candidates) {
    return showModalBottomSheet<FeedCandidate>(
      context: context,
      backgroundColor: NotionTheme.darkSurface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Pick a feed', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ...candidates.map((c) => ListTile(
                  leading: const Icon(Icons.rss_feed),
                  title: Text(c.title ?? 'Untitled feed', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(c.feedUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.of(context).pop(c),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _sync(String id) async {
    setState(() => _syncingId = id);
    try {
      await _remote.syncFeed(id);
    } catch (_) {} finally {
      if (mounted) setState(() => _syncingId = null);
      _refresh();
    }
  }

  Future<void> _confirmUnsubscribe(RemoteFeed feed) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unsubscribe?'),
        content: Text('Stop following ${feed.title ?? feed.feedUrl}? Items already saved stay in your vault.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Unsubscribe')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _remote.unsubscribeFeed(feed.id);
      _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtext = NotionTheme.darkTextSecondary;
    final feeds = ref.watch(feedsProvider);
    final fresh = ref.watch(freshFeedItemsProvider);

    return Scaffold(
      backgroundColor: NotionTheme.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Feeds', style: theme.textTheme.titleMedium),
      ),
      body: AuraBackground(
        child: RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Add a feed
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        hintText: 'Feed or site URL…',
                        prefixIcon: Icon(Icons.rss_feed, size: 18),
                      ),
                      onSubmitted: (_) => _add(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _busy ? null : _add,
                    child: _busy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Add'),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),

              // Your sources
              _sectionTitle(theme, Icons.tune, 'Your sources', subtext),
              const SizedBox(height: 8),
              feeds.when(
                data: (list) => list.isEmpty
                    ? _hint(theme, subtext, 'No subscriptions yet. Add a feed or site URL above.')
                    : Column(children: list.map((f) => _feedRow(theme, subtext, f)).toList()),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _hint(theme, subtext, 'Could not load feeds: $e'),
              ),
              const SizedBox(height: 28),

              // Fresh from your feeds (48h)
              _sectionTitle(theme, Icons.bolt, 'Fresh from your feeds · 48h', subtext),
              const SizedBox(height: 8),
              fresh.when(
                data: (items) => items.isEmpty
                    ? _hint(theme, subtext, 'Nothing new in the last 48 hours.')
                    : Column(children: items.map((l) => _itemRow(theme, subtext, l)).toList()),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _hint(theme, subtext, 'Could not load items: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedRow(ThemeData theme, Color subtext, RemoteFeed f) {
    final domain = () {
      try { return Uri.parse(f.siteUrl ?? f.feedUrl).host.replaceFirst('www.', ''); } catch (_) { return f.feedUrl; }
    }();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NotionTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NotionTheme.darkDivider),
      ),
      child: Opacity(
        opacity: f.isActive ? 1 : 0.5,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: f.faviconUrl != null
                  ? CachedNetworkImage(imageUrl: f.faviconUrl!, errorWidget: (_, __, ___) => const Icon(Icons.rss_feed, size: 18))
                  : const Icon(Icons.rss_feed, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.title ?? domain, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    f.isActive ? domain : (f.errorCount >= 10 ? '$domain · auto-disabled' : '$domain · paused'),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: subtext),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: _syncingId == f.id
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync, size: 20),
              tooltip: 'Sync now',
              onPressed: f.isActive && _syncingId == null ? () => _sync(f.id) : null,
            ),
            IconButton(
              icon: Icon(f.isActive ? Icons.pause : Icons.play_arrow, size: 20),
              tooltip: f.isActive ? 'Pause' : 'Resume',
              onPressed: () async {
                await _remote.setFeedActive(f.id, !f.isActive);
                _refresh();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Unsubscribe',
              onPressed: () => _confirmUnsubscribe(f),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemRow(ThemeData theme, Color subtext, Link link) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReaderScreen(link: link)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NotionTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NotionTheme.darkDivider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: link.imageUrl != null
                    ? CachedNetworkImage(imageUrl: link.imageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.article, size: 18))
                    : const Icon(Icons.article, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(link.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (link.summary != null && link.summary!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(link.summary!, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: subtext)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(title, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _hint(ThemeData theme, Color color, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color)),
      );
}
