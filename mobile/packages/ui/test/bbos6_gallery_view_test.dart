import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_ui/immich_ui.dart';

void main() {
  test('navigation follows date-group row boundaries', () {
    final controller = Bbos6GridNavigationController()
      ..configure(sectionItemCounts: [2, 5], columns: 3);
    addTearDown(controller.dispose);

    expect(controller.selectedIndex, 0);
    expect(controller.move(Bbos6GalleryDirection.down), 2);
    expect(controller.move(Bbos6GalleryDirection.right), 3);
    expect(controller.move(Bbos6GalleryDirection.down), 6);
    expect(controller.move(Bbos6GalleryDirection.up), 3);
    expect(controller.move(Bbos6GalleryDirection.left), 2);
    expect(controller.move(Bbos6GalleryDirection.up), 0);
    expect(controller.move(Bbos6GalleryDirection.up), isNull);
  });

  test('empty galleries have no focusable item', () {
    final controller = Bbos6GridNavigationController()
      ..configure(sectionItemCounts: [0], columns: 4);
    addTearDown(controller.dispose);

    expect(controller.selectedIndex, isNull);
    expect(controller.move(Bbos6GalleryDirection.right), isNull);
    controller.configure(sectionItemCounts: [3], columns: 4);
    expect(controller.selectedIndex, 0);
    controller.select(2);
    controller.configure(sectionItemCounts: [], columns: 4);
    expect(controller.selectedIndex, isNull);
  });

  testWidgets('trackpad navigation updates persistent footer and Enter activates', (tester) async {
    final controller = Bbos6GridNavigationController();
    addTearDown(controller.dispose);
    final opened = <int>[];
    final revealed = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Bbos6GalleryView(
            controller: controller,
            sectionItemCounts: const [2, 5],
            columnCount: 3,
            onReveal: revealed.add,
            onActivate: opened.add,
            footerBuilder: (context, index) => Text('Selected ${index ?? 'none'}'),
            child: GridView.count(
              crossAxisCount: 3,
              children: [
                for (var i = 0; i < 7; i++)
                  Bbos6GalleryItem(index: i, child: Center(child: Text('Photo $i'))),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Selected 0'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.text('Selected 2'), findsOneWidget);
    expect(revealed, [2]);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, [2]);

    await tester.tap(find.text('Photo 5'));
    await tester.pump();
    expect(find.text('Selected 5'), findsOneWidget);
  });
}
