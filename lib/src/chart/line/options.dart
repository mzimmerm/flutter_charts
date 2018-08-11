import '../options.dart';
import 'dart:ui' as ui show Paint;
import 'package:flutter/material.dart' as material show Colors;

class LineChartOptions extends ChartOptions {

  /// Control the look of the circle on line chart
  double hotspotInnerRadius = 3.0;
  double hotspotOuterRadius = 6.0;

  /// Paint for the inner circle on line chart.
  /// Using common paint object for all circles, we
  /// force all circles to look the same.
  /// todo 3 - consider per dataRow control.
  ui.Paint hotspotInnerPaint = new ui.Paint()
    ..color = material.Colors.yellow;

  ui.Paint hotspotOuterPaint = new ui.Paint()
    ..color = material.Colors.black;

  /// Width of the line connecting the circles on line chart.
  /// Paint for one series. Using one option for all series, we
  /// force all series width the same.
  /// todo 3 - consider per dataRow width instances.
  double lineStrokeWidth = 3.0;




}
