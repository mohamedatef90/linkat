import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/supabase_datasource.dart';
import '../providers/sync_providers.dart';
import '../theme/notion_theme.dart';
import '../widgets/link_card.dart';
import '../widgets/magic/magic.dart';

/// Links inside one server-side folder (reached from Manage Folders).
class FolderItemsScreen extends ConsumerWidget {
  final RemoteFolder folder;

  const FolderItemsScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final linksAsync = ref.watch(linksByFolderProvider(folder.id));

    return Scaffold(
      backgroundColor: NotionTheme.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(folder.name, style: theme.textTheme.titleMedium),
      ),
      body: AuraBackground(
        child: RefreshIndicator(
          onRefresh: () => ref.read(syncControllerProvider).syncNow(),
          child: linksAsync.when(
            data: (links) => links.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(
                          'No links in this folder yet',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: NotionTheme.fog2),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: links.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        LinkCard(link: links[index]),
                  ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: NotionTheme.lime),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }
}
