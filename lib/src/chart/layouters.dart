import 'dart:ui' as ui
    show Size, Offset, Rect, Paint, TextAlign, TextDirection, Canvas;

import 'dart:math' as math show max, min;

import 'package:flutter/widgets.dart' as widgets
    show TextStyle, TextSpan, TextPainter;

import 'package:flutter_charts/src/util/label_painter.dart';

import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/chart/data.dart';

import 'presenters.dart'; // V

import '../util/range.dart';
import '../util/util.dart' as util;
import '../util/line_presenter.dart' as line_presenter;

/// Layouters calculate coordinates of chart points
/// used for painting grid, labels, chart points etc.
///
/// Creates a simple chart layouter and call all needed [layout] methods.
///
/// Terms used:
///   - `absolute positions` refer to positions
///      "in the coordinates of the chart area" - the full size given to the
///      ChartPainter by the application.
abstract class ChartLayouter {
  /// ##### Abstract methods or sub-implemented getters

  /// Makes presenters, the visuals painted on each chart column that
  /// represent data, (points and lines for the line chart,
  /// rectangles for the bar chart, and so on).
  ///
  /// See [PresenterCreator] and [Presenter] for more details.
  /// todo 1 : There may be a question "why does a layouter need to
  /// know about Presenter, albeit indirectly?
  PresenterCreator presenterCreator;

  /// ##### Subclasses - aware members.

  /// Points columns are managed in ChartLayouter, because they are needed
  /// during Y layout. But their parent offset, and their use to create
  /// presentersColumns is managed in [DataContainer]
  PointsColumns pointsColumns;

  bool isStacked;

  ChartOptions options;
  ChartData data;
  ui.Size chartArea;

  LegendLayouter legendLayouter;
  YLayouter yLayouter;
  XLayouter xLayouter;
  DataContainer dataContainer;

  // todo -5 vvvvvvvvvvvvvvvvvvvvvvvv
  /// Notes:
  ///   - The *ContainerSizes members are defined external maximums.
  ///       Layouters always fill the containers external maximums,
  ///       so *ContainerSize also equals the containers' layed out size.
  ///   - The *ContainerSizes members include padding and margin
  ///   - The *ContainerOffset is where *ContainerSize (including pad and
  ///   margin) start.
  ui.Size legendContainerSize;
  ui.Offset legendContainerOffset;

  ui.Size xContainerSize;
  ui.Offset xContainerOffset;

  ui.Size yContainerSize;
  ui.Offset yContainerOffset;

  ui.Size dataContainerSize;
  ui.Offset dataContainerOffset;

  // todo -5 ^^^^^^^^^^^^^^^^^^^^^^^^

  /// This layouter stores positions in the [GuidingPoints] instance,
  /// and uses its members as "guiding points" where it's child layouts should
  /// draw themselves.
  // todo future GuidingPoints _guidingPoints;

  /// [xLayoutPainters] and [yLayoutPainters] hold on the X and Y Layouters output,
  /// maintain all points in absolute positions.
  ///
  /// Initialized in case the corresponding layouter does not run
  /// (e.g. no X, Y axis, no legend)
  List<XLayoutPainter> xLayoutPainters = new List();
  List<YLayoutPainter> yLayoutPainters = new List();
  List<LegendLayoutPainter> legendLayoutPainters = new List();

  /// Scaler of data values to values on the Y axis.
  YScalerAndLabelFormatter yScaler;

  /// Simple Layouter for a simple flutter chart.
  ///
  /// The simple flutter chart layout consists of only 2 major areas:
  ///   - [YLayouter] area manages and lays out the Y labels area, by calculating
  ///     sizes required for Y labels (in both X and Y direction).
  ///     The [YLayouter]
  ///   - [XLayouter] area manages and lays out the
  ///     - X labels area, and the
  ///     - grid area.
  ///     In the X direction, takes up all space left after the
  ///     YLayouter layes out the  Y labels area, that is, full width
  ///     minus [YLayouter.yLabelsContainerWidth].
  ///     In the Y direction, takes
  ///     up all available chart area, except a top horizontal strip,
  ///     required to paint half of the topmost label.
  ChartLayouter({
    ui.Size chartArea,
    ChartData chartData,
    ChartOptions chartOptions,
  }) {
    this.chartArea = chartArea;
    this.data = chartData;
    this.options = chartOptions;
  }

  layout() {
    // ### 1. Prepare early, from dataRows, the stackable points managed
    //        in [pointsColumns], as we need to scale y values and create labels
    //        from the stacked points (if chart shows values stacked).
    setupPointsColumns();

    // ### 2. Layout the legends on top

    LegendLayouter legendLayouter = new LegendLayouter(
      chartLayouter: this,
      availableWidth: chartArea.width,
    );

    legendLayouter.layout();

    // todo -5 vvv
    legendContainerSize = legendLayouter._size;
    legendContainerOffset = new ui.Offset(0.0, 0.0);
    // todo -5 ^^^

    // ### 3. Ask [YLayouter] to provide Y label container width.
    //        This provides the remaining width
    //        left for the [XLayouter] (grid and X axis) to use.
    //        The y axis absolute min and max is not relevant in this first call.
    double yContainerHeight = chartArea.height - legendContainerSize.height;

    var yLayouterFirst = new YLayouter(
      chartLayouter: this,
      layoutExpansion: new LayoutExpansion(
          width: chartArea.width,
          widthExpansionStyle: ExpansionStyle.GrowDoNotFill,
          height: yContainerHeight,
          heightExpansionStyle: ExpansionStyle.TryFill),
      yLabelsMaxHeightFromFirstLayout: 0.0,
      isFirst: true,
    );

    // print("   ### YLayouter #1: before layout: ${yLayouterFirst}");

    yLayouterFirst.layout();

    double yLabelsMaxHeightFromFirstLayout = yLayouterFirst.yLayoutPainters
        .map((var yLayoutPainter) => yLayoutPainter._labelPainter)
        .map(
            (LabelPainter labelPainter) => labelPainter.textPainter.size.height)
        .reduce(math.max);

    this.yLayouter = yLayouterFirst;

    // todo -5 vvvvvvvvvvvvvvvvvvvvvvvv
    yContainerSize =
        new ui.Size(yLayouterFirst._yLabelsContainerWidth, yContainerHeight);
    yContainerOffset = new ui.Offset(0.0, legendContainerSize.height);
    // todo -5 ^^^^^^^^^^^^^^^^^^^^^^^^

    // ### 4. Knowing the width required by Y axis
    //        (from first [YLayouter.layout] call), we can layout X labels
    //        and grid in X direction, by calling [XLayouter.layout].
    //        We do not give it the available height, although height may be
    //        marginally relevant (if there was not enough height for x labels).
    double xContainerWidth = chartArea.width - yContainerSize.width;
    var xLayouter = new XLayouter(
        chartLayouter: this,
        // todo 0 add padding, from options
        availableWidth: xContainerWidth);

    // print("   ### XLayouter");
    xLayouter.layout();
    this.xLayouter = xLayouter;

    xLayoutPainters = xLayouter.xLayoutPainters;

    // todo -5 vvvvvvvvvvvvvvvvvvvvvvvv
    xContainerSize = new ui.Size(xContainerWidth,
        xLayouter._xLabelsMaxHeight + 2 * options.xLabelsPadTB);
    xContainerOffset = new ui.Offset(
        yContainerSize.width, chartArea.height - xContainerSize.height);
    // todo -5 ^^^^^^^^^^^^^^^^^^^^^^^^

    // ### 5. Second call to YLayouter is needed, as available height for Y
    //        is only known after XLayouter provided height of xLabels
    //        on the bottom .
    //        The [yLabelsMaxHeightFromFirstLayout] are used to scale
    //        data values to the y axis, and put labels on ticks.

    // On the second real layout, make sure YLayouter expand down only to
    //   the top of the XLayouter area.
    var yLayouter = new YLayouter(
      chartLayouter: this,
      layoutExpansion: new LayoutExpansion(
          width: chartArea.width,
          widthExpansionStyle: ExpansionStyle.GrowDoNotFill,
          height: yContainerHeight - xContainerSize.height,
          heightExpansionStyle: ExpansionStyle.TryFill),
      yLabelsMaxHeightFromFirstLayout: yLabelsMaxHeightFromFirstLayout,
      isFirst: false,
    );

    // print("   ### YLayouter #2: before layout: ${yLayouter}");
    yLayouter.layout();

    this.yLayouter = yLayouter;

    // Note: yContainerSize and yContainerOffset did not change

    // Calculate what is left for the grid
    // todo -5 vvvvvvvvvvvvvvvvvvvvvvvv
    dataContainerSize = new ui.Size(
        chartArea.width - yContainerSize.width,
        chartArea.height -
            (legendContainerSize.height + xContainerSize.height));
    dataContainerOffset =
        new ui.Offset(yContainerSize.width, legendContainerSize.height);
    // todo -5 ^^^^^^^^^^^^^^^^^^^^^^^^

    // ### 6. Recalculate offsets for this Area layouter

    yLayoutPainters = yLayouter.yLayoutPainters;

    // ### 7. Layout the data area, which included the grid
    // by calculating the X and Y positions of grid.
    // This must be done here after X and Y are layed out.

    this.dataContainer = new DataContainer(
      chartLayouter: this,
      layoutExpansion: new LayoutExpansion(
          width: chartArea.width - yContainerSize.width,
          widthExpansionStyle: ExpansionStyle.TryFill,
          height: chartArea.height -
              (legendContainerSize.height + xContainerSize.height),
          heightExpansionStyle: ExpansionStyle.TryFill),
    );

    // dataContainer layout() must be called before applyParentOffset()
    //   to ensure the correct order of
    //   scalePointsColumns (first) and setupPresentersColumns (second)
    this.dataContainer.layout();

    // At the end, move the individual chart areas to their offsets.
    legendLayouter.legendLayoutPainters.forEach((legendLayoutPainter) {
      legendLayoutPainter.applyParentOffset(new ui.Offset(0.0, 0.0));
    });
    legendLayoutPainters = legendLayouter.legendLayoutPainters;

    xLayouter.xLayoutPainters.forEach((XLayoutPainter xLayoutPainter) {
      xLayoutPainter.applyParentOffset(
          new ui.Offset(yContainerSize.width, xContainerOffset.dy));
    });

    yLayouter.yLayoutPainters.forEach((YLayoutPainter yLayoutPainter) {
      yLayoutPainter.applyParentOffset(
          new ui.Offset(options.yLabelsPadLR, yContainerOffset.dy));
    });

    this.dataContainer.applyParentOffset(dataContainerOffset);
  }

