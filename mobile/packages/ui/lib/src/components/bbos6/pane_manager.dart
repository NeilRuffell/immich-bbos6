import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:immich_ui/src/components/bbos6/bbos6_selection_gradient.dart';

@immutable
class PaneManagerItem {
  const PaneManagerItem({required this.label, this.icon, this.showLabel = true}) : assert(label.length > 0);

  final String label;
  final Widget? icon;
  final bool showLabel;
}

/// A reusable BBOS6-inspired horizontal pane selector.
///
/// [selectedIndex] is controlled by the parent. PaneManager owns only keyboard
/// focus, never the content or data represented by a pane. Left and right move
/// between panes when the bar has focus; Enter/Select and touch activate a pane.
class PaneManager extends StatefulWidget {
  const PaneManager({
    required this.panes,
    required this.selectedIndex,
    required this.onSelected,
    this.autofocus = false,
    super.key,
  }) : assert(panes.length > 0),
       assert(selectedIndex >= 0 && selectedIndex < panes.length);

  static const double height = 52;

  final List<PaneManagerItem> panes;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool autofocus;

  @override
  State<PaneManager> createState() => _PaneManagerState();
}

class _PaneManagerState extends State<PaneManager> {
  late List<FocusNode> _nodes;
  int? _focusedIndex;

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(widget.panes.length, (_) => FocusNode());
  }

  @override
  void didUpdateWidget(PaneManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.panes.length != widget.panes.length) {
      for (final node in _nodes) {
        node.dispose();
      }
      _nodes = List.generate(widget.panes.length, (_) => FocusNode());
      _focusedIndex = null;
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _select(int index) {
    _nodes[index].requestFocus();
    if (index != widget.selectedIndex) {
      widget.onSelected(index);
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final focused = _nodes.indexWhere((item) => item.hasFocus);
    if (focused < 0) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (focused > 0) {
        _select(focused - 1);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (focused < _nodes.length - 1) {
        _select(focused + 1);
      }
      return KeyEventResult.handled;
    }

    // Keep Up/Down available to Flutter's normal focus traversal so the album
    // list and other controls remain reachable by the Q25 trackpad.
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final inactiveGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4B4E53), Color(0xFF292C31)],
    );

    return SizedBox(
      height: PaneManager.height,
      child: Material(
        color: Colors.black,
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKeyEvent,
          child: Row(
            children: [
              for (var index = 0; index < widget.panes.length; index++)
                Expanded(
                  child: Semantics(
                    label: widget.panes[index].showLabel ? null : widget.panes[index].label,
                    button: true,
                    selected: widget.selectedIndex == index,
                    child: InkWell(
                      key: ValueKey('pane-$index'),
                      focusNode: _nodes[index],
                      autofocus: widget.autofocus && index == widget.selectedIndex,
                      onFocusChange: (focused) {
                        if (focused) {
                          setState(() => _focusedIndex = index);
                        } else if (_focusedIndex == index) {
                          setState(() => _focusedIndex = null);
                        }
                      },
                      onTap: () => _select(index),
                      hoverColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      splashFactory: NoSplash.splashFactory,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: widget.selectedIndex == index
                              ? Bbos6SelectionGradient.forBrightness(Theme.of(context).brightness)
                              : inactiveGradient,
                          border: Border(
                            top: BorderSide(
                              color: _focusedIndex == index ? Colors.white : const Color(0xFF5A5D63),
                              width: _focusedIndex == index ? 2 : 1,
                            ),
                            bottom: BorderSide(
                              color: _focusedIndex == index ? Colors.white : const Color(0xFF17191C),
                              width: _focusedIndex == index ? 2 : 1,
                            ),
                            right: const BorderSide(color: Color(0xFF17191C)),
                          ),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.panes[index].icon != null)
                                  IconTheme(
                                    data: const IconThemeData(color: Colors.white, size: 20),
                                    child: widget.panes[index].icon!,
                                  ),
                                if (widget.panes[index].icon != null && widget.panes[index].showLabel)
                                  const SizedBox(width: 5),
                                if (widget.panes[index].showLabel)
                                  Flexible(
                                    child: Text(
                                      widget.panes[index].label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
