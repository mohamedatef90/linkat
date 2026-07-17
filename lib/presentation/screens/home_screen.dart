import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/datasources/remote/supabase_datasource.dart';
import '../../domain/entities/platform_type.dart';
import '../../domain/entities/link.dart';
import '../../services/pending_links_service.dart';
import '../providers/auth_providers.dart';
import '../providers/link_providers.dart';
import '../providers/sync_providers.dart';
import '../theme/notion_theme.dart';
import '../widgets/status_chip.dart';
import '../widgets/magic/magic.dart';
import 'folder_items_screen.dart';
import 'manage_folders_screen.dart';
import 'tags_screen.dart';
import 'topics_screen.dart';
import 'link_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Link>? _searchResults;
  bool _isSearchLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForShareIntents();
    _checkPendingLinks();
    // Kick off sync (pull + flush queued ops) and subscribe to Realtime.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncControllerProvider).start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingLinks();
      ref.read(syncControllerProvider).syncNow();
    }
  }

  /// Links saved from the iOS share extension while the app was closed are
  /// parked in shared UserDefaults; forward them to save-item.
  Future<void> _checkPendingLinks() async {
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final pendingLinks = await PendingLinksService.getPendingLinks();
      if (pendingLinks.isEmpty) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving shared link...'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }

      final controller = ref.read(syncControllerProvider);
      for (final pending in pendingLinks) {
        await controller.saveUrl(pending.url, fallbackTitle: pending.title);
      }
      await PendingLinksService.clearPendingLinks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pendingLinks.length == 1
                  ? 'Link saved — processing in the background'
                  : '${pendingLinks.length} links saved',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling pending links: $e');
    }
  }

  void _listenForShareIntents() {
    ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty && value.first.path.isNotEmpty) {
          _handleSharedContent(value.first.path);
          ReceiveSharingIntent.instance.reset();
        }
      },
      onError: (err) {
        debugPrint('getIntentDataStream error: $err');
      },
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      ReceiveSharingIntent.instance.getInitialMedia().then((
        List<SharedMediaFile> value,
      ) {
        if (value.isNotEmpty && value.first.path.isNotEmpty) {
          _handleSharedContent(value.first.path);
          ReceiveSharingIntent.instance.reset();
        }
      });
    });
  }

  /// Shared URLs save straight to save-item — no extra taps.
  Future<void> _handleSharedContent(String sharedText) async {
    final cleanedText = sharedText.trim();
    String? urlToSave;

    final uri = Uri.tryParse(cleanedText);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      urlToSave = cleanedText;
    } else {
      final match = RegExp(r'https?://[^\s]+', caseSensitive: false)
          .firstMatch(cleanedText);
      urlToSave = match?.group(0);
    }
    if (urlToSave == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving shared link...'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
    try {
      await ref.read(syncControllerProvider).saveUrl(urlToSave);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link saved — processing in the background'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving shared link: $e');
    }
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
      final repository = ref.read(linkRepositoryProvider);
      final results = await repository.searchLinks(query.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearchLoading = false;
        });
      }
    } catch (e) {
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

  bool _syncingAll = false;

  /// "Sync all links": uploads every local link that never reached the
  /// database (old links saved before sync existed), then does a full sync.
  Future<void> _syncAllLinks() async {
    if (_syncingAll) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync all links?'),
        content: const Text(
            'Uploads any links on this device that are missing from your '
            'cloud vault, then refreshes everything.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sync All'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _syncingAll = true);
    try {
      final queued =
          await ref.read(syncControllerProvider).syncAllLinks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(queued == 0
              ? 'All links are already in your cloud vault.'
              : 'Uploaded $queued link${queued == 1 ? '' : 's'} to your vault.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _syncingAll = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content:
            const Text('Your saved links stay in your account in the cloud.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(supabaseClientProvider).auth.signOut();
    if (mounted) context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor =
        isDarkMode ? NotionTheme.darkTextPrimary : NotionTheme.primaryBlack;
    final subtextColor =
        isDarkMode ? NotionTheme.darkTextSecondary : NotionTheme.textGray;
    final borderColor =
        isDarkMode ? NotionTheme.darkDivider : NotionTheme.dividerColor;
    final itemBackgroundColor =
        isDarkMode ? NotionTheme.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: NotionTheme.ink,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'RefVault',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rss_feed, color: NotionTheme.fog2),
            onPressed: () => context.push('/feeds'),
            tooltip: 'Feeds',
          ),
          IconButton(
            icon: _syncingAll
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: NotionTheme.fog2),
                  )
                : const Icon(Icons.cloud_upload_outlined,
                    color: NotionTheme.fog2),
            onPressed: _syncAllLinks,
            tooltip: 'Sync all links to database',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: NotionTheme.fog2),
            onPressed: _signOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: AuraBackground(
        child: RefreshIndicator(
        onRefresh: () => ref.read(syncControllerProvider).syncNow(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + kToolbarHeight + 8,
              16,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.dashboard_outlined, size: 28, color: textColor),
                    const SizedBox(width: 12),
                    Text('Dashboard', style: theme.textTheme.displayMedium),
                  ],
                ),
                const SizedBox(height: 24),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: NotionTheme.panel.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NotionTheme.borderSoft),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search your links...',
                      hintStyle: TextStyle(
                        color: subtextColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      prefixIcon: _isSearchLoading
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.primaryColor,
                                ),
                              ),
                            )
                          : Icon(Icons.search, color: subtextColor),
                      suffixIcon: _isSearching
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 20,
                                color: subtextColor,
                              ),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: _performSearch,
                    textInputAction: TextInputAction.search,
                  ),
                ),

                // Search Results
                if (_isSearching) ...[
                  const SizedBox(height: 12),
                  if (_searchResults != null && _searchResults!.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: subtextColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No results found',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_searchResults != null)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final link = _searchResults![index];
                        return _SearchResultCard(
                          link: link,
                          isDarkMode: isDarkMode,
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  Divider(color: borderColor),
                ],

                const SizedBox(height: 24),

                const Eyebrow('Platforms'),
                const SizedBox(height: 12),

                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < PlatformType.values.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: borderColor),
                        Reveal(
                          delay: Duration(milliseconds: 40 * i),
                          child: _PlatformRow(
                            platform: PlatformType.values[i],
                            textColor: textColor,
                            subtextColor: subtextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                const Eyebrow('Browse'),
                const SizedBox(height: 12),

                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _BrowseRow(
                        icon: Icons.tag,
                        label: 'Browse by Tags',
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TagsScreen(),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: borderColor),
                      _BrowseRow(
                        icon: Icons.category,
                        label: 'Browse by Topics',
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TopicsScreen(),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: borderColor),
                      _BrowseRow(
                        icon: Icons.folder_outlined,
                        label: 'Manage Folders',
                        textColor: textColor,
                        subtextColor: subtextColor,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ManageFoldersScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _buildFoldersSection(
                  theme,
                  textColor,
                  subtextColor,
                  itemBackgroundColor,
                  borderColor,
                ),
              ],
            ),
          ),
        ),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFoldersSection(
    ThemeData theme,
    Color textColor,
    Color subtextColor,
    Color itemBackgroundColor,
    Color borderColor,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final foldersAsync = ref.watch(foldersProvider);

        return foldersAsync.when(
          data: (folders) {
            if (folders.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Eyebrow('Folders'),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ManageFoldersScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Manage',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < folders.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: borderColor),
                        _FolderRow(
                          folder: folders[i],
                          textColor: textColor,
                          subtextColor: subtextColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

}

class _BrowseRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color subtextColor;
  final VoidCallback onTap;

  const _BrowseRow({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.subtextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: subtextColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: textColor),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 20, color: subtextColor),
          ],
        ),
      ),
    );
  }
}

