import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/platform_type.dart';
import '../../domain/entities/sync_types.dart';
import '../providers/sync_providers.dart';
import '../theme/notion_theme.dart';
import '../widgets/status_chip.dart';
import '../widgets/magic/magic.dart';
import 'reader_screen.dart';

class LinkDetailScreen extends ConsumerStatefulWidget {
  final Link link;

  const LinkDetailScreen({super.key, required this.link});

  @override
  ConsumerState<LinkDetailScreen> createState() => _LinkDetailScreenState();
}

class _LinkDetailScreenState extends ConsumerState<LinkDetailScreen> {
  late Link _currentLink;
  bool _isRefreshingMetadata = false;

  @override
  void initState() {
    super.initState();
    _currentLink = widget.link;
  }

  Future<void> _launchUrl(String url) async {
    final cleanUrl = url.trim().replaceAll(
      RegExp(r'[\u200B-\u200D\uFEFF\uFFFC]'),
      '',
    );
    final uri = Uri.parse(cleanUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Optimistic edit of the fields the server accepts from clients
  /// (title / pin / star / read); the sync service pushes it.
  Future<void> _applyUpdate(Link updated) async {
    setState(() => _currentLink = updated);
    try {
      final result = await ref.read(syncControllerProvider).updateLink(updated);
      if (mounted) setState(() => _currentLink = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Change queued — will sync when online'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteLink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete link?'),
        content: const Text('This removes it from all your devices.'),
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
    await ref.read(syncControllerProvider).deleteLink(_currentLink);
    if (mounted) Navigator.of(context).pop();
  }

  /// Re-run the server AI pipeline (parse → enrich). Repopulates the real
  /// thumbnail/summary/tags server-side; Realtime streams the result back.
  Future<void> _retryAi() async {
    if (_isRefreshingMetadata) return;
    setState(() => _isRefreshingMetadata = true);
    try {
      await ref.read(syncControllerProvider).retryAi(_currentLink);
      if (mounted) {
        setState(() =>
            _currentLink = _currentLink.copyWith(status: ItemStatus.pending));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Re-running AI… the card will update shortly.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshingMetadata = false);
    }
  }

  FaIconData _getPlatformIcon(PlatformType platform) {
    switch (platform) {
      case PlatformType.facebook:
        return FontAwesomeIcons.facebook;
      case PlatformType.instagram:
        return FontAwesomeIcons.instagram;
      case PlatformType.twitter:
        return FontAwesomeIcons.xTwitter;
      case PlatformType.youtube:
        return FontAwesomeIcons.youtube;
      case PlatformType.linkedin:
        return FontAwesomeIcons.linkedin;
      case PlatformType.other:
        return FontAwesomeIcons.link;
    }
  }

  Color _getPlatformColor(PlatformType platform) {
    switch (platform) {
      case PlatformType.facebook:
        return const Color(0xFF1877F2);
      case PlatformType.instagram:
        return const Color(0xFFE4405F);
      case PlatformType.twitter:
        return NotionTheme.white; // X's black mark is invisible on navy
      case PlatformType.youtube:
        return const Color(0xFFFF0000);
      case PlatformType.linkedin:
        return const Color(0xFF3B82F6);
      case PlatformType.other:
        return NotionTheme.fog2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = _currentLink;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor =
        isDark ? NotionTheme.darkDivider : NotionTheme.dividerColor;
    final textColor =
        isDark ? NotionTheme.darkTextPrimary : NotionTheme.primaryBlack;
    final subtextColor =
        isDark ? NotionTheme.darkTextSecondary : NotionTheme.textGray;
    final sidebarColor =
        isDark ? NotionTheme.darkSidebar : NotionTheme.sidebarColor;
    final isRead = link.readStatus == 'read';

    return Scaffold(
      backgroundColor: NotionTheme.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            FaIcon(
              _getPlatformIcon(link.platform),
              size: 18,
              color: _getPlatformColor(link.platform),
            ),
            const SizedBox(width: 8),
            Text(link.platform.displayName,
                style: theme.textTheme.titleMedium),
          ],
        ),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(
              link.isStarred ? Icons.star : Icons.star_border,
              color: link.isStarred ? Colors.amber[600] : textColor,
            ),
            onPressed: () =>
                _applyUpdate(link.copyWith(isStarred: !link.isStarred)),
            tooltip: link.isStarred ? 'Unstar' : 'Star',
          ),
          IconButton(
            icon: Icon(
              link.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: textColor,
            ),
            onPressed: () =>
                _applyUpdate(link.copyWith(isPinned: !link.isPinned)),
            tooltip: link.isPinned ? 'Unpin' : 'Pin',
          ),
          IconButton(
            icon: Icon(Icons.share, color: textColor),
            onPressed: () async {
              try {
                await Share.share(link.url, subject: link.title);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to share'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
          PopupMenuButton<String>(
            iconColor: textColor,
            onSelected: (action) {
              if (action == 'refresh') _retryAi();
              if (action == 'delete') _deleteLink();
              if (action == 'read') {
                _applyUpdate(
                    link.copyWith(readStatus: isRead ? 'unread' : 'read'));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'read',
                child: Text(isRead ? 'Mark as unread' : 'Mark as read'),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Retry AI'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: AuraBackground(
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            if (link.imageUrl != null)
              SizedBox(
                width: double.infinity,
                height: 200,
                child: CachedNetworkImage(
                  imageUrl: link.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: sidebarColor,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: sidebarColor,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: subtextColor,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 120,
                color: sidebarColor,
                child: Center(
                  child: Icon(Icons.link, size: 48, color: subtextColor),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(link.title,
                            style: theme.textTheme.displayMedium),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(link: link),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (link.publisherName != null) ...[
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 16, color: subtextColor),
                        const SizedBox(width: 4),
                        Text(
                          link.publisherName!,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: subtextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // URL (tappable)
                  InkWell(
                    onTap: () => _launchUrl(link.url),
                    child: Row(
                      children: [
                        Icon(Icons.link, size: 16, color: theme.primaryColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            link.url,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          color: subtextColor,
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: link.url),
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Link copied'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(color: borderColor),
                  const SizedBox(height: 16),

                  // Summary (generated by the server pipeline)
                  _buildSectionHeader(
                    context,
                    icon: Icons.auto_awesome,
                    title: 'AI Summary',
                    iconColor: theme.colorScheme.primary,
                    textColor: subtextColor,
                  ),
                  const SizedBox(height: 8),
                  if (link.summary != null || link.aiDescription != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        link.summary ?? link.aiDescription!,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sidebarColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        link.status.isProcessing
                            ? 'The summary is being generated — it usually '
                                'takes about a minute.'
                            : 'No AI summary available for this item.',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: subtextColor),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Key points
                  if (link.keyPoints.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      icon: Icons.format_list_bulleted,
                      title: 'Key Points',
                      textColor: subtextColor,
                    ),
                    const SizedBox(height: 8),
                    ...link.keyPoints.map(
                      (point) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(point,
                                  style: theme.textTheme.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  if (link.description != null) ...[
                    _buildSectionHeader(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Description',
                      textColor: subtextColor,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: sidebarColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        link.description!,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Tags
                  if (link.tags.isNotEmpty) ...[
                    Divider(color: borderColor),
                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      context,
                      icon: Icons.tag,
                      title: 'Tags',
                      textColor: subtextColor,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: link.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: sidebarColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            '#$tag',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Details
                  Divider(color: borderColor),
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                    context,
                    icon: Icons.info_outline,
                    title: 'Details',
                    textColor: subtextColor,
                  ),
                  const SizedBox(height: 8),
                  ...[
                    _buildMetadataRow(
                      context,
                      icon: Icons.category_outlined,
                      label: 'Topic',
                      value: link.topicLabel ?? link.topic.displayName,
                      textColor: textColor,
                      subtextColor: subtextColor,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _buildMetadataRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Added',
                    value: DateFormat.yMMMd().add_jm().format(link.createdAt),
                    textColor: textColor,
                    subtextColor: subtextColor,
                  ),
                  const SizedBox(height: 8),
                  _buildMetadataRow(
                    context,
                    icon: isRead
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    label: 'Read status',
                    value: link.readStatus,
                    textColor: textColor,
                    subtextColor: subtextColor,
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReaderScreen(link: link),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chrome_reader_mode_outlined),
                          label: const Text('Reader'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchUrl(link.url),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open Link'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NotionTheme.lime,
                            foregroundColor: NotionTheme.ink,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? textColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor ?? textColor ?? NotionTheme.textGray,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor ?? NotionTheme.textGray,
              ),
        ),
      ],
    );
  }

  Widget _buildMetadataRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? textColor,
    Color? subtextColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: subtextColor ?? NotionTheme.textGray),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: subtextColor ?? NotionTheme.textGray,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: textColor),
          ),
        ),
      ],
    );
  }
}
