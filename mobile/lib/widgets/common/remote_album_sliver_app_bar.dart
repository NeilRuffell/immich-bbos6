import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/extensions/datetime_extensions.dart';
import 'package:immich_mobile/presentation/widgets/sliver_app_bar/item_count_text.widget.dart';
import 'package:immich_mobile/providers/infrastructure/current_album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/remote_album.provider.dart';
import 'package:immich_mobile/providers/infrastructure/timeline.provider.dart';
import 'package:immich_mobile/providers/timeline/multiselect.provider.dart';
import 'package:immich_mobile/routing/router.dart';
import 'package:immich_mobile/widgets/album/remote_album_shared_user_icons.dart';

class RemoteAlbumSliverAppBar extends ConsumerStatefulWidget {
  const RemoteAlbumSliverAppBar({super.key, required this.kebabMenu, this.onEditTitle, this.onActivity});

  final Widget kebabMenu;
  final void Function()? onEditTitle;
  final void Function()? onActivity;

  @override
  ConsumerState<RemoteAlbumSliverAppBar> createState() => _MesmerizingSliverAppBarState();
}

class _MesmerizingSliverAppBarState extends ConsumerState<RemoteAlbumSliverAppBar> {
  double _scrollProgress = 0.0;

  // Reserve only the space used by album details, plus clearance for the
  // pinned toolbar. Longer album names and descriptions increase the height
  // instead of overflowing a one-size-fits-all header.
  double _expandedHeight(BuildContext context, String name, String description, bool isShared) {
    final maxWidth = math.max(1.0, MediaQuery.sizeOf(context).width - 32.0);
    final textScaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final titlePainter = TextPainter(
      text: TextSpan(text: name, style: _CompactAlbumTitle.style),
      textScaler: textScaler,
      textDirection: direction,
      maxLines: 3,
    )..layout(maxWidth: maxWidth);
    final titleHeight = titlePainter.height;
    titlePainter.dispose();

    var descriptionHeight = 0.0;
    if (description.isNotEmpty) {
      final descriptionPainter = TextPainter(
        text: TextSpan(text: description, style: _ExpandedBackgroundState.descriptionStyle),
        textScaler: textScaler,
        textDirection: direction,
        maxLines: 2,
      )..layout(maxWidth: maxWidth);
      descriptionHeight = math.min(44.0, descriptionPainter.height) + 4.0;
      descriptionPainter.dispose();
    }

    // The existing shared-user widget occupies 50dp when the album is shared.
    const toolbarClearance = kToolbarHeight + 30.0;
    const metadataHeight = 24.0;
    const bottomPadding = 12.0;
    final usersHeight = isShared ? 54.0 : 0.0;
    return math.max(
      180.0,
      toolbarClearance + metadataHeight + titleHeight + descriptionHeight + usersHeight + bottomPadding,
    );
  }

