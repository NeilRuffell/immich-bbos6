import 'package:flutter/material.dart';

abstract final class Bbos6SelectionGradient {
  static const light = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF088EEF),
      Color(0xFF088AEF),
      Color(0xFF0886EF),
      Color(0xFF0882EF),
      Color(0xFF087DE7),
      Color(0xFF0879E7),
      Color(0xFF1075E7),
      Color(0xFF1071E7),
      Color(0xFF106DDE),
      Color(0xFF1069DE),
      Color(0xFF1065DE),
    ],
  );

  static const dark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF459FD9),
      Color(0xFF3285C5),
      Color(0xFF2368AA),
    ],
  );

  static LinearGradient forBrightness(Brightness brightness) => brightness == Brightness.dark ? dark : light;
}
