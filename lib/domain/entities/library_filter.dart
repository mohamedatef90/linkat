import 'content_type.dart';

/// How the Library list is ordered.
enum LibrarySort {
  newest,
  oldest,
  titleAsc;

  String get label {
    switch (this) {
      case LibrarySort.newest:
        return 'Newest';
      case LibrarySort.oldest:
        return 'Oldest';
      case LibrarySort.titleAsc:
        return 'Title A–Z';
    }
  }
}

/// Immutable description of a Library query — mirrors the web `FilterState`.
/// Used as a Riverpod family argument, so it needs value equality.
class LibraryFilter {
  /// 'content' (Reading tab) or 'bookmark' (Bookmarks tab).
  final String kind;
  final Set<ContentType> sourceTypes;
  final Set<String> readStatuses;
  final bool starredOnly;

  /// Server topic string (e.g. "AI & Machine Learning"), not the lossy enum.
  final String? topicLabel;
  final Set<String> tags;
  final String? folderId;
  final LibrarySort sort;

  const LibraryFilter({
    this.kind = 'content',
    this.sourceTypes = const {},
    this.readStatuses = const {},
    this.starredOnly = false,
    this.topicLabel,
    this.tags = const {},
    this.folderId,
    this.sort = LibrarySort.newest,
  });

  LibraryFilter copyWith({
    String? kind,
    Set<ContentType>? sourceTypes,
    Set<String>? readStatuses,
    bool? starredOnly,
    String? topicLabel,
    bool clearTopic = false,
    Set<String>? tags,
    String? folderId,
    bool clearFolder = false,
    LibrarySort? sort,
  }) {
    return LibraryFilter(
      kind: kind ?? this.kind,
      sourceTypes: sourceTypes ?? this.sourceTypes,
      readStatuses: readStatuses ?? this.readStatuses,
      starredOnly: starredOnly ?? this.starredOnly,
      topicLabel: clearTopic ? null : (topicLabel ?? this.topicLabel),
      tags: tags ?? this.tags,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      sort: sort ?? this.sort,
    );
  }

  /// Count of active constraints beyond the kind tab — drives the "Filters"
  /// chip badge.
  int get activeCount =>
      sourceTypes.length +
      readStatuses.length +
      (starredOnly ? 1 : 0) +
      (topicLabel != null ? 1 : 0) +
      tags.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LibraryFilter &&
        other.kind == kind &&
        _setEq(other.sourceTypes, sourceTypes) &&
        _setEq(other.readStatuses, readStatuses) &&
        other.starredOnly == starredOnly &&
        other.topicLabel == topicLabel &&
        _setEq(other.tags, tags) &&
        other.folderId == folderId &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(
        kind,
        Object.hashAllUnordered(sourceTypes),
        Object.hashAllUnordered(readStatuses),
        starredOnly,
        topicLabel,
        Object.hashAllUnordered(tags),
        folderId,
        sort,
      );

  static bool _setEq<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);
}
