import '../options.dart';
import 'dart:ui' as ui show Color;
import 'package:flutter/material.dart' as material show Colors; // any color we can use is from here, more descriptive

import 'package:flutter/foundation.dart' show immutable;

@immutable
class LineChartOptions extends ChartOptions {
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

  /// Constructor with default values; super values can be set by passing an instantiated [ChartOptions] super.
  LineChartOptions({
    // This LineChartOptions constructor Cannot be const due to compile error in
    //   'legendOptions: chartOptions.legendOptions': chartOptions.legendOptions is not constant.
    //   I assume at compile time even the member reference dot (.) can not be done.
    // Forward an instance which values will be set on super
    ChartOptions chartOptions = const ChartOptions(),
    this.hotspotInnerRadius = 3.0,
    this.hotspotOuterRadius = 6.0,
    this.hotspotInnerPaintColor = material.Colors.yellow,
    this.hotspotOuterPaintColor = material.Colors.black,
    this.lineStrokeWidth = 3.0,
  }) : super(
          legendOptions: chartOptions.legendOptions,
          xContainerOptions: chartOptions.xContainerOptions,
          yContainerOptions: chartOptions.yContainerOptions,
          dataContainerOptions: chartOptions.dataContainerOptions,
          labelCommonOptions: chartOptions.labelCommonOptions,
        );

  /// Constructor with default values except no labels.
  LineChartOptions.noLabels()
      : this(
          chartOptions: const ChartOptions.noLabels(),
        );
}
