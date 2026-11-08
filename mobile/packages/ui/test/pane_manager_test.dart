import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immich_ui/src/components/bbos6/bbos6_selection_gradient.dart';
import 'package:immich_ui/src/components/bbos6/pane_manager.dart';

const panes = [
  PaneManagerItem(label: 'All'),
  PaneManagerItem(label: 'Shared'),
  PaneManagerItem(label: 'My Albums'),
];

void main() {
  testWidgets('PaneManager has three equal, square panes and uses the shared selection gradient', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: PaneManager(panes: panes, selectedIndex: 0, onSelected: (_) {}),
        ),
      ),
    );

    expect(tester.getSize(find.byType(PaneManager)).height, PaneManager.height);
    for (final pane in panes) {
      expect(find.text(pane.label), findsOneWidget);
    }

    final selected = find.descendant(
      of: find.byKey(const ValueKey('pane-0')),
      matching: find.byType(DecoratedBox),
    );
    final decoration = tester.widget<DecoratedBox>(selected.first).decoration as BoxDecoration;
    expect(decoration.gradient, Bbos6SelectionGradient.light);
    expect(decoration.borderRadius, isNull);

    final all = tester.getSize(find.byKey(const ValueKey('pane-0'))).width;
    final shared = tester.getSize(find.byKey(const ValueKey('pane-1'))).width;
    expect(all, shared);
  });

  testWidgets('touch commits selection and helper focuses the content target', (tester) async {
    var selected = 0;
    final changes = <int>[];
    final contentFocus = FocusNode(debugLabel: 'Album list');
    addTearDown(contentFocus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                PaneManager(
                  panes: panes,
                  selectedIndex: selected,
                  onSelected: (index) {
                    changes.add(index);
                    setState(() => selected = index);
                  },
                  contentFocusNode: contentFocus,
                ),
                TextButton(focusNode: contentFocus, onPressed: () {}, child: const Text('First album')),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Shared'));
    await tester.pump();
    expect(selected, 1);
    expect(changes, [1]);
    expect(contentFocus.hasFocus, isTrue);

    await tester.tap(find.text('Shared'));
    await tester.pump();
    expect(changes, [1]); // No duplicate selection event.
    expect(contentFocus.hasFocus, isTrue); // Still enters content.

    await tester.tap(find.text('My Albums'));
    await tester.pump();
    expect(selected, 2);
    expect(changes, [1, 2]);
    expect(contentFocus.hasFocus, isTrue);
  });

  testWidgets('arrows move highlight only; Enter and Select activate and enter content', (tester) async {
    var selected = 0;
    final changes = <int>[];
    final contentFocus = FocusNode(debugLabel: 'Album list');
    addTearDown(contentFocus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                PaneManager(
                  panes: panes,
                  selectedIndex: selected,
                  onSelected: (index) {
                    changes.add(index);
                    setState(() => selected = index);
                  },
                  contentFocusNode: contentFocus,
                ),
                TextButton(focusNode: contentFocus, onPressed: () {}, child: const Text('First album')),
              ],
            ),
          ),
        ),
      ),
    );

    tester.widget<InkWell>(find.byKey(const ValueKey('pane-0'))).focusNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected, 0);
    expect(changes, isEmpty);
    expect(contentFocus.hasFocus, isFalse);
    expect(tester.widget<InkWell>(find.byKey(const ValueKey('pane-1'))).focusNode!.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected, 0);
    expect(changes, isEmpty);
    expect(tester.widget<InkWell>(find.byKey(const ValueKey('pane-2'))).focusNode!.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(changes, isEmpty); // Horizontal boundary never changes the view.

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, 2);
    expect(changes, [2]);
    expect(contentFocus.hasFocus, isTrue);

    tester.widget<InkWell>(find.byKey(const ValueKey('pane-2'))).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(changes, [2]); // Re-activation enters content without filtering.
    expect(contentFocus.hasFocus, isTrue);

    tester.widget<InkWell>(find.byKey(const ValueKey('pane-1'))).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(selected, 1);
    expect(changes, [2, 1]);
    expect(contentFocus.hasFocus, isTrue);
  });

  testWidgets('pane and content scopes do not traverse into each other', (tester) async {
    final controller = PaneManagerController();
    addTearDown(controller.dispose);
    final first = FocusNode(debugLabel: 'First list item');
    final second = FocusNode(debugLabel: 'Second list item');
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PaneManager(
                panes: panes,
                selectedIndex: 0,
                controller: controller,
                contentFocusNode: first,
                onSelected: (_) {},
              ),
              PaneManagerContent(
                controller: controller,
                child: Column(
                  children: [
                    TextButton(focusNode: first, onPressed: () {}, child: const Text('First item')),
                    TextButton(focusNode: second, onPressed: () {}, child: const Text('Second item')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final pane = tester.widget<InkWell>(find.byKey(const ValueKey('pane-0'))).focusNode!;
    pane.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(pane.hasFocus, isTrue);
    expect(first.hasFocus, isFalse);
    expect(controller.isInContent, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(first.hasFocus, isTrue);
    expect(controller.isInContent, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(first.hasFocus, isTrue); // Cannot cross into pane manager.

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(second.hasFocus, isTrue); // Normal list navigation still works.

    // The router's single Back callback returns to the pane. Keyboard
    // callbacks no longer perform this transition independently.
    expect(controller.returnToPanes(), isTrue);
    await tester.pump();
    expect(pane.hasFocus, isTrue);
    expect(controller.isInContent, isFalse);
    expect(controller.returnToPanes(), isFalse); // Next Back belongs to page.
  });

  testWidgets('Back focuses the selected pane, not a merely highlighted pane', (tester) async {
    final controller = PaneManagerController();
    addTearDown(controller.dispose);
    final first = FocusNode();
    addTearDown(first.dispose);
    var selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                PaneManager(
                  panes: panes,
                  selectedIndex: selected,
                  contentFocusNode: first,
                  controller: controller,
                  onSelected: (index) => setState(() => selected = index),
                ),
                PaneManagerContent(
                  controller: controller,
                  child: TextButton(focusNode: first, onPressed: () {}, child: const Text('Album')),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    tester.widget<InkWell>(find.byKey(const ValueKey('pane-0'))).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, 1);
    expect(first.hasFocus, isTrue);

    expect(controller.returnToPanes(), isTrue);
    await tester.pump();
    expect(tester.widget<InkWell>(find.byKey(const ValueKey('pane-1'))).focusNode!.hasFocus, isTrue);
    expect(controller.returnToPanes(), isFalse);
  });

  testWidgets('PaneManagerContent supports RenderSliver children without a RenderBox error', (tester) async {
    final controller = PaneManagerController();
    final firstAlbum = FocusNode(debugLabel: 'First album');
    addTearDown(controller.dispose);
    addTearDown(firstAlbum.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PaneManager(
                  panes: panes,
                  selectedIndex: 0,
                  onSelected: (_) {},
                  controller: controller,
                  contentFocusNode: firstAlbum,
                ),
              ),
              PaneManagerContent(
                controller: controller,
                child: SliverList(
                  delegate: SliverChildListDelegate([
                    TextButton(
                      focusNode: firstAlbum,
                      onPressed: () {},
                      child: const Text('First album'),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Regression: a FocusScope with its default Semantics wrapper inserts
    // RenderSemanticsAnnotations (RenderBox) above RenderSliver and crashes.
    expect(tester.takeException(), isNull);
    tester.widget<InkWell>(find.byKey(const ValueKey('pane-0'))).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(firstAlbum.hasFocus, isTrue);

    expect(controller.returnToPanes(), isTrue);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(controller.isInContent, isFalse);
  });

  testWidgets('icon-only panes retain accessible labels and keyboard focus', (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaneManager(
            panes: const [
              PaneManagerItem(label: 'Camera', icon: Icon(Icons.camera_alt_outlined), showLabel: false),
              PaneManagerItem(label: 'Gallery', icon: Icon(Icons.photo_library_outlined), showLabel: false),
            ],
            selectedIndex: 0,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
    expect(find.text('Camera'), findsNothing);
    expect(find.bySemanticsLabel('Camera'), findsOneWidget);
  });

  testWidgets('unfocused PaneManager does not consume arrows from another control', (tester) async {
    final textNode = FocusNode();
    addTearDown(textNode.dispose);
    final changes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PaneManager(panes: panes, selectedIndex: 0, onSelected: changes.add),
              TextField(focusNode: textNode),
            ],
          ),
        ),
      ),
    );

    textNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(changes, isEmpty);
  });
}
