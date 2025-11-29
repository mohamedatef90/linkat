import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/platform_type.dart';
import '../../domain/entities/topic_type.dart';
import '../../data/services/translation_service.dart';
import '../providers/link_providers.dart';
import '../theme/notion_theme.dart';

final _translationServiceProvider = Provider<TranslationService>((ref) {
  return TranslationService();
});

class LinkDetailScreen extends ConsumerStatefulWidget {
  final Link link;

  const LinkDetailScreen({super.key, required this.link});

  @override
  ConsumerState<LinkDetailScreen> createState() => _LinkDetailScreenState();
}

class _LinkDetailScreenState extends ConsumerState<LinkDetailScreen> {
  String? _translatedSummary;
  String? _translatedDescription;
  bool _isTranslating = false;
  String _selectedLanguage = 'Arabic';
  late TopicType _currentTopic;
  late Link _currentLink;

  @override
  void initState() {
    super.initState();
    _currentTopic = widget.link.topic;
    _currentLink = widget.link;
  }

  final List<String> _languages = [
    'Arabic',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
    'Korean',
    'Portuguese',
    'Russian',
    'Italian',
  ];

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

  Future<void> _translateContent() async {
    final translationService = ref.read(_translationServiceProvider);

    if (!translationService.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Translation service not available. Check API key.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    // Translate AI summary if available
    if (widget.link.aiDescription != null) {
      final translated = await translationService.translate(
        text: widget.link.aiDescription!,
        targetLanguage: _selectedLanguage,
      );
      if (mounted) {
        setState(() {
          _translatedSummary = translated;
        });
      }
    }

    // Translate description if available
    if (widget.link.description != null) {
      final translated = await translationService.translate(
        text: widget.link.description!,
        targetLanguage: _selectedLanguage,
      );
      if (mounted) {
        setState(() {
          _translatedDescription = translated;
        });
      }
    }

    if (mounted) {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  void _clearTranslation() {
    setState(() {
      _translatedSummary = null;
      _translatedDescription = null;
    });
  }

  Future<void> _showTopicSelector() async {
    final selectedTopic = await showModalBottomSheet<TopicType>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _TopicSelectorSheet(currentTopic: _currentTopic),
    );

    if (selectedTopic != null && selectedTopic != _currentTopic) {
      await _updateTopic(selectedTopic);
    }
  }

  Future<void> _updateTopic(TopicType newTopic) async {
    final updateLink = ref.read(updateLinkProvider);

    final updatedLink = Link(
      id: _currentLink.id,
      url: _currentLink.url,
      title: _currentLink.title,
      description: _currentLink.description,
      imageUrl: _currentLink.imageUrl,
      platform: _currentLink.platform,
      topic: newTopic,
      createdAt: _currentLink.createdAt,
      publisherName: _currentLink.publisherName,
      aiDescription: _currentLink.aiDescription,
      tags: _currentLink.tags,
    );

    try {
      await updateLink(updatedLink);

      setState(() {
        _currentTopic = newTopic;
        _currentLink = updatedLink;
      });

      // Invalidate providers to refresh data
      ref.invalidate(allLinksProvider);
      ref.invalidate(linksByTopicProvider(newTopic));
      ref.invalidate(linksProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Topic updated to ${newTopic.displayName}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update topic'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  IconData _getTopicIcon(TopicType topic) {
    switch (topic) {
      case TopicType.aiTech:
        return Icons.psychology;
      case TopicType.development:
        return Icons.code;
      case TopicType.productUX:
        return Icons.design_services;
      case TopicType.design:
        return Icons.palette;
      case TopicType.business:
        return Icons.business;
      case TopicType.science:
        return Icons.science;
      case TopicType.entertainment:
        return Icons.movie;
      case TopicType.other:
        return Icons.more_horiz;
    }
  }

  Color _getTopicColor(TopicType topic) {
    switch (topic) {
      case TopicType.aiTech:
        return const Color(0xFF9333EA);
      case TopicType.development:
        return const Color(0xFF06B6D4);
      case TopicType.productUX:
        return const Color(0xFF3B82F6);
      case TopicType.design:
        return const Color(0xFFEC4899);
      case TopicType.business:
        return const Color(0xFF10B981);
      case TopicType.science:
        return const Color(0xFFF59E0B);
      case TopicType.entertainment:
        return const Color(0xFFEF4444);
      case TopicType.other:
        return NotionTheme.textGray;
    }
  }

  IconData _getPlatformIcon(PlatformType platform) {
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
        return const Color(0xFF000000);
      case PlatformType.youtube:
        return const Color(0xFFFF0000);
      case PlatformType.linkedin:
        return const Color(0xFF0A66C2);
      case PlatformType.other:
        return NotionTheme.textGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = _currentLink;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            FaIcon(
              _getPlatformIcon(link.platform),
              size: 18,
              color: _getPlatformColor(link.platform),
            ),
            const SizedBox(width: 8),
            Text(link.platform.displayName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              try {
                await Share.share(
                  link.url,
                  subject: link.title,
                );
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
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            if (link.imageUrl != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: NotionTheme.sidebarColor,
                  image: DecorationImage(
                    image: NetworkImage(link.imageUrl!),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 120,
                color: NotionTheme.sidebarColor,
                child: const Center(
                  child: Icon(
                    Icons.link,
                    size: 48,
                    color: NotionTheme.textGray,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    link.title,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),

                  const SizedBox(height: 8),

                  // Publisher name
                  if (link.publisherName != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 16,
                          color: NotionTheme.textGray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          link.publisherName!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NotionTheme.textGray,
                          ),
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
                        const Icon(
                          Icons.link,
                          size: 16,
                          color: Color(0xFF2382E2),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            link.url,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF2382E2),
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          color: NotionTheme.textGray,
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: link.url));
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
                  const Divider(color: NotionTheme.dividerColor),
                  const SizedBox(height: 16),

                  // AI Summary Section
                  if (link.aiDescription != null) ...[
                    _buildSectionHeader(
                      context,
                      icon: Icons.auto_awesome,
                      title: 'AI Summary',
                      iconColor: const Color(0xFF9333EA),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE9D5FF)),
                      ),
                      child: Text(
                        _translatedSummary ?? link.aiDescription!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Description Section
                  if (link.description != null) ...[
                    _buildSectionHeader(
                      context,
                      icon: Icons.description_outlined,
                      title: 'Description',
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NotionTheme.sidebarColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: NotionTheme.dividerColor),
                      ),
                      child: Text(
                        _translatedDescription ?? link.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: NotionTheme.textGray,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Translation Section
                  if (link.aiDescription != null || link.description != null) ...[
                    const Divider(color: NotionTheme.dividerColor),
                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      context,
                      icon: Icons.translate,
                      title: 'Translate',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: NotionTheme.sidebarColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: NotionTheme.dividerColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedLanguage,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: _languages.map((lang) {
                                  return DropdownMenuItem(
                                    value: lang,
                                    child: Text(lang),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedLanguage = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isTranslating ? null : _translateContent,
                          icon: _isTranslating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.translate, size: 18),
                          label: Text(_isTranslating ? 'Translating...' : 'Translate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NotionTheme.primaryBlack,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_translatedSummary != null || _translatedDescription != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _clearTranslation,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Show original'),
                        style: TextButton.styleFrom(
                          foregroundColor: NotionTheme.textGray,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],

                  // Tags Section
                  if (link.tags.isNotEmpty) ...[
                    const Divider(color: NotionTheme.dividerColor),
                    const SizedBox(height: 16),
                    _buildSectionHeader(
                      context,
                      icon: Icons.tag,
                      title: 'Tags',
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
                            color: NotionTheme.sidebarColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: NotionTheme.dividerColor),
                          ),
                          child: Text(
                            '#$tag',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: NotionTheme.textGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Metadata Section
                  const Divider(color: NotionTheme.dividerColor),
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                    context,
                    icon: Icons.info_outline,
                    title: 'Details',
                  ),
                  const SizedBox(height: 8),
                  // Topic row with edit button
                  InkWell(
                    onTap: _showTopicSelector,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getTopicColor(_currentTopic).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getTopicColor(_currentTopic).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTopicIcon(_currentTopic),
                            size: 16,
                            color: _getTopicColor(_currentTopic),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentTopic.displayName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _getTopicColor(_currentTopic),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit,
                            size: 14,
                            color: _getTopicColor(_currentTopic),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMetadataRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Added',
                    value: DateFormat.yMMMd().add_jm().format(link.createdAt),
                  ),

                  const SizedBox(height: 24),

                  // Open Link Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUrl(link.url),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Link'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NotionTheme.primaryBlack,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor ?? NotionTheme.textGray,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: NotionTheme.textGray,
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
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: NotionTheme.textGray,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: NotionTheme.textGray,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _TopicSelectorSheet extends StatelessWidget {
  final TopicType currentTopic;

  const _TopicSelectorSheet({required this.currentTopic});

  IconData _getTopicIcon(TopicType topic) {
    switch (topic) {
      case TopicType.aiTech:
        return Icons.psychology;
      case TopicType.development:
        return Icons.code;
      case TopicType.productUX:
        return Icons.design_services;
      case TopicType.design:
        return Icons.palette;
      case TopicType.business:
        return Icons.business;
      case TopicType.science:
        return Icons.science;
      case TopicType.entertainment:
        return Icons.movie;
      case TopicType.other:
        return Icons.more_horiz;
    }
  }

  Color _getTopicColor(TopicType topic) {
    switch (topic) {
      case TopicType.aiTech:
        return const Color(0xFF9333EA);
      case TopicType.development:
        return const Color(0xFF06B6D4);
      case TopicType.productUX:
        return const Color(0xFF3B82F6);
      case TopicType.design:
        return const Color(0xFFEC4899);
      case TopicType.business:
        return const Color(0xFF10B981);
      case TopicType.science:
        return const Color(0xFFF59E0B);
      case TopicType.entertainment:
        return const Color(0xFFEF4444);
      case TopicType.other:
        return NotionTheme.textGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.category, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Select Topic',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: NotionTheme.dividerColor, height: 1),
          ...TopicType.values.map((topic) {
            final isSelected = topic == currentTopic;
            final color = _getTopicColor(topic);
            return ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTopicIcon(topic),
                  size: 18,
                  color: color,
                ),
              ),
              title: Text(
                topic.displayName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_circle, color: color)
                  : null,
              onTap: () => Navigator.of(context).pop(topic),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
