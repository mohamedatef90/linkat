import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../services/pending_links_service.dart';
import '../providers/sync_providers.dart';
import '../theme/notion_theme.dart';

/// The persistent chrome around the four main tabs (Vault / Library / Feeds /
/// Settings). Owns the app-wide bootstrap that used to live on HomeScreen:
/// sync start, Realtime subscription, share-intent capture, pending-link
/// flush, and the resume hook.
class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForShareIntents();
    _checkPendingLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncControllerProvider).start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingLinks();
      ref.read(syncControllerProvider).syncNow();
    }
  }

  /// Links saved from the iOS share extension while the app was closed are
  /// parked in shared UserDefaults; forward them to save-item.
  Future<void> _checkPendingLinks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      final pendingLinks = await PendingLinksService.getPendingLinks();
      if (pendingLinks.isEmpty) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saving shared link...'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }

      final controller = ref.read(syncControllerProvider);
      for (final pending in pendingLinks) {
        await controller.saveUrl(pending.url, fallbackTitle: pending.title);
      }
      await PendingLinksService.clearPendingLinks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pendingLinks.length == 1
                  ? 'Link saved — processing in the background'
                  : '${pendingLinks.length} links saved',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: NotionTheme.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('AppShell: pending links error: $e');
    }
  }

  void _listenForShareIntents() {
    ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty && value.first.path.isNotEmpty) {
          _handleSharedContent(value.first.path);
          ReceiveSharingIntent.instance.reset();
        }
      },
      onError: (err) => debugPrint('getIntentDataStream error: $err'),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      ReceiveSharingIntent.instance.getInitialMedia().then(
        (List<SharedMediaFile> value) {
          if (value.isNotEmpty && value.first.path.isNotEmpty) {
            _handleSharedContent(value.first.path);
            ReceiveSharingIntent.instance.reset();
          }
        },
      );
    });
  }

  /// Shared URLs save straight to save-item — no extra taps.
  Future<void> _handleSharedContent(String sharedText) async {
    final cleanedText = sharedText.trim();
    String? urlToSave;

    final uri = Uri.tryParse(cleanedText);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      urlToSave = cleanedText;
    } else {
      final match = RegExp(r'https?://[^\s]+', caseSensitive: false)
          .firstMatch(cleanedText);
      urlToSave = match?.group(0);
    }
    if (urlToSave == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving shared link...'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
    }
    try {
      await ref.read(syncControllerProvider).saveUrl(urlToSave);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link saved — processing in the background'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: NotionTheme.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('AppShell: error saving shared link: $e');
    }
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      // Tapping the active tab again resets it to its root.
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    // FAB (add link) only makes sense on the Vault + Library tabs.
    final showFab = index <= 1;

    return Scaffold(
      backgroundColor: NotionTheme.ink,
      extendBody: true,
      body: widget.navigationShell,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () => context.push('/add'),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: _GlassNavBar(
        currentIndex: index,
        onTap: _goBranch,
      ),
    );
  }
}

class _GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _GlassNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: FontAwesomeIcons.vault, label: 'Vault'),
    (icon: FontAwesomeIcons.bookOpen, label: 'Library'),
    (icon: FontAwesomeIcons.rss, label: 'Feeds'),
    (icon: FontAwesomeIcons.sliders, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xD90D1B2B), // ink2 @ ~85%
            border: Border(top: BorderSide(color: NotionTheme.borderSoft)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  for (int i = 0; i < _items.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _items[i].icon,
                        label: _items[i].label,
                        selected: i == currentIndex,
                        onTap: () => onTap(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? NotionTheme.lime : NotionTheme.fog2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, size: 18, color: color),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
