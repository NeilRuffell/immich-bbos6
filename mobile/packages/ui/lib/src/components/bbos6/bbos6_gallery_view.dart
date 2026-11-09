import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    final next = index == 0 ? null : (_selectedIndex ?? 0).clamp(0, index - 1).toInt();
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
          ? _rowStarts[row - 1] + column.clamp(0, _rowLengths[row - 1] - 1).toInt()
          : current,
      Bbos6GalleryDirection.down => row + 1 < _rowStarts.length
          ? _rowStarts[row + 1] + column.clamp(0, _rowLengths[row + 1] - 1).toInt()
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
    required this.registerItem,
    required this.unregisterItem,
    required super.child,
    super.key,
  });

  final Bbos6GridNavigationController controller;
  final VoidCallback requestFocus;
  final void Function(int index, BuildContext context) registerItem;
  final void Function(int index, BuildContext context) unregisterItem;

  static Bbos6GalleryScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Bbos6GalleryScope>();

  @override
  bool updateShouldNotify(Bbos6GalleryScope oldWidget) =>
      controller != oldWidget.controller ||
      requestFocus != oldWidget.requestFocus ||
      registerItem != oldWidget.registerItem ||
      unregisterItem != oldWidget.unregisterItem;
}

class Bbos6GalleryView extends StatefulWidget {
  const Bbos6GalleryView({
    required this.controller,
    required this.sectionItemCounts,
    required this.columnCount,
    required this.onReveal,
    required this.onActivate,
    required this.child,
    this.autofocus = true,
    super.key,
  });

  final Bbos6GridNavigationController controller;
  final List<int> sectionItemCounts;
  final int columnCount;
  final ValueChanged<int> onReveal;
  final ValueChanged<int> onActivate;
  final Widget child;
  final bool autofocus;

  @override
  State<Bbos6GalleryView> createState() => _Bbos6GalleryViewState();
}

class _Bbos6GalleryViewState extends State<Bbos6GalleryView> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'BBOS6 timeline gallery');
  final Map<int, BuildContext> _renderedItems = <int, BuildContext>{};
  int? _pendingRevealIndex;
  bool _pendingRevealScheduled = false;

  void _registerItem(int index, BuildContext context) {
    _renderedItems[index] = context;
    if (_pendingRevealIndex == index) {
      _schedulePendingReveal();
    }
  }

  void _unregisterItem(int index, BuildContext context) {
    if (identical(_renderedItems[index], context)) {
      _renderedItems.remove(index);
    }
  }

  void _schedulePendingReveal() {
    if (_pendingRevealScheduled) {
      return;
    }
    _pendingRevealScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingRevealScheduled = false;
      if (!mounted) {
        return;
      }
      final index = _pendingRevealIndex;
      if (index != null) {
        _revealMeasured(index);
      }
    });
    // A scroll animation may have just ended without another frame pending.
    WidgetsBinding.instance.scheduleFrame();
  }

  // Read the actual painted viewport, not the screen height or estimated
  // sliver/header offsets. A pane beside the grid naturally reduces the
  // viewport's layout size; pinned headers can obscure its upper edge.
  double _visibleTop(RenderBox viewport) {
    var top = 0.0;
    void inspect(RenderObject object) {
      object.visitChildren((child) {
        if (child is! RenderSliver) {
          return;
        }

        if (child is RenderSliverPinnedPersistentHeader ||
            child is RenderSliverFloatingPinnedPersistentHeader) {
          final geometry = child.geometry;
          if (geometry != null && geometry.visible && geometry.paintExtent > 0) {
            final transform = child.getTransformTo(viewport);
            final headerTop = MatrixUtils.transformPoint(transform, Offset.zero).dy;
            final headerBottom = MatrixUtils.transformPoint(
              transform,
              Offset(0, geometry.paintExtent),
            ).dy;

            if (headerTop <= top + 1.0 && headerBottom > top) {
              top = math.min(viewport.size.height, headerBottom);
            }
          }
        }
        inspect(child);
      });
    }

    inspect(viewport);
    return top;
  }

  bool _revealMeasured(int index) {
    final itemContext = _renderedItems[index];
    final item = itemContext?.findRenderObject();
    if (item is! RenderBox || !item.attached || !item.hasSize) {
      return false;
    }

    final scrollable = Scrollable.maybeOf(itemContext!);
    final abstractViewport = RenderAbstractViewport.maybeOf(item);
    // RenderAbstractViewport is an interface, not a RenderBox type. Cast to
    // the actual box-backed viewport before using its paint geometry.
    final RenderBox? viewport =
        abstractViewport is RenderBox ? abstractViewport as RenderBox : null;
    if (scrollable == null || viewport == null ||
        !viewport.attached || !viewport.hasSize) {
      return false;
    }

    final position = scrollable.position;
    if (!position.hasPixels || !position.hasViewportDimension ||
        position.axisDirection != AxisDirection.down) {
      return false;
    }

    final bounds = MatrixUtils.transformRect(
      item.getTransformTo(viewport),
      Offset.zero & item.size,
    );
    final visibleTop = _visibleTop(viewport);
    final visibleBottom = viewport.size.height;
    if (visibleBottom <= visibleTop) {
      return false;
    }

    // Scrolling is minimal: keep an already-visible item stationary, align
    // its top against the actual top edge when navigating up, or its bottom
    // against the actual lower edge when navigating down.
    final double delta;
    if (bounds.top < visibleTop - 0.5) {
      delta = bounds.top - visibleTop;
    } else if (bounds.bottom > visibleBottom + 0.5) {
      delta = bounds.bottom - visibleBottom;
    } else {
      _pendingRevealIndex = null;
      return true;
    }

    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    ).toDouble();
    if ((target - position.pixels).abs() < 0.5) {
      _pendingRevealIndex = null;
      return true;
    }

    // A collapsing/pinning header can change its painted extent while
    // scrolling. Re-check once the animation finishes using fresh geometry.
    unawaited(
      position.animateTo(
        target,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      ).then((_) {
        if (mounted && _pendingRevealIndex == index) {
          _schedulePendingReveal();
        }
      }),
    );
    return true;
  }

  void _revealSelection(int index) {
    _pendingRevealIndex = index;
    if (!_revealMeasured(index)) {
      // The target is not built yet in a lazily materialized sliver. Let
      // the consumer bring it into the cache, then finish with measured
      // alignment as soon as Bbos6GalleryItem registers its render box.
      widget.onReveal(index);
      _schedulePendingReveal();
    }
  }


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
    if (_pendingRevealIndex != null && _pendingRevealIndex! >= widget.controller.itemCount) {
      _pendingRevealIndex = null;
    }
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
        _revealSelection(target);
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
    _renderedItems.clear();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Bbos6GalleryScope(
      controller: widget.controller,
      requestFocus: _focusNode.requestFocus,
      registerItem: _registerItem,
      unregisterItem: _unregisterItem,
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onFocusChange: widget.controller.setFocused,
        onKeyEvent: _onKeyEvent,
        child: widget.child,
      ),
    );
  }
}

