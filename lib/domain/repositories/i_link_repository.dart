import '../entities/link.dart';
import '../entities/platform_type.dart';
import '../entities/topic_type.dart';
import '../entities/custom_category.dart';
import '../entities/library_filter.dart';

abstract class ILinkRepository {
  Future<List<Link>> getLinks({PlatformType? platform});
  Future<void> saveLink(Link link);
  Future<void> updateLink(Link link);
  Future<void> deleteLink(int id);
  Future<List<Link>> searchLinks(String query);
  Future<List<Link>> searchByTag(String tag);
  Future<List<Link>> searchByTopic(TopicType topic);
  Future<List<String>> getAllTags();
  Future<List<Link>> getAllLinks();
  Future<Link?> findByUrl(String url);

  // Vault Hub / Library queries (local-first over synced rows)
  Future<int> countByKind(String kind, {bool excludeMobile = false});
  Future<int> countUnread();
  Future<List<Link>> continueReading({int limit = 10});
  Future<List<Link>> latestByKind(String kind,
      {int limit = 10, bool excludeMobile = false});
  Future<List<Link>> pinned();
  Future<List<Link>> queryLibrary(LibraryFilter filter);

  /// Links saved from this phone (share extension or manual add),
  /// `saved_via == 'mobile'`, newest first.
  Future<List<Link>> savedViaMobile({int? limit});

  // Custom Category methods
  Future<List<CustomCategory>> getCustomCategories();
  Future<CustomCategory?> getCustomCategory(int id);
  Future<void> saveCustomCategory(CustomCategory category);
  Future<void> updateCustomCategory(CustomCategory category);
  Future<void> deleteCustomCategory(int id);
  Future<List<Link>> getLinksByCustomCategory(int categoryId);
}
