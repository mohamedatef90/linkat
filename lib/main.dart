import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/screens/add_link_screen.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/feeds_screen.dart';
import 'presentation/screens/item_detail_loader.dart';
import 'presentation/screens/library_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/vault_hub_screen.dart';
import 'presentation/shell/app_shell.dart';
import 'presentation/theme/notion_theme.dart';

/// RefVault backend (shared with the web app). The anon key is public by
/// design — all access is enforced by RLS + auth.
const supabaseUrl = 'https://sjskpjgepbvblojohtlr.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNqc2twamdlcGJ2Ymxvam9odGxyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg5NzIzMzYsImV4cCI6MjA4NDU0ODMzNn0.x17WuelrlAXL_5UCyWo2FfD5BkH7IrPJbPWa9c125fY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const ProviderScope(child: LinkatApp()));
}

/// Re-evaluates router redirects whenever the auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  refreshListenable:
      GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
  redirect: (context, state) {
    final signedIn = Supabase.instance.client.auth.currentSession != null;
    final location = state.matchedLocation;
    if (location == '/splash') return null;
    if (!signedIn && location != '/auth') return '/auth';
    if (signedIn && location == '/auth') return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    // Full-screen routes above the shell (no bottom nav).
    GoRoute(
      path: '/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          AddLinkScreen(initialUrl: state.uri.queryParameters['url']),
    ),
    GoRoute(
      path: '/item/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          ItemDetailLoader(remoteId: state.pathParameters['id']!),
    ),
    // The four main tabs, each with its own navigation stack.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const VaultHubScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              builder: (context, state) => LibraryScreen(
                initialKind: state.uri.queryParameters['kind'],
                initialStatus: state.uri.queryParameters['status'],
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/feeds',
              builder: (context, state) => const FeedsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class LinkatApp extends ConsumerWidget {
  const LinkatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dark-only magic_black design language.
    return MaterialApp.router(
      title: 'Linkat',
      theme: NotionTheme.darkTheme,
      darkTheme: NotionTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