  double _calculateScrollProgress(FlexibleSpaceBarSettings? settings) {
    if (settings?.maxExtent == null || settings?.minExtent == null) {
      return 1.0;
    }

    final deltaExtent = settings!.maxExtent - settings.minExtent;
    if (deltaExtent <= 0.0) {
      return 1.0;
    }

    return (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isMultiSelectEnabled = ref.watch(multiSelectProvider.select((s) => s.isEnabled));

    final currentAlbum = ref.watch(currentRemoteAlbumProvider);
    if (currentAlbum == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final Color? actionIconColor = Color.lerp(Colors.white, context.primaryColor, _scrollProgress);

    final List<Shadow> actionIconShadows = [
      if (_scrollProgress < 0.95)
        Shadow(offset: const Offset(0, 2), blurRadius: 5, color: Colors.black.withValues(alpha: 0.5))
      else
        const Shadow(offset: Offset(0, 2), blurRadius: 0, color: Colors.transparent),
    ];

    return SliverAppBar(
      expandedHeight: _expandedHeight(context, currentAlbum.name, currentAlbum.description, currentAlbum.isShared),
      floating: false,
      pinned: true,
      snap: false,
      elevation: 0,
      leading: isMultiSelectEnabled
          ? const SizedBox.shrink()
          : IconButton(
              icon: Icon(
                Platform.isIOS ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back,
                color: actionIconColor,
                shadows: actionIconShadows,
              ),
              onPressed: () => context.maybePop(),
            ),
      actions: [
        IconButton(
          onPressed: () => context.pushRoute(SlideshowRoute(timeline: ref.read(timelineServiceProvider))),
          icon: Icon(Icons.slideshow_outlined, color: actionIconColor, shadows: actionIconShadows),
        ),
        if (currentAlbum.isActivityEnabled && currentAlbum.isShared)
          IconButton(
            icon: Icon(Icons.chat_outlined, color: actionIconColor, shadows: actionIconShadows),
            onPressed: widget.onActivity,
          ),
        widget.kebabMenu,
      ],
      title: Builder(
        builder: (context) {
          final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
          final scrollProgress = _calculateScrollProgress(settings);

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: scrollProgress > 0.95
                ? Text(
                    currentAlbum.name,
                    style: TextStyle(color: context.primaryColor, fontWeight: FontWeight.w600, fontSize: 18),
                  )
                : null,
          );
        },
      ),
      flexibleSpace: Builder(
        builder: (context) {
          final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
          final scrollProgress = _calculateScrollProgress(settings);

          // Update scroll progress for the leading button
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollProgress != scrollProgress) {
              setState(() {
                _scrollProgress = scrollProgress;
              });
            }
          });

          return FlexibleSpaceBar(
            background: _ExpandedBackground(scrollProgress: scrollProgress, onEditTitle: widget.onEditTitle),
          );
        },
      ),
    );
  }
}

class _ExpandedBackground extends ConsumerStatefulWidget {
  final double scrollProgress;
  final void Function()? onEditTitle;

  const _ExpandedBackground({required this.scrollProgress, this.onEditTitle});

  @override
  ConsumerState<_ExpandedBackground> createState() => _ExpandedBackgroundState();
}

class _ExpandedBackgroundState extends ConsumerState<_ExpandedBackground> with SingleTickerProviderStateMixin {
  static const descriptionStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    height: 1.15,
    shadows: [Shadow(offset: Offset(0, 2), blurRadius: 8, color: Colors.black54)],
  );

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        unawaited(_slideController.forward());
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentAlbum = ref.watch(currentRemoteAlbumProvider);

    if (currentAlbum == null) {
      return const SizedBox.shrink();
    }

    final dateRange = ref.watch(remoteAlbumDateRangeProvider(currentAlbum.id));
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF151515)),
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (dateRange.hasValue)
                      Text(
                        DateRangeFormatting.formatDateRange(
                          dateRange.value!.$1.toLocal(),
                          dateRange.value!.$2.toLocal(),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          shadows: [Shadow(offset: Offset(0, 2), blurRadius: 12, color: Colors.black87)],
                        ),
                      ),
                    const Text(
                      " • ",
                      style: TextStyle(
                        color: Colors.white,
                        shadows: [Shadow(offset: Offset(0, 2), blurRadius: 12, color: Colors.black87)],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      child: const ItemCountText(
                        style: TextStyle(
                          color: Colors.white,
                          shadows: [Shadow(offset: Offset(0, 2), blurRadius: 12, color: Colors.black87)],
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: widget.onEditTitle,
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        _CompactAlbumTitle(text: currentAlbum.name, maxWidth: constraints.maxWidth),
                  ),
                ),
                if (currentAlbum.description.isNotEmpty)
                  GestureDetector(
                    onTap: widget.onEditTitle,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 44),
                      child: SingleChildScrollView(
                        child: Text(
                          currentAlbum.description,
                          style: descriptionStyle,
                        ),
                      ),
                    ),
                  ),
                const Padding(padding: EdgeInsets.only(top: 4.0), child: RemoteAlbumSharedUserIcons()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactAlbumTitle extends StatelessWidget {
  final String text;
  final double maxWidth;

  const _CompactAlbumTitle({required this.text, required this.maxWidth});

  static const style = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 26,
    height: 1.08,
    letterSpacing: 0.2,
  );

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
