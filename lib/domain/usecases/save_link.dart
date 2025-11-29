import '../entities/link.dart';
import '../repositories/i_link_repository.dart';

class SaveLink {
  final ILinkRepository repository;

  SaveLink(this.repository);

  Future<void> call(Link link) {
    return repository.saveLink(link);
  }
}