  /// Create member [pointsColumns] from data rows [data.dataRows].
  void setupPointsColumns() {
    this.pointsColumns = new PointsColumns(
        layouter: this,
        presenterCreator: this.presenterCreator,
        isStacked: this.isStacked);
  }

  // todo -9  some getters from here are not needed?

  /// X coordinates of x ticks (x tick - middle of column, also middle of label)
  List<double> get xTicksXs =>
      xLayouter.xLayoutPainters
          .map((var xLayoutPainter) => xLayoutPainter.xTickX)
          .toList();

  double get gridStepWidth => xLayouter._gridStepWidth;
}

/// Auto-layouter of the area containing Y axis labels.
///
/// The primary direction of this layouter is "Y", which means
/// this layouter will use all vertical (Y) space available.
///
/// In the horizontal (X) direction, this layouter will use limited width -
/// as much width as needed to display Y labels, Y axis, and spacing.
///
/// See the constructor [YLayouter] for description of parameters that define
/// the available vertical space.
///
/// Out of calls to all layouter's [layout] by the parent
/// [ChartLayouter.layout], the call to this object's [layout] is second,
/// after [LegendLayouter.layout].
///
/// See [YLayouter.layout] for description
/// of how this [YLayouter.layout] calculates [YLayouter._yLabelsContainerWidth],
/// the width taken by this layouter for the Y axis labels, and what
/// it means for the remaining space.
///
class YLayouter {
  /// The containing layouter.
  ChartLayouter _chartLayouter;

  // ### input values

  // ### calculated values

  /// Results of laying out the Y axis labels, usable by clients.
  List<YLayoutPainter> yLayoutPainters = new List();

  double _yLabelsContainerWidth;
  LayoutExpansion _layoutExpansion;
  double _yLabelsMaxHeightFromFirstLayout;

  // first layouter ignores grid entirely
  bool _isFirst;

  /// Constructor of the layouter for the Y axis labels.
  /// The parameter [chartLayouter] provides this [YLayouter] access to it's
  /// parent layouter.
  ///
  /// Other parameters - [yAxisMin] and [yAxisMax] -
  /// define constraints it the Y direction.
  ///
  /// [yAxisMin]  and [yAxisMax] should be passed the minimum
  /// and maximum Y coordinates within (0.0, [chartLayouter.chartArea.height]).
  /// The min and max are interpreted as coordinates of the bottom and top
  /// of the area the layouter uses.
  ///
  /// This layouter uses the full height range of ([yAxisMin], [yAxisMax]),
  /// and takes as much width as needed for Y labels to be painted.
  ///
  /// "Abs" in the naming refers to coordinates within the
  /// "absolute" area [chartLayouter.chartArea]
  /// provided by Flutter for the [ChartPainter].
  ///

  ///
  YLayouter({
    ChartLayouter chartLayouter,
    LayoutExpansion layoutExpansion,
    double yLabelsMaxHeightFromFirstLayout,
    bool isFirst,
  }) {
    _chartLayouter = chartLayouter;
    _layoutExpansion = layoutExpansion;
    _yLabelsMaxHeightFromFirstLayout = yLabelsMaxHeightFromFirstLayout;
    _isFirst = isFirst;
  }

  /// Lays out the area containing the Y axis labels.
  ///
  /// Out of calls to all layouter's [layout] by the parent
  /// [ChartLayouter.layout], the call to this object's [layout] is second,
  /// after [LegendLayouter.layout].
  /// This [YLayouter.layout] calculates [YLayouter._yLabelsContainerWidth],
  /// the width taken by this layouter for the Y axis labels.
  ///
  /// The remaining horizontal width of [ChartLayouter.chartArea] minus
  /// [YLayouter._yLabelsContainerWidth] provides remaining available
  /// horizontal space for the [GridLayouter] and [XLayouter].
  void layout() {
    // todo -7: layoutExpansion - max of yLabel height, and the 2 paddings

    // todo -7 flip Min and Max and find a place which reverses
    double yAxisMin = _layoutExpansion.height -
        (_chartLayouter.options.xBottomMinTicksHeight +
            2 * _chartLayouter.options.xLabelsPadTB);

    // todo -7: max of this and some padding
    double yAxisMax = _yLabelsMaxHeightFromFirstLayout / 2;

    if (_chartLayouter.options.useUserProvidedYLabels) {
      layoutManually(yAxisMin, yAxisMax);
    } else {
      layoutAutomatically(yAxisMin, yAxisMax);
    }
    _yLabelsContainerWidth = yLayoutPainters
            .map((var yLayoutPainter) => yLayoutPainter._labelPainter)
            .map((LabelPainter labelPainter) =>
                labelPainter.textPainter.size.width)
            .reduce(math.max) +
        2 * _chartLayouter.options.yLabelsPadLR;
  }

  /// Manually layout Y axis by evenly dividing available height to all Y labels.
  void layoutManually(double yAxisMin, double yAxisMax) {
    List<double> flatData = _chartLayouter.pointsColumns
        .flattenPointsValues(); // todo -1 move to common layout, same for manual and auto

    // print("flatData=$flatData");

    List<String> yLabels = _chartLayouter.data.yLabels;

    var dataRange =
        new Interval(flatData.reduce(math.min), flatData.reduce(math.max));
    double dataStepHeight =
        (dataRange.max - dataRange.min) / (yLabels.length - 1);

    Interval yAxisRange = new Interval(yAxisMin, yAxisMax);

    double gridStepHeight =
        (yAxisRange.max - yAxisRange.min) / (yLabels.length - 1);

    List<num> yLabelsDividedInYAxisRange = new List();
    //var seq = new Iterable.generate(yLabels.length, (i) => i); // 0 .. length-1
    //for (var yIndex in seq) {
    for (var yIndex = 0; yIndex < yLabels.length; yIndex++) {
      yLabelsDividedInYAxisRange.add(yAxisRange.min + gridStepHeight * yIndex);
    }

    List<num> yLabelsDividedInYDataRange = new List();
    for (var yIndex = 0; yIndex < yLabels.length; yIndex++) {
      yLabelsDividedInYDataRange.add(dataRange.min + dataStepHeight * yIndex);
    }

    var yScaler = new YScalerAndLabelFormatter(
        dataRange: dataRange,
        valueOnLabels: yLabelsDividedInYAxisRange,
        toScaleMin: yAxisMin,
        toScaleMax: yAxisMax,
        chartOptions: _chartLayouter.options);

    yScaler.setLabelValuesForManualLayout(
        labelValues: yLabelsDividedInYDataRange,
        scaledLabelValues: yLabelsDividedInYAxisRange,
        formattedYLabels: yLabels);

    _commonLayout(yScaler);
  }

