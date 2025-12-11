import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/screens/add_link_screen.dart';
import 'presentation/screens/folder_detail_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/theme/notion_theme.dart';
import 'presentation/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // If .env file doesn't exist or is empty, continue without it
    debugPrint('Warning: Could not load .env file: $e');
  }

  runApp(const ProviderScope(child: LinkatApp()));
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) {
            final url = state.uri.queryParameters['url'];
            final topic = state.uri.queryParameters['topic'];
            return AddLinkScreen(initialUrl: url, initialTopic: topic);
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
