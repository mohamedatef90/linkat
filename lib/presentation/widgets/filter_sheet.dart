import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/content_type.dart';
import '../../domain/entities/library_filter.dart';
import '../providers/library_providers.dart';
import '../theme/notion_theme.dart';

/// Bottom-sheet Library filters — the mobile idiom that replaces the web's
/// row of desktop dropdowns. Returns the edited [LibraryFilter] on Apply.
Future<LibraryFilter?> showFilterSheet(
  BuildContext context,
  LibraryFilter current,
) {
  return showModalBottomSheet<LibraryFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterSheet(initial: current),
  );
}

/// The content types worth exposing as filters (mirrors the web Type filter).
const _kFilterableTypes = [
  ContentType.article,
  ContentType.video,
  ContentType.reel,
  ContentType.post,
  ContentType.thread,
  ContentType.podcast,
  ContentType.image,
  ContentType.other,
];

const _kReadStatuses = [
  ('unread', 'Unread'),
  ('reading', 'Reading'),
  ('read', 'Read'),
];

class _FilterSheet extends ConsumerStatefulWidget {
  final LibraryFilter initial;
  const _FilterSheet({required this.initial});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late Set<ContentType> _types;
  late Set<String> _statuses;
  late bool _starred;
  late String? _topic;
  late LibrarySort _sort;

  @override
  void initState() {
    super.initState();
    _types = {...widget.initial.sourceTypes};
    _statuses = {...widget.initial.readStatuses};
    _starred = widget.initial.starredOnly;
    _topic = widget.initial.topicLabel;
    _sort = widget.initial.sort;
  }

  void _apply() {
    Navigator.of(context).pop(
      widget.initial.copyWith(
        sourceTypes: _types,
        readStatuses: _statuses,
        starredOnly: _starred,
        topicLabel: _topic,
        clearTopic: _topic == null,
        sort: _sort,
      ),
    );
  }

  void _reset() {
    setState(() {
      _types = {};
      _statuses = {};
      _starred = false;
      _topic = null;
      _sort = LibrarySort.newest;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topics = ref.watch(topicLabelsProvider).valueOrNull ?? const [];

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: NotionTheme.ink2,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: NotionTheme.borderSoft)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NotionTheme.borderSoft,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Filters', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _section('Type'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in _kFilterableTypes)
                        _chip(
                          label: t.displayName,
                          selected: _types.contains(t),
                          onTap: () => setState(() => _types.contains(t)
                              ? _types.remove(t)
                              : _types.add(t)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _section('Read status'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (value, label) in _kReadStatuses)
                        _chip(
                          label: label,
                          selected: _statuses.contains(value),
                          onTap: () => setState(() => _statuses.contains(value)
                              ? _statuses.remove(value)
                              : _statuses.add(value)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Starred only'),
                    value: _starred,
                    activeThumbColor: NotionTheme.lime,
                    onChanged: (v) => setState(() => _starred = v),
                  ),
                  const SizedBox(height: 12),
                  if (topics.isNotEmpty) ...[
                    _section('Topic'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(
                          label: 'All',
                          selected: _topic == null,
                          onTap: () => setState(() => _topic = null),
                        ),
                        for (final t in topics)
                          _chip(
                            label: t,
                            selected: _topic == t,
                            onTap: () => setState(() => _topic = t),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  _section('Sort'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in LibrarySort.values)
                        _chip(
                          label: s.label,
                          selected: _sort == s,
                          onTap: () => setState(() => _sort = s),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _apply,
                    child: const Text('Apply filters'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: NotionTheme.fog2,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? NotionTheme.lime.withValues(alpha: 0.15)
              : NotionTheme.panel.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? NotionTheme.lime : NotionTheme.borderSoft,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? NotionTheme.lime : NotionTheme.fog,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
