import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sync_providers.dart';
import '../theme/notion_theme.dart';
import '../widgets/magic/magic.dart';
import 'folder_items_screen.dart';

/// CRUD for server-side folders (shared with the web app).
class ManageFoldersScreen extends ConsumerWidget {
  const ManageFoldersScreen({super.key});

  Future<void> _createFolder(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(supabaseDatasourceProvider).createFolder(name);
      ref.invalidate(foldersProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create folder: $e')),
        );
      }
    }
  }

  Future<void> _renameFolder(
      BuildContext context, WidgetRef ref, String id, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == current) return;
    try {
      await ref.read(supabaseDatasourceProvider).renameFolder(id, name);
      ref.invalidate(foldersProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not rename folder: $e')),
        );
      }
    }
  }

  Future<void> _deleteFolder(
      BuildContext context, WidgetRef ref, String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "$name"?'),
        content: const Text(
            'Links stay in your library; they just leave this folder.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(supabaseDatasourceProvider).deleteFolder(id);
      ref.invalidate(foldersProvider);
      ref.read(syncControllerProvider).syncNow();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete folder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtextColor =
        isDark ? NotionTheme.darkTextSecondary : NotionTheme.textGray;
    final foldersAsync = ref.watch(foldersProvider);

    return Scaffold(
      backgroundColor: NotionTheme.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Folders', style: theme.textTheme.titleMedium),
      ),
      body: AuraBackground(
        child: foldersAsync.when(
        data: (folders) => folders.isEmpty
            ? Center(
                child: Text(
                  'No folders yet',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: subtextColor),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: folders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(folder.name),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FolderItemsScreen(folder: folder),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'rename') {
                          _renameFolder(context, ref, folder.id, folder.name);
                        } else if (action == 'delete') {
                          _deleteFolder(context, ref, folder.id, folder.name);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Folders unavailable offline',
            style: theme.textTheme.bodyMedium?.copyWith(color: subtextColor),
          ),
        ),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createFolder(context, ref),
        child: const Icon(Icons.create_new_folder_outlined),
      ),
    );
  }
}