  /// Generates scaled and spaced Y labels from data, then auto layouts
  /// them on the Y axis according to data range [range] and display
  /// range [yAxisMin] to [yAxisMax].
  void layoutAutomatically(double yAxisMin, double yAxisMax) {
    List<double> flatData = _chartLayouter.pointsColumns
        .flattenPointsValues(); // todo -1 move to common layout, same for manual and auto

    // print("flatData=$flatData");

    Range range = new Range(
        values: flatData, chartOptions: _chartLayouter.options, maxLabels: 10);

    // revert toScaleMin/Max to accomodate y axis starting from top
    YScalerAndLabelFormatter yScaler = range.makeLabelsFromDataOnScale(
      toScaleMin: yAxisMin,
      toScaleMax: yAxisMax,
    );

    _commonLayout(yScaler);
  }

  void _commonLayout(YScalerAndLabelFormatter yScaler) {
    // Retain this scaler to be accessible to client code,
    // e.g. for coordinates of value points.
    _chartLayouter.yScaler = yScaler;
    ChartOptions options = _chartLayouter.options;

    // Initially all LabelPainters share same text style object from options.
    LabelStyle labelStyle = new LabelStyle(
      textStyle: options.labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.labelTextAlign, // center text
      textScaleFactor: options.labelTextScaleFactor,
    );
    // Create Y Labels (yLayoutPainters)
    // yLayoutPainters are created from  yScaler.labelInfos positions.
    for (LabelInfo labelInfo in yScaler.labelInfos) {
      // yTickY is both scaled data value and vertical (Y) center of the label.
      double yTickY = labelInfo.scaledLabelValue;
      var yLayoutPainter = new YLayoutPainter();
      yLayoutPainter._labelPainter = new LabelPainter(
        label: labelInfo.formattedYLabel,
        labelMaxWidth: double.INFINITY,
        labelStyle: labelStyle,
      );
      yLayoutPainter._labelPainter.textPainter.layout();
      double labelTopY =
          yTickY - yLayoutPainter._labelPainter.textPainter.height / 2;

      yLayoutPainter.yTickY = yTickY - labelTopY;

      // Move the contained LabelPainter to correct position
      yLayoutPainter.applyParentOffset(new ui.Offset(0.0, labelTopY));

      yLayoutPainters.add(yLayoutPainter);
    }
  }

  String toString() {
    return ", _yLabelsContainerWidth = ${_yLabelsContainerWidth}";
  }
}

/// A Wrapper of [YLayouter] members that can be used by clients
/// to layout y labels container.

/// Generally, the owner of this object decides what the offsets are:
///   - If owner is YLayouter, all positions are relative to the top of
///     the container of y labels
///   - If owner is Area [ChartLayouter], all positions are relative
///     to the top of the available [chartArea].
class YLayoutPainter {
  /// Painter configured to paint one label
  LabelPainter _labelPainter;

  ///  y offset of Y label middle point.
  ///
  ///  Also is the y offset of point that should
  /// show a "tick dash" for the label center on the y axis.
  ///
  /// First "tick dash" is on the first label, last on the last label,
  /// but y labels can be skipped.
  ///
  double yTickY;

  /// Absolute offset in chart
  ui.Offset _offset = ui.Offset.zero;

  /// Apply offset in parent. This call positions the Y Label (this instance)
  /// to the absolute position in the chart's available size
  void applyParentOffset(ui.Offset offset) {
    _offset += offset;
    yTickY += offset.dy;
  }

  void paint(ui.Canvas canvas) {
    _labelPainter.textPainter.paint(canvas, _offset);
  }
}

class YGridLinesLayoutPainter {
  List<YLinePresenter> yLinePresenters = new List();

  /// Apply offset in parent. This call positions the Y Label (this instance)
  /// to the absolute position in the chart's available size
  void applyParentOffset(ui.Offset offset) {
    yLinePresenters
        .forEach((yLinePresenter) => yLinePresenter.applyParentOffset(offset));
  }

  void paint(ui.Canvas canvas) {
    yLinePresenters.forEach((yLinePresenter) => yLinePresenter.paint(canvas));
  }
}

class XLinePresenter extends line_presenter.LinePresenter {
  /// Constructor from parent
  XLinePresenter({ui.Offset lineFrom, ui.Offset lineTo, ui.Paint linePaint}) {
    this.linePaint = linePaint;
    this.lineFrom = lineFrom;
    this.lineTo = lineTo;
  }

  /// Absolute offset in chart
  ui.Offset _offset = ui.Offset.zero;

  /// Apply offset in parent. This call positions the Y Label (this instance)
  /// to the absolute position in the chart's available size
  void applyParentOffset(ui.Offset offset) {
    this.lineFrom += offset; // translate
    this.lineTo += offset;
    _offset += offset;
  }

  void paint(ui.Canvas canvas) {
    canvas.drawLine(this.lineFrom, this.lineTo, this.linePaint);
  }
}

/// Auto-layouter of chart in the independent (X) axis direction.
///
/// Number of independent (X) values (length of each data row)
/// is assumed to be the same as number of
/// xLabels, so that value can be used interchangeably.
///
/// Note:
///   - As a byproduct this lays out the X labels in their container.
///   - Layouters may use Painters, for example for text (`TextSpan`),
///     for which we do not know any sizing needed for the Layouters,
///     until we call `TextPainter(text: textSpan).layout()`.
///     provided by LabelPainter.textPainterForLabel(String string)
///   - todo add iterations that allow layout size to be negotiated.
///     The above requires a Area layouter or similar object, that can ask
///     this object to recalculate
///     - skip labels to fit
///     - rotate labels to fit
///     - decrease font size to fit
///   - clients will typically make use of this object after [layout]
///     has been called on it
///
/// Assumes:
///   - Number of labels is the same as number of independent (X) axis points
///     for all values

class XLayouter {
  /// The containing layouter.
  ChartLayouter _chartLayouter;

  // ### input values

  List<String> _xLabels; // todo -6 remove. Replace by painters.labelPainter
  double _availableWidth;

  // ### calculated values

  /// Results of laying out the x axis labels, usabel by clients.
  List<XLayoutPainter> xLayoutPainters = new List();

  double _xLabelsMaxHeight;
  double _gridStepWidth;

  /// Constructor gives this layouter access to it's
  /// layouting Area [chartLayouter], giving it [availableWidth],
  /// which is currently the full [chartLayouter.chartArea] width.
  ///
  /// This layouter uses the full [availableWidth], and takes as
  /// much height as needed for X labels to be painted.
  ///
  XLayouter({
    ChartLayouter chartLayouter,
    double availableWidth,
  }) {
    _chartLayouter = chartLayouter;
    _xLabels = _chartLayouter.data.xLabels;
    _availableWidth = availableWidth;
  }

  /// Lays out the chart in horizontal (x) direction.

  /// Evenly divides the available width to all labels.
  /// First / Last vertical line is at the center of first / last label,
  ///
  /// Label width includes spacing on each side.
  ///
  /// In X direction, the X labels parent offset is 0.0  starts on the very
  /// left of the rectangle available for the chart.
  layout() {
    double yTicksWidth = _chartLayouter.options.yLeftMinTicksWidth +
        _chartLayouter.options.yRightMinTicksWidth;

    double labelMaxAllowedWidth =
        (_availableWidth - yTicksWidth) / _xLabels.length;

    _gridStepWidth = labelMaxAllowedWidth;

    ChartOptions options = _chartLayouter.options;

    // Initially all LabelPainters share same text style object from options.
    LabelStyle labelStyle = new LabelStyle(
      textStyle: options.labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.labelTextAlign, // center text
      textScaleFactor: options.labelTextScaleFactor,
    );

    for (var xIndex = 0; xIndex < _xLabels.length; xIndex++) {
      // double leftX = _gridStepWidth * xIndex;
      var xLayoutPainter = new XLayoutPainter();

      xLayoutPainter._labelPainter = new LabelPainter(
        label: _xLabels[xIndex],
        labelMaxWidth: double.INFINITY,
        labelStyle: labelStyle,
      );

      // core of X layout calcs - lay out label and find middle
      var textPainter = xLayoutPainter._labelPainter.textPainter;
      textPainter.layout();

      double halfLabelWidth = textPainter.width / 2;
      double halfStepWidth = _gridStepWidth / 2;
      double atIndexOffset = _gridStepWidth * xIndex;
      double xTickX = halfStepWidth +
          atIndexOffset +
          _chartLayouter.options
              .yLeftMinTicksWidth; // Start stepping after painting left Y tick
      double labelLeftX = xTickX - halfLabelWidth; // same center - tickX, label

      xLayoutPainter.xTickX = xTickX - labelLeftX;

      // Move xLayoutPainter down by option value inside XLayouter
      xLayoutPainter.applyParentOffset(new ui.Offset(
          labelLeftX, options.xLabelsPadTB));

      xLayoutPainters.add(xLayoutPainter);
    }

    // xlabels area without padding
    _xLabelsMaxHeight = xLayoutPainters
        .map((var xLayoutPainter) => xLayoutPainter._labelPainter.textPainter)
        .map((widgets.TextPainter painter) => painter.size.height)
        .reduce(math.max);
  }
}

