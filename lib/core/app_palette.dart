import 'package:flutter/material.dart';

abstract final class AppPalette {
  static const ink = Color(0xff171717);
  static const mutedInk = Color(0xff65728f);

  static Gradient pageBackgroundFor(bool darkMode) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: const [0, .34, .58, 1],
    colors: darkMode
        ? const [Colors.black, Colors.black, Colors.black, Colors.black]
        : const [
            Color(0xff9fe1e3),
            Color(0xffd9eeeb),
            Color(0xfff2d8cc),
            Color(0xfff7f8fa),
          ],
  );
}
