import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/content_type.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/sync_types.dart';
import '../providers/sync_providers.dart';
import '../screens/reader_screen.dart';
import '../theme/notion_theme.dart';
import 'status_chip.dart';

/// The one card used across Vault Hub, Library and folder views. Dark-only
/// (magic_black glass), with web-parity affordances: kind badge, status +
/// Retry AI, star, read-status pill, and a kind-aware primary action.
class LinkCard extends ConsumerWidget {
  final Link link;

  const LinkCard({super.key, required this.link});

  bool get _isContent => link.itemKind == 'content';

  String? get _faviconUrl {
    if (link.faviconUrl != null && link.faviconUrl!.isNotEmpty) {
      return link.faviconUrl;
    }
    final host = Uri.tryParse(link.url)?.host;
    if (host == null || host.isEmpty) return null;
    return 'https://www.google.com/s2/favicons?domain=$host&sz=64';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final aiSummary = link.aiDescription ?? link.summary ?? link.description;

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: NotionTheme.panel.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NotionTheme.borderSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _thumbnail(theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _kindBadge(),
                            const SizedBox(width: 8),
                            Flexible(child: StatusChip(link: link)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          link.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (aiSummary != null && aiSummary.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.auto_awesome,
                                  size: 10, color: NotionTheme.lime),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  aiSummary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: NotionTheme.fog,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _footer(context, ref, theme),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail(ThemeData theme) {
    final img = link.imageUrl;
    final favicon = _faviconUrl;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 72,
            height: 72,
            child: img != null
                ? CachedNetworkImage(
                    imageUrl: img,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => _thumbPlaceholder(),
                    errorWidget: (_, _, _) => _thumbFallback(favicon),
                  )
                : _thumbFallback(favicon),
          ),
        ),
        if (_isContent)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _contentTypeColor(link.contentType)
                    .withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                link.contentType.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _thumbPlaceholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [NotionTheme.panelElevated, NotionTheme.panel],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: NotionTheme.lime),
          ),
        ),
      );

  Widget _thumbFallback(String? favicon) {
    if (!_isContent && favicon != null) {
      return Container(
        color: NotionTheme.panelElevated,
        padding: const EdgeInsets.all(18),
        child: CachedNetworkImage(
          imageUrl: favicon,
          fit: BoxFit.contain,
          errorWidget: (_, _, _) =>
              const Icon(Icons.link, size: 24, color: NotionTheme.fog2),
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [NotionTheme.panelElevated, NotionTheme.panel],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child:
            Text(link.contentType.emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  Widget _kindBadge() {
    // Content: icon-only book badge (the thumbnail type-badge already names the
    // specific type — Article / Video / Reel…). Bookmark: icon + label, since
    // bookmarks carry no type badge.
    final content = _isContent;
    final color = content ? NotionTheme.lime : NotionTheme.fog2;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: content ? 5 : 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(content ? Icons.menu_book_rounded : Icons.bookmark_border,
              size: 11, color: color),
          if (!content) ...[
            const SizedBox(width: 4),
            Text(
              'Bookmark',
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, WidgetRef ref, ThemeData theme) {
    final isFailed =
        link.status == ItemStatus.failed || link.status == ItemStatus.degraded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          if (_isContent)
            _readStatusPill(ref)
          else
            Text(_dateLabel(), style: theme.textTheme.bodySmall),
          const Spacer(),
          _iconButton(
            icon: link.isStarred ? Icons.star : Icons.star_border,
            color: link.isStarred ? NotionTheme.accentYellow : NotionTheme.fog2,
            onTap: () => ref.read(syncControllerProvider).updateLink(
                  link.copyWith(isStarred: !link.isStarred),
                ),
          ),
          if (isFailed) ...[
            const SizedBox(width: 6),
            _iconButton(
              icon: Icons.refresh,
              color: NotionTheme.accentOrange,
              onTap: () => _retry(context, ref),
            ),
          ],
          const SizedBox(width: 6),
          _primaryButton(context),
        ],
      ),
    );
  }

  Widget _readStatusPill(WidgetRef ref) {
    final (label, color) = switch (link.readStatus) {
      'reading' => ('Reading', NotionTheme.lime),
      'read' => ('Read', NotionTheme.fog2),
      _ => ('Unread', NotionTheme.accentBlue),
    };
    return GestureDetector(
      onTap: () => ref
          .read(syncControllerProvider)
          .updateLink(link.copyWith(readStatus: _nextReadStatus())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  String _nextReadStatus() {
    switch (link.readStatus) {
      case 'unread':
        return 'reading';
      case 'reading':
        return 'read';
      default:
        return 'unread';
    }
  }

  Widget _primaryButton(BuildContext context) {
    final label = _isContent
        ? switch (link.readStatus) {
            'reading' => 'Continue',
            'read' => 'Read again',
            _ => 'Read',
          }
        : 'Visit site';
    final icon =
        _isContent ? Icons.menu_book_rounded : Icons.open_in_new_rounded;
    return InkWell(
      onTap: () => _isContent ? _openReader(context) : _visitSite(),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: NotionTheme.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: NotionTheme.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 11, color: NotionTheme.ink),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  String _dateLabel() {
    final d = link.publishedAt ?? link.createdAt;
    return DateFormat('MMM d, y').format(d);
  }

  void _openDetail(BuildContext context) {
    if (link.remoteId != null) {
      context.push('/item/${link.remoteId}');
    } else {
      _openReader(context);
    }
  }

  void _openReader(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ReaderScreen(link: link)),
    );
  }

  Future<void> _visitSite() async {
    final cleanUrl = link.url
        .trim()
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\uFFFC]'), '');
    final uri = Uri.tryParse(cleanUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(syncControllerProvider).retryAi(link);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Re-running AI… the card will update shortly.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static Color _contentTypeColor(ContentType type) {
    switch (type) {
      case ContentType.video:
      case ContentType.profile:
        return NotionTheme.accentBlue;
      case ContentType.reel:
      case ContentType.music:
        return NotionTheme.accentPink;
      case ContentType.short:
      case ContentType.podcast:
        return NotionTheme.accentOrange;
      case ContentType.post:
      case ContentType.thread:
        return NotionTheme.accentPurple;
      case ContentType.article:
        return NotionTheme.accentGreen;
      case ContentType.image:
        return NotionTheme.accentCyan;
      case ContentType.story:
        return NotionTheme.accentYellow;
      case ContentType.other:
        return NotionTheme.textGray;
    }
  }
}
