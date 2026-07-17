import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/remote/supabase_datasource.dart';
import '../../domain/entities/link.dart';
import '../providers/sync_providers.dart';
import '../theme/notion_theme.dart';
import '../widgets/status_chip.dart';
import '../widgets/magic/magic.dart';

/// Reading view for an enriched item: summary, key points, tags, and the
/// full extracted text (fetched from the server when the screen opens).
class ReaderScreen extends ConsumerStatefulWidget {
  final Link link;

  const ReaderScreen({super.key, required this.link});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  Link get link => widget.link;

  // AI translation (Arabic) — fetched on demand, cached server-side.
  TranslationResult? _translation;
  bool _translating = false;
  bool _showArabic = false;
  String? _translateError;

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _translate() async {
    // Once fetched, the button just toggles Arabic on/off.
    if (_translation != null) {
      setState(() => _showArabic = !_showArabic);
      return;
    }
    if (link.remoteId == null) return;
    setState(() {
      _translating = true;
      _translateError = null;
    });
    try {
      final result = await ref
          .read(supabaseDatasourceProvider)
          .translate(link.remoteId!, lang: 'ar');
      if (!mounted) return;
      setState(() {
        _translation = result;
        _showArabic = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _translateError = 'تعذّرت الترجمة · Translation failed');
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? NotionTheme.darkDivider : NotionTheme.dividerColor;
    final subtextColor =
        isDark ? NotionTheme.darkTextSecondary : NotionTheme.textGray;
    final surfaceColor =
        isDark ? NotionTheme.darkSurface : NotionTheme.backgroundOffWhite;

    final contentText = link.remoteId != null
        ? ref.watch(contentTextProvider(link.remoteId!))
        : const AsyncValue<String?>.data(null);

    return Scaffold(
      backgroundColor: NotionTheme.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Reader', style: theme.textTheme.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _launchUrl(link.url),
            tooltip: 'Open original',
          ),
        ],
      ),
      body: AuraBackground(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(link.title, style: theme.textTheme.displayMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                if (link.publisherName != null) ...[
                  Flexible(
                    child: Text(
                      link.publisherName!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: subtextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                StatusChip(link: link),
              ],
            ),
            const SizedBox(height: 16),

            // Article / post / reel hero image.
            if (link.imageUrl != null && link.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: link.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // AI translation to Arabic (NVIDIA/Gemini, cached server-side).
            if (link.remoteId != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _translating ? null : _translate,
                  icon: _translating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.translate,
                          size: 16, color: theme.colorScheme.primary),
                  label: Text(
                    _translating
                        ? 'Translating…'
                        : _translation != null
                            ? (_showArabic ? 'Show original' : 'اقرأ بالعربية')
                            : 'ترجم للعربية · Translate to Arabic',
                  ),
                ),
              ),
              if (_translateError != null) ...[
                const SizedBox(height: 8),
                Text(_translateError!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.redAccent)),
              ],
              if (_showArabic && _translation != null) ...[
                const SizedBox(height: 12),
                _arabicCard(theme, surfaceColor, borderColor),
              ],
              const SizedBox(height: 16),
            ],

            if (link.summary != null) ...[
              _sectionTitle(theme, Icons.auto_awesome, 'Summary',
                  theme.colorScheme.primary),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Text(
                  link.summary!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (link.keyPoints.isNotEmpty) ...[
              _sectionTitle(
                  theme, Icons.format_list_bulleted, 'Key points', subtextColor),
              const SizedBox(height: 8),
              ...link.keyPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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
                        child: Text(
                          point,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (link.tags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: link.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text('#$tag', style: theme.textTheme.bodySmall),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],

            Divider(color: borderColor),
            const SizedBox(height: 16),
            _sectionTitle(theme, Icons.article_outlined, 'Article', subtextColor),
            const SizedBox(height: 8),
            contentText.when(
              data: (text) => (text == null || text.isEmpty)
                  ? Text(
                      'Full text is not available for this item.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: subtextColor),
                    )
                  : Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                'Could not load the article text. Pull to refresh later.',
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: subtextColor),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      )),
    );
  }

  /// The Arabic translation, laid out right-to-left.
  Widget _arabicCard(ThemeData theme, Color surfaceColor, Color borderColor) {
    final t = _translation!;
    final primary = theme.colorScheme.primary;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.translate, size: 16, color: primary),
                const SizedBox(width: 6),
                Text('الترجمة العربية',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600, color: primary)),
              ],
            ),
            const SizedBox(height: 10),
            if (t.title != null && t.title!.isNotEmpty) ...[
              Text(t.title!,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.5)),
              const SizedBox(height: 8),
            ],
            if (t.summary != null && t.summary!.isNotEmpty) ...[
              Text(t.summary!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.7)),
              const SizedBox(height: 12),
            ],
            ...t.keyPoints.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration:
                            BoxDecoration(color: primary, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(point,
                          style:
                              theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                    ),
                  ],
                ),
              ),
            ),
            if (t.body != null && t.body!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(t.body!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.7)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
      ThemeData theme, IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.labelSmall
              ?.copyWith(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
