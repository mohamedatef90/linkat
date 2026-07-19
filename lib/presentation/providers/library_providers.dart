import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/library_filter.dart';
import 'link_providers.dart';

/// One-shot request to open the Library tab with a specific filter — set by
/// Vault Hub stat tiles / "View all" links before switching tabs, then
/// consumed and cleared by LibraryScreen (needed because the shell keeps the
/// Library branch alive in an IndexedStack).
final libraryEntryProvider = StateProvider<LibraryFilter?>((ref) => null);

/// Vault Hub header counts: bookmarks / content / unread-content.
typedef VaultCounts = ({int bookmarks, int content, int unread});

final vaultCountsProvider = FutureProvider<VaultCounts>((ref) async {
  // Recompute whenever the link set changes (SyncController invalidates this).
  final repo = ref.watch(linkRepositoryProvider);
  final results = await Future.wait([
    repo.countByKind('bookmark', excludeMobile: true),
    repo.countByKind('content'),
    repo.countUnread(),
  ]);
  return (bookmarks: results[0], content: results[1], unread: results[2]);
});

final continueReadingProvider = FutureProvider<List<Link>>((ref) {
  return ref.watch(linkRepositoryProvider).continueReading(limit: 6);
});

final latestContentProvider = FutureProvider<List<Link>>((ref) {
  return ref.watch(linkRepositoryProvider).latestByKind('content', limit: 6);
});

final latestBookmarksProvider = FutureProvider<List<Link>>((ref) {
  return ref
      .watch(linkRepositoryProvider)
      .latestByKind('bookmark', limit: 12, excludeMobile: true);
});

final pinnedLinksProvider = FutureProvider<List<Link>>((ref) {
  return ref.watch(linkRepositoryProvider).pinned();
});

/// All links saved from this phone (extension or manual add). Powers the
/// Library "Mobile" tab and the Vault Hub "From your phone" section.
final mobileLinksProvider = FutureProvider<List<Link>>((ref) {
  return ref.watch(linkRepositoryProvider).savedViaMobile();
});

/// The filtered Library list. Family arg is an immutable [LibraryFilter].
final libraryProvider =
    FutureProvider.family<List<Link>, LibraryFilter>((ref, filter) {
  return ref.watch(linkRepositoryProvider).queryLibrary(filter);
});

/// Distinct server topic labels present in the vault, for the filter sheet.
final topicLabelsProvider = FutureProvider<List<String>>((ref) async {
  final links = await ref.watch(linkRepositoryProvider).getAllLinks();
  final labels = <String>{
    for (final l in links)
      if (l.topicLabel != null && l.topicLabel!.trim().isNotEmpty)
        l.topicLabel!.trim(),
  };
  final sorted = labels.toList()..sort();
  return sorted;
});
