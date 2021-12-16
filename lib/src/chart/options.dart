import 'dart:ui' as ui show Color, TextDirection, TextAlign;
import 'dart:math' as math show pi;
import 'package:flutter/foundation.dart' show immutable;

// todo-00-new done: Use ui.Color as it can be const:  import 'package:flutter/material.dart' as material show Colors;
import 'package:flutter/widgets.dart' as widgets show TextStyle;

/// Options for chart allow to configure certain sizes, colors, and layout.
///
/// Generally, some defaults are provided here. Some options, mostly sizing
/// related, may be overridden or adjusted by the chart auto-layout,
/// see [SimpleChartContainer].
// @immutable
class ChartOptions {
  
  /// Manages showing the legend container on the chart.
  final bool isLegendContainerShown;
  final bool isXContainerShown;
  final bool isYContainerShown;
  /// In the current implementation, X gridlines (horizontal) disappear when `isYContainerShown = false`, 
  /// which is probably reasonable, although should be fixed.
  ///   
  /// However, Y gridlines (vertical) are showing even when `isXContainerShown = false`.
  /// This option allows to toggle it.
  final bool isYGridlinesShown;
  
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

  final bool useUserProvidedYLabels;

  /// Shows largest value on very top of the chart grid, to save space.
  final bool largestValuePointOnVeryTop; // false not supported yet

  /// Number of grid lines and y axis labels. Not implemented
  final int maxNumYLabels;

  /// Color defaults
  final ui.Color gridLinesColor;// todo-00-new : use const: material.Colors.grey;
  final ui.Color xLabelsColor; // todo-00-new : use const: material.Colors.grey;

  /// Length of the ticks around the grid rectangle.
  ///
  /// Each tick indicates a center of a label (X on the top and bottom,
  /// Y on the left and righ)
  /// Autolayout can increase these lengths, to fit labels below them.
  final double yLeftMinTicksWidth;
  final double yRightMinTicksWidth;
  final double xBottomMinTicksHeight;

  // todo 1 in LB, LR, separate top, bottom, left, right, and only keep those used

  /// Pad space around the X labels area. TB - top/bottom, LR - left/right.
  final double xLabelsPadTB; // top and bottom
  /// Pad space around the X labels area. TB - top/bottom, LR - left/right.
  final double xLabelsPadLR; // todo-00-new-last unused.

  /// Pad space around the Y labels area. TB - top/bottom, LR - left/right.
  final double yLabelsPadTB; // todo-00-new-last.
  /// Pad space around the Y labels area. TB - top/bottom, LR - left/right.
  final double yLabelsPadLR;

  // Series color indicator size - the "Series color indicator"
  // is the square that shows the color of each dataRow (color of lines or bars)
  // together with data series name (legend name).

  /// Margin on the left/right of the LegendContainer
  final double legendContainerMarginLR;

  /// Margin on the top/bottom of the LegendContainer
  final double legendContainerMarginTB;

  /// Between each legend item pairs (indicator + label)
  final double betweenLegendItemsPadding;

  /// Width of the colored square, indicator of each dataRow
  final double legendColorIndicatorWidth;

  /// Between square indicator, to label
  final double legendItemIndicatorToLabelPad;

  /// Portion of horizontal (X) grid width, used to display presenter leafs.
  ///
  /// For example, for the bar chart, this represents the portion of one
  /// label width along X axis,
  /// which displays the bars (grouped or stacked).
  final double gridStepWidthPortionUsedByAtomicPresenter;

  /// Controls the order the painter paints [ChartData.dataRows].
  /// Motivation: On the line chart, if two data rows have same values,
  /// the "last painted value wins". This option helps to change the data rows
  /// painting order - painting starts from the first or from the last.
  /// While so far only makes a difference on the line chart, this is defined
  /// as a common option in case there is some future overlap use on other
  /// chart types.
  final DataRowsPaintingOrder dataRowsPaintingOrder;

  final double labelFontSize;

  // todo-00-new : final ui.Color? labelTextColor = material.Colors.grey[600];
  final ui.Color labelTextColor; // todo-00-new : use const: material.Colors.grey[600];

  // ############## Iterative label layout options

  /// General: Maximum iterations of label re-layouts, before giving up.
  ///    "giving up" means that labels may show ovelaping
  final int maxLabelReLayouts;

