import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/entities/platform_type.dart';
import '../../domain/entities/topic_type.dart';
import '../../domain/entities/link.dart';
import '../../data/services/ai_search_service.dart';
import '../providers/link_providers.dart';
import '../theme/notion_theme.dart';
import 'link_detail_screen.dart';

class FolderDetailScreen extends ConsumerStatefulWidget {
  final String platformName;

  const FolderDetailScreen({super.key, required this.platformName});

  @override
  ConsumerState<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends ConsumerState<FolderDetailScreen> {
  TopicType? _selectedTopic;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _useAiSearch = true;
  bool _isAiSearching = false;
  List<Link>? _aiSearchResults;
  String? _aiSearchExplanation;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performAiSearch(List<Link> allLinks) async {
    if (_searchQuery.isEmpty || !_useAiSearch) {
      setState(() {
        _aiSearchResults = null;
        _aiSearchExplanation = null;
      });
      return;
    }

    final aiSearchService = ref.read(aiSearchServiceProvider);
    if (!aiSearchService.isAvailable) {
      return;
    }

    setState(() {
      _isAiSearching = true;
    });

    final result = await aiSearchService.smartSearch(
      query: _searchQuery,
      allLinks: allLinks,
    );

    if (mounted) {
      setState(() {
        _aiSearchResults = result.results;
        _aiSearchExplanation = result.explanation;
        _isAiSearching = false;
      });
    }
  }

  List<Link> _filterLinks(List<Link> links) {
    // If AI search has results, use them
    if (_aiSearchResults != null && _searchQuery.isNotEmpty && _useAiSearch) {
      var filtered = _aiSearchResults!;
      // Still apply topic filter on AI results
      if (_selectedTopic != null) {
        filtered = filtered.where((link) => link.topic == _selectedTopic).toList();
      }
      return filtered;
    }

    var filtered = links;

    // Filter by topic
    if (_selectedTopic != null) {
      filtered = filtered
          .where((link) => link.topic == _selectedTopic)
          .toList();
    }

    // Filter by search query (basic search)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((link) {
        return link.title.toLowerCase().contains(query) ||
            (link.description?.toLowerCase().contains(query) ?? false) ||
            (link.aiDescription?.toLowerCase().contains(query) ?? false) ||
            link.url.toLowerCase().contains(query) ||
            link.tags.any((tag) => tag.toLowerCase().contains(query)) ||
            link.topic.displayName.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  Widget _buildTopicChip(TopicType? topic, String label) {
    final isSelected = _selectedTopic == topic;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTopic = selected ? topic : null;
        });
      },
      backgroundColor: NotionTheme.backgroundOffWhite,
      selectedColor: NotionTheme.primaryBlack,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : NotionTheme.primaryBlack,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
          color: isSelected
              ? NotionTheme.primaryBlack
              : NotionTheme.dividerColor,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildLinkCard(
    BuildContext context,
    Link link,
    PlatformType platform,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LinkDetailScreen(link: link),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: NotionTheme.backgroundOffWhite,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: NotionTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                if (link.imageUrl != null)
                  Container(
                    width: 80,
                    height: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: NotionTheme.sidebarColor,
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: NetworkImage(link.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(color: NotionTheme.dividerColor),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 60,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: NotionTheme.sidebarColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: NotionTheme.dividerColor),
                    ),
                    child: const Icon(
                      Icons.link,
                      color: NotionTheme.textGray,
                      size: 24,
                    ),
                  ),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (link.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          link.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: NotionTheme.textGray,
                                fontSize: 13,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1, color: NotionTheme.dividerColor),

          // Actions Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Topic Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: NotionTheme.sidebarColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    link.topic.displayName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),