class _PlatformRow extends ConsumerWidget {
  final PlatformType platform;
  final Color textColor;
  final Color subtextColor;

  const _PlatformRow({
    required this.platform,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linksProvider(platform));

    return InkWell(
      onTap: () => context.push('/folder/${platform.name}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            FaIcon(
              _getIcon(platform),
              size: 20,
              color: _getIconColor(platform),
            ),
            const SizedBox(width: 12),
            Text(
              platform.displayName,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: textColor),
            ),
            const Spacer(),
            linksAsync.when(
              data: (links) => Text(
                '${links.length}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: subtextColor),
              ),
              loading: () => SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: subtextColor,
                ),
              ),
              error: (_, __) =>
                  Icon(Icons.error_outline, size: 14, color: subtextColor),
            ),
          ],
        ),
      ),
    );
  }

  FaIconData _getIcon(PlatformType platform) {
    switch (platform) {
      case PlatformType.facebook:
        return FontAwesomeIcons.facebook;
      case PlatformType.instagram:
        return FontAwesomeIcons.instagram;
      case PlatformType.twitter:
        return FontAwesomeIcons.xTwitter;
      case PlatformType.youtube:
        return FontAwesomeIcons.youtube;
      case PlatformType.linkedin:
        return FontAwesomeIcons.linkedin;
      case PlatformType.other:
        return FontAwesomeIcons.link;
    }
  }

  Color _getIconColor(PlatformType platform) {
    switch (platform) {
      case PlatformType.facebook:
        return const Color(0xFF1877F2);
      case PlatformType.instagram:
        return const Color(0xFFE4405F);
      case PlatformType.twitter:
        return NotionTheme.white; // X's black mark is invisible on navy
      case PlatformType.youtube:
        return const Color(0xFFFF0000);
      case PlatformType.linkedin:
        return const Color(0xFF3B82F6); // lifted for dark-bg contrast
      case PlatformType.other:
        return NotionTheme.fog2;
    }
  }
}

class _FolderRow extends ConsumerWidget {
  final RemoteFolder folder;
  final Color textColor;
  final Color subtextColor;

  const _FolderRow({
    required this.folder,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linksByFolderProvider(folder.id));

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FolderItemsScreen(folder: folder),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                folder.name,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: textColor),
              ),
            ),
            linksAsync.when(
              data: (links) => Text(
                '${links.length}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: subtextColor),
              ),
              loading: () => SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: subtextColor,
                ),
              ),
              error: (_, __) => Icon(
                Icons.error_outline,
                size: 14,
                color: subtextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Link link;
  final bool isDarkMode;

  const _SearchResultCard({required this.link, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        isDarkMode ? NotionTheme.darkDivider : NotionTheme.dividerColor;
    final itemBackgroundColor =
        isDarkMode ? NotionTheme.darkSurface : Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => LinkDetailScreen(link: link)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: itemBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: link.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: link.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color:
                              isDarkMode ? Colors.white12 : Colors.grey[100],
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color:
                              isDarkMode ? Colors.white12 : Colors.grey[100],
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: theme.textTheme.bodySmall?.color,
                            size: 20,
                          ),
                        ),
                      )
                    : Container(
                        color: isDarkMode ? Colors.white12 : Colors.grey[100],
                        child: Icon(
                          Icons.link,
                          color: theme.textTheme.bodySmall?.color,
                          size: 20,
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          link.topicLabel ?? link.topic.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        link.platform.displayName,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      StatusChip(link: link),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.textTheme.bodySmall?.color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
