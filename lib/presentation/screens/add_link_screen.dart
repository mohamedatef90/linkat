import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/topic_type.dart';
import '../providers/link_providers.dart';
import '../theme/notion_theme.dart';

class AddLinkScreen extends ConsumerStatefulWidget {
  final String? initialUrl;
  final String? initialTopic;
  const AddLinkScreen({super.key, this.initialUrl, this.initialTopic});

  @override
  ConsumerState<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends ConsumerState<AddLinkScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _tagController;
  bool _isLoading = false;
  String? _error;
  TopicType? _manualTopic;
  List<String> _selectedTags = [];
  List<String> _availableTags = [];
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _tagController = TextEditingController();
    // Set initial topic if provided
    if (widget.initialTopic != null) {
      try {
        _manualTopic = TopicType.values.firstWhere(
          (t) => t.name == widget.initialTopic,
        );
      } catch (_) {
        // Invalid topic name, ignore
      }
    }
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await ref.read(allTagsProvider.future);
    if (mounted) {
      setState(() {
        _availableTags = tags;
      });
    }
  }

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

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim().toLowerCase();
    if (trimmed.isNotEmpty && !_selectedTags.contains(trimmed)) {
      setState(() {
        _selectedTags.add(trimmed);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  Future<void> _checkForDuplicateAndSave() async {
    // Sanitize URL to remove invisible characters
    final url = _urlController.text.trim().replaceAll(
      RegExp(r'[\u200B-\u200D\uFEFF\uFFFC]'),
      '',
    );
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check for duplicate
      final repository = ref.read(linkRepositoryProvider);
      final existingLink = await repository.findByUrl(url);

      if (existingLink != null && mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show duplicate warning dialog
        final result = await _showDuplicateDialog(existingLink);
        if (result == 'replace') {
          await _saveLink(replaceId: existingLink.id);
        } else if (result == 'discard') {
          if (mounted) {
            context.pop();
          }
        }
        // If null, user cancelled - do nothing
        return;
      }

      // No duplicate, proceed to save
      await _saveLink();
    } catch (e) {
      setState(() {
        _error = 'Failed to check for duplicate: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _showDuplicateDialog(Link existingLink) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Text('Duplicate Link'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This link already exists in your collection:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NotionTheme.backgroundOffWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NotionTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existingLink.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    existingLink.url,
                    style: TextStyle(
                      color: NotionTheme.textGray,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTopicColor(existingLink.topic).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          existingLink.topic.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getTopicColor(existingLink.topic),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        existingLink.platform.displayName,
                        style: const TextStyle(
                          fontSize: 10,
                          color: NotionTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('What would you like to do?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Discard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('replace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: NotionTheme.primaryBlack,
              foregroundColor: Colors.white,
            ),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLink({int? replaceId}) async {
    // Sanitize URL to remove invisible characters
    final url = _urlController.text.trim().replaceAll(
      RegExp(r'[\u200B-\u200D\uFEFF\uFFFC]'),
      '',
    );
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final platformService = ref.read(platformDetectionServiceProvider);
      final metadataService = ref.read(metadataServiceProvider);
      final aiService = ref.read(aiDescriptionServiceProvider);
      final aiClassificationService = ref.read(aiClassificationServiceProvider);
      final topicService = ref.read(topicClassificationServiceProvider);
      final saveLink = ref.read(saveLinkUseCaseProvider);
      final updateLink = ref.read(updateLinkProvider);

      final platform = platformService.detectPlatform(url);
      final metadata = await metadataService.fetchMetadata(url);

      // Use manual title if provided, otherwise use metadata
      final title = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : (metadata['title'] ?? url);

      // Use manual description if provided, otherwise use metadata
      final description = _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : metadata['description'];

      // Try AI classification first, fall back to keyword-based
      var topic = topicService.classifyContent(
        title: title,
        description: description,
      );
      List<String> tags = List.from(_selectedTags);

      // Use AI to classify and generate tags if no manual tags provided
      if (_selectedTags.isEmpty) {
        final aiClassification = await aiClassificationService.classifyContent(
          url: url,
          title: title,
          description: description,
        );

        if (aiClassification != null) {
          topic = aiClassification.category;
          tags = aiClassification.tags;
        }
      }

      // Use manual topic if user selected one
      if (_manualTopic != null) {
        topic = _manualTopic!;
      }

      // Generate AI description based on content
      final aiDescription = await aiService.generateDescription(
        url: url,
        title: title,
        existingDescription: description,
      );

      final link = Link(
        id: replaceId,
        url: url,
        title: title,
        description: description,
        imageUrl: metadata['image'],
        publisherName: metadata['publisher'],
        aiDescription: aiDescription,
        platform: platform,
        topic: topic,
        tags: tags,
        createdAt: DateTime.now(),
      );

      if (replaceId != null) {
        await updateLink(link);
      } else {
        await saveLink(link);
      }

      if (mounted) {
        // Refresh the list for this platform
        ref.invalidate(linksProvider(platform));
        ref.invalidate(allLinksProvider);
        ref.invalidate(allTagsProvider);
        context.pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to save link: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showTagSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _TagSelectorSheet(
        availableTags: _availableTags,
        selectedTags: _selectedTags,
        onTagSelected: (tag) {
          _addTag(tag);
          Navigator.pop(context);
        },
        onNewTag: (tag) {
          _addTag(tag);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Link')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('URL', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: NotionTheme.backgroundOffWhite,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: NotionTheme.dividerColor),
              ),
              child: TextField(
                controller: _urlController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'https://example.com',
                  hintStyle: TextStyle(
                    color: NotionTheme.textGray.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  errorText: _error,
                  prefixIcon: const Icon(
                    Icons.link,
                    color: NotionTheme.textGray,
                  ),
                ),
                keyboardType: TextInputType.url,
                autofocus: true,
              ),
            ),
            const SizedBox(height: 16),

            // Advanced options toggle
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAdvanced = !_showAdvanced;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _showAdvanced ? Icons.expand_less : Icons.expand_more,
                      color: NotionTheme.textGray,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Advanced Options',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: NotionTheme.textGray,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: NotionTheme.dividerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Advanced options section
            if (_showAdvanced) ...[
              const SizedBox(height: 12),

              // Manual Title
              Text(
                'Title (optional)',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: NotionTheme.backgroundOffWhite,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: NotionTheme.dividerColor),
                ),
                child: TextField(
                  controller: _titleController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Leave empty for auto-detection',
                    hintStyle: TextStyle(
                      color: NotionTheme.textGray.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.title,
                      color: NotionTheme.textGray,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Manual Description
              Text(
                'Description (optional)',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: NotionTheme.backgroundOffWhite,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: NotionTheme.dividerColor),
                ),
                child: TextField(
                  controller: _descriptionController,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Leave empty for auto-detection',
                    hintStyle: TextStyle(
                      color: NotionTheme.textGray.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(
                        Icons.description,
                        color: NotionTheme.textGray,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tags section
              Text(
                'Tags (optional)',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showTagSelector,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NotionTheme.backgroundOffWhite,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: NotionTheme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tag,
                        color: NotionTheme.textGray,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _selectedTags.isEmpty
                            ? Text(
                                'Tap to add tags',
                                style: TextStyle(
                                  color: NotionTheme.textGray.withOpacity(0.5),
                                ),
                              )
                            : Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _selectedTags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: NotionTheme.primaryBlack.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '#$tag',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () => _removeTag(tag),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: NotionTheme.textGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: NotionTheme.textGray,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            // Manual Topic Selection
            Text(
              'Topic (optional)',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Leave empty for AI auto-detection',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: NotionTheme.textGray,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TopicType.values.map((topic) {
                final isSelected = _manualTopic == topic;
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
                      _manualTopic = selected ? topic : null;
                    });
                  },
                  backgroundColor: color.withOpacity(0.1),
                  selectedColor: color,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? color : color.withOpacity(0.3),
                    ),
                  ),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _checkForDuplicateAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NotionTheme.primaryBlack,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Save Link',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagSelectorSheet extends StatefulWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final Function(String) onTagSelected;
  final Function(String) onNewTag;

  const _TagSelectorSheet({
    required this.availableTags,
    required this.selectedTags,
    required this.onTagSelected,
    required this.onNewTag,
  });

  @override
  State<_TagSelectorSheet> createState() => _TagSelectorSheetState();
}

class _TagSelectorSheetState extends State<_TagSelectorSheet> {
  late TextEditingController _searchController;
  List<String> _filteredTags = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredTags = widget.availableTags
        .where((tag) => !widget.selectedTags.contains(tag))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTags(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTags = widget.availableTags
            .where((tag) => !widget.selectedTags.contains(tag))
            .toList();
      } else {
        _filteredTags = widget.availableTags
            .where((tag) =>
                !widget.selectedTags.contains(tag) &&
                tag.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.tag, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Select or Add Tag',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: NotionTheme.dividerColor, height: 1),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: NotionTheme.backgroundOffWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NotionTheme.dividerColor),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterTags,
                decoration: InputDecoration(
                  hintText: 'Search or create new tag...',
                  hintStyle: TextStyle(
                    color: NotionTheme.textGray.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: NotionTheme.textGray,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    widget.onNewTag(value.trim());
                  }
                },
              ),
            ),
          ),

          // Create new tag option
          if (_searchController.text.isNotEmpty &&
              !_filteredTags.contains(_searchController.text.trim().toLowerCase()))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListTile(
                leading: const Icon(Icons.add, color: NotionTheme.primaryBlack),
                title: Text(
                  'Create "${_searchController.text.trim()}"',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () => widget.onNewTag(_searchController.text.trim()),
                tileColor: NotionTheme.backgroundOffWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

          // Tags list
          Flexible(
            child: _filteredTags.isEmpty && _searchController.text.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tag,
                            size: 48,
                            color: NotionTheme.textGray.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No tags yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: NotionTheme.textGray,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Type to create a new tag',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: NotionTheme.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTags.length,
                    itemBuilder: (context, index) {
                      final tag = _filteredTags[index];
                      return ListTile(
                        leading: const Icon(Icons.tag, size: 18),
                        title: Text('#$tag'),
                        onTap: () => widget.onTagSelected(tag),
                        dense: true,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
