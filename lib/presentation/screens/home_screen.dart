import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/platform_type.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/custom_category.dart';
import '../../services/pending_links_service.dart';
import '../providers/link_providers.dart';
import '../theme/notion_theme.dart';
import '../providers/theme_provider.dart';
import 'tags_screen.dart';
import 'topics_screen.dart';
import 'link_detail_screen.dart';
import 'manage_categories_screen.dart';
import 'category_detail_screen.dart';

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

      // Fetch metadata from the URL
      Map<String, String?> metadata = {
        'title': null,
        'description': null,
        'image': null,
        'publisher': null,
      };

      try {
        final fetchedMetadata = await metadataService.fetchMetadata(
          pending.url,
        );
        metadata = fetchedMetadata;
      } catch (e) {
        // Use fallback on error
      }

      // Use fetched title, or pending title if available, or URL as last resort
      if (metadata['title'] == null || metadata['title']!.isEmpty) {
        if (pending.title.isNotEmpty) {
          metadata['title'] = pending.title;
        } else {
          // Extract domain as fallback title
          final uri = Uri.tryParse(pending.url);
          metadata['title'] = uri?.host ?? pending.url;
        }
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

      // Detect content type from URL and metadata
      final contentTypeService = ref.read(contentTypeDetectionServiceProvider);
      final contentType = contentTypeService.detectContentType(
        pending.url,
        platform,
        metadata['contentType'],
      );

      final link = Link(
        url: pending.url,
        title: metadata['title'] ?? pending.title,
        description: metadata['description'],
        imageUrl: metadata['image'],
        publisherName: metadata['publisher'],
        aiDescription: aiDescription,
        platform: platform,
        topic: topic,
        contentType: contentType,
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
      final urlRegExp = RegExp(r'https?://[^\s]+', caseSensitive: false);
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
    final theme = Theme.of(context);
    // Use actual theme brightness instead of just the provider state
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? NotionTheme.darkTextPrimary : NotionTheme.primaryBlack;
    final subtextColor = isDarkMode ? NotionTheme.darkTextSecondary : NotionTheme.textGray;
    final borderColor = isDarkMode
        ? NotionTheme.darkDivider
        : NotionTheme.dividerColor;
    final itemBackgroundColor = isDarkMode
        ? NotionTheme.darkSurface
        : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Linkat',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _getThemeIcon(ref.watch(themeModeProvider)),
              color: textColor,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            tooltip: _getThemeTooltip(ref.watch(themeModeProvider)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
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
                  color: itemBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _searchExplanation!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
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

              Text(
                'PLATFORMS',
                style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),

              // Platform List
              Container(
                decoration: BoxDecoration(
                  color: itemBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: PlatformType.values.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final platform = PlatformType.values[index];
                    return _PlatformRow(
                      platform: platform,
                      textColor: textColor,
                      subtextColor: subtextColor,
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'BROWSE',
                style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),

              // Browse Section
              Container(
                decoration: BoxDecoration(
                  color: itemBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tag, size: 20, color: subtextColor),
                            const SizedBox(width: 12),
                            Text(
                              'Browse by Tags',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: textColor,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: subtextColor,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Divider(height: 1, color: borderColor),

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
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.category, size: 20, color: subtextColor),
                            const SizedBox(width: 12),
                            Text(
                              'Browse by Topics',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: textColor,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: subtextColor,
                            ),
                          ],
                        ),
                      ),
                    ),

                    Divider(height: 1, color: borderColor),

                    // Manage Categories Row
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const ManageCategoriesScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.settings_outlined,
                              size: 20,
                              color: subtextColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Manage Categories',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: textColor,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: subtextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Custom Categories Section
              _buildCustomCategoriesSection(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add'),
        backgroundColor: theme.floatingActionButtonTheme.backgroundColor,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCustomCategoriesSection(
    ThemeData theme,
    Color textColor,
    Color subtextColor,
    Color itemBackgroundColor,
    Color borderColor,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final categoriesAsync = ref.watch(customCategoriesProvider);

        return categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Row(
                  children: [
                    Text(
                      'MY CATEGORIES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: subtextColor,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ManageCategoriesScreen(),
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
                Container(
                  decoration: BoxDecoration(
                    color: itemBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < categories.length; i++) ...[
                        if (i > 0) Divider(height: 1, color: borderColor),
                        _CategoryRow(
                          category: categories[i],
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

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeTooltip(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light mode (tap for dark)';
      case ThemeMode.dark:
        return 'Dark mode (tap for auto)';
      case ThemeMode.system:
        return 'Auto mode (tap for light)';
    }
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

class _CategoryRow extends ConsumerWidget {
  final CustomCategory category;
  final Color textColor;
  final Color subtextColor;

  const _CategoryRow({
    required this.category,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linksByCustomCategoryProvider(category.id!));
    final categoryColor = Color(category.colorValue);
    final categoryIcon = category.iconName != null
        ? IconData(int.parse(category.iconName!), fontFamily: 'MaterialIcons')
        : Icons.folder_outlined;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(category: category),
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
                color: categoryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                categoryIcon,
                size: 18,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: textColor,
                ),
              ),
            ),
            linksAsync.when(
              data: (links) => Text(
                '${links.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtextColor,
                ),
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
    final borderColor = isDarkMode
        ? NotionTheme.darkDivider
        : NotionTheme.dividerColor;
    final itemBackgroundColor = isDarkMode
        ? NotionTheme.darkSurface
        : Colors.white;

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
            // Thumbnail
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
                          color: isDarkMode ? Colors.white12 : Colors.grey[100],
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDarkMode ? Colors.white12 : Colors.grey[100],
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

            // Content
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
                          link.topic.displayName,
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
