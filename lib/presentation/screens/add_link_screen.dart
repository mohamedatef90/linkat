import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/link_providers.dart';
import '../providers/sync_providers.dart';
import '../theme/notion_theme.dart';
import '../widgets/magic/magic.dart';

/// Saves a URL through the save-item Edge Function. The server parses and
/// AI-enriches asynchronously; this screen only shows an instant local
/// metadata preview while that happens.
class AddLinkScreen extends ConsumerStatefulWidget {
  final String? initialUrl;
  const AddLinkScreen({super.key, this.initialUrl});

  @override
  ConsumerState<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends ConsumerState<AddLinkScreen> {
  late final TextEditingController _urlController;
  bool _isSaving = false;
  bool _isPreviewLoading = false;
  String? _error;
  String? _previewTitle;
  String? _previewDescription;
  String? _previewImage;
  String? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
    if (widget.initialUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchPreview(widget.initialUrl!);
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String get _sanitizedUrl => _urlController.text
      .trim()
      .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF\uFFFC]'), '');

  Future<void> _fetchPreview(String url) async {
    setState(() => _isPreviewLoading = true);
    try {
      final metadata =
          await ref.read(metadataServiceProvider).fetchMetadata(url);
      if (mounted) {
        setState(() {
          _previewTitle = metadata['title'];
          _previewDescription = metadata['description'];
          _previewImage = metadata['image'];
        });
      }
    } catch (_) {
      // Preview is best-effort; the server fills the real metadata.
    } finally {
      if (mounted) setState(() => _isPreviewLoading = false);
    }
  }

  Future<void> _save() async {
    final url = _sanitizedUrl;
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      setState(() => _error = 'Enter a valid http(s) URL');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref
          .read(syncControllerProvider)
          .saveUrl(url, folderId: _selectedFolderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved — processing in the background'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to save link: $e';
          _isSaving = false;
        });
      }
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
    final fieldColor =
        isDark ? NotionTheme.darkSurface : NotionTheme.backgroundOffWhite;
    final foldersAsync = ref.watch(foldersProvider);

    return Scaffold(
      backgroundColor: NotionTheme.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Add Link', style: theme.textTheme.titleMedium),
      ),
      body: AuraBackground(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('URL',
                style:
                    theme.textTheme.labelSmall?.copyWith(color: subtextColor)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _urlController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'https://example.com',
                  hintStyle: TextStyle(color: subtextColor.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  errorText: _error,
                  prefixIcon: Icon(Icons.link, color: subtextColor),
                ),
                keyboardType: TextInputType.url,
                autofocus: widget.initialUrl == null,
                onSubmitted: (value) => _fetchPreview(value.trim()),
              ),
            ),
            const SizedBox(height: 20),

            // Instant local preview (server enrichment replaces it later)
            if (_isPreviewLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_previewTitle != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fieldColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_previewImage != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: _previewImage!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _previewTitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (_previewDescription != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _previewDescription!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: subtextColor),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            Text('Folder (optional)',
                style:
                    theme.textTheme.labelSmall?.copyWith(color: subtextColor)),
            const SizedBox(height: 8),
            foldersAsync.when(
              data: (folders) => folders.isEmpty
                  ? Text(
                      'No folders yet — create them from the home screen',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: subtextColor),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: folders.map((folder) {
                        final isSelected = _selectedFolderId == folder.id;
                        return FilterChip(
                          label: Text(folder.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFolderId =
                                  selected ? folder.id : null;
                            });
                          },
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
              loading: () => const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => Text(
                'Folders unavailable offline',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: subtextColor),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Title, summary, tags and topic are generated automatically '
              'after saving.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: subtextColor,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 24),
            GradientButton(
              label: 'Save Link',
              icon: Icons.bookmark_add_outlined,
              expand: true,
              loading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ],
        ),
      )),
    );
  }
}
