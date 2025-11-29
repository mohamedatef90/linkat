import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/topic_type.dart';
import '../providers/link_providers.dart';
import '../theme/notion_theme.dart';
import 'link_detail_screen.dart';

class TopicsScreen extends ConsumerStatefulWidget {
  const TopicsScreen({super.key});

  @override
  ConsumerState<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends ConsumerState<TopicsScreen> {
  TopicType? _selectedTopic;

  IconData _getTopicIcon(TopicType topic) {
    switch (topic) {
      case TopicType.aiTech:
        return Icons.psychology;
      case TopicType.development:
        return Icons.code;
      case TopicType.productUX:
        return Icons.design_services;
      case TopicType.design:
        return Icons.palette;
      case TopicType.business:
        return Icons.business;
      case TopicType.science:
        return Icons.science;
      case TopicType.entertainment:
        return Icons.movie;
      case TopicType.other:
        return Icons.more_horiz;
    }
  }

  Color _getTopicColor(TopicType topic) {
    switch (topic) {
      case TopicType.aiTech:
        return const Color(0xFF9333EA); // Purple
      case TopicType.development:
        return const Color(0xFF06B6D4); // Cyan
      case TopicType.productUX:
        return const Color(0xFF3B82F6); // Blue
      case TopicType.design:
        return const Color(0xFFEC4899); // Pink
      case TopicType.business:
        return const Color(0xFF10B981); // Green
      case TopicType.science:
        return const Color(0xFFF59E0B); // Amber
      case TopicType.entertainment:
        return const Color(0xFFEF4444); // Red
      case TopicType.other:
        return NotionTheme.textGray;
    }
  }

  void _showAssignTopicDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _AssignTopicSheet(
          scrollController: scrollController,
          selectedTopic: _selectedTopic,
        ),
      ),
    );
  }

  void _showCategorySettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _CategorySettingsSheet(
          scrollController: scrollController,
          getTopicIcon: _getTopicIcon,
          getTopicColor: _getTopicColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.category, size: 20),
            SizedBox(width: 8),
            Text('Topics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Category settings',
            onPressed: _showCategorySettings,
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Assign topic to links',
            onPressed: _showAssignTopicDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_selectedTopic != null) {
            // Navigate to add link with pre-selected topic
            context.push('/add?topic=${_selectedTopic!.name}');
          } else {
            context.push('/add');
          }
        },
        backgroundColor: _selectedTopic != null
            ? _getTopicColor(_selectedTopic!)
            : NotionTheme.primaryBlack,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(_selectedTopic != null
            ? 'Add to ${_selectedTopic!.displayName}'
            : 'Add Link'),
      ),
      body: Column(
        children: [
          // Topics grid
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TopicType.values.map((topic) {
                final isSelected = _selectedTopic == topic;
                final color = _getTopicColor(topic);
                return FilterChip(
                  avatar: Icon(
                    _getTopicIcon(topic),
                    size: 16,
                    color: isSelected ? Colors.white : color,
                  ),
                  label: Text(topic.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedTopic = selected ? topic : null;
                    });
                  },
                  backgroundColor: color.withOpacity(0.1),
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? color : color.withOpacity(0.3),
                    ),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ),

          const Divider(color: NotionTheme.dividerColor),

          // Links with selected topic
          if (_selectedTopic != null)
            Expanded(
              child: _TopicLinksView(topic: _selectedTopic!),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 48,
                      color: NotionTheme.textGray.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select a topic to see links',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: NotionTheme.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySettingsSheet extends StatelessWidget {
  final ScrollController scrollController;
  final IconData Function(TopicType) getTopicIcon;
  final Color Function(TopicType) getTopicColor;

  const _CategorySettingsSheet({
    required this.scrollController,
    required this.getTopicIcon,
    required this.getTopicColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.settings, size: 20),
              const SizedBox(width: 8),
              Text(
                'Category Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: NotionTheme.dividerColor, height: 1),

        // Info section
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFE0B2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Categories are predefined and cannot be added or removed. You can assign links to different categories using the edit button.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange[900],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Categories list
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: TopicType.values.length,
            itemBuilder: (context, index) {
              final topic = TopicType.values[index];
              final color = getTopicColor(topic);
              final icon = getTopicIcon(topic);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  title: Text(
                    topic.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  subtitle: Text(
                    _getTopicDescription(topic),
                    style: TextStyle(
                      fontSize: 12,
                      color: NotionTheme.textGray,
                    ),
                  ),
                  trailing: _TopicLinkCount(topic: topic),
                ),
              );
            },
          ),
        ),

        // Footer with tips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: NotionTheme.dividerColor),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tips:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildTipItem(
                context,
                Icons.auto_awesome,
                'AI auto-categorizes links when you save them',
              ),
              const SizedBox(height: 4),
              _buildTipItem(
                context,
                Icons.edit_note,
                'Use "Assign topic" to bulk move links',
              ),
              const SizedBox(height: 4),
              _buildTipItem(
                context,
                Icons.touch_app,
                'Tap a category chip to filter links',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: NotionTheme.textGray),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: NotionTheme.textGray,
            ),
          ),
        ),
      ],
    );
  }

  String _getTopicDescription(TopicType topic) {
    switch (topic) {
      case TopicType.aiTech:
        return 'AI, Machine Learning, Technology';
      case TopicType.development:
        return 'Programming, Software, Coding';
      case TopicType.productUX:
        return 'Product Design, UX/UI';
      case TopicType.design:
        return 'Graphic Design, Creative, Branding';
      case TopicType.business:
        return 'Business, Marketing, Finance';
      case TopicType.science:
        return 'Science, Research, Education';
      case TopicType.entertainment:
        return 'Movies, Music, Gaming, Sports';
      case TopicType.other:
        return 'Miscellaneous or unclassified';
    }
  }
}

