import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/library_filter.dart';
import '../../domain/entities/link.dart';
import '../providers/auth_providers.dart';
import '../providers/library_providers.dart';
import '../providers/link_providers.dart';
import '../providers/sync_providers.dart';
import '../theme/notion_theme.dart';
import '../widgets/link_card.dart';
import '../widgets/magic/magic.dart';

/// The daily briefing home — Vault Hub. Mirrors the web home: greeting +
/// stat tiles, Priority Vault (pinned), then capped briefing sections that
/// bridge into the Library.
class VaultHubScreen extends ConsumerStatefulWidget {
  const VaultHubScreen({super.key});

  @override
  ConsumerState<VaultHubScreen> createState() => _VaultHubScreenState();
}

class _VaultHubScreenState extends ConsumerState<VaultHubScreen> {
  final _searchController = TextEditingController();
  List<Link>? _searchResults;
  bool _isSearching = false;
  bool _isSearchLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearchLoading = true;
      _isSearching = true;
    });
    try {
      final results =
          await ref.read(linkRepositoryProvider).searchLinks(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearchLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearchLoading = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = null;
      _isSearching = false;
    });
  }

  /// Set the one-shot Library filter, then switch to the Library tab.
  void _openLibrary({String kind = 'content', String? status}) {
    ref.read(libraryEntryProvider.notifier).state = LibraryFilter(
      kind: kind,
      readStatuses: status != null ? {status} : {},
    );
    context.go('/library');
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Working late';
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Winding down';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = ref.watch(currentUserProvider)?.email ?? 'your vault';

    return Scaffold(
      backgroundColor: NotionTheme.ink,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Qlip',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: AuraBackground(
        child: RefreshIndicator(
          onRefresh: () => ref.read(syncControllerProvider).syncNow(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              16,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(email),
                const SizedBox(height: 8),
                Text(_greeting(), style: theme.textTheme.displaySmall),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: NotionTheme.fog2),
                ),
                const SizedBox(height: 20),
                _searchBar(theme),
                if (_isSearching)
                  _searchResultsSection(theme)
                else
                  _briefing(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: NotionTheme.panel.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NotionTheme.borderSoft),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: NotionTheme.white),
        decoration: InputDecoration(
          hintText: 'Search your vault…',
          hintStyle: const TextStyle(color: NotionTheme.fog2, fontSize: 14),
          prefixIcon: _isSearchLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: NotionTheme.lime),
                  ),
                )
              : const Icon(Icons.search, color: NotionTheme.fog2),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.close,
                      size: 20, color: NotionTheme.fog2),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: _performSearch,
      ),
    );
  }

  Widget _searchResultsSection(ThemeData theme) {
    final results = _searchResults;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: (results == null)
          ? const SizedBox.shrink()
          : results.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text('No results found',
                        style: theme.textTheme.bodyMedium),
                  ),
                )
              : Column(
                  children: [
                    for (final link in results)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LinkCard(link: link),
                      ),
                  ],
                ),
    );
  }

  Widget _briefing(ThemeData theme) {
    final counts = ref.watch(vaultCountsProvider);
    final pinned = ref.watch(pinnedLinksProvider).valueOrNull ?? const [];
    final phone = ref.watch(mobileLinksProvider).valueOrNull ?? const [];
    final continueReading =
        ref.watch(continueReadingProvider).valueOrNull ?? const [];
    final picks = ref.watch(dailyPicksProvider).valueOrNull ?? const [];
    final fresh = ref.watch(latestContentProvider).valueOrNull ?? const [];
    final bookmarks = ref.watch(latestBookmarksProvider).valueOrNull ?? const [];
    final phoneShown = phone.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        // Stat tiles
        counts.when(
          data: (c) => Row(
            children: [
              _statTile('Bookmarks', c.bookmarks,
                  () => _openLibrary(kind: 'bookmark')),
              const SizedBox(width: 10),
              _statTile('Library', c.content, () => _openLibrary()),
              const SizedBox(width: 10),
              _statTile('Unread', c.unread,
                  () => _openLibrary(status: 'unread')),
            ],
          ),
          loading: () => const SizedBox(height: 92),
          error: (_, _) => const SizedBox.shrink(),
        ),

        if (pinned.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Eyebrow('Priority vault'),
          const SizedBox(height: 12),
          _pinnedGrid(pinned),
        ],

        // Order requested: From your phone → Recently → Continue reading.
        if (phoneShown.isNotEmpty)
          _section(
            'From your phone',
            phoneShown,
            onViewAll: () => _openLibrary(kind: 'mobile'),
          ),

        if (bookmarks.isNotEmpty)
          _section(
            'Recently bookmarked',
            bookmarks,
            onViewAll: () => _openLibrary(kind: 'bookmark'),
          ),

        if (continueReading.isNotEmpty)
          _section(
            'Continue reading',
            continueReading,
            onViewAll: () => _openLibrary(status: 'reading'),
          ),

        if (picks.isNotEmpty)
          _section("Today's picks", picks),

        if (fresh.isNotEmpty)
          _section(
            'Fresh in your library',
            fresh,
            onViewAll: () => _openLibrary(),
          ),

        if (pinned.isEmpty &&
            phoneShown.isEmpty &&
            continueReading.isEmpty &&
            fresh.isEmpty &&
            bookmarks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
              child: Text('Save your first link to get started',
                  style: theme.textTheme.bodyMedium),
            ),
          ),
      ],
    );
  }

  Widget _statTile(String label, int value, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: NotionTheme.panel.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NotionTheme.borderSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CountUp(
                value,
                style: const TextStyle(
                  color: NotionTheme.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: NotionTheme.fog2,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pinnedGrid(List<Link> pinned) {
    final shown = pinned.take(9).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: shown.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.6,
      ),
      itemBuilder: (_, i) => _pinnedTile(shown[i]),
    );
  }

  Widget _pinnedTile(Link link) {
    final host = Uri.tryParse(link.url)?.host ?? '';
    final favicon = (link.faviconUrl != null && link.faviconUrl!.isNotEmpty)
        ? link.faviconUrl!
        : (host.isEmpty
            ? null
            : 'https://www.google.com/s2/favicons?domain=$host&sz=64');
    return GestureDetector(
      onTap: () async {
        final uri = Uri.tryParse(link.url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: NotionTheme.panel.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NotionTheme.borderSoft),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: favicon != null
                  ? CachedNetworkImage(
                      imageUrl: favicon,
                      errorWidget: (_, _, _) => const Icon(Icons.link,
                          size: 16, color: NotionTheme.fog2),
                    )
                  : const Icon(Icons.link, size: 16, color: NotionTheme.fog2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                link.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: NotionTheme.fog,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Link> links, {VoidCallback? onViewAll}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Row(
          children: [
            Eyebrow(title),
            const Spacer(),
            if (onViewAll != null)
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: NotionTheme.lime,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < links.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Reveal(
              delay: Duration(milliseconds: 24 * i),
              child: LinkCard(link: links[i]),
            ),
          ),
      ],
    );
  }
}
