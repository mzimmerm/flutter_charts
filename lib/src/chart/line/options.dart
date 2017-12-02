import '../options.dart';
import 'dart:ui' as ui show Paint;
import 'package:flutter/material.dart' as material show Paint, Colors;

class LineChartOptions extends ChartOptions {

  /// Control the look of the circle on line chart
  double hotspotInnerRadius = 3.0;
  double hotspotOuterRadius = 6.0;

  /// Paint of inner circle. By extracting the whole object, we force
  /// all circles to look the same. todo 3 - consider each dataRow control.
  ui.Paint hotspotInnerPaint = new ui.Paint()
    ..color = material.Colors.yellow;

  ui.Paint hotspotOuterPaint = new ui.Paint()
    ..color = material.Colors.black;

  /// Control the properties of line connecting the circles on line chart
  double lineStrokeWidth = 3.0;
}
