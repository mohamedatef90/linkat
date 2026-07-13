import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/screens/add_link_screen.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/folder_detail_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/theme/notion_theme.dart';
import 'presentation/providers/theme_provider.dart';

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

final _router = GoRouter(
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
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) {
            final url = state.uri.queryParameters['url'];
            return AddLinkScreen(initialUrl: url);
          },
        ),
        GoRoute(
          path: 'folder/:platform',
          builder: (context, state) {
            final platform = state.pathParameters['platform']!;
            return FolderDetailScreen(platformName: platform);
          },
        ),
      ],
    ),
  ],
);

class LinkatApp extends ConsumerWidget {
  const LinkatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Linkat',
      theme: NotionTheme.lightTheme,
      darkTheme: NotionTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
