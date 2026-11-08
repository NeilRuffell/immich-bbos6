import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_ui/src/components/bbos6/bbos6_search_bar.dart';

void main() {
  testWidgets('search bar reproduces 54dp Music chrome and provides input slot', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Bbos6SearchBar(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(Bbos6SearchBar)).height, Bbos6SearchBar.height);
    final panel = find.descendant(of: find.byType(Bbos6SearchBar), matching: find.byType(DecoratedBox));
    final decor = tester.widget<DecoratedBox>(panel.first).decoration as BoxDecoration;
    expect(decor.border, const Border(top: BorderSide(color: Color(0xFF5A5D63))));
    expect((decor.gradient as LinearGradient).colors, const [Color(0xFF4B4E53), Color(0xFF292C31)]);

    await tester.enterText(find.byType(TextField), 'Summer');
    await tester.pump();
    expect(controller.text, 'Summer');
  });

  testWidgets('BBOS6 search chrome retains an input child rather than owning search logic', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Bbos6SearchBar(child: Center(child: Text('Existing search input'))),
        ),
      ),
    );
    expect(find.text('Existing search input'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