  /// Font size iteration: When iterative step decreases font size, use this ratio on every step.
  final double decreaseLabelFontRatio;

  /// Label skip iteration: When iterative laout step skis labels, this is how many are skiped on
  ///   the first iteration.
  final int showEveryNthLabel;

  /// On multiple auto layout iterations, every new iteration skips more labels.
  /// every iteration, the number of labels skipped is multiplied by
  /// [multiplyLabelSkip]. For example, if on first layout,
  /// [showEveryNthLabel] was 3, and labels still overlap, on the next re-layout
  /// the  [showEveryNthLabel] would be `3 * multiplyLabelSkip`.
  final int multiplyLabelSkip;

  /// Tilt Label iteration: If label do not fit horizontally,
  ///   they are tilted by this value.
  final double labelTiltRadians;

  // ############## Text Style

  final ui.TextDirection labelTextDirection;
  final ui.TextAlign labelTextAlign;
  final ui.TextAlign legendTextAlign ;
  final double labelTextScaleFactor;

  /// todo-2 remove, replace with formatter outright
  final String yLabelUnits;

  const ChartOptions({
    this.isLegendContainerShown = true,
    this.isXContainerShown = true,
    this.isYContainerShown = true,
    this.isYGridlinesShown = true,
    this.useUserProvidedYLabels = false,
    this.largestValuePointOnVeryTop = true,
    this.maxNumYLabels = 4,
    this.gridLinesColor = const ui.Color(0xFF9E9E9E), // todo-00-new : use const: material.Colors.grey;
    this.xLabelsColor =  const ui.Color(0xFF9E9E9E),  // todo-00-new : use const: material.Colors.grey;
    this.yLeftMinTicksWidth = 6.0,
    this.yRightMinTicksWidth = 6.0,
    this.xBottomMinTicksHeight = 6.0,
    this.xLabelsPadTB = 6.0,
    this.xLabelsPadLR = 40.0,
    this.yLabelsPadTB = 40.0,
    this.yLabelsPadLR = 6.0,
    this.legendContainerMarginLR = 8.0,
    this.legendContainerMarginTB = 4.0,
    this.betweenLegendItemsPadding = 4.0,
    this.legendColorIndicatorWidth = 20.0,
    this.legendItemIndicatorToLabelPad = 2.0,
    this.gridStepWidthPortionUsedByAtomicPresenter = 0.75,
    this.dataRowsPaintingOrder = DataRowsPaintingOrder.firstToLast,
    this.labelFontSize = 14.0,
    this.labelTextColor = const ui.Color(0xFF757575), // todo-00-new : use const: material.Colors.grey[600];
    this.maxLabelReLayouts = 5,
    this.decreaseLabelFontRatio = 1.0,
    this.showEveryNthLabel = 1,
    this.multiplyLabelSkip = 2,
    this.labelTiltRadians = math.pi / 4,
    this.labelTextDirection = ui.TextDirection.ltr,
    this.labelTextAlign = ui.TextAlign.center,
    this.legendTextAlign = ui.TextAlign.left,
    this.labelTextScaleFactor = 1.0,
    this.yLabelUnits = '',
  });

  /// Convenience constructor sets all values to default except labels and gridlines are defined not to show.
  const ChartOptions.noLabels() : this(
    isLegendContainerShown: false,
    isXContainerShown: false,
    isYContainerShown: false,
    isYGridlinesShown: false,
  );
  
  /// Text style for both X and Y labels.
  ///
  /// The (future) iterative container can change this default for labels to fit.
  widgets.TextStyle get labelTextStyle => widgets.TextStyle(
    color: labelTextColor,
    fontSize: labelFontSize,
  );

  String toLabel(String label) => label + yLabelUnits;

  String valueToLabel(num value) {
    // if there are >= 3 < 6 decimal digits, replace with K (etc)
    // todo 1 add an option for how to format; a method or a formatter.
    String val = value.toString();
    if (val.endsWith('000000000')) val = val.substring(0, val.length - 9) + 'B';
    if (val.endsWith('000000')) val = val.substring(0, val.length - 6) + 'M';
    if (val.endsWith('000')) val = val.substring(0, val.length - 3) + 'K';

    return val + yLabelUnits;
  }
}

enum DataRowsPaintingOrder { 
  firstToLast, 
  lastToFirst,
}