/// A Wrapper of [XLayouter] members that can be used by clients
/// to layout x labels container.

/// All positions are relative to the left of the container of x labels
class XLayoutPainter {
  /// Painter configured to paint one label
  LabelPainter _labelPainter;

  /// The X position of point that should
  /// show a "tick dash" for the label center on the x axis.
  ///
  /// Notes:
  ///   - This is same as the X-scaled position of the X value
  ///   (only relevant for measured X variable,
  ///   for ordinal X variable, the X value is simply made evenly
  ///   spaced across X available space).
  ///   - Also same as the position of middle of X label wrapped
  /// in [_labelPainter].
  ///
  /// The actual value changes after applying parent offset
  /// by [applyParentOffset].
  ///
  /// Equal to the x offset of X label middle point.
  ///
  /// First "tick dash" is on the first label, last on the last label.
  double xTickX;

  /// Absolute offset in chart
  ui.Offset _offset = ui.Offset.zero;

  /// Apply offset in parent. This call positions the X Label (this instance)
  /// to the absolute position in the chart's available size
  void applyParentOffset(ui.Offset offset) {
    xTickX += offset.dx;
    _offset += offset;
  }

  void paint(ui.Canvas canvas) {
    _labelPainter.textPainter.paint(canvas, _offset);
  }
}

enum ExpansionStyle { TryFill, GrowDoNotFill }

/// Defines how a layout should expand in a direction.
///
/// Generally,
///   - If direction style is [TryFill], layouter should use all
/// available length in the direction. This is intended to fill a predefined
/// available length, such as show X axis labels
///   - If direction style is [GrowDoNotFill], layouter should use as much space
///   as needed in the direction, but stop well before the available length.
///   The "well before" is not really defined here.
///   This is intended to for example layout Y axis in X direction,
///   where we want to put the data container to the right of the Y labels.
///
class LayoutExpansion {
  double width;
  ExpansionStyle widthExpansionStyle;
  double height;
  ExpansionStyle heightExpansionStyle;

  LayoutExpansion(
      {this.width,
      this.widthExpansionStyle,
      this.height,
      this.heightExpansionStyle}) {
    if (this.width <= 0.0) {
      throw new StateError("Invalid width $width");
    }
    if (this.height <= 0.0) {
      throw new StateError("Invalid height $height");
    }
  }
}

/// Lays out, moves, and paints each base block on the chart. The basic chart block
/// are:
///   - [ChartContainer] - the whole chart
///   - [LegendContainer] - manages the legend
///   - [YContainer] - manages the Y labels layout, which defines:
///     - Y axis label sizes
///     - Y positions of Y axis labels, defined as yTickY.
///       yTicksY s are the Y points of scaled data values
///       and also Y points on which the Y labels are centered.
///   - [XContainer] - Equivalent to YContainer, but manages X direction
///     layout and labels.
///   - [DataContainer] - manages the area which displays:
///     - data as bar chart, line chart, or other chart type.
///     - grid (this includes the X and Y axis).
///
/// Roles:
///   - Constructor: a paramater named [layoutExpansion] is required
///   - Layouter: through the [layout] method.
///   - Translator (in X and Y direction): through the [applyParentOffset]
///     method.
///   - Painter: through the [paint] method.
///
/// Note on Lifecycle of [LayouterPainterContainer] : objects should be such that
///       after construction, methods should be called in the order declared
///       here.
///
abstract class LayouterPainterContainer {
  /// External size enforced by external layouter.
  ///
  ///   - If width or height is non zero, the container must not exceed it (although, generally,
  /// containers will fill the whole width or height).
  ///   - If width or height is zero, the container can
  LayoutExpansion _layoutExpansion;

  /// The containing layouter.
  ChartLayouter _chartLayouter;

  /// Maintains current offset, a sum of all offsets
  /// passed in subsequent calls to [applyParentOffset] during object
  /// lifetime.
  ui.Offset _offset = ui.Offset.zero;

  /// [layoutExpansion] defines
  LayouterPainterContainer({
    ChartLayouter chartLayouter,
    LayoutExpansion layoutExpansion,
  }) {
    _layoutExpansion = layoutExpansion;
    _chartLayouter = chartLayouter;
  }

  void layout();

  void applyParentOffset(ui.Offset offset) {
    _offset += offset;
  }

  ui.Size get layoutSize;

  /// Answers the requested expansion sizes.
  ///
  /// Before layout, clients may need to ask for expansion,
  /// as that gives a reliabel pre-layout size in directions
  /// where [ExpansionStyle == ExpansionStyle.TryFill]
  LayoutExpansion get layoutExpansion => _layoutExpansion;

  double get containerHeight {
    if (layoutExpansion.heightExpansionStyle != ExpansionStyle.TryFill) {
      throw new StateError(
          "Before layout, cannot ask for height if style is not ${ExpansionStyle.TryFill}. " +
              "If asking after layout, call [layoutSize]");
    }

    return layoutExpansion.height;
  }

  double get containerWidth {
    if (layoutExpansion.widthExpansionStyle != ExpansionStyle.TryFill) {
      throw new StateError(
          "Before layout, cannot ask for width if style is not ${ExpansionStyle.TryFill}. " +
              "If asking after layout, call [layoutSize]");
    }

    return layoutExpansion.width;
  }

  void paint(ui.Canvas canvas);
}

/// Manages the core chart area which displays:
///   - the data as bar chart, line chart, or other chart type
///   - the grid (this includes the X and Y axis).
class DataContainer extends LayouterPainterContainer {
  XGridLinesLayoutPainter xGridLinesLayoutPainter;
  YGridLinesLayoutPainter yGridLinesLayoutPainter;

  /// Columns of presenters.
  ///
  /// Presenters may be:
  ///   - points and lines in line chart
  ///   - bars (stacked or grouped) in bar chart
  ///
  /// todo 0 replace with getters; see if members can be made private,  manipulated via YLayouterOutput.
  PresentersColumns presentersColumns;

  DataContainer({
    ChartLayouter chartLayouter,
    LayoutExpansion layoutExpansion,
  })
      : super(
          layoutExpansion: layoutExpansion,
          chartLayouter: chartLayouter,
        ) {}

  void layout() {
    _layoutGrid();

    // Scale the [pointsColumns] to the [YLayouter] 's scale.
    // Must be called before
    scalePointsColumns();
  }

