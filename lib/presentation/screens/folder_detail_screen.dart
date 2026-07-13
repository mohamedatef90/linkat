import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/platform_type.dart';
import '../../domain/entities/topic_type.dart';
import '../../domain/entities/content_type.dart';
import '../../domain/entities/link.dart';
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
  bool _isRefreshingAll = false;
  int _refreshProgress = 0;
  int _refreshTotal = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshAllImages(List<Link> links, PlatformType platform) async {
    if (_isRefreshingAll) return;

    // Filter links that have images or might need refresh
    final linksToRefresh = links.where((link) => link.imageUrl != null || link.imageUrl == null).toList();

    if (linksToRefresh.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No links to refresh'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isRefreshingAll = true;
      _refreshProgress = 0;
      _refreshTotal = linksToRefresh.length;
    });

    final metadataService = ref.read(metadataServiceProvider);
    final updateLink = ref.read(updateLinkProvider);
    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < linksToRefresh.length; i++) {
      final link = linksToRefresh[i];

      try {
        final metadata = await metadataService.fetchMetadata(link.url);

        if (mounted) {
          final updatedLink = link.copyWith(
            title: metadata['title'] ?? link.title,
            description: metadata['description'] ?? link.description,
            imageUrl: metadata['image'],
            publisherName: metadata['publisher'] ?? link.publisherName,
          );

          await updateLink(updatedLink);

          // Clear old cached image
          if (link.imageUrl != null) {
            await CachedNetworkImage.evictFromCache(link.imageUrl!);
          }
          if (metadata['image'] != null && metadata['image'] != link.imageUrl) {
            await CachedNetworkImage.evictFromCache(metadata['image']!);
          }

          successCount++;
        }
      } catch (e) {
        failCount++;
        debugPrint('Failed to refresh link ${link.url}: $e');
      }

      if (mounted) {
        setState(() {
          _refreshProgress = i + 1;
        });
      }
    }

    // Invalidate providers to refresh data
    ref.invalidate(linksProvider(platform));
    ref.invalidate(allLinksProvider);

    if (mounted) {
      setState(() {
        _isRefreshingAll = false;
        _refreshProgress = 0;
        _refreshTotal = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failCount == 0
                ? 'Refreshed $successCount links successfully'
                : 'Refreshed $successCount links, $failCount failed',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: failCount == 0 ? NotionTheme.accentGreen : NotionTheme.accentOrange,
        ),
      );
    }
  }

  List<Link> _filterLinks(List<Link> links) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedBackgroundColor = isDark
        ? NotionTheme.darkAccentPrimary
        : NotionTheme.primaryBlack;
    final unselectedBackgroundColor = isDark
        ? NotionTheme.darkSurface
        : NotionTheme.backgroundOffWhite;
    final selectedTextColor = Colors.white;
    final unselectedTextColor = isDark
        ? NotionTheme.darkTextPrimary
        : NotionTheme.primaryBlack;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTopic = isSelected ? null : topic;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedBackgroundColor
              : unselectedBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? NotionTheme.darkDivider : NotionTheme.dividerColor),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLinkCard(
    BuildContext context,
    Link link,
    PlatformType platform,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Use stored content type, or detect from URL as fallback
    final contentType = link.contentType;

    final borderColor = isDark
        ? NotionTheme.darkDivider
        : NotionTheme.dividerColor;
    final subtextColor = theme.textTheme.bodySmall?.color ?? Colors.grey;
    final itemBackgroundColor = isDark ? NotionTheme.darkSurface : Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => LinkDetailScreen(link: link)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: itemBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                  // Thumbnail with content type overlay
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: link.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: link.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark
                                            ? [NotionTheme.darkSurfaceElevated, NotionTheme.darkSurface]
                                            : [Colors.grey[200]!, Colors.grey[100]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark
                                            ? [NotionTheme.darkSurfaceElevated, NotionTheme.darkSurface]
                                            : [Colors.grey[200]!, Colors.grey[100]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        size: 24,
                                        color: isDark ? NotionTheme.darkTextMuted : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [NotionTheme.darkSurfaceElevated, NotionTheme.darkSurface]
                                          : [Colors.grey[200]!, Colors.grey[100]!],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      contentType.emoji,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Content type badge overlay
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getContentTypeColor(contentType).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            contentType.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          link.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        // Show AI Summary if available, otherwise show description
                        if (link.aiDescription != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 10,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  link.aiDescription!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: theme.colorScheme.primary.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (link.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            link.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.black.withOpacity(0.02),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Topic Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.15),
                          theme.colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      link.topic.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Share Button
                  _buildIconButton(
                    icon: Icons.share_rounded,
                    color: subtextColor,
                    onTap: () => _showShareSheet(context, link),
                  ),
                  const SizedBox(width: 8),

                  // Delete Action
                  _buildIconButton(
                    icon: Icons.delete_outline_rounded,
                    color: subtextColor,
                    onTap: () async {
                      final confirmed = await _showDeleteDialog(context, link);

                      if (confirmed == true && context.mounted) {
                        await ref.read(deleteLinkUseCaseProvider)(link.id!);
                        ref.invalidate(linksProvider(platform));
                        ref.invalidate(allLinksProvider);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link deleted'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),

                  // Open Button with gradient
                  InkWell(
                    onTap: () async {
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
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: NotionTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'Open',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
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

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Color _getContentTypeColor(ContentType type) {
    switch (type) {
      case ContentType.video:
        return NotionTheme.accentBlue;
      case ContentType.reel:
        return NotionTheme.accentPink;
      case ContentType.short:
        return NotionTheme.accentOrange;
      case ContentType.post:
        return NotionTheme.accentPurple;
      case ContentType.article:
        return NotionTheme.accentGreen;
      case ContentType.image:
        return NotionTheme.accentCyan;
      case ContentType.story:
        return NotionTheme.accentYellow;
      case ContentType.thread:
        return NotionTheme.accentPurple;
      case ContentType.podcast:
        return NotionTheme.accentOrange;
      case ContentType.music:
        return NotionTheme.accentPink;
      case ContentType.profile:
        return NotionTheme.accentBlue;
      case ContentType.other:
        return NotionTheme.textGray;
    }
  }

  Future<bool?> _showDeleteDialog(BuildContext context, Link link) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? NotionTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? NotionTheme.darkDivider : NotionTheme.dividerColor,
          ),
        ),
        title: Text('Delete Link?', style: theme.textTheme.titleLarge),
        content: Text(
          'Are you sure you want to delete "${link.title}"?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showShareSheet(BuildContext context, Link link) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? NotionTheme.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? NotionTheme.darkDivider : NotionTheme.dividerColor,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.copy, color: theme.iconTheme.color),
                title: Text('Copy Link', style: theme.textTheme.bodyLarge),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: link.url));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.ios_share, color: theme.iconTheme.color),
                title: Text('Share', style: theme.textTheme.bodyLarge),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final box = context.findRenderObject() as RenderBox?;
                    final sharePositionOrigin = box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : const Rect.fromLTWH(0, 0, 1, 1);
                    await Share.share(
                      link.url,
                      subject: link.title,
                      sharePositionOrigin: sharePositionOrigin,
                    );
                  } catch (e, st) {
                    debugPrint('Share error: $e\n$st');
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark
        ? NotionTheme.darkDivider
        : NotionTheme.dividerColor;
    final textColor = isDark ? NotionTheme.darkTextPrimary : NotionTheme.primaryBlack;
    final subtextColor = isDark ? NotionTheme.darkTextSecondary : NotionTheme.textGray;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            FaIcon(
              _getIcon(platform),
              size: 20,
              color: _getIconColor(platform),
            ),
            const SizedBox(width: 8),
            Text(platform.displayName, style: theme.textTheme.titleMedium),
            if (_isRefreshingAll) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$_refreshProgress/$_refreshTotal',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        titleSpacing: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          linksAsync.when(
            data: (links) => IconButton(
              icon: _isRefreshingAll
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: textColor,
                      ),
                    )
                  : Icon(Icons.refresh_rounded, color: textColor),
              onPressed: _isRefreshingAll ? null : () => _refreshAllImages(links, platform),
              tooltip: 'Refresh all images',
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
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
                      color: isDark
                          ? NotionTheme.darkSurface
                          : NotionTheme.backgroundOffWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Search links...',
                        hintStyle: TextStyle(
                          color: subtextColor.withOpacity(0.6),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: subtextColor,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: subtextColor,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
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
                            color: subtextColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty || _selectedTopic != null
                                ? 'No matching links'
                                : 'No links yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: subtextColor,
                            ),
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
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading links',
            style: theme.textTheme.bodyMedium?.copyWith(color: subtextColor),
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
