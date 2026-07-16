import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linkat/presentation/screens/auth_screen.dart';
import 'package:linkat/presentation/theme/notion_theme.dart';

void main() {
  Widget buildAuthScreen() {
    return ProviderScope(
      child: MaterialApp(
        theme: NotionTheme.lightTheme,
        home: const AuthScreen(),
      ),
    );
  }

  testWidgets('Auth screen renders and toggles sign in / sign up',
      (WidgetTester tester) async {
    await tester.pumpWidget(buildAuthScreen());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.tap(find.text("Don't have an account? Sign up"));
    await tester.pump();
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('Auth screen rejects empty submit', (tester) async {
    await tester.pumpWidget(buildAuthScreen());

    await tester.tap(find.text('Sign In'));
    await tester.pump();
    expect(find.text('Enter your email and password'), findsOneWidget);
  });
}
