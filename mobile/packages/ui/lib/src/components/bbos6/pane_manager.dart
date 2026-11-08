import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:immich_ui/src/components/bbos6/bbos6_selection_gradient.dart';

/// Shared navigation state for a PaneManager and its owned content.
///
/// The two FocusScopes have stopped traversal edges. Keyboard focus never
/// crosses between them; explicit pane activation enters content and Back
/// returns to the selected pane.
class PaneManagerController {
  final FocusScopeNode paneScope = FocusScopeNode(
    debugLabel: 'PaneManager header',
    traversalEdgeBehavior: TraversalEdgeBehavior.stop,
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.stop,
  );
  final FocusScopeNode contentScope = FocusScopeNode(
    debugLabel: 'PaneManager content',
    traversalEdgeBehavior: TraversalEdgeBehavior.stop,
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.stop,
  );

  List<FocusNode> _paneNodes = const [];
  int _selectedIndex = 0;

  bool get isInContent => contentScope.hasFocus;

  void _attach(List<FocusNode> nodes, int selectedIndex) {
    _paneNodes = nodes;
    _selectedIndex = selectedIndex;
  }

  void _updateSelection(int selectedIndex) {
    _selectedIndex = selectedIndex;
  }

  void _detach(List<FocusNode> nodes) {
    if (identical(_paneNodes, nodes)) {
      _paneNodes = const [];
    }
  }

  /// Called by the shared Back handler; false leaves normal page Back intact.
  bool returnToPanes() {
    if (!isInContent || _selectedIndex >= _paneNodes.length) {
      return false;
    }
    _paneNodes[_selectedIndex].requestFocus();
    return true;
  }

  void dispose() {
    paneScope.dispose();
    contentScope.dispose();
  }
}

/// Isolates the owned list/grid from the PaneManager focus scope.
/// Place all relevant content controls and list slivers beneath this widget.
class PaneManagerContent extends StatelessWidget {
  const PaneManagerContent({required this.controller, required this.child, super.key});

  final PaneManagerController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FocusScope(node: controller.contentScope, child: child);
  }
}


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
/// focus only; Enter/Select or touch activates the focused pane. When a
/// [contentFocusNode] is supplied, this helper also transfers focus into
/// the selected pane's first content item after the parent updates it.
class PaneManager extends StatefulWidget {
  const PaneManager({
    required this.panes,
    required this.selectedIndex,
    required this.onSelected,
    this.contentFocusNode,
    this.controller,
    this.autofocus = false,
    super.key,
  }) : assert(panes.length > 0),
       assert(selectedIndex >= 0 && selectedIndex < panes.length);

  static const double height = 52;

  final List<PaneManagerItem> panes;
  final int selectedIndex;
  /// Called only when activation changes the selected pane.
  final ValueChanged<int> onSelected;

  /// A focus target inside the currently displayed pane's content.
  /// The caller supplies only the target node; PaneManager handles navigation.
  final FocusNode? contentFocusNode;

  /// Supply with a [PaneManagerContent] to enable strict focus isolation and Back.
  final PaneManagerController? controller;

  final bool autofocus;

  @override
  State<PaneManager> createState() => _PaneManagerState();
}

class _PaneManagerState extends State<PaneManager> {
  late List<FocusNode> _nodes;
  final _ownPaneScope = FocusScopeNode(
    debugLabel: 'Standalone PaneManager header',
    traversalEdgeBehavior: TraversalEdgeBehavior.stop,
    directionalTraversalEdgeBehavior: TraversalEdgeBehavior.stop,
  );
  int? _focusedIndex;

  @override
  void initState() {
    super.initState();
    _nodes = List.generate(widget.panes.length, (_) => FocusNode());
    widget.controller?._attach(_nodes, widget.selectedIndex);
  }

  @override
  void didUpdateWidget(PaneManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(_nodes);
      widget.controller?._attach(_nodes, widget.selectedIndex);
    } else {
      widget.controller?._updateSelection(widget.selectedIndex);
    }
    if (oldWidget.panes.length != widget.panes.length) {
      widget.controller?._detach(_nodes);
      for (final node in _nodes) {
        node.dispose();
      }
      _nodes = List.generate(widget.panes.length, (_) => FocusNode());
      widget.controller?._attach(_nodes, widget.selectedIndex);
      _focusedIndex = null;
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(_nodes);
    _ownPaneScope.dispose();
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _focusPane(int index) {
    _nodes[index].requestFocus();
  }

  void _activatePane(int index) {
    _focusPane(index);
    if (index != widget.selectedIndex) {
      widget.onSelected(index);
    }
    final destination = widget.contentFocusNode;
    if (destination == null) {
      return;
    }

    // Sliver lists build items lazily. Reset the containing scroll view first
    // so the initial content item can be mounted before requesting its focus.
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null && scrollable.position.hasPixels) {
      scrollable.position.jumpTo(scrollable.position.minScrollExtent);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && destination.context != null) {
        destination.requestFocus();
      }
    });
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
        _focusPane(focused - 1);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (focused < _nodes.length - 1) {
        _focusPane(focused + 1);
      }
      return KeyEventResult.handled;
    }

    // Android D-pad centre/trackpad click can map to Select rather than Enter.
    // InkWell also handles keyboard activation where Flutter supplies it.
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _activatePane(focused);
      return KeyEventResult.handled;
    }

    // Never enter the owned content via Up/Down. Back is the only return path.
    if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final inactiveGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4B4E53), Color(0xFF292C31)],
    );

    final paneBar = SizedBox(
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
                      onTap: () => _activatePane(index),
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
    final scopedBar = FocusScope(
      node: widget.controller?.paneScope ?? _ownPaneScope,
      child: paneBar,
    );
    final controller = widget.controller;
    if (controller == null) {
      return scopedBar;
    }
    // Consumes Android system Back while the owned list has focus. When
    // PaneManager has focus, Back is unhandled and the page navigates normally.
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (ModalRoute.of(context)?.isCurrent != true) {
          return false;
        }
        return controller.returnToPanes();
      },
      child: scopedBar,
    );
  }
}
