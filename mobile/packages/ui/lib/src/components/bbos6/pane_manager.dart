import 'package:flutter/foundation.dart';
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
    return FocusScope(
      node: controller.contentScope,
      // The child may be a RenderSliver. FocusScope's default Semantics
      // inserts a RenderBox, which is invalid directly above slivers.
      // Disabling only this wrapper's semantics preserves content semantics.
      includeSemantics: false,
      // Back is handled only by PaneManager's BackButtonListener below.
      // Also intercepting a physical Back key here changes focus before
      // Android dispatches its route pop and can make one press pop twice.
      child: _PaneContentFocusScrollSync(
        controller: controller,
        child: kDebugMode ? _PaneContentScrollTrace(controller: controller, child: child) : child,
      ),
    );
  }
}

/// Keeps keyboard/trackpad focus visible within the PaneManager-owned
/// Scrollable, aligning upward travel below the pinned pane header and
/// downward travel against the bottom of the viewport.
/// This wrapper is safe for RenderSliver children: it creates no RenderBox.
class _PaneContentFocusScrollSync extends StatefulWidget {
  const _PaneContentFocusScrollSync({required this.controller, required this.child});

  final PaneManagerController controller;
  final Widget child;

  @override
  State<_PaneContentFocusScrollSync> createState() => _PaneContentFocusScrollSyncState();
}