class _TopicLinkCount extends ConsumerWidget {
  final TopicType topic;

  const _TopicLinkCount({required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linksByTopicProvider(topic));

    return linksAsync.when(
      data: (links) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: NotionTheme.backgroundOffWhite,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${links.length}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: NotionTheme.textGray,
          ),
        ),
      ),
      loading: () => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const Text('-'),
    );
  }
}

class _TopicLinksView extends ConsumerWidget {
  final TopicType topic;

  const _TopicLinksView({required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linksByTopicProvider(topic));

    return linksAsync.when(
      data: (links) {
        if (links.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: NotionTheme.textGray.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No links in this topic',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NotionTheme.textGray,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: links.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final link = links[index];
            return _buildLinkCard(context, link);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(NotionTheme.primaryBlack),
        ),
      ),
      error: (err, stack) => Center(
        child: Text('Error: $err'),
      ),
    );
  }

  Widget _buildLinkCard(BuildContext context, Link link) {
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
                width: 60,
                height: 60,
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
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: NotionTheme.sidebarColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.link,
                  color: NotionTheme.textGray,
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        link.platform.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: NotionTheme.textGray,
                        ),
                      ),
                      if (link.tags.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            link.tags.take(2).map((t) => '#$t').join(' '),
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

            const Icon(
              Icons.chevron_right,
              color: NotionTheme.textGray,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignTopicSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final TopicType? selectedTopic;

  const _AssignTopicSheet({
    required this.scrollController,
    this.selectedTopic,
  });

  @override
  ConsumerState<_AssignTopicSheet> createState() => _AssignTopicSheetState();
}

class _AssignTopicSheetState extends ConsumerState<_AssignTopicSheet> {
  TopicType? _targetTopic;
  final Set<int> _selectedLinkIds = {};

  IconData _getTopicIcon(TopicType topic) {
    switch (topic) {
      case TopicType.aiTech:
        return Icons.psychology;
      case TopicType.development:
        return Icons.code;
      case TopicType.productUX:
        return Icons.design_services;
      case TopicType.design:
        return Icons.palette;
      case TopicType.business:
        return Icons.business;
      case TopicType.science:
        return Icons.science;
      case TopicType.entertainment:
        return Icons.movie;
      case TopicType.other:
        return Icons.more_horiz;
    }
  }

  Color _getTopicColor(TopicType topic) {
    switch (topic) {
      case TopicType.aiTech:
        return const Color(0xFF9333EA);
      case TopicType.development:
        return const Color(0xFF06B6D4);
      case TopicType.productUX:
        return const Color(0xFF3B82F6);
      case TopicType.design:
        return const Color(0xFFEC4899);
      case TopicType.business:
        return const Color(0xFF10B981);
      case TopicType.science:
        return const Color(0xFFF59E0B);
      case TopicType.entertainment:
        return const Color(0xFFEF4444);
      case TopicType.other:
        return NotionTheme.textGray;
    }
  }

  Future<void> _assignTopics() async {
    if (_targetTopic == null || _selectedLinkIds.isEmpty) return;

    final updateLink = ref.read(updateLinkProvider);
    final allLinks = await ref.read(allLinksProvider.future);

    for (final linkId in _selectedLinkIds) {
      final link = allLinks.firstWhere((l) => l.id == linkId);
      final updatedLink = Link(
        id: link.id,
        url: link.url,
        title: link.title,
        description: link.description,
        imageUrl: link.imageUrl,
        platform: link.platform,
        topic: _targetTopic!,
        createdAt: link.createdAt,
        publisherName: link.publisherName,
        aiDescription: link.aiDescription,
        tags: link.tags,
      );
      await updateLink(updatedLink);
    }

    // Invalidate providers
    ref.invalidate(allLinksProvider);
    ref.invalidate(linksByTopicProvider(_targetTopic!));
    ref.invalidate(linksProvider);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Moved ${_selectedLinkIds.length} link(s) to ${_targetTopic!.displayName}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLinksAsync = ref.watch(allLinksProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.edit_note, size: 20),
              const SizedBox(width: 8),
              Text(
                'Assign Topic to Links',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: NotionTheme.dividerColor, height: 1),

        // Target topic selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select target topic:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TopicType.values.map((topic) {
                  final isSelected = _targetTopic == topic;
                  final color = _getTopicColor(topic);
                  return FilterChip(
                    avatar: Icon(
                      _getTopicIcon(topic),
                      size: 14,
                      color: isSelected ? Colors.white : color,
                    ),
                    label: Text(topic.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _targetTopic = selected ? topic : null;
                      });
                    },
                    backgroundColor: color.withAlpha(26),
                    selectedColor: color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? color : color.withAlpha(77),
                      ),
                    ),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const Divider(color: NotionTheme.dividerColor, height: 1),

        // Links list
        Expanded(
          child: allLinksAsync.when(
            data: (links) {
              if (links.isEmpty) {
                return const Center(
                  child: Text('No links available'),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: links.length,
                itemBuilder: (context, index) {
                  final link = links[index];
                  final isSelected = _selectedLinkIds.contains(link.id);
                  final topicColor = _getTopicColor(link.topic);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedLinkIds.add(link.id!);
                        } else {
                          _selectedLinkIds.remove(link.id);
                        }
                      });
                    },
                    title: Text(
                      link.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: topicColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            link.topic.displayName,
                            style: TextStyle(
                              color: topicColor,
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
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    activeColor: NotionTheme.primaryBlack,
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, _) => Center(
              child: Text('Error: $err'),
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: NotionTheme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _targetTopic != null && _selectedLinkIds.isNotEmpty
                      ? _assignTopics
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NotionTheme.primaryBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _selectedLinkIds.isEmpty
                        ? 'Select links'
                        : 'Assign ${_selectedLinkIds.length} link(s)',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
