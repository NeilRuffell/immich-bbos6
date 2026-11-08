import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_ui/src/components/bbos6/bbos6_media_list_tile.dart';
import 'package:immich_ui/src/components/bbos6/bbos6_selection_gradient.dart';

import 'test_utils.dart';

BoxDecoration rowDecoration(WidgetTester tester) {
  final decorations = find.descendant(
    of: find.byType(Bbos6MediaListTile),
    matching: find.byType(DecoratedBox),
  );
  return tester.widget<DecoratedBox>(decorations.first).decoration as BoxDecoration;
}

void main() {
  testWidgets('BBOS6 row is 68dp high, black and square when unfocused', (tester) async {
    await tester.pumpTestWidget(
      Bbos6MediaListTile(
        leading: const Icon(Icons.folder),
        title: 'Folders',
        onTap: () {},
      ),
    );

    expect(tester.getSize(find.byType(Bbos6MediaListTile)).height, 68);
    expect(rowDecoration(tester).color, Colors.black);
    expect(rowDecoration(tester).gradient, isNull);
    expect(rowDecoration(tester).border, const Border(bottom: BorderSide(color: Color(0xFF303030))));
    expect(rowDecoration(tester).borderRadius, isNull);
  });

  testWidgets('BBOS6 light focus gradient uses the Music palette and keyboard Enter activates', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var activations = 0;

    await tester.pumpTestWidget(
      Bbos6MediaListTile(
        title: 'Folders',
        focusNode: focusNode,
        onTap: () => activations++,
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    expect(rowDecoration(tester).gradient, Bbos6SelectionGradient.light);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 1);

    focusNode.unfocus();
    await tester.pump();
    expect(rowDecoration(tester).color, Colors.black);
  });

  testWidgets('BBOS6 dark focus gradient uses the Music night palette', (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Bbos6MediaListTile(
            title: 'Partners',
            focusNode: focusNode,
            onTap: () {},
            showDivider: false,
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    expect(rowDecoration(tester).gradient, Bbos6SelectionGradient.dark);
    expect(rowDecoration(tester).border, isNull);
  });

  testWidgets('BBOS6 row preserves touch activation', (tester) async {
    var activations = 0;
    await tester.pumpTestWidget(
      Bbos6MediaListTile(
        leading: const Icon(Icons.group),
        title: 'Partners',
        onTap: () => activations++,
      ),
    );

    await tester.tap(find.text('Partners'));
    await tester.pump();
    expect(activations, 1);
  });
}