class _PaneContentFocusScrollSyncState extends State<_PaneContentFocusScrollSync> {
  ScrollableState? _scrollable;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_keepFocusedItemVisible);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollable = Scrollable.maybeOf(context);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_keepFocusedItemVisible);
    super.dispose();
  }

  void _keepFocusedItemVisible() {
    if (!widget.controller.contentScope.hasFocus) {
      return;
    }
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    final scrollable = _scrollable;
    if (focusedContext == null || scrollable == null || Scrollable.maybeOf(focusedContext) != scrollable) {
      return;
    }

    final position = scrollable.position;
    final focusedRender = focusedContext.findRenderObject();
    final viewportRender = scrollable.context.findRenderObject();
    if (!position.hasPixels ||
        !position.hasContentDimensions ||
        focusedRender is! RenderBox ||
        !focusedRender.attached ||
        !focusedRender.hasSize ||
        viewportRender is! RenderBox ||
        !viewportRender.attached ||
        !viewportRender.hasSize ||
        viewportRender.size.height <= 0) {
      return;
    }

    final viewportTop = viewportRender.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + viewportRender.size.height;
    var visibleTop = viewportTop;

    // The pane bar can be pinned over the Scrollable's viewport. Account
    // for its actual rendered bottom rather than hardcoding an Albums offset.
    final paneRender = widget.controller.paneScope.context?.findRenderObject();
    if (paneRender is RenderBox && paneRender.attached && paneRender.hasSize) {
      final paneBottom = paneRender.localToGlobal(Offset(0, paneRender.size.height)).dy;
      if (paneBottom > visibleTop && paneBottom < viewportBottom) {
        visibleTop = paneBottom;
      }
    }

    final focusedTop = focusedRender.localToGlobal(Offset.zero).dy;
    final focusedBottom = focusedTop + focusedRender.size.height;

    // Match standalone list traversal: only scroll when focus crosses a
    // visible edge. Up aligns below the pinned pane bar; down aligns with
    // the viewport bottom. Moving focus within those edges does not scroll.
    final bool revealUp = focusedTop < visibleTop - 0.5;
    final bool revealDown = focusedBottom > viewportBottom + 0.5;
    if (!revealUp && !revealDown) {
      return;
    }
    final alignment = revealUp
        ? ((visibleTop - viewportTop) / viewportRender.size.height).clamp(0.0, 1.0).toDouble()
        : 1.0;
    position.ensureVisible(focusedRender, alignment: alignment);
    if (kDebugMode) {
      debugPrint(
        'BBOS6-PaneScroll: focus.reveal-${revealUp ? "up" : "down"} '
        'focus=${FocusManager.instance.primaryFocus?.debugLabel ?? "none"} '
        'visibleTop=${visibleTop.toStringAsFixed(1)} '
        'itemY=${focusedTop.toStringAsFixed(1)}..${focusedBottom.toStringAsFixed(1)} '
        'viewportBottom=${viewportBottom.toStringAsFixed(1)} '
        'scrollPixels=${position.pixels.toStringAsFixed(1)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Debug-only observer. It is omitted from profile and release widget trees.
/// Neither its focus listener nor its scroll listener changes navigation.
class _PaneContentScrollTrace extends StatefulWidget {
  const _PaneContentScrollTrace({required this.controller, required this.child});

  final PaneManagerController controller;
  final Widget child;

  @override
  State<_PaneContentScrollTrace> createState() => _PaneContentScrollTraceState();
}

class _PaneContentScrollTraceState extends State<_PaneContentScrollTrace> {
  ScrollableState? _scrollable;
  ScrollPosition? _position;
  bool _wasInContent = false;
  double? _lastLoggedScrollOffset;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scrollable = Scrollable.maybeOf(context);
    final position = scrollable?.position;
    if (!identical(_position, position)) {
      _position?.removeListener(_onScrollChanged);
      _position = position;
      _position?.addListener(_onScrollChanged);
      _lastLoggedScrollOffset = null;
    }
    _scrollable = scrollable;
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    _position?.removeListener(_onScrollChanged);
    super.dispose();
  }

  void _onFocusChanged() {
    final inContent = widget.controller.contentScope.hasFocus;
    if (!inContent && !_wasInContent) {
      return;
    }
    _wasInContent = inContent;
    _trace(inContent ? 'focus.changed' : 'focus.left');

    if (inContent) {
      final focusedNode = FocusManager.instance.primaryFocus;
      // Check the scroll offset again after any implicit focus scrolling.
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (mounted &&
            widget.controller.contentScope.hasFocus &&
            identical(FocusManager.instance.primaryFocus, focusedNode)) {
          _trace('focus.after-150ms');
        }
      });
    }
  }

  void _onScrollChanged() {
    if (!widget.controller.contentScope.hasFocus) {
      return;
    }
    final position = _position;
    if (position == null || !position.hasPixels) {
      return;
    }
    final pixels = position.pixels;
    if (_lastLoggedScrollOffset != null && (pixels - _lastLoggedScrollOffset!).abs() < 20) {
      return;
    }
    _lastLoggedScrollOffset = pixels;
    _trace('scroll.changed');
  }

  void _trace(String stage) {
    if (!kDebugMode) {
      return;
    }
    final focus = FocusManager.instance.primaryFocus;
    final position = _position;
    final offset = position != null && position.hasPixels ? position.pixels.toStringAsFixed(1) : 'unavailable';
    final maxOffset = position != null && position.hasContentDimensions
        ? position.maxScrollExtent.toStringAsFixed(1)
        : 'unavailable';
    final focusObject = focus?.context?.findRenderObject();
    final viewportObject = _scrollable?.context.findRenderObject();

    var geometry = 'itemY=unavailable viewportY=unavailable visibility=unknown';
    if (focusObject is RenderBox &&
        viewportObject is RenderBox &&
        focusObject.attached &&
        viewportObject.attached &&
        focusObject.hasSize &&
        viewportObject.hasSize) {
      final itemTop = focusObject.localToGlobal(Offset.zero).dy;
      final itemBottom = itemTop + focusObject.size.height;
      final viewportTop = viewportObject.localToGlobal(Offset.zero).dy;
      final viewportBottom = viewportTop + viewportObject.size.height;
      final visibility = itemBottom <= viewportTop
          ? 'above'
          : itemTop >= viewportBottom
          ? 'below'
          : 'intersects';
      geometry =
          'itemY=${itemTop.toStringAsFixed(1)}..${itemBottom.toStringAsFixed(1)} '
          'viewportY=${viewportTop.toStringAsFixed(1)}..${viewportBottom.toStringAsFixed(1)} '
          'visibility=$visibility';
    }

    debugPrint(
      'BBOS6-PaneScroll: $stage '
      'inContent=${widget.controller.contentScope.hasFocus} '
      'focus=${focus?.debugLabel ?? "none"} '
      'focusId=${focus == null ? "none" : identityHashCode(focus)} '
      'scrollPixels=$offset maxScroll=$maxOffset $geometry',
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


@immutable
class PaneManagerItem {
  const PaneManagerItem({
    required this.label,
    this.icon,
    this.showLabel = true,
    this.semanticLabel,
    this.flex = 1,
    this.labelFontSize = 14,
    this.onActivate,
  }) : assert(label.length > 0),
       assert(flex > 0),
       assert(labelFontSize > 0);

  final String label;
  final Widget? icon;
  final bool showLabel;
  final String? semanticLabel;

  final int flex;
  final double labelFontSize;
  final VoidCallback? onActivate;
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

  // Only available in debug APKs. Compiled out of release/profile builds.
  void _traceFocus(String stage, {int? paneIndex, FocusNode? destination}) {
    if (!kDebugMode) {
      return;
    }
    final focusedIndex = _nodes.indexWhere((node) => node.hasFocus);
    final primary = FocusManager.instance.primaryFocus;
    debugPrint(
      'BBOS6-PaneManager: $stage '
      'pane=$paneIndex selected=${widget.selectedIndex} focusedPane=$focusedIndex '
      'targetSupplied=${destination != null} targetAttached=${destination?.context != null} '
      'targetCanRequestFocus=${destination?.canRequestFocus} '
      'targetHasFocus=${destination?.hasFocus} '
      'contentScopeHasFocus=${widget.controller?.contentScope.hasFocus} '
      'primaryFocus=${primary?.debugLabel ?? primary?.runtimeType.toString() ?? "none"}',
    );
  }

  void _focusPane(int index) {
    _nodes[index].requestFocus();
  }

  void _activatePane(int index, {required String source}) {
    _traceFocus('activate.start source=$source', paneIndex: index, destination: widget.contentFocusNode);
    _focusPane(index);
    final action = widget.panes[index].onActivate;
    if (action != null) {
      _traceFocus('activate.action', paneIndex: index);
      action();
      return;
    }
    if (index != widget.selectedIndex) {
      widget.onSelected(index);
    }
    final destination = widget.contentFocusNode;
    if (destination == null) {
      _traceFocus('activate.no-content-target', paneIndex: index);
      return;
    }

    // Sliver lists build items lazily. Reset the containing scroll view first
    // so the initial content item can be mounted before requesting its focus.
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null && scrollable.position.hasPixels) {
      scrollable.position.jumpTo(scrollable.position.minScrollExtent);
    }
    _traceFocus('activate.scheduled', paneIndex: index, destination: destination);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _traceFocus('activate.post-frame', paneIndex: index, destination: destination);
      if (mounted && destination.context != null) {
        destination.requestFocus();
        _traceFocus('activate.requested-focus', paneIndex: index, destination: destination);
      } else {
        _traceFocus('activate.target-unavailable', paneIndex: index, destination: destination);
      }
      // Focus requests are committed asynchronously. Observe the resulting
      // primary focus without introducing any timing change in release builds.
      if (kDebugMode) {
        Future<void>.delayed(Duration.zero, () {
          if (mounted) {
            _traceFocus('activate.after-focus-update', paneIndex: index, destination: destination);
          }
        });
      }
    });
    // addPostFrameCallback alone does not request a frame. Activating the
    // already-selected pane doesn't call onSelected or rebuild the page.
    // Explicitly schedule the frame needed for the focus handoff.
    WidgetsBinding.instance.scheduleFrame();
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
      _activatePane(focused, source: 'key:${event.logicalKey.keyLabel}');
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
                  flex: widget.panes[index].flex,
                  child: Semantics(
                    label: widget.panes[index].semanticLabel ??
                        (widget.panes[index].showLabel ? null : widget.panes[index].label),
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
                        _traceFocus('pane.focus-changed=$focused', paneIndex: index, destination: widget.contentFocusNode);
                      },
                      onTap: () => _activatePane(index, source: 'tap'),
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
                                        fontSize: widget.panes[index].labelFontSize,
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
    // BackButtonListener requires a Router with a BackButtonDispatcher.
    // Widget previews/tests without a Router retain the scope-only behavior.
    if (controller == null || Router.maybeOf(context)?.backButtonDispatcher == null) {
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
