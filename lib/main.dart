import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/screens/add_link_screen.dart';
import 'presentation/screens/folder_detail_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/theme/notion_theme.dart';

Future<void> main() async {
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // If .env file doesn't exist or is empty, continue without it
    print('Warning: Could not load .env file: $e');
  }

  runApp(const ProviderScope(child: LinkatApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
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

class LinkatApp extends StatelessWidget {
  const LinkatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Linkat',
      theme: NotionTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
