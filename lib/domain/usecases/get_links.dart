import '../entities/link.dart';
import '../entities/platform_type.dart';
import '../repositories/i_link_repository.dart';

class GetLinks {
  final ILinkRepository repository;

  GetLinks(this.repository);

  Future<List<Link>> call({PlatformType? platform}) {
    return repository.getLinks(platform: platform);
  }
}
