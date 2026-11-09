import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:immich_ui/src/components/bbos6/bbos6_selection_gradient.dart';

enum Bbos6GalleryDirection { left, right, up, down }

class Bbos6GridNavigationController extends ChangeNotifier {
  final List<int> _rowStarts = [];
  final List<int> _rowLengths = [];
  int _itemCount = 0;
  int? _selectedIndex;
  bool _hasFocus = false;

  int? get selectedIndex => _selectedIndex;
  int get itemCount => _itemCount;
  bool get hasFocus => _hasFocus;

  void configure({required List<int> sectionItemCounts, required int columns}) {
    assert(columns > 0);
    _rowStarts.clear();
    _rowLengths.clear();
    var index = 0;
    for (final sectionCount in sectionItemCounts) {
      assert(sectionCount >= 0);
      var remaining = sectionCount;
      while (remaining > 0) {
        final length = remaining < columns ? remaining : columns;
        _rowStarts.add(index);
        _rowLengths.add(length);
        index += length;
        remaining -= length;
      }
    }

    _itemCount = index;
    final next = index == 0 ? null : (_selectedIndex ?? 0).clamp(0, index - 1);
    if (next != _selectedIndex) {
      _selectedIndex = next;
      notifyListeners();
    }
  }

  void setFocused(bool focused) {
    if (_hasFocus != focused) {
      _hasFocus = focused;
      notifyListeners();
    }
  }

  void select(int index) {
    if (index < 0 || index >= _itemCount || _selectedIndex == index) {
      return;
    }
    _selectedIndex = index;
    notifyListeners();
  }

  int? move(Bbos6GalleryDirection direction) {
    if (_itemCount == 0) {
      return null;
    }
    final current = _selectedIndex ?? 0;
    final row = _rowForIndex(current);
    final column = current - _rowStarts[row];
    final target = switch (direction) {
      Bbos6GalleryDirection.left => current > 0 ? current - 1 : current,
      Bbos6GalleryDirection.right => current + 1 < _itemCount ? current + 1 : current,
      Bbos6GalleryDirection.up => row > 0
          ? _rowStarts[row - 1] + column.clamp(0, _rowLengths[row - 1] - 1)
          : current,
      Bbos6GalleryDirection.down => row + 1 < _rowStarts.length
          ? _rowStarts[row + 1] + column.clamp(0, _rowLengths[row + 1] - 1)
          : current,
    };
    if (target == current) {
      return null;
    }
    select(target);
    return target;
  }

  int _rowForIndex(int index) {
    var lower = 0;
    var upper = _rowStarts.length - 1;
    while (lower <= upper) {
      final middle = (lower + upper) ~/ 2;
      final start = _rowStarts[middle];
      if (index < start) {
        upper = middle - 1;
      } else if (index >= start + _rowLengths[middle]) {
        lower = middle + 1;
      } else {
        return middle;
      }
    }
    throw RangeError.index(index, _rowStarts);
  }
}

class Bbos6GalleryScope extends InheritedWidget {
  const Bbos6GalleryScope({
    required this.controller,
    required this.requestFocus,
    required super.child,
    super.key,
  });

  final Bbos6GridNavigationController controller;
  final VoidCallback requestFocus;

  static Bbos6GalleryScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Bbos6GalleryScope>();

  @override
  bool updateShouldNotify(Bbos6GalleryScope oldWidget) =>
      controller != oldWidget.controller || requestFocus != oldWidget.requestFocus;
}

class Bbos6GalleryView extends StatefulWidget {
  const Bbos6GalleryView({
    required this.controller,
    required this.sectionItemCounts,
    required this.columnCount,
    required this.onReveal,
    required this.onActivate,
    required this.footerBuilder,
    required this.child,
    this.autofocus = true,
    super.key,
  });

  static const double footerHeight = 56;

  final Bbos6GridNavigationController controller;
  final List<int> sectionItemCounts;
  final int columnCount;
  final ValueChanged<int> onReveal;
  final ValueChanged<int> onActivate;
  final Widget Function(BuildContext context, int? selectedIndex) footerBuilder;
  final Widget child;
  final bool autofocus;

  @override
  State<Bbos6GalleryView> createState() => _Bbos6GalleryViewState();
}

class _Bbos6GalleryViewState extends State<Bbos6GalleryView> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'BBOS6 timeline gallery');

  @override
  void initState() {
    super.initState();
    _configure();
  }

  @override
  void didUpdateWidget(covariant Bbos6GalleryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure();
  }

  void _configure() {
    widget.controller.configure(
      sectionItemCounts: widget.sectionItemCounts,
      columns: widget.columnCount,
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (!node.hasPrimaryFocus || (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }

    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => Bbos6GalleryDirection.left,
      LogicalKeyboardKey.arrowRight => Bbos6GalleryDirection.right,
      LogicalKeyboardKey.arrowUp => Bbos6GalleryDirection.up,
      LogicalKeyboardKey.arrowDown => Bbos6GalleryDirection.down,
      _ => null,
    };

    if (direction != null) {
      final target = widget.controller.move(direction);
      if (target != null) {
        widget.onReveal(target);
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.select) {
      final selected = widget.controller.selectedIndex;
      if (selected != null) {
        widget.onActivate(selected);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Bbos6GalleryScope(
      controller: widget.controller,
      requestFocus: _focusNode.requestFocus,
      child: Column(
        children: [
          Expanded(
            child: Focus(
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              onFocusChange: widget.controller.setFocused,
              onKeyEvent: _onKeyEvent,
              child: widget.child,
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.black,
              border: Border(top: BorderSide(color: Color(0xFF515251))),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: Bbos6GalleryView.footerHeight,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedBuilder(
                      animation: widget.controller,
                      builder: (context, _) => widget.footerBuilder(context, widget.controller.selectedIndex),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Bbos6GalleryItem extends StatelessWidget {
  const Bbos6GalleryItem({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = Bbos6GalleryScope.maybeOf(context);
    if (scope == null) {
      return child;
    }

    final controller = scope.controller;
    return Listener(
      onPointerDown: (_) {
        controller.select(index);
        scope.requestFocus();
      },
      child: AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          final focused = controller.hasFocus && controller.selectedIndex == index;
          final gradient = Bbos6SelectionGradient.forBrightness(Theme.of(context).brightness);
          return Semantics(
            selected: focused,
            child: Stack(
              fit: StackFit.expand,
              children: [
                child!,
                if (focused)
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: gradient.begin,
                          end: gradient.end,
                          colors: gradient.colors.map((color) => color.withValues(alpha: 0.22)).toList(),
                          stops: gradient.stops,
                        ),
                        border: Border.all(color: const Color(0xFF088EEF), width: 3),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
