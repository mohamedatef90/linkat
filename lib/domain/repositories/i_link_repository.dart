import '../entities/link.dart';
import '../entities/platform_type.dart';
import '../entities/topic_type.dart';
import '../entities/custom_category.dart';

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

  // Custom Category methods
  Future<List<CustomCategory>> getCustomCategories();
  Future<CustomCategory?> getCustomCategory(int id);
  Future<void> saveCustomCategory(CustomCategory category);
  Future<void> updateCustomCategory(CustomCategory category);
  Future<void> deleteCustomCategory(int id);
  Future<List<Link>> getLinksByCustomCategory(int categoryId);
}
