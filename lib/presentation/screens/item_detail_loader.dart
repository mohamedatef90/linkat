import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/link.dart';
import '../providers/link_providers.dart';
import '../theme/notion_theme.dart';
import 'link_detail_screen.dart';

/// Resolves an item by its server id (the `/item/:id` deep link) and renders
/// the existing detail screen. Powers card taps, push notifications and
/// share-sheet deep links.
class ItemDetailLoader extends ConsumerWidget {
  final String remoteId;

  const ItemDetailLoader({super.key, required this.remoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(allLinksProvider);

    return linksAsync.when(
      data: (links) {
        Link? match;
        for (final l in links) {
          if (l.remoteId == remoteId) {
            match = l;
            break;
          }
        }
        if (match == null) {
          return Scaffold(
            backgroundColor: NotionTheme.ink,
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: const Center(
              child: Text('Item not found',
                  style: TextStyle(color: NotionTheme.fog2)),
            ),
          );
        }
        return LinkDetailScreen(link: match);
      },
      loading: () => const Scaffold(
        backgroundColor: NotionTheme.ink,
        body: Center(child: CircularProgressIndicator(color: NotionTheme.lime)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: NotionTheme.ink,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}