  void _layoutGrid() {
    // Name vars that are needed from members, passed to constructor
    ChartOptions options = _chartLayouter.options;
    List<XLayoutPainter> xLayoutPainters = _chartLayouter.xLayoutPainters;
    List<YLayoutPainter> yLayoutPainters = _chartLayouter.yLayoutPainters;
    XLayouter xLayouter = _chartLayouter.xLayouter;
    YLayouter yLayouter = _chartLayouter.yLayouter;
    bool isStacked = _chartLayouter.isStacked;
    YScalerAndLabelFormatter yScaler = _chartLayouter.yScaler;
    double xGridStep = _chartLayouter.gridStepWidth;

    // ### 1. Vertical Grid (yGrid) layout:

    // For each already layed out X labels in [xLayoutPainters],
    // create one [YLinePresenter] and add it to [yGridLinesLayoutPainter]

    this.yGridLinesLayoutPainter = new YGridLinesLayoutPainter();
    XLayoutPainter lastXLayoutPainter;

    for (var xIndex = 0; xIndex < xLayoutPainters.length; xIndex++) {
      var xLayoutPainter = xLayoutPainters.elementAt(xIndex);
      lastXLayoutPainter = xLayoutPainter;
      // Add vertical yGrid line in the middle or on the left
      double x = isStacked
          ? xLayoutPainter.xTickX - xGridStep / 2
          : xLayoutPainter.xTickX;

      YLinePresenter yLinePresenter = new YLinePresenter(
        lineFrom: new ui.Offset(x, 0.0),
        lineTo: new ui.Offset(x, containerHeight),
        linePaint: gridLinesPaint(options),
      );

      // For each xLayoutPainter, add a new vertical grid line - yGrid line.
      this.yGridLinesLayoutPainter.yLinePresenters.add(yLinePresenter);
    }

    // For stacked, we need to add last right vertical yGrid line
    if (isStacked && lastXLayoutPainter != null) {
      double x = lastXLayoutPainter.xTickX + xGridStep / 2;
      YLinePresenter yLinePresenter = new YLinePresenter(
          lineFrom: new ui.Offset(x, 0.0),
          lineTo:   new ui.Offset(x, containerHeight),
          linePaint: gridLinesPaint(options));
      this.yGridLinesLayoutPainter.yLinePresenters.add(yLinePresenter);
    }
    // ### 2. Horizontal Grid (xGrid) layout:

    // Iterate yLabels and for each add a horizontal grid line
    // When iterating Y labels, also create the horizontal lines - xGridLines
    this.xGridLinesLayoutPainter = new XGridLinesLayoutPainter();

    // Position the horizontal xGrid at mid-points of labels at yTickY.
    for (var yIndex = 0; yIndex < yLayoutPainters.length; yIndex++) {
      var yLayoutPainter = yLayoutPainters.elementAt(yIndex);
      double yTickY = yLayoutPainter.yTickY;
      XLinePresenter xLinePresenter = new XLinePresenter(
          lineFrom: new ui.Offset(0.0, yTickY),
          lineTo: new ui.Offset(this._layoutExpansion.width, yTickY),
          linePaint: gridLinesPaint(options));

      // For each new added y label (yLayoutPainter),
      //   also add a new horizontal grid line - xGrid line.
      this.xGridLinesLayoutPainter.xLinePresenters.add(xLinePresenter);
    }
  }

  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);

    // Move all container atomic elements - lines, labels, circles etc
    this.xGridLinesLayoutPainter.applyParentOffset(offset);

    // draw vertical grid
    this.yGridLinesLayoutPainter.applyParentOffset(offset);

    // Apply offset of lines and bars.
    _chartLayouter.pointsColumns.applyParentOffset(offset);

    // Any time offset of [_chartLayouter.pointsColumns] has changed,
    //   we have to recreate the absolute positions
    //   of where to draw data points, data lines and data bars.
    setupPresentersColumns();
  }

  ui.Size get layoutSize {
    // todo -7: Check that layed out size (looking into all members)
    //          is same as the pre-layout size returned here
    return new ui.Size(_layoutExpansion.width, _layoutExpansion.height);
  }

  void paint(ui.Canvas canvas) {
    // draw horizontal grid
    this.xGridLinesLayoutPainter.paint(canvas);

    // draw vertical grid
    this.yGridLinesLayoutPainter.paint(canvas);

    // todo -7 move here painting of lines and bars.
    //         Look at VerticalBarChartPainter extends ChartPainter
    //         and rename drawPresentersColumns to paint
    //         But needs to take care of some things
  }

  // ##### Scaling and layout methods of [_chartLayouter.pointsColumns]
  //       and [presentersColumns]

  /// Scales all data stored in leafs of columns and rows
  /// as [StackableValuePoint]. Depending on whether we are layouting
  /// a stacked or unstacked chart, scaling is done on stacked or unstacked
  /// values.
  ///
  /// Must be called before [setupPresentersColumns] as [setupPresentersColumns]
  /// uses the  absolute scaled [_chartLayouter.pointsColumns].
  void scalePointsColumns() {
    _chartLayouter.pointsColumns.scale();
  }

  /// Creates from [ChartData] (model for this layouter),
  /// columns of leaf values encapsulated as [StackableValuePoint]s,
  /// and from the values, the columns of leaf presenters,
  /// encapsulated as [Presenter]s.
  ///
  /// The resulting elements (points and presenters) are
  /// stored in member [presentersColumns].
  /// This is a core method that must run at the end of layout.
  /// Painters use the created leaf presenters directly to draw lines, points,
  /// and bars from the presenters' prepared ui elements:
  /// lines, points, bars, etc.

  void setupPresentersColumns() {
    this.presentersColumns = new PresentersColumns(
      pointsColumns: _chartLayouter.pointsColumns,
      layouter: _chartLayouter,
      presenterCreator: _chartLayouter.presenterCreator,
    );
  }
}

class XGridLinesLayoutPainter {
  List<XLinePresenter> xLinePresenters = new List();

  /// Apply offset in parent. This call positions the X Label (this instance)
  /// to the absolute position in the chart's available size
  void applyParentOffset(ui.Offset offset) {
    xLinePresenters
        .forEach((xLinePresenter) => xLinePresenter.applyParentOffset(offset));
  }

  void paint(ui.Canvas canvas) {
    xLinePresenters.forEach((xLinePresenter) => xLinePresenter.paint(canvas));
  }
}

class YLinePresenter extends line_presenter.LinePresenter {
  /// Constructor from parent
  YLinePresenter({ui.Offset lineFrom, ui.Offset lineTo, ui.Paint linePaint}) {
    this.linePaint = linePaint;
    this.lineFrom = lineFrom;
    this.lineTo = lineTo;
  }

  /// Absolute offset in chart
  ui.Offset _offset = ui.Offset.zero;

  /// Apply offset in parent. This call positions the X Label (this instance)
  /// to the absolute position in the chart's available size
  void applyParentOffset(ui.Offset offset) {
    this.lineFrom += offset; // translate
    this.lineTo += offset;

    _offset += offset;
  }

  void paint(ui.Canvas canvas) {
    canvas.drawLine(this.lineFrom, this.lineTo, this.linePaint);
  }
}

/// Lays out the legend area for the chart.
///
/// The legend area contains individual legend items. Each legend item
/// has a color square and text, which describes one data row (that is,
/// one data series).
///
/// Currently, each individual legend item is given the same size.
/// This is not very efficient but simple, so legend text should be short
class LegendLayouter {
  /// The containing layouter.
  ChartLayouter _chartLayouter;

  double _availableWidth;

  /// Offset-free size contains the whole layed out area of legend.
  ui.Size _size;

  // ### calculated values

  /// Results of laying out the legend labels. Each member is one series label.
  List<LegendLayoutPainter> legendLayoutPainters = new List();

  /// Constructor gives this layouter access to it's
  /// layouting Area [chartLayouter], giving it [availableWidth],
  /// which is currently the full width of the [chartArea].
  ///
  /// This layouter uses the full [availableWidth], and takes as
  /// much height as needed for legend labels to be painted.
  ///
  LegendLayouter({
    ChartLayouter chartLayouter,
    double availableWidth,
  }) {
    _chartLayouter = chartLayouter;
    _availableWidth = availableWidth;
  }

  /// Lays out the legend area.
  ///
  /// Evenly divides available width to all legend items.
  layout() {
    layoutCore();
  }

  layoutCore() {
    ChartOptions options = _chartLayouter.options;
    List<String> dataRowsLegends = _chartLayouter.data.dataRowsLegends;
    LegendItemSizing itemSizing = new LegendItemSizing(
      options: options,
      availableWidth: _availableWidth,
      numLegendItems: dataRowsLegends.length,
    );

    // todo -3 Call the layoutUntilFitsParent here
    // Initially all LabelPainters share same text style object from options.
    LabelStyle labelStyle = new LabelStyle(
      textStyle: options.labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.labelTextAlign, // center text
      textScaleFactor: options.labelTextScaleFactor,
    );

    // First paint all legends, to figure out max height of legends to center all
    // legends label around common center.
    // (todo -1 - is this ^^^ needed? can text of same font be diff. height)

    var maxItemSize = ui.Size.zero;
    for (var index = 0; index < dataRowsLegends.length; index++) {
      LabelPainter labelPainter = new LabelPainter(
        label: dataRowsLegends[index],
        labelMaxWidth: double.INFINITY,
        labelStyle: labelStyle,
      );
      labelPainter.textPainter.layout();
      widgets.TextPainter textPainter = labelPainter.textPainter;
      maxItemSize = new ui.Size(math.max(maxItemSize.width, textPainter.width),
          math.max(maxItemSize.height, textPainter.height));
    }

    // Now we know legend container size.width and height (width is unused)
    // From there, get the size of one legend item todo -3 : really??
    _size = new ui.Size(
        maxItemSize.width,
        math.max(maxItemSize.height, itemSizing.indicatorHeight) +
            2 * itemSizing.containerMarginTB);

    // Layout legend core: for each row, create and position
    //   - an indicator rectangle and it's paint
    //   - label painter
    for (var index = 0; index < dataRowsLegends.length; index++) {
      var legendOutput = new LegendLayoutPainter();

      legendOutput._labelPainter = new LabelPainter(
        label: dataRowsLegends[index],
        labelMaxWidth: double.INFINITY,
        labelStyle: labelStyle,
      );
      widgets.TextPainter textPainter = legendOutput._labelPainter.textPainter;
      textPainter.layout();

      double indicatorX =
          itemSizing.legendItemWidth * index + itemSizing.containerMarginLR;

      // height-wise center both indicatorRect and label around common
      // middle in  _size.height / 2
      double indicatorTop = (_size.height - itemSizing.indicatorHeight) / 2;
      legendOutput._indicatorRect = new ui.Offset(indicatorX, indicatorTop) &
          new ui.Size(itemSizing.indicatorWidth, itemSizing.indicatorHeight);

      double labelLeftX = indicatorX +
          itemSizing.indicatorWidth +
          itemSizing.indicatorToLegendPad;

      // todo -3 labelTopY Is all this needed?
      double labelTopY = (_size.height - textPainter.height) / 2;
      legendOutput._labelOffset = new ui.Offset(labelLeftX, labelTopY);

      legendOutput._indicatorPaint = new ui.Paint();
      legendOutput._indicatorPaint.color = _chartLayouter.data
          .dataRowsColors[index % _chartLayouter.data.dataRowsColors.length];

      legendLayoutPainters.add(legendOutput);
    }
  }

