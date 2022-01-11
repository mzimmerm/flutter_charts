import 'package:flutter/widgets.dart' as widgets;

import 'painter.dart' as painter;

/// Abstract base class of Flutter Charts.
///
abstract class FlutterChart extends widgets.CustomPaint {
  /// Default constructor accepts size
  const FlutterChart({
    widgets.Key? key,
    required painter.FlutterChartPainter painter,
    widgets.CustomPainter? foregroundPainter,
    widgets.Size size = widgets.Size.zero,
    widgets.Widget? child,
  }) : super(
          key: key,
          painter: painter,
          foregroundPainter: foregroundPainter,
          size: size,
          child: child,
        );
}
