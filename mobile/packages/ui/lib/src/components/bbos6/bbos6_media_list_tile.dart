import 'package:flutter/material.dart';
import 'package:immich_ui/src/components/bbos6/bbos6_selection_gradient.dart';

class Bbos6MediaListTile extends StatefulWidget {
  const Bbos6MediaListTile({
    required this.title,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.trailing,
    this.focusNode,
    this.autofocus = false,
    this.showDivider = true,
    super.key,
  });

  static const double rowHeight = 68;
  static const double titleSize = 15;
  static const double subtitleSize = 12;

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool showDivider;

  @override
  State<Bbos6MediaListTile> createState() => _Bbos6MediaListTileState();
}

class _Bbos6MediaListTileState extends State<Bbos6MediaListTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Bbos6MediaListTile.rowHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _focused ? null : Colors.black,
          gradient: _focused ? Bbos6SelectionGradient.forBrightness(Theme.of(context).brightness) : null,
          border: widget.showDivider
              ? const Border(bottom: BorderSide(color: Color(0xFF303030)))
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            onFocusChange: (focused) => setState(() => _focused = focused),
            onTap: widget.onTap,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            highlightColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            child: Row(
              children: [
                if (widget.leading != null)
                  SizedBox(
                    width: Bbos6MediaListTile.rowHeight,
                    height: Bbos6MediaListTile.rowHeight,
                    child: Center(
                      child: IconTheme(
                        data: IconThemeData(color: widget.onTap == null ? const Color(0xFF777777) : Colors.white),
                        child: widget.leading!,
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.onTap == null ? const Color(0xFF777777) : Colors.white,
                            fontSize: Bbos6MediaListTile.titleSize,
                          ),
                        ),
                        if (widget.subtitle != null)
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.onTap == null
                                  ? const Color(0xFF777777)
                                  : _focused
                                  ? const Color(0xFFEDF4FF)
                                  : const Color(0xFFB3C1CE),
                              fontSize: Bbos6MediaListTile.subtitleSize,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: IconTheme(
                      data: IconThemeData(color: widget.onTap == null ? const Color(0xFF777777) : Colors.white),
                      child: widget.trailing!,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
