import 'dart:ui' as ui show Color, TextDirection, TextAlign;
import 'dart:math' as math show pi;
import 'package:flutter/material.dart' as material show Colors;
import 'package:flutter/widgets.dart' as widgets show TextStyle;


/// Options for chart allow to configure certain sizes, colors, and layout.
///
/// Generally, some defaults are provided here. Some options, mostly sizing
/// related, may be overriden or adjusted by the chart auto-layout,
/// see [SimpleChartContainer].
class ChartOptions {

  /// Defines how to create and layout chart's Y labels: either from user
  /// defined Y labels, or from auto-created Y labels from data.
  ///
  /// - If `true`, a "manual" layout of Y axis is used.
  ///   This requires [ChartData.yLabels] to be defined.
  ///   Labels can be Strings or numbers..
  ///   Current layout implementation splits Y axis into even number of
  ///   sections, each of [ChartData.yLabels] labels one horizontal guide line.
  /// - If `false`, a "auto" layout of Y axis is used.
  ///   - Current auto-layout implementation smartly creates
  ///     a limited number of Y labels from data, so that Y labels do not
  ///     crowd, and little Y space is wasted on top.

  final bool useUserProvidedYLabels = false;

  /// Shows largest value on very top of the chart grid, to save space.
  final bool largestValuePointOnVeryTop = true; // false not supported yet

  /// Number of grid lines and y axis labels. Not implemented
  final int maxNumYLabels = 4;

  /// Color defaults
  final ui.Color gridLinesColor = material.Colors.grey;
  final ui.Color xLabelsColor = material.Colors.grey; // const ui.Color(0xFFEEEEEE)

  /// Length of the ticks around the grid rectangle.
  ///
  /// Each tick indicates a center of a label (X on the top and bottom,
  /// Y on the left and righ)
  /// Autolayout can increase these lengths, to fit labels below them.
  @deprecated double xTopPaddingAboveTicksHeight = 6.0; // Padding above grid
  final double yLeftMinTicksWidth = 6.0;
  final double yRightMinTicksWidth = 6.0;
  final double xBottomMinTicksHeight = 6.0;

  // todo 1 in LB, LR, separate top, bottom, left, right, and only keep those used

  /// Pad space around the X labels area. TB - top/bottom, LR - left/right.
  final double xLabelsPadTB = 6.0; // top and bottom
  /// Pad space around the X labels area. TB - top/bottom, LR - left/right.
  final double xLabelsPadLR = 40.0; // todo 0 unused.

  /// Pad space around the Y labels area. TB - top/bottom, LR - left/right.
  final double yLabelsPadTB = 40.0; // todo 0 unused.
  /// Pad space around the Y labels area. TB - top/bottom, LR - left/right.
  final double yLabelsPadLR = 6.0;

  // Series color indicator size - the "Series color indicator"
  // is the square that shows the color of each dataRow
  // (color of lines or bars)
  // together with data series name (legend name).

  /// Margin on the left/right of the LegendContainer
  final double legendContainerMarginLR = 8.0; // keep 12.0, looks better unaligned

  /// Margin on the top/bottom of the LegendContainer
  final double legendContainerMarginTB = 4.0;

  /// Between each legend item pairs (indicator + label)
  final double betweenLegendItemsPadding = 4.0;

  /// Width of the colored square, indicator of each dataRow
  final double legendColorIndicatorWidth = 20.0;

  /// Between square indicator, to label
  final double legendItemIndicatorToLabelPad = 2.0;


  /// Portion of horizontal (X) grid width, used to display presenter leafs.
  ///
  /// For example, for the bar chart, this represents the portion of one
  /// label width along X axis,
  /// which displays the bars (grouped or stacked).
  final double gridStepWidthPortionUsedByAtomicPresenter = 0.75;

  /// Controls the order the painter paints [ChartData.dataRows].
  /// Motivation: Oh the line chart, if two data rows have same values,
  /// the "last painted value wins". This option helps to change the data rows
  /// painting order - painting starts from the first or from the last.
  /// While so far only makes a difference on the line chart, this is defined
  /// as a common option in case there is some future overlap use on other
  /// chart types.
  final bool firstDataRowPaintedFirst = true;

  final double labelFontSize = 14.0;

  final ui.Color labelTextColor = material.Colors.grey[600];

  // ############## Iterative label layout options

  /// General: Maximum iterations of label re-layouts, before giving up.
  ///    "giving up" means that labels may show ovelaping
  final int maxLabelReLayouts = 5;

  /// Font size iteration: When iterative step decreases font size, use this ratio on every step.
  final double decreaseLabelFontRatio = 1.0; // todo-10 : 0.75;

  /// Label skip iteration: When iterative laout step skis labels, this is how many are skiped on
  ///   the first iteration.
  final int showEveryNthLabel = 1;

  /// On multiple auto layout iterations, every new iteration skips more labels.
  /// every iteration, the number of labels skipped is multiplied by
  /// [multiplyLabelSkip]. For example, if on first layout,
  /// [showEveryNthLabel] was 3, and labels still overlap, on the next re-layout
  /// the  [showEveryNthLabel] would be `3 * multiplyLabelSkip`.
  final int multiplyLabelSkip = 2;

  /// Tilt Label iteration: If label do not fit horizontally,
  ///   they are tilted by this value.
  final double labelTiltRadians = math.pi / 4;

  // ############## Text Style

  /// Text style for both X and Y labels.
  ///
  /// The (future) iterative container can change this default for labels to fit.
  widgets.TextStyle get labelTextStyle => new widgets.TextStyle(
    color: labelTextColor,
    fontSize: labelFontSize,);

  final ui.TextDirection labelTextDirection   = ui.TextDirection.ltr;
  final ui.TextAlign     labelTextAlign       = ui.TextAlign.center;
  final ui.TextAlign     legendTextAlign      = ui.TextAlign.left; // indicator close
  final double           labelTextScaleFactor = 1.0;

  /// todo-2 remove, replace with formatter outright
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

}
