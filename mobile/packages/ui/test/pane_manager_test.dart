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

  testWidgets('touch activates a pane, and reactivation can focus content', (tester) async {
    var selected = 0;
    final changes = <int>[];
    final activations = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: PaneManager(
              panes: panes,
              selectedIndex: selected,
              onSelected: (index) {
                changes.add(index);
                setState(() => selected = index);
              },
              onActivated: activations.add,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Shared'));
    await tester.pump();
    expect(selected, 1);
    expect(changes, [1]);
    expect(activations, [1]);

    await tester.tap(find.text('Shared'));
    await tester.pump();
    expect(changes, [1]); // Already selected: no redundant content change.
    expect(activations, [1, 1]); // Still transfers focus into its list.

    await tester.tap(find.text('My Albums'));
    await tester.pump();
    expect(selected, 2);
    expect(changes, [1, 2]);
    expect(activations, [1, 1, 2]);
  });

  testWidgets('left/right only highlight; Enter commits and transfers focus to content', (tester) async {
    var selected = 0;
    final changes = <int>[];
    final activations = <int>[];
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
                  onActivated: (index) {
                    activations.add(index);
                    contentFocus.requestFocus();
                  },
                ),
                ListTile(focusNode: contentFocus, title: const Text('First album')),
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
    expect(selected, 0); // No view change from horizontal highlight movement.
    expect(changes, isEmpty);
    expect(tester.widget<InkWell>(find.byKey(const ValueKey('pane-1'))).focusNode!.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected, 0);
    expect(changes, isEmpty);
    expect(tester.widget<InkWell>(find.byKey(const ValueKey('pane-2'))).focusNode!.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(changes, isEmpty); // Right boundary is contained within pane bar.

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(selected, 2);
    expect(changes, [2]);
    expect(activations, [2]);
    expect(contentFocus.hasFocus, isTrue);

    // The chosen pane remains selected while the focus is in the list.
    expect(tester.widget<InkWell>(find.byKey(const ValueKey('pane-2'))).focusNode!.hasFocus, isFalse);

    tester.widget<InkWell>(find.byKey(const ValueKey('pane-2'))).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(changes, [2]); // Already selected, but still entered the list.
    expect(activations, [2, 2]);
    expect(contentFocus.hasFocus, isTrue);
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