  /// todo -4 finish and document
/*
  List<LegendLayouterOutput> overflownOutputs() {
    this.outputs.where((output) {output.labelPainter.})
  }
  */
}

/// A value class, manages the maximum boundaries of one legend item :
/// one color square + legend text.
class LegendItemSizing {
  ChartOptions _options;
  double _availableWidth;
  int _numLegendItems;

  /// Maximum boundaries of one legend item : one color square + legend text
  LegendItemSizing({
    ChartOptions options,
    double availableWidth,
    int numLegendItems,
  }) {
    _options = options;
    _availableWidth = availableWidth;
    _numLegendItems = numLegendItems;
  }

  double get indicatorToLegendPad => _options.legendColorIndicatorPaddingLR;

  double get indicatorWidth => _options.legendColorIndicatorWidth;

  double get indicatorHeight => indicatorWidth;

  double get containerMarginTB => _options.legendContainerMarginTB;

  double get containerMarginLR => _options.legendContainerMarginLR;

  // Allocated width of one color square + legend text (one legend item)
  double get legendItemWidth =>
      (_availableWidth - 2 * containerMarginLR) / _numLegendItems;

  // Allocated width of one legend text
  double get legendLabelWidth =>
      legendItemWidth - (indicatorWidth + 2 * containerMarginLR);
}

/// Represents one layed out item of the legend: [_indicatorRect] is
/// the rectangle for the color indicator, the [_labelPainter] is a layed out
/// [widgets.TextPainter] for the label text.
///
/// Painters can paint this object in a loop similar to
/// ```
/// void drawLegend(ui.Canvas canvas) {
///    for (common.LegendLayouterOutput legend in layouter.legendLayoutPainters) {
///      legend.labelPainter.paint(canvas, legend.labelOffset);
///      canvas.drawRect(legend.indicatorRect, legend.indicatorPaint); }}
/// ```
///
/// All positions are relative to the left of the [LegendLayouter]'s container.
class LegendLayoutPainter {
  // todo -4

  /// Painter configured to paint each legend label
  LabelPainter _labelPainter;

  ///  rectangle of the legend color square series indicator
  ui.Rect _indicatorRect;

  /// Paint used to paint the indicator
  ui.Paint _indicatorPaint;

  ///  offset of legend label
  ui.Offset _labelOffset;

  /// Absolute offset in chart
  ui.Offset _offset;

  /// Apply offset in parent. This call positions the X Label (this instance)
  /// to the absolute position in the chart's available size
  void applyParentOffset(ui.Offset offset) {
    _labelOffset += offset;

    // Duplicated info
    _offset = new ui.Offset(_labelOffset.dx, _labelOffset.dy);
  }

  void paint(ui.Canvas canvas) {
    _labelPainter.textPainter.paint(canvas, _offset);
    canvas.drawRect(_indicatorRect, _indicatorPaint);
  }
}

/// Lays out a list of labels horizontally, evenly sized, and evenly spaced.
///
/// The motivation for this class is to layout labels when
/// the horizontal (X) space is restricted, and we want to manipulate
/// the label positions to automatically scale to fit.
///
/// Layout is forced to fit
/// by ensuring all labels fit within the X direction space
/// by decreasing the font size, tilting the labels, or skipping some labels,
/// or (last resource??) trimming the labels.
///
/// todo -2: No attempt is made to decrease Y direction size (height), but if
/// the passed [_maxHeight] is finite, a validity check is made
/// if the actual layed out height is within the passed height.
///
/// Instances are created from a label list; each label is
/// wrapped as a [LabelPainter] instance. All member [LabelPainter] instances
/// in [labelPainters] share the text properties (style, direction, align etc.)
/// of this parent instance
///
/// The initial text style of member [labelPainters] is from [ChartOptions].
/// The motivation is that a calling auto-fit program will change the text
/// style to fit a defined width.
///
/// Provides methods to
///   - Layout member labelPainters, for the purpose of
///   finding if they overflow their even size width.
///   - Change text style for all labels (by setting members and applying
///   them on the member [labelPainters].
///   - Layout the container by laying out the contained [labelPainters]
///   - Query size needed to paint each [labelPainters] and the whole container.
class HorizontalFixedWidthAutoScaledLabelsContainer {
  List<String> _labels;

  /// Wrappers for label strings
  List<LabelPainter> _labelPainters;

  /// Width of container. This is the fixed width this container
  /// must fill
  double _width;

  double _maxHeight = double.INFINITY;

  double _calculatedHeight;

  ChartOptions _options;

  /// Padding left of the leftmost label
  double _leftPad;

  /// Padding between each label
  double _betweenPad;

  /// Padding right of the rightmost label
  double _rightPad;

  bool _layoutClean = false;

  // TODO -4 STORING LABELSTYLE AS MEMBER IS TEMPORARY WHILE WE ARE PLUGGING FixedWidthHorizontalLabelsContainer TO X LABELS AND LEGEND LAYOUT, LAYOUTING ONCE
  LabelStyle _labelStyle;

  /// Calculated width allocated to each label.
  ///
  /// This width does not depend on text style - it is calculated
  /// by evenly dividing the available container width (total width, taking
  /// into account padding) by the number of labels.
  double get allocatedLabelWidth {
    double perLabelWidth =
        (_width - (_leftPad + (_labels.length - 1) * _betweenPad + _rightPad)) /
            _labels.length;
    if (perLabelWidth <= 0.0) {
      throw new StateError("Container does not leave space for labels.");
    }
    return perLabelWidth;
  }

  // todo -3
  /*
  double get layedoutHeight {

  };
  */

  /// Validate height of this container against constructor [_maxHeight].
  /// todo -3
  double get validateHeight {
    if (_maxHeight != double.INFINITY) {
      if (_maxHeight - _calculatedHeight > util.epsilon) {
        throw new StateError("Invalid size: $_maxHeight,  $_calculatedHeight");
      }
      return _calculatedHeight;
    }
    throw new StateError("Do not need to ask.");
  }

  bool isTooBig = true; // transient layout helper

  /// Constructs the container that must fit into a fixed boundary
  /// defined by the [width] parameter.
  ///
  /// Constraints
  ///   - [_width] must be set to a finite value
  ///     (not double.INFINITY). todo -2 add condition
  ///   -  [_maxHeight] is optional; it may be INFINITY (in most cases would be).
  ///      If not INFINITY, a validation is performed for height overflow todo -2 add condition
  ///
  HorizontalFixedWidthAutoScaledLabelsContainer({
    List<String> labels,
    double width,
    double maxHeight,
    ChartOptions options,
    double leftPad,
    double betweenPad,
    double rightPad,
  }) {
    _labels = labels;
    _width = width;
    _maxHeight = maxHeight; // optional
    _options = options;
    _leftPad = leftPad;
    _betweenPad = betweenPad;
    _rightPad = rightPad;

    // Instance is created from a label list; each label is
    //   wrapped as a [LabelPainter] instance.
    // The initial text style of member [labelPainters] is from [ChartOptions].
    // All member [LabelPainter] instances
    //   in [labelPainters] share the text properties (style, direction, align etc.)
    //   of this parent instance
    _options = options;

    // Initially all LabelPainters share same text style object from options.
    LabelStyle labelStyle = new LabelStyle(
      textStyle: options.labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.labelTextAlign, // center text
      textScaleFactor: options.labelTextScaleFactor,
    );
    _labelStyle = labelStyle;

    _labelPainters = labels.map((label) {
      return new LabelPainter(
        label: label,
        labelMaxWidth: allocatedLabelWidth,
        labelStyle: labelStyle,
      );
    }).toList();

    // Note: This class does not keep the LabelTextModifier,
    //       just passes it to member LabelPainters
  }

