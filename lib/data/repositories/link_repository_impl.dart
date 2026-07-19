import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/platform_type.dart';
import '../../domain/entities/topic_type.dart';
import '../../domain/entities/content_type.dart';
import '../../domain/entities/custom_category.dart';
import '../../domain/entities/library_filter.dart';
import '../../domain/repositories/i_link_repository.dart';
import '../models/link_model.dart';
import '../models/custom_category_model.dart';

class LinkRepositoryImpl implements ILinkRepository {
  late Future<Isar> db;

  LinkRepositoryImpl() {
    db = _initDb();
  }

  Future<Isar> _initDb() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [LinkModelSchema, CustomCategoryModelSchema],
        directory: dir.path,
      );
    }
    return Future.value(Isar.getInstance());
  }

  @override
  Future<List<Link>> getLinks({PlatformType? platform}) async {
    final isar = await db;
    if (platform != null) {
      final links = await isar.linkModels
          .filter()
          .platformEqualTo(platform)
          .sortByCreatedAtDesc()
          .findAll();
      return links.map((e) => e.toEntity()).toList();
    } else {
      final links = await isar.linkModels
          .where()
          .sortByCreatedAtDesc()
          .findAll();
      return links.map((e) => e.toEntity()).toList();
    }
  }

  @override
  Future<List<Link>> getAllLinks() async {
    final isar = await db;
    final links = await isar.linkModels
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    return links.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> saveLink(Link link) async {
    final isar = await db;
    final linkModel = LinkModel.fromEntity(link);
    await isar.writeTxn(() async {
      await isar.linkModels.put(linkModel);
    });
  }

  @override
  Future<void> updateLink(Link link) async {
    final isar = await db;
    final linkModel = LinkModel.fromEntity(link);
    await isar.writeTxn(() async {
      await isar.linkModels.put(linkModel);
    });
  }

  @override
  Future<void> deleteLink(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.linkModels.delete(id);
    });
  }

  @override
  Future<List<Link>> searchLinks(String query) async {
    final isar = await db;
    final links = await isar.linkModels
        .filter()
        .titleContains(query, caseSensitive: false)
        .or()
        .urlContains(query, caseSensitive: false)
        .or()
        .tagsElementContains(query, caseSensitive: false)
        .or()
        .descriptionContains(query, caseSensitive: false)
        .or()
        .aiDescriptionContains(query, caseSensitive: false)
        .findAll();
    return links.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<Link>> searchByTag(String tag) async {
    final isar = await db;
    final links = await isar.linkModels
        .filter()
        .tagsElementEqualTo(tag, caseSensitive: false)
        .sortByCreatedAtDesc()
        .findAll();
    return links.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<Link>> searchByTopic(TopicType topic) async {
    final isar = await db;
    final links = await isar.linkModels
        .filter()
        .topicEqualTo(topic)
        .sortByCreatedAtDesc()
        .findAll();
    return links.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<String>> getAllTags() async {
    final isar = await db;
    final links = await isar.linkModels.where().findAll();
    final Set<String> allTags = {};
    for (final link in links) {
      allTags.addAll(link.tags);
    }
    return allTags.toList()..sort();
  }

  @override
  Future<Link?> findByUrl(String url) async {
    final isar = await db;
    final link = await isar.linkModels
        .filter()
        .urlEqualTo(url, caseSensitive: false)
        .findFirst();
    return link?.toEntity();
  }

  // ---- Vault Hub / Library queries ----

  @override
  Future<int> countByKind(String kind, {bool excludeMobile = false}) async {
    final isar = await db;
    return isar.linkModels
        .filter()
        .itemKindEqualTo(kind)
        .optional(excludeMobile, (q) => q.not().savedViaEqualTo('mobile'))
        .count();
  }

  @override
  Future<int> countUnread() async {
    final isar = await db;
    return isar.linkModels
        .filter()
        .itemKindEqualTo('content')
        .readStatusEqualTo('unread')
        .count();
  }

  @override
  Future<List<Link>> continueReading({int limit = 10}) async {
    final isar = await db;
    final links = await isar.linkModels
        .filter()
        .itemKindEqualTo('content')
        .readStatusEqualTo('reading')
        .sortByUpdatedAtDesc()
        .limit(limit)
        .findAll();
    return links.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<Link>> latestByKind(String kind,
      {int limit = 10, bool excludeMobile = false}) async {
    final isar = await db;
    final links = await isar.linkModels
        .filter()
        .itemKindEqualTo(kind)
        .optional(excludeMobile, (q) => q.not().savedViaEqualTo('mobile'))
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
    return links.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<Link>> pinned() async {
    final isar = await db;
    // Priority Vault = pinned bookmarks, excluding phone/extension saves.
    final links = await isar.linkModels
        .filter()
        .isPinnedEqualTo(true)
        .itemKindEqualTo('bookmark')
        .not()
        .savedViaEqualTo('mobile')
        .sortByCreatedAtDesc()
        .findAll();
    return links.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<Link>> queryLibrary(LibraryFilter f) async {
    final isar = await db;
    final builder = isar.linkModels
        .filter()
        .itemKindEqualTo(f.kind)
        // Bookmarks view excludes phone/extension saves — those live in the
        // Mobile tab only.
        .optional(
          f.kind == 'bookmark',
          (q) => q.not().savedViaEqualTo('mobile'),
        )
        .optional(
          f.folderId != null,
          (q) => q.folderRemoteIdsElementEqualTo(f.folderId!),
        )
        .optional(
          f.sourceTypes.isNotEmpty,
          (q) => q.anyOf(
            f.sourceTypes,
            (q, ContentType t) => q.contentTypeEqualTo(t),
          ),
        )
        .optional(
          f.readStatuses.isNotEmpty,
          (q) => q.anyOf(
            f.readStatuses,
            (q, String s) => q.readStatusEqualTo(s),
          ),
        )
        .optional(f.starredOnly, (q) => q.isStarredEqualTo(true))
        .optional(
          f.topicLabel != null,
          (q) => q.topicLabelEqualTo(f.topicLabel),
        )
        .optional(
          f.tags.isNotEmpty,
          (q) => q.anyOf(
            f.tags,
            (q, String t) => q.tagsElementEqualTo(t),
          ),
        );

    final models = await switch (f.sort) {
      LibrarySort.newest => builder.sortByCreatedAtDesc().findAll(),
      LibrarySort.oldest => builder.sortByCreatedAt().findAll(),
      LibrarySort.titleAsc => builder.sortByTitle().findAll(),
    };
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<Link>> savedViaMobile({int? limit}) async {
    final isar = await db;
    final q = isar.linkModels
        .filter()
        .savedViaEqualTo('mobile')
        .sortByCreatedAtDesc();
    final models =
        await (limit != null ? q.limit(limit).findAll() : q.findAll());
    return models.map((e) => e.toEntity()).toList();
  }

  // Custom Category methods
  @override
  Future<List<CustomCategory>> getCustomCategories() async {
    final isar = await db;
    final categories = await isar.customCategoryModels
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    return categories.map((e) => e.toEntity()).toList();
  }

  @override
  Future<CustomCategory?> getCustomCategory(int id) async {
    final isar = await db;
    final category = await isar.customCategoryModels.get(id);
    return category?.toEntity();
  }

  @override
  Future<void> saveCustomCategory(CustomCategory category) async {
    final isar = await db;
    final model = CustomCategoryModel.fromEntity(category);
    await isar.writeTxn(() async {
      await isar.customCategoryModels.put(model);
    });
  }

  @override
  Future<void> updateCustomCategory(CustomCategory category) async {
    final isar = await db;
    final model = CustomCategoryModel.fromEntity(category);
    await isar.writeTxn(() async {
      await isar.customCategoryModels.put(model);
    });
  }

  @override
  Future<void> deleteCustomCategory(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.customCategoryModels.delete(id);
    });
  }

  @override
  Future<List<Link>> getLinksByCustomCategory(int categoryId) async {
    final isar = await db;
    final links = await isar.linkModels
        .filter()
        .customCategoryIdEqualTo(categoryId)
        .sortByCreatedAtDesc()
        .findAll();
    return links.map((e) => e.toEntity()).toList();
  }
}