                // Share Button with Menu
                IconButton(
                  icon: const Icon(
                    Icons.share,
                    size: 18,
                    color: NotionTheme.textGray,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Share',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.copy,
                                color: NotionTheme.primaryBlack,
                              ),
                              title: const Text('Copy Link'),
                              onTap: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: link.url),
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Link copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.ios_share,
                                color: NotionTheme.primaryBlack,
                              ),
                              title: const Text('Share'),
                              onTap: () async {
                                Navigator.pop(context);

                                try {
                                  final box =
                                      context.findRenderObject() as RenderBox?;
                                  final sharePositionOrigin = box != null
                                      ? box.localToGlobal(Offset.zero) &
                                            box.size
                                      : const Rect.fromLTWH(0, 0, 1, 1);

                                  await Share.share(
                                    link.url,
                                    subject: link.title,
                                    sharePositionOrigin: sharePositionOrigin,
                                  );
                                } catch (e, st) {
                                  debugPrint('🔥 Share error: $e');
                                  debugPrint('$st');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to share link'),
                                        duration: Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),

                // Delete Action
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: NotionTheme.textGray,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete link',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              title: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: () {
                                ref.read(deleteLinkUseCaseProvider)(link.id!);
                                ref.invalidate(linksProvider(platform));
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),

                // Open Button
                InkWell(
                  onTap: () async {
                    // Sanitize URL to remove invisible characters
                    final cleanUrl = link.url.trim().replaceAll(
                      RegExp(r'[\u200B-\u200D\uFEFF\uFFFC]'),
                      '',
                    );
                    final uri = Uri.parse(cleanUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: NotionTheme.primaryBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: const [
                        Text(
                          'Open',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.open_in_new, size: 11, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platform = PlatformType.values.firstWhere(
      (e) => e.name == widget.platformName,
      orElse: () => PlatformType.other,
    );
    final linksAsync = ref.watch(linksProvider(platform));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            FaIcon(
              _getIcon(platform),
              size: 20,
              color: _getIconColor(platform),
            ),
            const SizedBox(width: 8),
            Text(platform.displayName),
          ],
        ),
        titleSpacing: 0,
      ),
      body: linksAsync.when(
        data: (links) => Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: NotionTheme.sidebarColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: NotionTheme.dividerColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _aiSearchResults = null;
                          _aiSearchExplanation = null;
                        });
                      },
                      onSubmitted: (_) {
                        if (_useAiSearch && _searchQuery.isNotEmpty) {
                          _performAiSearch(links);
                        }
                      },
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: _useAiSearch
                            ? 'AI Search (e.g., "design articles", "coding tutorials")'
                            : 'Search links...',
                        hintStyle: TextStyle(
                          color: NotionTheme.textGray.withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          _useAiSearch ? Icons.auto_awesome : Icons.search,
                          color: _useAiSearch
                              ? const Color(0xFF9333EA)
                              : NotionTheme.textGray,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_useAiSearch && !_isAiSearching)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.send,
                                        color: Color(0xFF9333EA),
                                        size: 20,
                                      ),
                                      onPressed: () => _performAiSearch(links),
                                    ),
                                  if (_isAiSearching)
                                    const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF9333EA),
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: NotionTheme.textGray,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                        _aiSearchResults = null;
                                        _aiSearchExplanation = null;
                                      });
                                    },
                                  ),
                                ],
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _useAiSearch = !_useAiSearch;
                            _aiSearchResults = null;
                            _aiSearchExplanation = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _useAiSearch
                                ? const Color(0xFFFAF5FF)
                                : NotionTheme.sidebarColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _useAiSearch
                                  ? const Color(0xFF9333EA)
                                  : NotionTheme.dividerColor,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: _useAiSearch
                                    ? const Color(0xFF9333EA)
                                    : NotionTheme.textGray,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'AI Search',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _useAiSearch
                                      ? const Color(0xFF9333EA)
                                      : NotionTheme.textGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_aiSearchExplanation != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _aiSearchExplanation!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: NotionTheme.textGray,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Topic Filters
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTopicChip(null, 'All'),
                  const SizedBox(width: 8),
                  ...TopicType.values.map(
                    (topic) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildTopicChip(topic, topic.displayName),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Links List
            Expanded(
              child: Builder(
                builder: (context) {
                  final filteredLinks = _filterLinks(links);

                  if (filteredLinks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty || _selectedTopic != null
                                ? Icons.search_off
                                : Icons.inbox_outlined,
                            size: 48,
                            color: NotionTheme.textGray.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _selectedTopic != null
                                ? 'No matching links'
                                : 'No links yet',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: NotionTheme.textGray),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    itemCount: filteredLinks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final link = filteredLinks[index];
                      return _buildLinkCard(context, link, platform);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              NotionTheme.primaryBlack,
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading links',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