/// A ready-to-use BBOS6 image grid for screens without a Timeline/sliver
/// adapter. All focus, directional navigation and viewport reveal behavior is
/// delegated to [Bbos6GalleryView]; consumers supply only their existing tile
/// widgets and activation callback.
class Bbos6GalleryGrid extends StatefulWidget {
  const Bbos6GalleryGrid({
    required this.itemCount,
    required this.columns,
    required this.itemBuilder,
    required this.onActivate,
    this.padding = EdgeInsets.zero,
    this.childAspectRatio = 1.0,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.autofocus = true,
    super.key,
  }) : assert(columns > 0),
       assert(childAspectRatio > 0);

  final int itemCount;
  final int columns;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int> onActivate;
  final EdgeInsets padding;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final bool autofocus;

  @override
  State<Bbos6GalleryGrid> createState() => _Bbos6GalleryGridState();
}

class _Bbos6GalleryGridState extends State<Bbos6GalleryGrid> {
  final Bbos6GridNavigationController _navigation = Bbos6GridNavigationController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _navigation.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = math.max(
          0.0,
          constraints.maxWidth - widget.padding.horizontal -
              widget.crossAxisSpacing * (widget.columns - 1),
        ) / widget.columns;
        final tileHeight = tileWidth / widget.childAspectRatio;
        final rowStride = tileHeight + widget.mainAxisSpacing;

        void revealUnbuilt(int index) {
          if (!_scrollController.hasClients) {
            return;
          }
          final position = _scrollController.position;
          final rowTop = widget.padding.top + (index ~/ widget.columns) * rowStride;
          final rowBottom = rowTop + tileHeight;
          final target = rowTop < position.pixels
              ? rowTop
              : rowBottom > position.pixels + position.viewportDimension
                  ? rowBottom - position.viewportDimension
                  : position.pixels;
          if ((target - position.pixels).abs() >= 0.5) {
            // Position the lazily built target inside the cache. The shared
            // gallery then performs final measured edge alignment.
            _scrollController.jumpTo(
              target.clamp(position.minScrollExtent, position.maxScrollExtent).toDouble(),
            );
          }
        }

        return Bbos6GalleryView(
          controller: _navigation,
          sectionItemCounts: [widget.itemCount],
          columnCount: widget.columns,
          onReveal: revealUnbuilt,
          onActivate: widget.onActivate,
          autofocus: widget.autofocus,
          child: GridView.builder(
            controller: _scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.columns,
              childAspectRatio: widget.childAspectRatio,
              mainAxisSpacing: widget.mainAxisSpacing,
              crossAxisSpacing: widget.crossAxisSpacing,
            ),
            padding: widget.padding,
            itemCount: widget.itemCount,
            itemBuilder: (context, index) => Bbos6GalleryItem(
              index: index,
              child: widget.itemBuilder(context, index),
            ),
          ),
        );
      },
    );
  }
}

class Bbos6GalleryItem extends StatefulWidget {
  const Bbos6GalleryItem({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  State<Bbos6GalleryItem> createState() => _Bbos6GalleryItemState();
}

class _Bbos6GalleryItemState extends State<Bbos6GalleryItem> {
  Bbos6GalleryScope? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextScope = Bbos6GalleryScope.maybeOf(context);
    if (!identical(_scope, nextScope)) {
      _scope?.unregisterItem(widget.index, context);
      _scope = nextScope;
      _scope?.registerItem(widget.index, context);
    }
  }

  @override
  void didUpdateWidget(covariant Bbos6GalleryItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _scope?.unregisterItem(oldWidget.index, context);
      _scope?.registerItem(widget.index, context);
    }
  }

  @override
  void dispose() {
    _scope?.unregisterItem(widget.index, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope;
    if (scope == null) {
      return widget.child;
    }

    final controller = scope.controller;
    return Listener(
      onPointerDown: (_) {
        controller.select(widget.index);
        scope.requestFocus();
      },
      child: AnimatedBuilder(
        animation: controller,
        child: widget.child,
        builder: (context, child) {
          final focused = controller.hasFocus && controller.selectedIndex == widget.index;
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
