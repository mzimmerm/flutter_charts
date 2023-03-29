import 'dart:ui' as ui
    show Color, Paint, PaintingStyle, TextDirection, TextAlign;
import 'package:flutter/material.dart' as material show Colors; // any color we can use is from here, more descriptive
import 'dart:math' as math show pi, log, ln10, pow, max;
import 'package:flutter/widgets.dart' as widgets show TextStyle;
import 'package:flutter/foundation.dart' show immutable;

// extension libraries
import 'container/container_common.dart';
import 'container/axis_container.dart';
import 'line/options.dart';
import 'bar/options.dart';


/// Options for chart allow to configure certain sizes, colors, and layout.
///
/// Generally, some defaults are provided here. Some options, mostly sizing
/// related, may be overridden or adjusted by the chart auto-layout,
/// see [SimpleChartContainer].
@immutable
class ChartOptions {
  final IterativeLayoutOptions iterativeLayoutOptions;
  final LegendOptions legendOptions;
  final XContainerOptions xContainerOptions;
  final YContainerOptions yContainerOptions;
  final DataContainerOptions dataContainerOptions;
  final LabelCommonOptions labelCommonOptions;
  final LineChartOptions lineChartOptions;
  final VerticalBarChartOptions verticalBarChartOptions;

  const ChartOptions({
    this.iterativeLayoutOptions = const IterativeLayoutOptions(),
    this.legendOptions = const LegendOptions(),
    this.xContainerOptions = const XContainerOptions(),
    this.yContainerOptions = const YContainerOptions(),
    this.dataContainerOptions = const DataContainerOptions(),
    this.labelCommonOptions = const LabelCommonOptions(),
    this.lineChartOptions = const LineChartOptions(),
    this.verticalBarChartOptions = const VerticalBarChartOptions(),
  });

  /// Convenience constructor sets all values to default except labels and gridlines are defined not to show.
  const ChartOptions.noLabels()
      : this(
          legendOptions: const LegendOptions(
            isLegendContainerShown: false,
          ),
          xContainerOptions: const XContainerOptions(
            isXContainerShown: false,
          ),
          yContainerOptions: const YContainerOptions(
            isYContainerShown: false,
            isYGridlinesShown: false,
          ),
        );
}

@immutable
class IterativeLayoutOptions {
  /// The maximum number of iterations of label re-layouts, before giving up.
  ///
  ///  By "giving up" it is meant that labels may start to overlap.
  final int maxLabelReLayouts;

  /// The ratio by which we decrease font size during the re-layout of labels.
  ///
  /// In the default layout strategy, this starts to apply when tilting labels does
  /// not result in labels fitting the provided width or height.
  final double decreaseLabelFontRatio;

  /// The number of labels skipped  during the re-layout of labels.
  ///
  /// In the default layout strategy, this starts to apply when tilting labels or decreasing
  /// label font size does not result in labels fitting the provided width or height.
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

  const IterativeLayoutOptions({
    this.maxLabelReLayouts = 5,
    this.decreaseLabelFontRatio = 1.0,
    this.showEveryNthLabel = 1,
    this.multiplyLabelSkip = 2,
    this.labelTiltRadians = -math.pi / 4, // negative rotation is counter-clockwise, generally preferred for labels
  });
}

@immutable
class LegendOptions {
  /// Manages showing the legend container on the chart.
  final bool isLegendContainerShown;

  // Series color indicator size - the "Series color indicator"
  // is the square that shows the color of each valuesRow (color of lines or bars)
  // together with data series name (legend name).

  /// Margin on the left/right of the [LegendContainer]
  final double legendContainerMarginLR;

  /// Margin on the top/bottom of the  [LegendContainer]
  final double legendContainerMarginTB;

  /// Between each legend item pairs (indicator + label)
  final double betweenLegendItemsPadding;

  /// Width of the colored square, indicator of each valuesRow
  final double legendColorIndicatorWidth;

  /// Between square indicator, to label
  final double legendItemIndicatorToLabelPad;

  final ui.TextAlign legendTextAlign;

  /// Controls (four) build-in layouts for legends that client can choose
  /// without requiring code extensions.
  final LegendAndItemLayoutEnum legendAndItemLayoutEnum;

