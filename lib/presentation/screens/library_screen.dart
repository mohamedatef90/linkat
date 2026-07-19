import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../domain/entities/library_filter.dart';
import '../../domain/entities/platform_type.dart';
import '../providers/library_providers.dart';
import '../providers/link_providers.dart';
import '../providers/sync_providers.dart';
import '../theme/notion_theme.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/link_card.dart';
import '../widgets/magic/magic.dart';
import 'manage_folders_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  /// Deep-link seeds from the web-parity routes (`/library?kind=bookmark`,
  /// `/library?status=reading`).
  final String? initialKind;
  final String? initialStatus;

  const LibraryScreen({super.key, this.initialKind, this.initialStatus});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  late LibraryFilter _filter;

  /// Platforms whose Mobile-tab section is expanded past the 10-item cap.
  final Set<PlatformType> _expandedPlatforms = {};

  @override
  void initState() {
    super.initState();
    final entry = ref.read(libraryEntryProvider);
    final initialKind = const {'mobile', 'bookmark', 'content'}
            .contains(widget.initialKind)
        ? widget.initialKind!
        : 'content';
    _filter = entry ??
        LibraryFilter(
          kind: initialKind,
          readStatuses:
              widget.initialStatus != null ? {widget.initialStatus!} : {},
        );
    if (entry != null) {
      // Consume the one-shot request so it doesn't re-apply on rebuild.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(libraryEntryProvider.notifier).state = null;
      });
    }
  }

  bool get _isContent => _filter.kind == 'content';
  bool get _isMobile => _filter.kind == 'mobile';

  void _setKind(String kind) {
    if (_filter.kind == kind) return;
    setState(() => _filter = _filter.copyWith(kind: kind));
  }

  Future<void> _openFilters() async {
    final result = await showFilterSheet(context, _filter);
    if (result != null && mounted) setState(() => _filter = result);
  }

  void _toggleTag(String tag) {
    final tags = {..._filter.tags};
    tags.contains(tag) ? tags.remove(tag) : tags.add(tag);
    setState(() => _filter = _filter.copyWith(tags: tags));
  }

  void _toggleFolder(String folderId) {
    setState(() => _filter = _filter.folderId == folderId
        ? _filter.copyWith(clearFolder: true)
        : _filter.copyWith(folderId: folderId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // React to later entry requests while this branch is already alive.
    ref.listen(libraryEntryProvider, (_, next) {
      if (next != null) {
        setState(() => _filter = next);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(libraryEntryProvider.notifier).state = null;
        });
      }
    });
    return Scaffold(
      backgroundColor: NotionTheme.ink,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Library',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: AuraBackground(
        child: RefreshIndicator(
          onRefresh: () => ref.read(syncControllerProvider).syncNow(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    16,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kindTabs(theme),
                      if (!_isMobile) ...[
                        const SizedBox(height: 14),
                        _controlRow(),
                        _tagRow(),
                      ],
                    ],
                  ),
                ),
              ),
              if (_isMobile)
                _mobileSliver(theme)
              else
                _listSliver(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listSliver(ThemeData theme) {
    final itemsAsync = ref.watch(libraryProvider(_filter));
    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _emptyState(theme),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => Reveal(
              delay: Duration(milliseconds: 24 * (i % 8)),
              child: LinkCard(link: items[i]),
            ),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: NotionTheme.lime),
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('Could not load: $e',
              style: theme.textTheme.bodyMedium),
        ),
      ),
    );
  }

  /// The Mobile tab: everything saved from this phone, grouped by platform.
  Widget _mobileSliver(ThemeData theme) {
    final mobileAsync = ref.watch(mobileLinksProvider);
    return mobileAsync.when(
      data: (links) {
        if (links.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _emptyState(theme),
          );
        }
        const perPlatform = 10;
        final sections = <Widget>[];
        for (final platform in PlatformType.values) {
          final group =
              links.where((l) => l.platform == platform).toList();
          if (group.isEmpty) continue;
          final expanded = _expandedPlatforms.contains(platform);
          final shown = expanded ? group : group.take(perPlatform).toList();
          sections.add(_platformHeader(theme, platform, group.length));
          for (final link in shown) {
            sections.add(Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LinkCard(link: link),
            ));
          }
          if (group.length > perPlatform) {
            sections.add(_seeMore(
              expanded: expanded,
              hidden: group.length - perPlatform,
              onTap: () => setState(() {
                expanded
                    ? _expandedPlatforms.remove(platform)
                    : _expandedPlatforms.add(platform);
              }),
            ));
          }
          sections.add(const SizedBox(height: 12));
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate(sections),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: NotionTheme.lime),
        ),
      ),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child:
              Text('Could not load: $e', style: theme.textTheme.bodyMedium),
        ),
      ),
    );
  }

  Widget _seeMore({
    required bool expanded,
    required int hidden,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: NotionTheme.panel.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NotionTheme.borderSoft),
          ),
          child: Text(
            expanded ? 'Show less' : 'See more ($hidden)',
            style: const TextStyle(
              color: NotionTheme.lime,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _platformHeader(ThemeData theme, PlatformType platform, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          FaIcon(_platformIcon(platform),
              size: 15, color: _platformColor(platform)),
          const SizedBox(width: 10),
          Text(
            platform.displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: NotionTheme.panel.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: NotionTheme.fog2,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  FaIconData _platformIcon(PlatformType platform) {
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
        return FontAwesomeIcons.globe;
    }
  }

  Color _platformColor(PlatformType platform) {
    switch (platform) {
      case PlatformType.facebook:
        return const Color(0xFF1877F2);
      case PlatformType.instagram:
        return const Color(0xFFE4405F);
      case PlatformType.twitter:
        return NotionTheme.white;
      case PlatformType.youtube:
        return const Color(0xFFFF0000);
      case PlatformType.linkedin:
        return const Color(0xFF3B82F6);
      case PlatformType.other:
        return NotionTheme.lime;
    }
  }

  Widget _kindTabs(ThemeData theme) {
    Widget tab(String kind, IconData icon, String label) {
      final selected = _filter.kind == kind;
      return Expanded(
        child: GestureDetector(
          onTap: () => _setKind(kind),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? NotionTheme.grad : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 15,
                    color: selected ? NotionTheme.ink : NotionTheme.fog2),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? NotionTheme.ink : NotionTheme.fog2,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: NotionTheme.panel.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NotionTheme.borderSoft),
      ),
      child: Row(
        children: [
          tab('mobile', Icons.smartphone, 'Mobile'),
          const SizedBox(width: 4),
          tab('bookmark', Icons.bookmark_border, 'Bookmarks'),
          const SizedBox(width: 4),
          tab('content', Icons.menu_book_rounded, 'Reading'),
        ],
      ),
    );
  }

  Widget _controlRow() {
    final foldersAsync = ref.watch(foldersProvider);
    final activeCount = _filter.activeCount;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _pill(
            icon: Icons.tune,
            label: activeCount > 0 ? 'Filters · $activeCount' : 'Filters',
            active: activeCount > 0,
            onTap: _openFilters,
          ),
          const SizedBox(width: 8),
          ...foldersAsync.maybeWhen(
            data: (folders) => [
              for (final f in folders) ...[
                _pill(
                  icon: Icons.folder_outlined,
                  label: f.name,
                  active: _filter.folderId == f.id,
                  onTap: () => _toggleFolder(f.id),
                ),
                const SizedBox(width: 8),
              ],
            ],
            orElse: () => const [],
          ),
          _pill(
            icon: Icons.settings_outlined,
            label: 'Manage',
            active: false,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManageFoldersScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagRow() {
    final tagsAsync = ref.watch(allTagsProvider);
    return tagsAsync.maybeWhen(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox(height: 4);
        final shown = tags.take(24).toList();
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in shown)
                GestureDetector(
                  onTap: () => _toggleTag(tag),
                  child: _tagChip(tag, _filter.tags.contains(tag)),
                ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox(height: 4),
    );
  }

  Widget _tagChip(String tag, bool selected) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? NotionTheme.lime.withValues(alpha: 0.15)
              : NotionTheme.panel.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? NotionTheme.lime : NotionTheme.borderSoft,
          ),
        ),
        child: Text(
          '#$tag',
          style: TextStyle(
            fontSize: 11,
            color: selected ? NotionTheme.lime : NotionTheme.fog2,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      );

  Widget _pill({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? NotionTheme.lime.withValues(alpha: 0.15)
              : NotionTheme.panel.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? NotionTheme.lime : NotionTheme.borderSoft,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15, color: active ? NotionTheme.lime : NotionTheme.fog2),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: active ? NotionTheme.lime : NotionTheme.fog,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    final (IconData icon, String title, String subtitle) = _isMobile
        ? (
            Icons.smartphone,
            'Nothing from your phone yet',
            'Links you save here — via the share sheet or the + button — '
                'appear grouped by platform.',
          )
        : _isContent
            ? (
                Icons.menu_book_rounded,
                'No reading yet',
                'Articles, videos and posts you save land here.',
              )
            : (
                Icons.bookmark_border,
                'No bookmarks yet',
                'Plain website links you save show up here.',
              );
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44, color: NotionTheme.fog2),
          const SizedBox(height: 14),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
