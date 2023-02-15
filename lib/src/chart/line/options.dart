import 'dart:ui' as ui show Color;
import 'package:flutter/material.dart' as material show Colors; // any color we can use is from here, more descriptive
import 'package:flutter/foundation.dart' show immutable;

@immutable
class LineChartOptions {
  /// Control the look of the circle on line chart
  final double hotspotInnerRadius;
  final double hotspotOuterRadius;

  /// Paint for the inner circle on line chart.
  /// Using common paint object for all circles, we
  /// force all circles to look the same.
  /// todo 3 - consider per dataRow control.
  final ui.Color hotspotInnerPaintColor;

  final ui.Color hotspotOuterPaintColor;

  /// Width of the line connecting the circles on line chart.
  /// Paint for one series. Using one option for all series, we
  /// force all series width the same.
  /// todo 3 - consider per dataRow width instances.
  final double lineStrokeWidth;

  /// Constructor with default values.
  const LineChartOptions({
    this.hotspotInnerRadius = 3.0,
    this.hotspotOuterRadius = 6.0,
    this.hotspotInnerPaintColor = material.Colors.yellow,
    this.hotspotOuterPaintColor = material.Colors.black,
    this.lineStrokeWidth = 3.0,
  });
}