  const LegendOptions({
    this.isLegendContainerShown = true,
    this.legendContainerMarginLR = 8.0,
    this.legendContainerMarginTB = 4.0,
    this.betweenLegendItemsPadding = 4.0,
    this.legendColorIndicatorWidth = 20.0,
    this.legendItemIndicatorToLabelPad = 2.0,
    this.legendTextAlign = ui.TextAlign.left,
    this.legendAndItemLayoutEnum = LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTight,
  });
}

@immutable
class XContainerOptions {
  final bool isXContainerShown;

  /// Pad space around the X labels area. TB - top/bottom, LR - left/right.
  final double xLabelsPadTB;

  /// Pad space around the X labels area. TB - top/bottom, LR - left/right. Unused.
  final double xLabelsPadLR;

  const XContainerOptions({
    this.isXContainerShown = true,
    this.xLabelsPadTB = 6.0,
    this.xLabelsPadLR = 40.0,
  });

  /// Also providing a method to format X labels, but should NOT be used YET
  String valueToLabel(num value) {
    /*
    // if there are >= 3 < 6 decimal digits, replace with K (etc)
    String val = value.toString();
    if (val.endsWith('000000000')) val = val.substring(0, val.length - 9) + 'B';
    if (val.endsWith('000000')) val = val.substring(0, val.length - 6) + 'M';
    if (val.endsWith('000')) val = val.substring(0, val.length - 3) + 'K';

    return val + yLabelUnits;
   */
    throw StateError('XContainerOptions.valueToLabel should not be used YET');
  }

}

@immutable
class YContainerOptions {
  final bool isYContainerShown;

  /// In the current implementation, X gridlines (horizontal) disappear when `isYContainerShown = false`,
  /// which is probably reasonable, although should be fixed.
  ///
  /// However, Y gridlines (vertical) are showing even when `isXContainerShown = false`.
  /// This option allows to toggle it.
  final bool isYGridlinesShown;

  /// Pad space around the Y labels area. TB - top/bottom, LR - left/right. Unused
  final double yLabelsPadTB;

  /// Pad space around the Y labels area. TB - top/bottom, LR - left/right.
  final double yLabelsPadLR;

  /// todo 2 remove, replace with formatter outright
  final String yLabelUnits;

  const YContainerOptions({
    this.isYContainerShown = true,
    this.isYGridlinesShown = true,
    this.yLabelsPadTB = 40.0,
    this.yLabelsPadLR = 6.0,
    this.yLabelUnits = '',
  });

  String toLabel(String label) => label + yLabelUnits;

  String valueToLabel(num value) {
    // if there are >= 3 < 6 decimal digits, replace with K (etc)
    // todo 1 add an option for how to format; a method or a formatter.
    String val = value.toString();
    if (val.endsWith('000000000')) val = '{$val.substring(0, val.length - 9)} B';
    if (val.endsWith('000000')) val = '{$val.substring(0, val.length - 6)} M';
    if (val.endsWith('000')) val = '{$val.substring(0, val.length - 3)} K';

    return val + yLabelUnits;
  }
}

/// Identity transform.
///
/// Causes no changes to data.
T identity<T>(T y) => y;

/// 10-based logarithm.
num log10(num y) => math.log(y) / math.ln10;

/// Reverse of  10-based logarithm.
num inverseLog10(num y) => math.pow(10, y); // 10^y;

@immutable
class DataContainerOptions {
  final ui.Color gridLinesColor;

  /// Portion of horizontal (X) grid width, used to display [PointPresenter] leafs.
  ///
  /// For example, for the bar chart, this represents the portion of one
  /// label width along X axis, which displays the bars (grouped or stacked).
  final double gridStepWidthPortionUsedByAtomicPointPresenter;

  /// Controls the order in which the painter paints the [DeprecatedChartData.valuesRows].
  ///
  /// Motivation: On the line chart, if two data rows have same values,
  /// the "last painted value wins". This option helps to change the data rows
  /// painting order - painting starts from the first or from the last.
  /// While so far only makes a difference on the line chart, this is defined
  /// as a common option in case there is some future overlap use on other
  /// chart types.
  final DataRowsPaintingOrder valuesRowsPaintingOrder;

  /// The transformation function which is always applied on y data before data are added to the chart internals.
  ///
  /// Defaults to identity.
  final num Function(num y) yTransform;