  /// Provides methods to
  ///   - Layout individual [labelPainters], for the purpose of
  ///   finding if they overflow their even size width.
  ///
  /// anyLabelOverflows() - must be called after layoutIndividualLabels()
  ///

  ///   - Change text style for all labels (by setting members and applying
  ///   them on the member [labelPainters].
  ///   - Layout the container by laying out the contained [labelPainters].
  ///   This should layout to maxWidth, and throw exception on overflow.
  ///   - Query size needed to paint each [labelPainters] and the whole container.

// todo -3 add all method signatures first, implement next
  /// - layout the container with each label at evenly spaced positions
  void layoutQuaranteeFitFirstTiltNextDecreaseFontNextSkipNextTrim() {
    // TODO -4 FOR NOW, JUST LAYOUT, ONCE, NOT CHECKING FOR OVERFLOW
    _applyStyleThenLayoutAndCheckOverflow(labelStyle: _labelStyle);

    // todo -3
    // call layoutAndCheckOverflow on all labelPainters
    // if at least one overflows, tilt all labels by -70 degrees
    // etc.
  }

  /// Layout member [_labelPainters] forcing the max width and
  /// check for overflow.
  ///
  /// Returns `true` if at least one element of [_labelPainters] overflows,
  /// `false` otherwise.
  ///
  /// As a sideeffect, if false is returned, all  [_labelPainters] were
  /// layoued out, and can be painted.
  bool _layoutAndCheckOverflow() {
    // same as label_painted, on all
    return _labelPainters.any((labelPainter) {
      labelPainter.layoutAndCheckOverflow();
    });
  }

  /// Apply new text style and layout, then check if
  /// any member of [_labelPainters] overflows.
  /// returns `true` if at least one overflows.
  bool _applyStyleThenLayoutAndCheckOverflow({
    LabelStyle labelStyle,
  }) {
    // Here need to process all painters, as we want to apply style to all.
    _labelPainters.forEach((labelPainter) {
      labelPainter.applyStyleThenLayoutAndCheckOverflow(labelStyle: labelStyle);
    });
    // todo -4: PUT THIS BACK. FOR NOW, WE JUST LAYOUT ONCE, NOT CARING ABOUT OVERFLOW: return _labelPainters.any((labelPainter) {labelPainter.isOverflowing;});
    return false;
  }
}

/// Structural "backplane" model for chart layout.
///
/// Maintains positions (offsets) of a minimum set of *significant points* in layout.
/// Significant points are those at which the main layouter will paint
/// it's layouter children, such as: top-left of the Y axis labels,
/// top-left of the X axis labels, top-left of the data grid and other points.
/// The significant points are scaled and positioned in
/// the coordinates of ChartPainter.
///
/// SimpleChartLayouter stores positions in this instance,
/// and use its members as "guiding points" where it's child layouts should
/// draw themselves.
class GuidingPoints {
  List<ui.Offset> yLabelPoints;
}

/// Manages both scaled and unscaled X and Y values created from data.
///
/// While [GuidingPoints] manages points where layouts should
/// draw themselves, this class manages data values that should be drawn.
class LayoutValues {
  /// Y values of grid (also centers of Y labels),
  /// on the data scale
  List<num> yUnscaledGridValues;

  /// Y values of grid (also centers of Y labels),
  /// scaled to the main layouter coordinates.
  List<num> yGridValues;
}

/// Represents values and coordinates of one presented atom of data (x and y).
///
/// The managed values are:
///   - [xLabel], [y], and also the stacking support values [fromY], [toY];
/// The managed coordinates are absolute coordinates painted by [ChartPainter]:
///   - [scaledX], [scaledY], [scaledFrom], [scaledTo], and also
///   the stacking support coordinates [fromScaledY], [toScaledY].
/// are General x, y coordinates are the outer bound where
/// represented values will be shown.
///
/// For a bar chart (stacked or grouped), this may be the rectangle
/// representing one data value.
///
/// Notes:
///   - [scaledFrom] and [scaledTo] are offsets for painting in absolute chart
///     coordinates. Both are set lazily after [scale] is called.
///   - This object does not manage it's stacking (setting it's [stackFromY],
///     it is left for the container that manages this object along with
///     values before (below) and after (above).
class StackableValuePoint {
  // initial values
  String
      xLabel; // todo 0 check if this is unused; and why we need label in value?
  double y;
  int dataRowIndex; // series index
  StackableValuePoint predecessorPoint;
  bool isStacked = false;

  // stacking - sets the y coordinate of range representing this point's value
  double fromY;
  double toY;

  /// Scaled values. All set lazily after [scale]
  double scaledX;
  double scaledY;
  double fromScaledY;
  double toScaledY;

  /// Scaled Offsets for painting in absolute chart coordinates.
  /// More precisely, offsets of the bottom and top of the presenter of this
  /// point - for example, for VerticalBar, bottom and top of each bar
  /// representing this value point (data point)
  ui.Offset scaledFrom;
  ui.Offset scaledTo;

  StackableValuePoint({
    String xLabel,
    double y,
    int dataRowIndex,
    StackableValuePoint predecessorPoint,
  }) {
    this.xLabel = xLabel;
    this.y = y;
    this.dataRowIndex = dataRowIndex;
    this.predecessorPoint = predecessorPoint;
    this.isStacked = false;

    this.fromY = 0.0;
    this.toY = this.y;
  }

  StackableValuePoint stack() {
    this.isStacked = true;

    // todo -1 validate: check if both points y is same sign or zero
    this.fromY = predecessorPoint != null ? predecessorPoint.toY : 0.0;
    this.toY = this.fromY + this.y;

    return this;
  }

  /// Stacks this point on top of the passed [predecessorPoint].
  ///
  /// Points are constructed unstacked. Depending on chart type,
  /// a later processing can stack points using this method
  /// (if chart type is [ChartLayouter.isStacked].
  StackableValuePoint stackOnAnother(StackableValuePoint predecessorPoint) {
    this.predecessorPoint = predecessorPoint;
    return this.stack();
  }

  /// Scales this point's data values [x] and [y], and all stacked y values
  /// and points - [scaledX], [scaledY], [fromScaledY],  [toScaledY],
  /// [scaledFrom], [scaledTo] - using the passed values scaler [yScaler].
  ///
  /// Note that the x values are not really scaled, as object doed not
  /// manage the unscaled [x] (it manages the corresponding label only).
  /// For this reason, the [scaledX] value must be provided explicitly.
  /// The provided [scaledX] value should be the
  /// "within [ChartPainter] absolute" x coordinate (generally the center
  /// of the correspoding x label).
  ///
  StackableValuePoint scale({
    YScalerAndLabelFormatter yScaler,
    double scaledX,
  }) {
    this.scaledX = scaledX;
    this.scaledY = yScaler.scaleY(value: this.y);
    this.fromScaledY = yScaler.scaleY(value: this.fromY);
    this.toScaledY = yScaler.scaleY(value: this.toY);
    this.scaledFrom = new ui.Offset(scaledX, this.fromScaledY);
    this.scaledTo = new ui.Offset(scaledX, this.toScaledY);

    return this;
  }

  void applyParentOffset(ui.Offset offset) {
    // only apply  offset on scaled values, those have chart coordinates that are painted.

    // not needed to offset : StackableValuePoint predecessorPoint;

    /// Scaled values represent screen coordinates, apply offset to all.
    scaledX += offset.dx;
    scaledY += offset.dy;
    fromScaledY += offset.dy;
    toScaledY += offset.dy;

    scaledFrom += offset;
    scaledTo += offset;
  }

  /// Copy - clone of this object unstacked. Does not allow to clone if
  /// already stacked.
  ///
  /// Returns a new [StackableValuePoint] which is a full deep copy of this
  /// object. This includes cloning of [double] type members and [ui.Offset]
  /// type members.
  StackableValuePoint unstackedClone() {
    if (isStacked) {
      throw new Exception("Cannot clone if already stacked");
    }

    StackableValuePoint clone = new StackableValuePoint(
        xLabel: this.xLabel,
        y: this.y,
        dataRowIndex: this.dataRowIndex,
        predecessorPoint: this.predecessorPoint);

    // numbers and Strings, being immutable, can be just assigned.
    // rest of objects (ui.Offset) must be created from immutable leafs.
    clone.xLabel = xLabel;
    clone.y = y;
    clone.predecessorPoint = null;
    clone.dataRowIndex = dataRowIndex;
    clone.isStacked = false;
    clone.fromY = fromY;
    clone.toY = toY;
    clone.scaledX = scaledX;
    clone.scaledY = scaledY;
    clone.fromScaledY = fromScaledY;
    clone.toScaledY = toScaledY;
    if (scaledFrom != null)
      clone.scaledFrom = new ui.Offset(scaledFrom.dx, scaledFrom.dy);
    if (scaledTo != null)
      clone.scaledTo = new ui.Offset(scaledTo.dx, scaledTo.dy);

    return clone;
  }
}

