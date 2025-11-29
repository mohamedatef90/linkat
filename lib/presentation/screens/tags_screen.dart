import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/link.dart';
import '../providers/link_providers.dart';
import '../theme/notion_theme.dart';
import 'link_detail_screen.dart';

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  String? _selectedTag;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isDropdownOpen = false;
  }

  void _toggleDropdown(List<String> tags) {
    if (_isDropdownOpen) {
      _removeOverlay();
    } else {
      _showDropdown(tags);
    }
    setState(() {});
  }

  void _showDropdown(List<String> tags) {
    _overlayEntry = _createOverlayEntry(tags);
    Overlay.of(context).insert(_overlayEntry!);
    _isDropdownOpen = true;
  }

  OverlayEntry _createOverlayEntry(List<String> tags) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: _TagDropdownContent(
              tags: tags,
              selectedTag: _selectedTag,
              searchQuery: _searchQuery,
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
                _overlayEntry?.markNeedsBuild();
              },
              onTagSelected: (tag) {
                setState(() {
                  _selectedTag = tag;
                });
                _removeOverlay();
              },
              onClearSelection: () {
                setState(() {
                  _selectedTag = null;
                });
                _removeOverlay();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(allTagsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.tag, size: 20),
            SizedBox(width: 8),
            Text('Tags'),
          ],
        ),
      ),
      body: tagsAsync.when(
        data: (tags) {
          if (tags.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tag,
                    size: 48,
                    color: NotionTheme.textGray.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tags yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: NotionTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tags will appear when you save links',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: NotionTheme.textGray,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Tag selector dropdown
              Padding(
                padding: const EdgeInsets.all(16),
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: GestureDetector(
                    onTap: () => _toggleDropdown(tags),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: NotionTheme.backgroundOffWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isDropdownOpen
                              ? NotionTheme.primaryBlack
                              : NotionTheme.dividerColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tag,
                            color: NotionTheme.textGray,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _selectedTag != null
                                ? Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: NotionTheme.primaryBlack,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          '#$_selectedTag',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedTag = null;
                                          });
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          size: 18,
                                          color: NotionTheme.textGray,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Select a tag (${tags.length} available)',
                                    style: TextStyle(
                                      color: NotionTheme.textGray.withOpacity(0.7),
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _isDropdownOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: NotionTheme.textGray,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(color: NotionTheme.dividerColor, height: 1),

              // Links with selected tag
              if (_selectedTag != null)
                Expanded(
                  child: _TagLinksView(tag: _selectedTag!),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 48,
                          color: NotionTheme.textGray.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a tag to see links',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NotionTheme.textGray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the dropdown above to choose a tag',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: NotionTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(NotionTheme.primaryBlack),
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading tags',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

class _TagDropdownContent extends StatefulWidget {
  final List<String> tags;
  final String? selectedTag;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final Function(String) onTagSelected;
  final VoidCallback onClearSelection;

  const _TagDropdownContent({
    required this.tags,
    required this.selectedTag,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onTagSelected,
    required this.onClearSelection,
  });

  @override
  State<_TagDropdownContent> createState() => _TagDropdownContentState();
}

class _TagDropdownContentState extends State<_TagDropdownContent> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTags = widget.tags.where((tag) {
      if (widget.searchQuery.isEmpty) return true;
      return tag.toLowerCase().contains(widget.searchQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 350),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NotionTheme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: NotionTheme.backgroundOffWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: widget.onSearchChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search tags...',
                  hintStyle: TextStyle(
                    color: NotionTheme.textGray.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: NotionTheme.textGray,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            widget.onSearchChanged('');
                          },
                          child: const Icon(
                            Icons.close,
                            color: NotionTheme.textGray,
                            size: 18,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),

          const Divider(color: NotionTheme.dividerColor, height: 1),

          // Clear selection option
          if (widget.selectedTag != null)
            ListTile(
              leading: const Icon(Icons.clear_all, size: 20),
              title: const Text(
                'Clear selection',
                style: TextStyle(fontSize: 14),
              ),
              dense: true,
              onTap: widget.onClearSelection,
            ),

          // Tags list
          Flexible(
            child: filteredTags.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 32,
                          color: NotionTheme.textGray.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No tags found',
                          style: TextStyle(
                            color: NotionTheme.textGray,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: filteredTags.length,
                    itemBuilder: (context, index) {
                      final tag = filteredTags[index];
                      final isSelected = widget.selectedTag == tag;
                      return ListTile(
                        leading: Icon(
                          Icons.tag,
                          size: 18,
                          color: isSelected
                              ? NotionTheme.primaryBlack
                              : NotionTheme.textGray,
                        ),
                        title: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected
                                ? NotionTheme.primaryBlack
                                : Colors.black87,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: NotionTheme.primaryBlack,
                                size: 18,
                              )
                            : null,
                        selected: isSelected,
                        selectedTileColor: NotionTheme.backgroundOffWhite,
                        dense: true,
                        onTap: () => widget.onTagSelected(tag),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TagLinksView extends ConsumerWidget {
  final String tag;

  const _TagLinksView({required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linksByTagProvider(tag));

    return linksAsync.when(
      data: (links) {
        if (links.isEmpty) {
          return Center(
            child: Text(
              'No links with this tag',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NotionTheme.textGray,
              ),
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
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: NotionTheme.textGray,
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
            ),
          ],
        ),
      ),
    );
  }
}