  /// User provided inverse to [yTransform].
  ///
  /// Defaults to identity. If the [yTransform] is set to a function different from the
  /// default [T identity<T>(T y)], user is responsible
  /// for providing the [yInverseTransform] as well. Some common inverse functions are exported by
  /// [flutter_charts]; See [log10] and [inverseLog10].
  final num Function(num y) yInverseTransform;

  // Added for symmetry with Y axis. Unused YET.
  final num Function(num y) xTransform;
  final num Function(num y) xInverseTransform;

  /// The request to start Y axis and it's labels at data minimum.
  ///
  /// When [extendAxisToOriginRequested] is set to [true], the Y axis and it's labels tries to start at the minimum
  /// Y data value (after transforming it with the [yTransform] method).
  ///
  /// The default value [false] starts the Y axis and it's labels at 0. Starting at 0 is NOT allowed ('banned')
  /// in several conditions:
  /// - On the [VerticalBarChart]
  /// - For some [yTransform]s for example logarithm transform,
  ///   where both data and logarithm must start above y value of 0.
  /// The implementation of this 'ban' is governed by [ChartBehavior.extendAxisToOrigin];
  /// If not allowed, the request is rejected, and data start at 0.
  final bool extendAxisToOriginRequested;

  /// Length of the ticks around the grid rectangle.
  ///
  /// Each tick indicates a center of a label (X on the top and bottom,
  /// Y on the left and right)
  /// Auto layout can increase these lengths, to fit labels below them.
  final double dataBottomTickHeight;

  /// Length of the ticks around the grid rectangle.
  ///
  /// Each tick indicates a center of a label (X on the top and bottom,
  /// Y on the left and right)
  /// Auto layout can increase these lengths, to fit labels below them.
  final double dataLeftTickWidth;

  /// Length of the ticks around the grid rectangle.
  ///
  /// Each tick indicates a center of a label (X on the top and bottom,
  /// Y on the left and right)
  /// Auto layout can increase these lengths, to fit labels below them.
  final double dataRightTickWidth;

  // todo-00-last-done : moved here from presenter.dart
  ui.Paint gridLinesPaint() {
    ui.Paint paint = ui.Paint();
    paint.color = gridLinesColor;
    paint.style = ui.PaintingStyle.stroke;
    paint.strokeWidth = 1.0;

    return paint;
  }

  const DataContainerOptions({
    this.gridLinesColor = material.Colors.grey, // const ui.Color(0xFF9E9E9E),
    this.dataBottomTickHeight = 6.0,
    this.dataLeftTickWidth = 6.0,
    this.dataRightTickWidth = 6.0,
    this.gridStepWidthPortionUsedByAtomicPointPresenter = 0.75,
    this.valuesRowsPaintingOrder = DataRowsPaintingOrder.firstToLast,
    this.extendAxisToOriginRequested = true,
    this.yTransform = identity<num>,
    this.yInverseTransform = identity<num>,
    this.xTransform = identity<num>,
    this.xInverseTransform = identity<num>,
  });
}

@immutable
class LabelCommonOptions {
  // Options which are included in TextStyle (labelFontSize and labelTextColor) 
  //   now set in LabelCommonOptions.get labelTextStyle
  //   final ui.Color labelFontSize;
  //   final ui.Color labelTextColor;
  final ui.TextDirection labelTextDirection;
  final ui.TextAlign labelTextAlign;
  final double labelTextScaleFactor;
  /// Estimated width of a horizontally oriented label.
  final double estimatedHorizontalLabelWidth;

  /// Estimated height of a horizontally oriented label.
  final double estimatedHorizontalLabelHeight;

  const LabelCommonOptions({
    // this.labelFontSize = 14.0,
    // this.labelTextColor = const ui.Color(0xFF757575),
    this.labelTextDirection = ui.TextDirection.ltr,
    this.labelTextAlign = ui.TextAlign.center,
    this.labelTextScaleFactor = 1.0,
    this.estimatedHorizontalLabelWidth = 40.0,
    this.estimatedHorizontalLabelHeight = 12.0,
  });

