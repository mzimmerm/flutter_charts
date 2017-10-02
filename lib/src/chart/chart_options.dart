import 'dart:ui' as ui show Color;
import 'dart:math' as math show Random, pow;
import 'package:flutter/material.dart' as material show Colors;

import 'random_chart_data.dart' show RandomChartData;


/// Options for chart allow to configure certain sizes, colors, and layout.
///
/// Generally, some defaults are provided here. Some options, mostly sizing
/// related, may be overriden or adjusted by the chart auto-layout.
class ChartOptions {

  /// Defines how to layout chart's Y labels: manually or using auto-layout,
  /// and auto-creation and scaling of Y labels from data.
  ///
  /// - If `true`, a "manual" layout of Y axis is used.
  ///   This requires [ChartData.yLabels] to be defined.
  ///   Labels can be Strings or numbers..
  ///   Current layout implementation splits Y axis into even number of
  ///   sections, each of [ChartData.yLabels] labels one horizontal guide line.
  /// - If `false`, a "auto" layout of Y axis is used.
  ///   - Current auto-layout implementation smartly creates Y labels
  ///     from data on a limited number of points, so that Y labels do not
  ///     crowd, and little Y space is wasted on top.

  bool doManualLayoutUsingYLabels = false;

  /// Shows largest value on very top of the chart grid, to save space.
  bool largestValuePointOnVeryTop = true; // false not supported yet

  /// Colors corresponding to each data row (series) in [ChartData].
  final List<ui.Color> dataRowsColors = new List<ui.Color>();

  /// Number of grid lines and y axis labels. Not implemented
  final int maxNumYLabels = 4;

  /// Color defaults
  final ui.Color gridLinesColor = material.Colors.grey;
  final ui.Color xLabelsColor = material.Colors
      .grey; // or const ui.Color(0xFFEEEEEE)

  /// Length of ticks around the grid rectangle.
  /// Autolayout can increase these lengths, to fit labels below them.
  final double xTopMinTicksHeight = 6.0; // todo 00 not applied?
  final double yRightMinTicksWidth = 6.0;
  final double xBottomMinTicksHeight = 6.0;
  final double yLeftMinTicksWidth = 6.0;

  /// Pad space around X labels. todo 1 separate top, bottom, left, right, and only keep those used
  final double xLabelsPadTB = 12.0; // top and bottom
  final double xLabelsPadLR = 12.0; // left and right - Unused

  /// Pad space around Y labels.todo 1 separate top, bottom, left, right, and only keep those used
  final double yLabelsPadTB = 12.0;
  final double yLabelsPadLR = 12.0;

  /// Side of the square used to show color of lines/bars
  /// together with data series name (legend name).
  double legendColorIndicatorWidth = 20.0;
  double legendColorIndicatorPaddingLR = 1.0;
  double legendContainerMarginLR = 12.0; // todo 1 make = xLabelsPadLR;
  double legendContainerMarginTB = 6.0;

  final String yLabelUnits = "";

  String toLabel(String label) => label + yLabelUnits;

  String valueToLabel(num value) {
    // if there are >= 3 < 6 decimal digits, replace with K (etc)
    // todo 1 add an option for how to format; a method or a formatter.
    String val = value.toString();
    if (val.endsWith("000000000")) val = val.substring(0, val.length - 9) + "B";
    if (val.endsWith("000000")) val = val.substring(0, val.length - 6) + "M";
    if (val.endsWith("000")) val = val.substring(0, val.length - 3) + "K";

    return val + yLabelUnits;
  }

  /// Sets up colors first threee data rows (series) explicitly, rest randomly
  void setDataRowsRandomColors(int dataRowsCount) {
    if (dataRowsCount >= 1) {
      dataRowsColors.add(material.Colors.red);
    }
    if (dataRowsCount >= 2) {
      dataRowsColors.add(material.Colors.green);
    }
    if (dataRowsCount >= 3) {
      dataRowsColors.add(material.Colors.blue);
    }
    if (dataRowsCount > 3) {
      for (int i = 3; i < dataRowsCount; i++) {
        int colorHex = new math.Random().nextInt(0xFFFFFF);
        int opacityHex = 0xFF;
        dataRowsColors.add(
            new ui.Color(colorHex + (opacityHex * math.pow(16, 6))));
      }
    }
  }

}

/// File for [LineChartOptions] and [RandomLineChartOptions]
/// todo 00 document
///
class LineChartOptions extends ChartOptions {

  final double hotspotInnerRadius = 3.0;
  final double hotspotOuterRadius = 6.0;

}

// todo 00 separate to it's file OR merge random_chart_data to chart_data
class RandomLineChartOptions extends LineChartOptions {


}