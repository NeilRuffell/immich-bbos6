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

  testWidgets('edge scrolling aligns the focused row with a constrained pane', (tester) async {
    final controller = Bbos6GridNavigationController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(720, 660);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 52, child: Center(child: Text('Top controls'))),
              Expanded(
                child: Bbos6GalleryView(
                  controller: controller,
                  sectionItemCounts: const [30],
                  columnCount: 2,
                  onReveal: (_) {},
                  onActivate: (_) {},
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 80,
                    ),
                    itemCount: 30,
                    itemBuilder: (context, index) => Bbos6GalleryItem(
                      index: index,
                      key: ValueKey('tile-$index'),
                      child: Center(child: Text('Tile $index')),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48, child: Center(child: Text('Bottom controls'))),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(controller.selectedIndex, 6);
    final gridBounds = tester.getRect(find.byType(GridView));
    final bottomItem = tester.getRect(find.byKey(const ValueKey('tile-6')));
    expect(bottomItem.bottom, closeTo(gridBounds.bottom, 1.0));
    expect(bottomItem.bottom, lessThan(tester.getTopLeft(find.text('Bottom controls')).dy));

    for (var i = 0; i < 2; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
    }
    expect(controller.selectedIndex, 2);
    final topItem = tester.getRect(find.byKey(const ValueKey('tile-2')));
    expect(topItem.top, closeTo(gridBounds.top, 1.0));
    expect(topItem.top, greaterThan(tester.getBottomLeft(find.text('Top controls')).dy - 1));
  });

  testWidgets('changing surrounding pane sizes changes the focus scroll boundary', (tester) async {
    final controller = Bbos6GridNavigationController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(720, 760);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    late StateSetter resize;
    var topHeight = 32.0;
    var bottomHeight = 28.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              resize = setState;
              return Column(
                children: [
                  SizedBox(height: topHeight),
                  Expanded(
                    child: Bbos6GalleryView(
                      controller: controller,
                      sectionItemCounts: const [30],
                      columnCount: 2,
                      onReveal: (_) {},
                      onActivate: (_) {},
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 80,
                        ),
                        itemCount: 30,
                        itemBuilder: (context, index) => Bbos6GalleryItem(
                          key: ValueKey('resized-tile-$index'),
                          index: index,
                          child: Text('Tile $index'),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: bottomHeight),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    resize(() {
      topHeight = 78;
      bottomHeight = 86;
    });
    await tester.pump();

    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(controller.selectedIndex, 6);
    expect(
      tester.getRect(find.byKey(const ValueKey('resized-tile-6'))).bottom,
      closeTo(tester.getRect(find.byType(GridView)).bottom, 1.0),
    );
  });

  testWidgets('pinned sliver app bar defines the actual upper reveal edge', (tester) async {
    final controller = Bbos6GridNavigationController();
    addTearDown(controller.dispose);
    tester.view.physicalSize = const Size(720, 760);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Bbos6GalleryView(
            controller: controller,
            sectionItemCounts: const [40],
            columnCount: 2,
            onReveal: (_) {},
            onActivate: (_) {},
            child: CustomScrollView(
              slivers: [
                const SliverAppBar(
                  pinned: true,
                  expandedHeight: 140,
                  title: Text('Album header'),
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Bbos6GalleryItem(
                      index: index,
                      key: ValueKey('album-tile-$index'),
                      child: Center(child: Text('Photo $index')),
                    ),
                    childCount: 40,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 80,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    for (var i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 6; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
    }
    expect(controller.selectedIndex, 4);
    final itemRect = tester.getRect(find.byKey(const ValueKey('album-tile-4')));
    final toolbarBottom = tester.getRect(find.byType(AppBar).first).bottom;
    expect(itemRect.top, greaterThanOrEqualTo(toolbarBottom - 1.0));
    expect(itemRect.top, closeTo(toolbarBottom, 1.0));
  });

  testWidgets('unbuilt targets still use the consumer reveal callback', (tester) async {
    final controller = Bbos6GridNavigationController();
    addTearDown(controller.dispose);
    final fallbacks = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Bbos6GalleryView(
          controller: controller,
          sectionItemCounts: const [3],
          columnCount: 3,
          onReveal: fallbacks.add,
          onActivate: (_) {},
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(controller.selectedIndex, 1);
    expect(fallbacks, [1]);
  });

  testWidgets('trackpad navigation selects images and Enter activates', (tester) async {
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

    expect(controller.selectedIndex, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(controller.selectedIndex, 2);
    // The registered child can be measured, so the legacy callback is not
    // needed. It remains available for lazily unbuilt targets.
    expect(revealed, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, [2]);

    await tester.tap(find.text('Photo 5'));
    await tester.pump();
    expect(controller.selectedIndex, 5);
  });
}