/// A column of value points, with support for stacked type charts.
///
/// Supports to convert the raw data values from the data rows,
/// into values that are either
///   - unstacked (such as in the line chart),  in which case it manages
///   [points] that have values from [ChartData.dataRows].
///   - stacked (such as in the bar chart), in which case it manages
///   [points] that have values added up from [ChartData.dataRows].
///
/// Negative and positive points must be stacked separately,
/// to support correctly displayed stacked values above and below zero.
class PointsColumn {
  /// List of charted values in this column
  List<StackableValuePoint> points;

  /// List of stacked positive or zero value points - support for stacked type charts,
  /// where negative and positive points must be stacked separately,
  /// above and below zero.
  List<StackableValuePoint> stackedPositivePoints; // non-negative actually

  /// List of stacked negative value points - support for stacked type charts,
  /// where negative and positive points must be stacked separately,
  /// above and below zero.
  List<StackableValuePoint> stackedNegativePoints;

  PointsColumn nextRightPointsColumn;

  ///  Construct column from the passed [points].
  ///
  ///  Passed points are assumed to:
  ///    - Be configured with appropriate [predecessorPoint]
  ///    - Not stacked
  ///  Creates members [stackedNegativePoints], [stackedPositivePoints]
  ///  which exist only to be stacked, so the constructor stacks them
  ///  on creation.
  PointsColumn({
    List<StackableValuePoint> points,
  }) {
    // todo -1 add validation that points are not stacked
    this.points = points;

    this.stackedPositivePoints = this.selectThenCollectStacked(
        points: this.points, selector: (point) => point.y >= 0);
    this.stackedNegativePoints = this.selectThenCollectStacked(
        points: this.points, selector: (point) => point.y < 0);
  }

  // points are ordered in series order, first to last  (bottom to top),
  // and maintain their 0 based row (series) index
  /// todo 0 document
  List<StackableValuePoint> selectThenCollectStacked({
    List<StackableValuePoint> points,
    bool selector(StackableValuePoint point),
  }) {
    StackableValuePoint predecessorPoint;
    List<StackableValuePoint> selected = this.points.where((point) {
      return selector(point);
    }) // point.y >= 0;
        .map((point) {
      var thisPoint = point.unstackedClone().stackOnAnother(predecessorPoint);
      predecessorPoint = thisPoint;
      return thisPoint;
    }).toList();
    return selected;
  }

  /// Column Utility for iterating over all points in order
  Iterable allPoints() {
    return []
      ..addAll(points)
      ..addAll(stackedNegativePoints)
      ..addAll(stackedPositivePoints);
  }
}

/// Represents coordinates of [ChartData.dataRows], scaled to Y axis, inverted,
/// and stacked (if the type of chart requires stacking).
///
/// Passed to presenters, which paint the values in areas above labels,
/// in the appropriate presentation (point and line chart, column chart, etc)
///
/// Manages value point structure as column based (currently only supported)
/// or row based.
class PointsColumns {
  List<List<StackableValuePoint>> _pointsRows;
  List<List<StackableValuePoint>> _pointsColumns;
  ChartLayouter _layouter;
  List<PointsColumn> pointsColumns;
  bool _isStacked;

  /// Creates [_pointsRows] with the same structure and values as
  /// the passed [dataRows]. Then transposes the [_pointsRows]
  /// to [_pointsColumns].
  PointsColumns({
    ChartLayouter layouter,
    PresenterCreator presenterCreator,
    bool isStacked,
  }) {
    _layouter = layouter;
    _pointsRows = new List();
    _isStacked = isStacked;

    ChartData chartData = layouter.data;

    // Manages "predecessor in stack" points - each element is the per column point
    // below the currently processed point. The currently processed point is
    // (potentially) stacked on it's predecessor.
    List<StackableValuePoint> rowOfPredecessorPoints =
        new List(chartData.dataRows[0].length); // todo 0 deal with no data rows
    for (int col = 0; col < rowOfPredecessorPoints.length; col++)
      rowOfPredecessorPoints[col] = null;

    for (int row = 0; row < chartData.dataRows.length; row++) {
      List<num> dataRow = chartData.dataRows[row];
      List<StackableValuePoint> pointsRow = new List<StackableValuePoint>();
      _pointsRows.add(pointsRow);
      // int col = 0;
      // dataRow.forEach((var colValue) {
      StackableValuePoint predecessorPoint;
      for (int col = 0; col < dataRow.length; col++) {
        num colValue = dataRow[col];

        // Create all points unstacked. A later processing can stack them,
        // depending on chart type. See [StackableValuePoint.stackOnAnother]
        var thisPoint = new StackableValuePoint(
            xLabel: null,
            y: colValue,
            dataRowIndex: row,
            predecessorPoint: rowOfPredecessorPoints[col]);

        pointsRow.add(thisPoint);
        rowOfPredecessorPoints[col] = thisPoint;
      }
    }
    _pointsRows.toList();
    _pointsColumns = util.transpose(_pointsRows);

    // convert "column oriented" List<List<StackableValuePoint>> _pointsColumns
    // to public List<ValuePointsColumn> pointsColumns
    PointsColumn leftColumn;
    pointsColumns = new List();

    _pointsColumns.forEach((List<StackableValuePoint> columnPoints) {
      var pointsColumn = new PointsColumn(points: columnPoints);
      pointsColumns.add(pointsColumn);
      leftColumn?.nextRightPointsColumn = pointsColumn;
      leftColumn = pointsColumn;
    });
  }

  /// Scales this object's column values managed in [pointsColumns].
  ///
  /// This allows separation of creating this object with
  /// the original, unscaled data points, and apply scaling later
  /// on the stackable (stacked or unstacked) values.
  ///
  /// Notes:
  ///   - Iterates this object's [pointsColumns], then the contained
  ///   [PointsColumn.points], and scales each point by
  ///   applying its [StackableValuePoint.scale] method.
  ///   - No scaling of the internal representation stored in [_pointsRows]
  ///   or [_pointsColumns].
  void scale() {
    int col = 0;
    pointsColumns.forEach((PointsColumn column) {
      column.allPoints().forEach((StackableValuePoint point) {
        double scaledX = _layouter.xTicksXs[col];
        point.scale(scaledX: scaledX, yScaler: _layouter.yScaler);
      });
      col++;
    });
  }

  void applyParentOffset(ui.Offset offset) {
    int col = 0;
    pointsColumns.forEach((PointsColumn column) {
      column.allPoints().forEach((StackableValuePoint point) {
        // todo -10: double scaledX = _layouter.xTicksXs[col];
        point.applyParentOffset(offset);
      });
      col++;
    });
  }

  List<num> flattenPointsValues() {
    if (_isStacked) return flattenStackedPointsYValues();

    return flattenUnstackedPointsYValues();
  }

  /// Flattens values of all unstacked data points.
  ///
  /// Use in layouters for unstacked charts (e.g. line chart)
  List<num> flattenUnstackedPointsYValues() {
    // todo 1 replace with expand like in: dataRows.expand((i) => i).toList()

    List<num> flat = [];
    pointsColumns.forEach((PointsColumn column) {
      column.points.forEach((StackableValuePoint point) {
        flat.add(point.toY);
      });
    });
    return flat;
  }

  /// Flattens values of all stacked data points.
  ///
  /// Use in layouters for stacked charts (e.g. VerticalBar chart)
  List<num> flattenStackedPointsYValues() {
    List<num> flat = [];
    pointsColumns.forEach((PointsColumn column) {
      column.stackedNegativePoints.forEach((StackableValuePoint point) {
        flat.add(point.toY);
      });
      column.stackedPositivePoints.forEach((StackableValuePoint point) {
        flat.add(point.toY);
      });
    });
    return flat;
  }

  PointsColumn pointsColumnAt({int columnIndex}) => pointsColumns[columnIndex];

  StackableValuePoint pointAt({int columnIndex, int rowIndex}) =>
      pointsColumns[columnIndex].points[rowIndex];
}
