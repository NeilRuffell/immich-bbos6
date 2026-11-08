import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_mobile/presentation/pages/bbos6_pictures_home.dart';
import 'package:immich_ui/immich_ui.dart';
import 'package:immich_mobile/widgets/common/immich_logo.dart';

const labels = [
  'Pictures Library',
  'Albums',
  'On Device',
  'Memories',
  'Places',
  'People',
  'Settings',
];

Widget buildHome(List<String> selected, {bool readonly = false}) {
  return MaterialApp(
    home: Bbos6PicturesHome(
      readonly: readonly,
      onPicturesLibrary: () => selected.add('Pictures Library'),
      onAlbums: () => selected.add('Albums'),
      onDevice: () => selected.add('On Device'),
      onMemories: () => selected.add('Memories'),
      onPlaces: () => selected.add('Places'),
      onPeople: () => selected.add('People'),
      onSettings: () => selected.add('Settings'),
    ),
  );
}

void main() {
  testWidgets('Pictures home has seven rows in the requested order and no tab bar', (tester) async {
    await tester.pumpWidget(buildHome([]));

    expect(find.text('immich'), findsOneWidget);
    expect(find.byType(ImmichLogo), findsOneWidget);
    expect(find.byType(Bbos6MediaListTile), findsNWidgets(7));
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.centerTitle, isFalse);
    expect(appBar.titleSpacing, 12);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsNothing);

    final rows = tester.widgetList<Bbos6MediaListTile>(find.byType(Bbos6MediaListTile)).toList();
    expect(rows.map((row) => row.title).toList(), labels);
    expect(rows.first.autofocus, isTrue);
    expect(rows.last.showDivider, isFalse);
  });

  testWidgets('each Pictures entry invokes its existing destination callback', (tester) async {
    final selected = <String>[];
    await tester.pumpWidget(buildHome(selected));

    for (final label in labels) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    expect(selected, labels);
  });

  testWidgets('read-only mode retains Pictures Library and Settings as active entries', (tester) async {
    await tester.pumpWidget(buildHome([], readonly: true));

    final rows = tester.widgetList<Bbos6MediaListTile>(find.byType(Bbos6MediaListTile)).toList();
    expect(rows.first.onTap, isNotNull);
    for (final row in rows.skip(1).take(5)) {
      expect(row.onTap, isNull);
    }
    expect(rows.last.title, 'Settings');
    expect(rows.last.onTap, isNotNull);
  });
}
