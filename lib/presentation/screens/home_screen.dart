import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/entities/platform_type.dart';
import '../../domain/entities/link.dart';
import '../../services/pending_links_service.dart';
import '../providers/link_providers.dart';
import '../theme/notion_theme.dart';
import 'tags_screen.dart';
import 'topics_screen.dart';
import 'link_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Link>? _searchResults;
  String? _searchExplanation;
  bool _isSearchLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForShareIntents();
    _checkPendingLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Check for pending links when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed - checking for pending links');
      _checkPendingLinks();
    }
  }

  /// Check for pending links saved from share extension
  Future<void> _checkPendingLinks() async {
    // Small delay to ensure app is fully loaded
    await Future.delayed(const Duration(milliseconds: 300));

    debugPrint('HomeScreen: Starting pending links check...');

    try {
      final pendingLinks = await PendingLinksService.getPendingLinks();

      debugPrint('HomeScreen: Got ${pendingLinks.length} pending links');

      if (pendingLinks.isNotEmpty) {
        // Show processing indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Processing shared link...'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }

        // Process each pending link
        for (final pending in pendingLinks) {
          debugPrint('HomeScreen: Processing link: ${pending.url}');
          await _processPendingLink(pending);
        }

        // Clear pending links after processing
        await PendingLinksService.clearPendingLinks();

        // Refresh the links list
        if (mounted) {
          ref.invalidate(allLinksProvider);
          ref.invalidate(linksProvider);

          // Invalidate all platform providers
          for (final platform in PlatformType.values) {
            ref.invalidate(linksProvider(platform));
          }

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                pendingLinks.length == 1
                    ? 'Link saved successfully!'
                    : '${pendingLinks.length} links saved successfully!',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error checking pending links: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _processPendingLink(PendingLink pending) async {
    try {
      final platformService = ref.read(platformDetectionServiceProvider);
      final metadataService = ref.read(metadataServiceProvider);
      final aiService = ref.read(aiDescriptionServiceProvider);
      final aiClassificationService = ref.read(aiClassificationServiceProvider);
      final topicService = ref.read(topicClassificationServiceProvider);
      final saveLink = ref.read(saveLinkUseCaseProvider);

      final platform = platformService.detectPlatform(pending.url);

      // Try to fetch additional metadata
      Map<String, String?> metadata = {
        'title': pending.title,
        'description': null,
        'image': null,
        'publisher': null,
      };

      try {
        final fetchedMetadata = await metadataService.fetchMetadata(pending.url);
        // Only override title if fetched one is better
        if (fetchedMetadata['title'] != null &&
            fetchedMetadata['title']!.isNotEmpty &&
            !pending.title.startsWith('Link from ')) {
          metadata = fetchedMetadata;
          metadata['title'] = pending.title; // Keep user's title
        } else {
          metadata = fetchedMetadata;
          if (metadata['title'] == null || metadata['title']!.isEmpty) {
            metadata['title'] = pending.title;
          }
        }
      } catch (e) {
        // Use pending link data as fallback
      }

      // Classify topic
      var topic = topicService.classifyContent(
        title: metadata['title'] ?? pending.url,
        description: metadata['description'],
      );
      List<String> tags = [];

      // Use AI to classify and generate tags
      try {
        final aiClassification = await aiClassificationService.classifyContent(
          url: pending.url,
          title: metadata['title'],
          description: metadata['description'],
        );

        if (aiClassification != null) {
          topic = aiClassification.category;
          tags = aiClassification.tags;
        }
      } catch (e) {
        // Use keyword-based classification as fallback
      }

      // Generate AI description
      String? aiDescription;
      try {
        aiDescription = await aiService.generateDescription(
          url: pending.url,
          title: metadata['title'],
          existingDescription: metadata['description'],
        );
      } catch (e) {
        // Skip AI description on error
      }

      final link = Link(
        url: pending.url,
        title: metadata['title'] ?? pending.title,
        description: metadata['description'],
        imageUrl: metadata['image'],
        publisherName: metadata['publisher'],
        aiDescription: aiDescription,
        platform: platform,
        topic: topic,
        tags: tags,
        createdAt: pending.createdAt,
      );

      await saveLink(link);
    } catch (e) {
      debugPrint('Error processing pending link: $e');
    }
  }

  Future<void> _performAiSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _searchExplanation = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearchLoading = true;
      _isSearching = true;
    });

    try {
      final aiSearchService = ref.read(aiSearchServiceProvider);
      final allLinks = await ref.read(allLinksProvider.future);

      final result = await aiSearchService.smartSearch(
        query: query,
        allLinks: allLinks,
      );

      if (mounted) {
        setState(() {
          _searchResults = result.results;
          _searchExplanation = result.explanation;
          _isSearchLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _searchExplanation = 'Search failed';
          _isSearchLoading = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = null;
      _searchExplanation = null;
      _isSearching = false;
    });
  }

  void _listenForShareIntents() {
    // Listen for shared content when app is already running
    ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty && value.first.path.isNotEmpty) {
          _handleSharedContent(value.first.path);
          // Reset after handling
          ReceiveSharingIntent.instance.reset();
        }
      },
      onError: (err) {
        debugPrint("getIntentDataStream error: $err");
      },
    );

    // Check for initial shared content (when app was opened via share)
    // Use a small delay to ensure the widget is fully mounted
    Future.delayed(const Duration(milliseconds: 500), () {
      ReceiveSharingIntent.instance.getInitialMedia().then((
        List<SharedMediaFile> value,
      ) {
        if (value.isNotEmpty && value.first.path.isNotEmpty) {
          _handleSharedContent(value.first.path);
          // Reset after handling
          ReceiveSharingIntent.instance.reset();
        }
      });
    });
  }

  void _handleSharedContent(String sharedText) {
    // Clean up the shared text
    final cleanedText = sharedText.trim();

    // Try to extract URL from shared content
    String? urlToSave;

    // Check if the entire text is a URL
    final uri = Uri.tryParse(cleanedText);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      urlToSave = cleanedText;
    } else {
      // Try to find a URL within the text
      final urlRegExp = RegExp(
        r'https?://[^\s]+',
        caseSensitive: false,
      );
      final match = urlRegExp.firstMatch(cleanedText);
      if (match != null) {
        urlToSave = match.group(0);
      }
    }

    if (urlToSave != null && mounted) {
      // Navigate to add screen with the URL
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.push('/add?url=${Uri.encodeComponent(urlToSave!)}');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Linkat')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              Row(
                children: [
                  const Icon(Icons.dashboard_outlined, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // AI Search Bar
              Container(
                decoration: BoxDecoration(
                  color: NotionTheme.backgroundOffWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: NotionTheme.dividerColor),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'AI Search: try "AI articles" or "design tools"',
                    hintStyle: TextStyle(
                      color: NotionTheme.textGray.withAlpha(128),
                      fontSize: 14,
                    ),
                    prefixIcon: _isSearchLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF9333EA),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF9333EA),
                          ),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: _performAiSearch,
                  textInputAction: TextInputAction.search,
                ),
              ),

              // Search Results
              if (_isSearching) ...[
                const SizedBox(height: 16),
                if (_searchExplanation != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Color(0xFF9333EA),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _searchExplanation!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9333EA),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                if (_searchResults != null && _searchResults!.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: NotionTheme.textGray.withAlpha(128),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No results found',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: NotionTheme.textGray,
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
                      return _SearchResultCard(link: link);
                    },
                  ),
                const SizedBox(height: 16),
                const Divider(color: NotionTheme.dividerColor),
              ],

              const SizedBox(height: 24),

              Text('PLATFORMS', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),

              // Platform List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: PlatformType.values.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: NotionTheme.dividerColor,
                ),
                itemBuilder: (context, index) {
                  final platform = PlatformType.values[index];
                  return _PlatformRow(platform: platform);
                },
              ),

              const SizedBox(height: 32),

              Text('BROWSE', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 8),

              // Tags Row
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TagsScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.tag, size: 20, color: NotionTheme.textGray),
                      const SizedBox(width: 12),
                      Text(
                        'Browse by Tags',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: NotionTheme.dividerColor,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: NotionTheme.textGray,
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 1, color: NotionTheme.dividerColor),

              // Topics Row
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TopicsScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.category, size: 20, color: NotionTheme.textGray),
                      const SizedBox(width: 12),
                      Text(
                        'Browse by Topics',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: NotionTheme.dividerColor,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: NotionTheme.textGray,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        backgroundColor: NotionTheme.primaryBlack,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PlatformRow extends ConsumerWidget {
  final PlatformType platform;

  const _PlatformRow({required this.platform});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linksProvider(platform));

    return InkWell(
      onTap: () => context.push('/folder/${platform.name}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                decoration: TextDecoration.underline,
                decorationColor: NotionTheme.dividerColor,
              ),
            ),
            const Spacer(),
            linksAsync.when(
              data: (links) => Text(
                '${links.length}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: NotionTheme.textGray),
              ),
              loading: () => const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1),
              ),
              error: (_, __) => const Icon(Icons.error_outline, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(PlatformType platform) {
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
        return const Color(0xFF000000);
      case PlatformType.youtube:
        return const Color(0xFFFF0000);
      case PlatformType.linkedin:
        return const Color(0xFF0A66C2);
      case PlatformType.other:
        return NotionTheme.textGray;
    }
  }
}

class _SearchResultCard extends StatelessWidget {
  final Link link;

  const _SearchResultCard({required this.link});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LinkDetailScreen(link: link),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NotionTheme.backgroundOffWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NotionTheme.dividerColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (link.imageUrl != null)
              Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  image: DecorationImage(
                    image: NetworkImage(link.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: NotionTheme.sidebarColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.link,
                  color: NotionTheme.textGray,
                  size: 20,
                ),
              ),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9333EA).withAlpha(26),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          link.topic.displayName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF9333EA),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        link.platform.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: NotionTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: NotionTheme.textGray,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
