import '../repositories/i_link_repository.dart';

class DeleteLink {
  final ILinkRepository repository;

  DeleteLink(this.repository);

  Future<void> call(int id) {
    return repository.deleteLink(id);
  }
}
