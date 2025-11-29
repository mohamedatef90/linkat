import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/platform_type.dart';
import '../../domain/entities/topic_type.dart';
import '../../domain/repositories/i_link_repository.dart';
import '../models/link_model.dart';

class LinkRepositoryImpl implements ILinkRepository {
  late Future<Isar> db;

  LinkRepositoryImpl() {
    db = _initDb();
  }

  Future<Isar> _initDb() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open([LinkModelSchema], directory: dir.path);
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
}
