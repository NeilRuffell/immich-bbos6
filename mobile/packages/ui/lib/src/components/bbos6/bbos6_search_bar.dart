import 'package:flutter/material.dart';

/// BBOS6 Music search chrome, translated from MusicSearchBarView.java.
///
/// This is strictly visual: callers supply their own text input, controller,
/// search callbacks, and keyboard handling.
class Bbos6SearchBar extends StatelessWidget {
  const Bbos6SearchBar({required this.child, super.key});

  static const double height = 54;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4B4E53), Color(0xFF292C31)],
          ),
          border: Border(top: BorderSide(color: Color(0xFF5A5D63))),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(5)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4E555B), Color(0xFF6B7074)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFD6D7D6),
                      Color(0xFFE7E7E7),
                      Color(0xFFEFEFEF),
                      Color(0xFFF7F7F7),
                      Colors.white,
                      Colors.white,
                    ],
                    stops: [0, 0.04, 0.08, 0.12, 0.18, 1],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
