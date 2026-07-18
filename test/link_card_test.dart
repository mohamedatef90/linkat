import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:linkat/domain/entities/content_type.dart';
import 'package:linkat/domain/entities/link.dart';
import 'package:linkat/domain/entities/platform_type.dart';
import 'package:linkat/presentation/theme/notion_theme.dart';
import 'package:linkat/presentation/widgets/link_card.dart';

Link _link({required String kind, String readStatus = 'unread'}) => Link(
      url: 'https://example.com/post',
      title: 'A test item',
      platform: PlatformType.other,
      contentType: ContentType.article,
      createdAt: DateTime(2026, 1, 1),
      remoteId: 'remote-1',
      itemKind: kind,
      readStatus: readStatus,
    );

Widget _host(Link link) => ProviderScope(
      child: MaterialApp(
        theme: NotionTheme.darkTheme,
        home: Scaffold(body: LinkCard(link: link)),
      ),
    );

void main() {
  testWidgets('content card shows Article badge and a Read action',
      (tester) async {
    await tester.pumpWidget(_host(_link(kind: 'content')));
    await tester.pump();

    expect(find.text('Article'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget); // read-status pill
  });

  testWidgets('content card in reading state shows Continue',
      (tester) async {
    await tester.pumpWidget(
      _host(_link(kind: 'content', readStatus: 'reading')),
    );
    await tester.pump();

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
  });

  testWidgets('bookmark card shows Bookmark badge and Visit site',
      (tester) async {
    await tester.pumpWidget(_host(_link(kind: 'bookmark')));
    await tester.pump();

    expect(find.text('Bookmark'), findsOneWidget);
    expect(find.text('Visit site'), findsOneWidget);
  });
}
