import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/datasources/remote/supabase_datasource.dart';
import '../../domain/entities/link.dart';
import '../providers/sync_providers.dart';
import '../theme/notion_theme.dart';
import '../widgets/status_chip.dart';
import '../widgets/magic/magic.dart';
import 'link_detail_screen.dart';

/// Links inside one server-side folder.
class FolderItemsScreen extends ConsumerWidget {
  final RemoteFolder folder;

  const FolderItemsScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtextColor =
        isDark ? NotionTheme.darkTextSecondary : NotionTheme.textGray;
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
                            ?.copyWith(color: subtextColor),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: links.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _FolderLinkCard(link: links[index], isDark: isDark),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      )),
    );
  }
}

class _FolderLinkCard extends StatelessWidget {
  final Link link;
  final bool isDark;

  const _FolderLinkCard({required this.link, required this.isDark});

  /// Website icon: server favicon_url first, else Google's favicon service.
  String? get _faviconUrl {
    if (link.faviconUrl != null && link.faviconUrl!.isNotEmpty) {
      return link.faviconUrl;
    }
    final host = Uri.tryParse(link.url)?.host;
    if (host == null || host.isEmpty) return null;
    return 'https://www.google.com/s2/favicons?domain=$host&sz=64';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        isDark ? NotionTheme.darkDivider : NotionTheme.dividerColor;
    final backgroundColor = isDark ? NotionTheme.darkSurface : Colors.white;
    final aiSummary = link.aiDescription ?? link.summary ?? link.description;
    final favicon = _faviconUrl;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LinkDetailScreen(link: link)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Website icon (favicon) — falls back to the thumbnail, then a glyph.
            SizedBox(
              width: 50,
              height: 50,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: isDark ? Colors.white12 : Colors.grey[100],
                  alignment: Alignment.center,
                  child: favicon != null
                      ? CachedNetworkImage(
                          imageUrl: favicon,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => link.imageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: link.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.link, size: 20),
                                )
                              : const Icon(Icons.link, size: 20),
                        )
                      : (link.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: link.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.link, size: 20),
                            )
                          : const Icon(Icons.link, size: 20)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  // AI summary of the link (same source as FolderDetailScreen).
                  if (aiSummary != null && aiSummary.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 12,
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            aiSummary.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(link.platform.displayName,
                          style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      StatusChip(link: link),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
