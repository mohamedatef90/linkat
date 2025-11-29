import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/link_repository_impl.dart';
import '../../data/services/metadata_service.dart';
import '../../data/services/platform_detection_service.dart';
import '../../data/services/topic_classification_service.dart';
import '../../data/services/ai_description_service.dart';
import '../../data/services/ai_classification_service.dart';
import '../../data/services/ai_search_service.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/platform_type.dart';
import '../../domain/entities/topic_type.dart';
import '../../domain/repositories/i_link_repository.dart';
import '../../domain/usecases/delete_link.dart';
import '../../domain/usecases/get_links.dart';
import '../../domain/usecases/save_link.dart';

final linkRepositoryProvider = Provider<ILinkRepository>((ref) {
  return LinkRepositoryImpl();
});

final platformDetectionServiceProvider = Provider<PlatformDetectionService>((
  ref,
) {
  return PlatformDetectionService();
});

final metadataServiceProvider = Provider<MetadataService>((ref) {
  return MetadataService();
});

final aiDescriptionServiceProvider = Provider<AiDescriptionService>((ref) {
  return AiDescriptionService();
});

final aiClassificationServiceProvider = Provider<AiClassificationService>((ref) {
  return AiClassificationService();
});

final aiSearchServiceProvider = Provider<AiSearchService>((ref) {
  return AiSearchService();
});

final topicClassificationServiceProvider = Provider<TopicClassificationService>(
  (ref) {
    return TopicClassificationService();
  },
);

final getLinksUseCaseProvider = Provider<GetLinks>((ref) {
  return GetLinks(ref.watch(linkRepositoryProvider));
});

final saveLinkUseCaseProvider = Provider<SaveLink>((ref) {
  return SaveLink(ref.watch(linkRepositoryProvider));
});

final deleteLinkUseCaseProvider = Provider<DeleteLink>((ref) {
  return DeleteLink(ref.watch(linkRepositoryProvider));
});

final linksProvider = FutureProvider.family<List<Link>, PlatformType?>((
  ref,
  platform,
) async {
  final getLinks = ref.watch(getLinksUseCaseProvider);
  return getLinks(platform: platform);
});

final searchLinksProvider = FutureProvider.family<List<Link>, String>((
  ref,
  query,
) async {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.searchLinks(query);
});

final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.getAllTags();
});

final linksByTagProvider = FutureProvider.family<List<Link>, String>((
  ref,
  tag,
) async {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.searchByTag(tag);
});

final linksByTopicProvider = FutureProvider.family<List<Link>, TopicType>((
  ref,
  topic,
) async {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.searchByTopic(topic);
});

final allLinksProvider = FutureProvider<List<Link>>((ref) async {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.getAllLinks();
});

final updateLinkProvider = Provider<Future<void> Function(Link)>((ref) {
  final repository = ref.watch(linkRepositoryProvider);
  return (Link link) => repository.updateLink(link);
});

final findLinkByUrlProvider = FutureProvider.family<Link?, String>((
  ref,
  url,
) async {
  final repository = ref.watch(linkRepositoryProvider);
  return repository.findByUrl(url);
});