  /// Text style for all labels (X labels, Y labels, legend labels).
  ///
  /// To set any properties that can be set in Flutter [TextStyle]
  ///   (for example label text color, label font size, label font family),
  ///   the client has to create their own extension of `LabelCommonOptions`, overriding the getter `labelTextStyle`,
  ///   and setting such properties.
  /// See example `ex34OptionsDefiningUserTextStyleOnLabels`.
  /// 
  /// Also, the iterative container can change label font size for labels to fit.
  /// See [DefaultIterativeLabelLayoutStrategy] regarding label font size changes.
  /// 
  widgets.TextStyle get labelTextStyle => const widgets.TextStyle(
    color: ui.Color(0xFF757575), // was causing compile err: material.Colors.grey[600],
    fontSize: 14.0,
  );

/*
  widgets.TextStyle get labelTextStyle => GoogleFonts.getFont(
        'Comforter',
        fontSize: 14.0,
        color: const ui.Color(0xFF757575),
      );
*/
}

/// Groups methods that define padding common across containers.
///
/// Motivation and reason for existence:
///   Some areas of any chart need to have the same width or height in pixels when shown.
///   For example, the [YContainer] and [DataContainer] should have the same height into which
///   y labels, and data y values are lextr-ed (linearly extrapolated).
///   Such areas, if padded from top or bottom, or from left or right (in this example, top and bottom)
///   should be padded with the same padding height, otherwise the size in pixels, left out
///   for [YContainer] and [DataContainer] would not have the same height.
///   This is where instances of this class, the [ChartPaddingGroup] come in: They define
///   functions that yield common padding. The names of the functions suggest where such common padding should
///   be applied:
///     - [heightPadBottomOfYAndData]
///     - [heightPadTopOfYAndData]
///     - [widthPadLeftOfXAndData]
///     - [widthPadRightOfXAndData]
///
/// By 'across containers' we mean that multiple [ChartAreaContainer]s require the same padding
/// to correctly lineup.
///
/// For example, a padding on the bottom of a [YContainer] which provides space
/// to the bottom half of the label, must be duplicated on the bottom of the [DataContainer]
/// for the container contents to lineup in the vertical direction.
///
/// Note: Perhaps a better alternative would be to replace the padding with a table row
///       with two cells below the  [YContainer] and the [DataContainer]. Worth investigating?
@immutable
class ChartPaddingGroup {

  const ChartPaddingGroup({required this.fromChartOptions});

  final ChartOptions fromChartOptions;

  double heightPadBottomOfYAndData() {
    return math.max(
        fromChartOptions.labelCommonOptions.estimatedHorizontalLabelHeight,
        fromChartOptions.dataContainerOptions.dataBottomTickHeight,
    );
  }

  double heightPadTopOfYAndData() {
    return math.max(
      fromChartOptions.labelCommonOptions.estimatedHorizontalLabelHeight,
      0.0, // No ticks on top of DataContainer - in the future there could be, if there is another X axis on top
    );
  }

  double widthPadLeftOfXAndData() {
    return math.max(
      0.0, // No label protrusion assumed : fromChartOptions.labelCommonOptions.estimatedHorizontalLabelWidth,
      fromChartOptions.dataContainerOptions.dataLeftTickWidth,
    );
  }

  double widthPadRightOfXAndData() {
    return math.max(
      0.0, // No label protrusion assumed : fromChartOptions.labelCommonOptions.estimatedHorizontalLabelWidth,
      fromChartOptions.dataContainerOptions.dataRightTickWidth,
    );
  }
}

enum DataRowsPaintingOrder {
  firstToLast,
  lastToFirst,
}

enum LegendAndItemLayoutEnum {
  legendIsColumnStartLooseItemIsRowStartLoose, // See comment on legendIsColumnStartTightItemIsRowStartTight
  legendIsColumnStartTightItemIsRowStartTight, // default for legend column : Item row is top, so is NOT overriden, so must be set to intended!
  legendIsRowCenterLooseItemIsRowEndLoose, // Item row is not top, forced to 'start', 'tight' , so noop
  legendIsRowStartTightItemIsRowStartTight, // default for legend row : desired and tested
  legendIsRowStartTightItemIsRowStartTightSecondGreedy, // second Item is greedy wrapped
  legendIsRowStartTightItemIsRowStartTightItemChildrenPadded,
  legendIsRowStartTightItemIsRowStartTightItemChildrenAligned,
}