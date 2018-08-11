import 'dart:ui' as ui
    show Size, Offset, Rect, Paint, Canvas;

import 'package:flutter_charts/src/util/collection.dart' as custom_collection
    show CustomList;

import 'dart:math' as math show max, min;

import 'package:vector_math/vector_math.dart' as vector_math
    show Matrix2;

import 'package:flutter/widgets.dart' as widgets
    show TextStyle;

import 'package:flutter_charts/src/chart/label_container.dart';

import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/chart/data.dart';

import 'presenter.dart'; // V

import '../util/range.dart';
import '../util/util.dart' as util;
import '../util/geometry.dart' as geometry;
import 'package:flutter_charts/src/chart/line_container.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart'
    as strategy;

/// Containers calculate coordinates of chart points
/// used for painting grid, labels, chart points etc.
///
/// Creates a simple chart container and call all needed [layout] methods.
///
/// Terms used:
///   - `absolute positions` refer to positions
///      "in the coordinates of the chart area" - the full size given to the
///      ChartPainter by the application.
abstract class ChartContainer {
  /// ##### Abstract methods or subclasses-implemented getters

  /// Makes presenters, the visuals painted on each chart column that
  /// represent data, (points and lines for the line chart,
  /// rectangles for the bar chart, and so on).
  ///
  /// See [PresenterCreator] and [Presenter] for more details.
  /// todo 1 : There may be a question "why does a container need to
  /// know about Presenter, even indirectly"?
  PresenterCreator presenterCreator;

  /// ##### Subclasses - aware members.

  /// Keeps data values grouped in columns.
  ///
  /// This column grouped data instance is managed here in the [ChartContainer],
  /// (immediate owner of [YContainer] and [DataContainer])
  /// as their data points are needed both during [YContainer.layout]
  /// to calculate scaling, and also in [DataContainer.layout] to create
  /// [PresentersColumns] instance.
  PointsColumns pointsColumns;

  bool isStacked;

  ChartOptions options;
  ChartData data;
  ui.Size chartArea;

  /// Base Areas of chart.
  LegendContainer legendContainer;
  YContainer yContainer;
  XContainer xContainer;
  DataContainer dataContainer;

  // Layout strategy for XContainer labels
  strategy.LabelLayoutStrategy xContainerLabelLayoutStrategy;

  /// Scaler of data values to values on the Y axis.
  YScalerAndLabelFormatter yScaler;

  /// Simple Legend+X+Y+Data Container for a flutter chart.
  ///
  /// The simple flutter chart layout consists of only 2 major areas:
  ///   - [YContainer] area manages and lays out the Y labels area, by calculating
  ///     sizes required for Y labels (in both X and Y direction).
  ///     The [YContainer]
  ///   - [XContainer] area manages and lays out the
  ///     - X labels area, and the
  ///     - grid area.
  ///     In the X direction, takes up all space left after the
  ///     YContainer layes out the  Y labels area, that is, full width
  ///     minus [YContainer.yLabelsContainerWidth].
  ///     In the Y direction, takes
  ///     up all available chart area, except a top horizontal strip,
  ///     required to paint half of the topmost label.
  ChartContainer({
    ui.Size chartArea, // @required
    ChartData chartData, // @required
    ChartOptions chartOptions, // @required
    strategy.LabelLayoutStrategy xContainerLabelLayoutStrategy, // @optional
  }) {
    this.chartArea = chartArea;
    this.data = chartData;
    this.options = chartOptions;
    this.xContainerLabelLayoutStrategy = xContainerLabelLayoutStrategy;
  }

  layout() {
    // ### 1. Prepare early, from dataRows, the stackable points managed
    //        in [pointsColumns], as [YContainer] needs to scale y values and
    //        create labels from the stacked points (if chart is stacked).
    setupPointsColumns();

    // ### 2. Layout the legends on top
    legendContainer = new LegendContainer(
      parentContainer: this,
      layoutExpansion: new LayoutExpansion(
          width: chartArea.width,
          widthExpansionStyle: ExpansionStyle.TryFill,
          height: chartArea.height,
          heightExpansionStyle: ExpansionStyle.GrowDoNotFill),
    );

    legendContainer.layout();
    ui.Size legendContainerSize = legendContainer.layoutSize;
    ui.Offset legendContainerOffset = ui.Offset.zero;
    legendContainer.applyParentOffset(legendContainerOffset);

    // ### 3. Ask [YContainer] to provide Y label container width.
    //        This provides the remaining width left for the [XContainer]
    //        (grid and X axis) to use. The yLabelsMaxHeightFromFirstLayout
    //        is not relevant in this first call.
    double yContainerHeight = chartArea.height - legendContainerSize.height;

    var yContainerFirst = new YContainer(
      parentContainer: this,
      layoutExpansion: new LayoutExpansion(
          width: chartArea.width,
          widthExpansionStyle: ExpansionStyle.GrowDoNotFill,
          height: yContainerHeight,
          heightExpansionStyle: ExpansionStyle.TryFill),
      yLabelsMaxHeightFromFirstLayout: 0.0,
    );

    yContainerFirst.layout();
    double yLabelsMaxHeightFromFirstLayout = yContainerFirst.yLabelsMaxHeight;
    this.yContainer = yContainerFirst;
    ui.Size yContainerSize = yContainer.layoutSize;

    // ### 4. Knowing the width required by Y axis, layout X
    //        (from first [YContainer.layout] call).

    xContainer = new XContainer(
      parentContainer: this,
      layoutExpansion: new LayoutExpansion(
          width: chartArea.width - yContainerSize.width,
          widthExpansionStyle: ExpansionStyle.TryFill,
          height: chartArea.height - legendContainerSize.height,
          heightExpansionStyle: ExpansionStyle.GrowDoNotFill),
      xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy != null
          ? xContainerLabelLayoutStrategy
          : new strategy.DefaultIterativeLabelLayoutStrategy(
              options: this.options,
            ),
    );

    xContainer.layout();

    ui.Size xContainerSize = xContainer.layoutSize;
    ui.Offset xContainerOffset = new ui.Offset(
        yContainerSize.width, chartArea.height - xContainerSize.height);
    xContainer.applyParentOffset(xContainerOffset);

    // ### 5. Second call to YContainer is needed, as available height for Y
    //        is only known after XContainer provided required height of xLabels
    //        on the bottom .
    //        The [yLabelsMaxHeightFromFirstLayout] are used to scale
    //        data values to the y axis, and put labels on ticks.

    // On the second layout, make sure YContainer expand down only to
    //   the top of the XContainer area.
    yContainer = new YContainer(
      parentContainer: this,
      layoutExpansion: new LayoutExpansion(
          width: chartArea.width,
          widthExpansionStyle: ExpansionStyle.GrowDoNotFill,
          height: yContainerHeight - xContainerSize.height,
          heightExpansionStyle: ExpansionStyle.TryFill),
      yLabelsMaxHeightFromFirstLayout: yLabelsMaxHeightFromFirstLayout,
    );

    yContainer.layout();
    yContainerSize = yContainer.layoutSize;
    ui.Offset yContainerOffset = new ui.Offset(0.0, legendContainerSize.height);
    yContainer.applyParentOffset(yContainerOffset);

    ui.Offset dataContainerOffset =
        new ui.Offset(yContainerSize.width, legendContainerSize.height);

    // ### 6. Layout the data area, which included the grid
    // by calculating the X and Y positions of grid.
    // This must be done after X and Y are layed out - see xTickXs, yTickYs.

    this.dataContainer = new DataContainer(
      parentContainer: this,
      layoutExpansion: new LayoutExpansion(
          width: chartArea.width - yContainerSize.width,
          widthExpansionStyle: ExpansionStyle.TryFill,
          height: chartArea.height -
              (legendContainerSize.height + xContainerSize.height),
          heightExpansionStyle: ExpansionStyle.TryFill),
    );

    dataContainer.layout();
    dataContainer.applyParentOffset(dataContainerOffset);
  }

  /// Create member [pointsColumns] from [data.dataRows].
  void setupPointsColumns() {
    this.pointsColumns = new PointsColumns(
      container: this,
      presenterCreator: this.presenterCreator,
      isStacked: this.isStacked,
    );
  }

  /// X coordinates of x ticks (x tick - middle of column, also middle of label).
  /// Once [XContainer.layout] and [YContainer.layout] are complete,
  /// this list drives the layout of [DataContainer].
  ///
  /// See [AxisLabelContainer.parentOffsetTick] for details.
  List<double> get xTickXs => xContainer._xLabelContainers
      .map((var xLabelContainer) => xLabelContainer.parentOffsetTick)
      .toList();

  /// Y coordinates of y ticks (y tick - scaled value of data, also middle of label).
  /// Once [XContainer.layout] and [YContainer.layout] are complete,
  /// this list drives the layout of [DataContainer].
  ///
  /// See [AxisLabelContainer.parentOffsetTick] for details.
  List<double> get yTickYs {
    return yContainer._yLabelContainers
        .map((var yLabelContainer) => yLabelContainer.parentOffsetTick)
        .toList();
  }

  double get gridStepWidth => xContainer._gridStepWidth;
}

/// Container of the Y axis labels.
///
/// This [ChartAreaContainer] operates as follows:
/// - Vertically available space is all used (filled).
/// - Horizontally available space is used only as much as needed.
/// The used amount is given by maximum Y label width, plus extra spacing.
/// - See [layout] and [layoutSize] for resulting size calculations.
/// - See the [XContainer] constructor for the assumption on [LayoutExpansion].

class YContainer extends ChartAreaContainer {
  /// Containers of Y labels.
  ///
  /// The actual Y labels values are always generated
  /// todo 0-future-minor : above is not true now for user defined labels
  List<AxisLabelContainer> _yLabelContainers;

  /// private [_layoutSize] is calculated in layout and stored
  ui.Size _layoutSize;

  LayoutExpansion _layoutExpansion;

  double _yLabelsMaxHeightFromFirstLayout;

  /// Constructs the container that holds Y labels.
  ///
  /// The passed [LayoutExpansion] is (assumed) to direct the expansion to fill
  /// all available vertical space, and only use necessary horizontal space.
  YContainer({
    ChartContainer parentContainer,
    LayoutExpansion layoutExpansion,
    double yLabelsMaxHeightFromFirstLayout,
  }) : super(
          parentContainer: parentContainer,
          layoutExpansion: layoutExpansion,
        ) {
    _yLabelsMaxHeightFromFirstLayout = yLabelsMaxHeightFromFirstLayout;
  }

  /// Lays out the area containing the Y axis labels.
  ///
  /// Out of calls to all container's [layout] by the parent
  /// [ChartContainer.layout], the call to this object's [layout] is second,
  /// after [LegendContainer.layout].
  /// This [YContainer.layout] calculates [YContainer]'s labels width,
  /// the width taken by this container for the Y axis labels.
  ///
  /// The remaining horizontal width of [ChartContainer.chartArea] minus
  /// [YContainer]'s labels width provides remaining available
  /// horizontal space for the [GridContainer] and [XContainer].
  void layout() {
    // yAxisMin and yAxisMax define end points of the Y axis, in the YContainer
    //   coordinates.
    // todo 0-layout: layoutExpansion - max of yLabel height, and the 2 paddings

    // todo 0-layout flip Min and Max and find a place which reverses
    double yAxisMin = _layoutExpansion._height -
        (_parentContainer.options.xBottomMinTicksHeight);

    // todo 0-layout: max of this and some padding
    double yAxisMax = _yLabelsMaxHeightFromFirstLayout / 2;

    if (_parentContainer.options.useUserProvidedYLabels) {
      layoutManually(yAxisMin, yAxisMax);
    } else {
      layoutAutomatically(yAxisMin, yAxisMax);
    }

    double yLabelsContainerWidth = _yLabelContainers
            .map((yLabelContainer) => yLabelContainer.layoutSize.width)
            .reduce(math.max) +
        2 * _parentContainer.options.yLabelsPadLR;

    _layoutSize = new ui.Size(yLabelsContainerWidth, _layoutExpansion._height);
  }

  /// Manually layout Y axis by evenly dividing available height to all Y labels.
  void layoutManually(double yAxisMin, double yAxisMax) {
    List<double> flatData = _parentContainer.pointsColumns
        .flattenPointsValues(); // todo-2 move to common layout, same for manual and auto

    List<String> yLabels = _parentContainer.data.yLabels;

    var yDataRange =
        new Interval(flatData.reduce(math.min), flatData.reduce(math.max));
    double dataStepHeight =
        (yDataRange.max - yDataRange.min) / (yLabels.length - 1);

    Interval yAxisRange = new Interval(yAxisMin, yAxisMax);

    double yGridStepHeight =
        (yAxisRange.max - yAxisRange.min) / (yLabels.length - 1);

    List<num> yLabelsDividedInYAxisRange = new List();
    //var seq = new Iterable.generate(yLabels.length, (i) => i); // 0 .. length-1
    //for (var yIndex in seq) {
    for (var yIndex = 0; yIndex < yLabels.length; yIndex++) {
      yLabelsDividedInYAxisRange.add(yAxisRange.min + yGridStepHeight * yIndex);
    }

    List<num> yLabelsDividedInYDataRange = new List();
    for (var yIndex = 0; yIndex < yLabels.length; yIndex++) {
      yLabelsDividedInYDataRange.add(yDataRange.min + dataStepHeight * yIndex);
    }

    var yScaler = new YScalerAndLabelFormatter(
        dataRange: yDataRange,
        valueOnLabels: yLabelsDividedInYAxisRange,
        toScaleMin: yAxisMin,
        toScaleMax: yAxisMax,
        chartOptions: _parentContainer.options);

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
    // todo-2 move to common layout, same for manual and auto
    List<double> flatData = geometry.iterableNumToDouble(
        _parentContainer.pointsColumns.flattenPointsValues());

    Range range = new Range(
        values: flatData,
        chartOptions: _parentContainer.options,);

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
    _parentContainer.yScaler = yScaler;
    ChartOptions options = _parentContainer.options;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = new LabelStyle(
      textStyle: options.labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.labelTextAlign, // center text
      textScaleFactor: options.labelTextScaleFactor,
    );
    // Create one Y Label (yLabelContainer) for each labelInfo,
    // and add to yLabelContainers list.
    _yLabelContainers = new List();

    for (LabelInfo labelInfo in yScaler.labelInfos) {
      // yTickY is both scaled data value and vertical (Y) center of the label.
      // It is kept alway relative to the immediate container - YContainer
      double yTickY = labelInfo.scaledLabelValue;
      var yLabelContainer = new AxisLabelContainer(
        label: labelInfo.formattedYLabel,
        labelMaxWidth: double.infinity,
        labelTiltMatrix: new vector_math.Matrix2.identity(),
        canvasTiltMatrix: new vector_math.Matrix2.identity(),
        labelStyle: labelStyle,
      );
      yLabelContainer.layout();
      double labelTopY = yTickY - yLabelContainer.layoutSize.height / 2;

      yLabelContainer.parentOffsetTick = yTickY;

      // Move the contained LabelContainer to correct position
      yLabelContainer.applyParentOffset(
        new ui.Offset(_parentContainer.options.yLabelsPadLR, labelTopY),
      );

      _yLabelContainers.add(yLabelContainer);
    }
  }

  void applyParentOffset(ui.Offset offset) {
    // super not really needed - only child containers are offset.
    super.applyParentOffset(offset);

    _yLabelContainers.forEach((AxisLabelContainer yLabelContainer) {
      yLabelContainer.applyParentOffset(offset);
    });
  }

  ui.Size get layoutSize {
    return _layoutSize;
  }

  void paint(ui.Canvas canvas) {
    for (var yLabelContainer in _yLabelContainers) {
      yLabelContainer.paint(canvas);
    }
  }

  double get yLabelsMaxHeight => _yLabelContainers
      .map((yLabelContainer) => yLabelContainer.layoutSize.height)
      .reduce(math.max);
}

/// Container of the X axis labels.
///
/// This [ChartAreaContainer] operates as follows:
/// - Horizontally available space is all used (filled).
/// - Vertically available space is used only as much as needed.
/// The used amount is given by maximum X label height, plus extra spacing.
/// - See [layout] and [layoutSize] for resulting size calculations.
/// - See the [XContainer] constructor for the assumption on [LayoutExpansion].

class XContainer extends AdjustableContentChartAreaContainer {
  /// X labels.
  List<AxisLabelContainer> _xLabelContainers;

  double _gridStepWidth;

  /// Size allocated for each shown label (>= [_gridStepWidth]
  double _shownLabelsStepWidth;
  ui.Size _layoutSize;

  /// Constructs the container that holds X labels.
  ///
  /// The passed [LayoutExpansion] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  XContainer({
    ChartContainer parentContainer,
    LayoutExpansion layoutExpansion,
    strategy.LabelLayoutStrategy xContainerLabelLayoutStrategy,
  }) : super(
          layoutExpansion: layoutExpansion,
          parentContainer: parentContainer,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    xContainerLabelLayoutStrategy.onContainer(this);
  }

  /// Lays out the chart in horizontal (x) direction.
  ///
  /// Evenly divides the available width to all labels (spacing included).
  /// First / Last vertical line is at the center of first / last label.
  ///
  /// The layout is independent of whether the labels are tilted or not,
  ///   in the sense that all tilting logic is hidden in
  ///   [LabelContainer], and queried by [LabelContainer.layoutSize].

  layout() {
    // First clear any children that could be created on nested re-layout
    _xLabelContainers = new List();

    ChartOptions options = _parentContainer.options;

    List<String> xLabels = _parentContainer.data.xLabels;

    double yTicksWidth =
        options.yLeftMinTicksWidth + options.yRightMinTicksWidth;

    double availableWidth = _layoutExpansion._width - yTicksWidth;

    double labelMaxAllowedWidth = availableWidth / xLabels.length;

    _gridStepWidth = labelMaxAllowedWidth;

    // todo-2 move showEveryNthLabel to IterativeLaoytstrategy.
    //        Also define common interface, LabelLayoutStrategy, and NonIterative
    //        implementation, just taking user input.
    /*
    int numShownLabels =
        (xLabels.length / xContainerLabelLayoutStrategy.showEveryNthLabel)
            .toInt();
    */
    int numShownLabels =
        (xLabels.length ~/ xContainerLabelLayoutStrategy.showEveryNthLabel);
    _shownLabelsStepWidth = availableWidth / numShownLabels;

    LabelStyle labelStyle = _styleForLabels(options);

    // Core layout loop, creates a AxisLabelContainer from each xLabel,
    //   and lays out the XLabelContainers along X in _gridStepWidth increments.

    for (var xIndex = 0; xIndex < xLabels.length; xIndex++) {
      var xLabelContainer = new AxisLabelContainer(
        label: xLabels[xIndex],
        labelMaxWidth: double.infinity,
        labelTiltMatrix: xContainerLabelLayoutStrategy.labelTiltMatrix,
        canvasTiltMatrix: xContainerLabelLayoutStrategy.canvasTiltMatrix,
        labelStyle: labelStyle,
      );

      xLabelContainer.skipByParent = !_isLabelOnIndexShown(xIndex);

      // Core of X layout calcs - lay out label to find the size that is takes,
      //   then find X middle of the bounding rectangle

      ui.Rect labelBound = ui.Offset.zero & xLabelContainer.layoutSize;
      double halfStepWidth = _gridStepWidth / 2;
      double atIndexOffset = _gridStepWidth * xIndex;
      double xTickX =
          halfStepWidth + atIndexOffset + options.yLeftMinTicksWidth;
      double labelTopY = options.xLabelsPadTB; // down by XContainer padding

      xLabelContainer.parentOffsetTick = xTickX;

      // tickX and label centers are same. labelLeftTop = label paint start.
      var labelLeftTop = new ui.Offset(
        xTickX - labelBound.width / 2,
        labelTopY,
      );

      xLabelContainer.applyParentOffset(labelLeftTop);

      _xLabelContainers.add(xLabelContainer);
    }

    // xlabels area without padding
    double xLabelsMaxHeight = _xLabelContainers
        .map((xLabelContainer) => xLabelContainer.layoutSize.height)
        .reduce(math.max);

    // Set the layout size calculated by this layout
    _layoutSize = new ui.Size(
      _layoutExpansion._width,
      xLabelsMaxHeight + 2 * options.xLabelsPadTB,
    );

    // This achieves auto-layout of labels to fit along X axis.
    // Iterative call to this layout method, until fit or max depth is reached,
    //   whichever comes first.
    xContainerLabelLayoutStrategy.reLayout();
  }

  LabelStyle _styleForLabels(ChartOptions options) {
    widgets.TextStyle labelTextStyle = new widgets.TextStyle(
      color: options.labelTextStyle.color,
      fontSize: xContainerLabelLayoutStrategy.labelFontSize,
    );

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = new LabelStyle(
      textStyle: labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.labelTextAlign, // center text
      textScaleFactor: options.labelTextScaleFactor,
    );
    return labelStyle;
  }

  void applyParentOffset(ui.Offset offset) {
    // super not really needed - only child containers are offset.
    super.applyParentOffset(offset);

    _xLabelContainers.forEach((AxisLabelContainer xLabelContainer) {
      xLabelContainer.applyParentOffset(offset);
    });
  }

  ui.Size get layoutSize {
    return _layoutSize;
  }

  void paint(ui.Canvas canvas) {
    if (xContainerLabelLayoutStrategy.labelTiltRadians == 0.0) {
      // Horizontal X labels:
      _paintLabelContainers(canvas);
    } else {
      // Tilted X labels. Must use canvas and offset coordinate rotation.
      canvas.save();
      canvas.rotate(-1 * xContainerLabelLayoutStrategy.labelTiltRadians);

      _rotateLabelContainersAsCanvas();
      _paintLabelContainers(canvas);

      canvas.restore();
    }
  }

  void _rotateLabelContainersAsCanvas() {
    for (var xLabelContainer in _xLabelContainers) {
      xLabelContainer.rotateLabelWithCanvas();
    }
  }

  void _paintLabelContainers(canvas) {
    for (var xLabelContainer in _xLabelContainers) {
      if (!xLabelContainer.skipByParent) xLabelContainer.paint(canvas);
    }
  }

  bool _isLabelOnIndexShown(int xIndex) {
    if (xIndex % xContainerLabelLayoutStrategy.showEveryNthLabel == 0)
      return true;
    return false;
  }

  // Checks the contained labels, represented as [AxisLabelContainer],
  // for overlap.
  //
  /// Only should be called after [layout]
  ///
  /// Identifying overlap is crucial in labels auto-layout.
  ///
  /// Notes:
  ///   - [_gridStepWidth] is a limit for each label container width in the X direction.
  ///
  ///   - Labels are layed out evenly, so if any label container's [layoutSize]
  ///   in the X direction overflows the [_gridStepWidth],
  ///   labels containers DO overlap. In such situation, the caller should
  ///   take action to make labels smaller, tilt, or skip.
  ///
  bool labelsOverlap() {
    if (this._xLabelContainers.any((axisLabelContainer) =>
        !axisLabelContainer.skipByParent &&
        axisLabelContainer.layoutSize.width > _shownLabelsStepWidth)) {
      return true;
    }

    return false;
  }
}

/// A marker of container with adjustable contents,
/// such as labels that can be skipped.
// todo-2 LabelLayoutStrategy should be a member of AdjustableContect, not
//          in AdjustableContentChartAreaContainer
//          Also, AdjustableContent should be a mixin.
//          But Dart bug #25742 does not allow mixins with named parameters.
abstract class AdjustableContent {
  bool labelsOverlap();
}

/// Provides ability to connect [LabelLayoutStrategy] to [Container],
/// (actually currently the [ChartAreaContainer].
abstract class AdjustableContentChartAreaContainer extends ChartAreaContainer
    implements AdjustableContent {
  strategy.LabelLayoutStrategy _xContainerLabelLayoutStrategy;
  strategy.LabelLayoutStrategy get xContainerLabelLayoutStrategy =>
      _xContainerLabelLayoutStrategy;

  AdjustableContentChartAreaContainer({
    ChartContainer parentContainer,
    LayoutExpansion layoutExpansion,
    strategy.LabelLayoutStrategy xContainerLabelLayoutStrategy,
  }) : super(
          parentContainer: parentContainer,
          layoutExpansion: layoutExpansion,
        ) {
    _xContainerLabelLayoutStrategy = xContainerLabelLayoutStrategy;
  }
}

enum ExpansionStyle { TryFill, GrowDoNotFill }

/// Defines how a container [layout] should expand the container in a direction.
///
/// Direction can be "width" or "height".
///
/// Generally,
///   - If direction style is [TryFill], the container should use all
///     available length in the direction (that is, [width] or [height].
///     This is intended to fill a predefined
///     available length, such as show X axis labels
///   - If direction style is [GrowDoNotFill], container should use as much space
///     as needed in the direction, but stop well before the available length.
///     The "well before" is not really defined here.
///     This is intended to for example layout Y axis in X direction,
///     where we want to put the data container to the right of the Y labels.
///
///
class LayoutExpansion {
  double _width;
  ExpansionStyle _widthExpansionStyle;
  double _height;
  ExpansionStyle _heightExpansionStyle;

  LayoutExpansion({
    double width,
    ExpansionStyle widthExpansionStyle,
    double height,
    ExpansionStyle heightExpansionStyle,
  }) {
    _width = width;
    _widthExpansionStyle = widthExpansionStyle;
    _height = height;
    _heightExpansionStyle = heightExpansionStyle;
    if (this._width <= 0.0) {
      throw new StateError("Invalid width $_width");
    }
    if (this._height <= 0.0) {
      throw new StateError("Invalid height $_height");
    }
  }

  double get height {
    if (_heightExpansionStyle != ExpansionStyle.TryFill) {
      throw new StateError(
          "Before layout, cannot ask for height if style is not ${ExpansionStyle
              .TryFill}. " +
              "If asking after layout, call [layoutSize]");
    }

    return _height;
  }

  double get width {
    if (_widthExpansionStyle != ExpansionStyle.TryFill) {
      throw new StateError(
          "Before layout, cannot ask for width if style is not ${ExpansionStyle
              .TryFill}. " +
              "If asking after layout, call [layoutSize]");
    }

    return _width;
  }

  LayoutExpansion cloneWith({double width, double height}) {
    height ??= _height;
    width ?? _width;
    return new LayoutExpansion(
        width: width,
        widthExpansionStyle: _widthExpansionStyle,
        height: height,
        heightExpansionStyle: _heightExpansionStyle);
  }
}

/// Base class which manages, lays out, moves, and paints
/// graphical elements on the chart, for example individual
/// labels, but also a collection of labels.
///
/// This base class manages
///
/// Roles:
///   - Constructor: a paramater named [layoutExpansion] is required
///   - Container: through the [layout] method.
///   - Translator (in X and Y direction): through the [applyParentOffset]
///     method.
///   - Painter: through the [paint] method.
///
/// Note on Lifecycle of [Container] : objects should be such that
///       after construction, methods should be called in the order declared
///       here.
///
abstract class Container {
  /// External size enforced by the parent container.
  LayoutExpansion _layoutExpansion;

  /// Maintains current offset, a sum of all offsets
  /// passed in subsequent calls to [applyParentOffset] during object
  /// lifetime.
  ui.Offset offset = ui.Offset.zero;

  // todo-2 move _tiltMatrix to container base, similar to offset and comment as unused
  /// Maintains current tiltMatrix, a sum of all tiltMatrixs
  /// passed in subsequent calls to [applyParentTiltMatrix] during object
  /// lifetime.
  vector_math.Matrix2 _tiltMatrix = new vector_math.Matrix2.identity();

  /// Provides access to tiltMatrix for extension's [paint] methods.
  vector_math.Matrix2 get tiltMatrix => _tiltMatrix;

  /// [skipByParent] directs the parent container that this container should not be
  /// painted or layed out - as if it collapsed to zero size.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  bool skipByParent = false;

  /// If size constraints imposed by parent are too tight,
  /// some internal calculations of sizes may lead to negative values,
  /// making painting of this container not possible.
  ///
  /// Setting the [enableSkipOnDistressedSize] `true` helps to solve such situation.
  /// It causes the container not be painted
  /// (skipped during layout) when space is constrained too much
  /// (not enough space to reasonably paint the container contents).
  /// Note that setting this to `true` may result
  /// in surprizing behavior, instead of exceptions.
  ///
  /// Note that concrete implementations must add
  /// appropriate support for collapse to work.
  ///
  /// Unlike [skipByParent], which directs the parent to ignore this container,
  /// [enableSkipOnDistressedSize] is intended to be checked in code
  /// for some invalid conditions, and if they are reached, bypass painting
  /// the container.
  bool enableSkipOnDistressedSize = true; // todo-10 set to true for distress test

  bool _isDistressed = false;

  Container({
    LayoutExpansion layoutExpansion,
  }) {
    _layoutExpansion = layoutExpansion;
  }

  // ##### Abstract methods to implement

  void layout();

  void paint(ui.Canvas canvas);

  /// Allow a parent container to move this Container.
  ///
  /// Override if parent move needs to propagate to internals of
  /// this [Container].
  void applyParentOffset(ui.Offset offset) {
    this.offset += offset;
  }

  /// Tilt may apply to the whole container.
  /// todo-2 unused? move to base class? similar to offset?
  void applyParentTiltMatrix(vector_math.Matrix2 tiltMatrix) {
    if (tiltMatrix == new vector_math.Matrix2.identity()) return;
    this._tiltMatrix = this._tiltMatrix * tiltMatrix;
  }

  /// Size after [layout] has been called.
  ui.Size get layoutSize;

  /// Answers the requested expansion sizes.
  ///
  /// Before layout, clients may need to ask for expansion,
  /// as that gives a reliabel pre-layout size in directions
  /// where [ExpansionStyle == ExpansionStyle.TryFill]
  LayoutExpansion get layoutExpansion => _layoutExpansion;

// todo-2: Add assertion abstract method in direction where we should fill,
//          that the layout size is same as the expansion size.

}

/// Base class which manages, lays out, moves, and paints
/// each top level block on the chart. The basic top level chart blocks are:
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
///     - Data as bar chart, line chart, or other chart type.
///     - Grid (this includes the X and Y axis).
///
/// See [Container] for discussion of roles of this class.
/// This extension of  [Container] has the added ability
/// to access the container's parent, which is handled by
/// [parentContainer].
abstract class ChartAreaContainer extends Container {
  /// The chart top level.
  ///
  /// Departure from a top down approach, this allows to
  /// access the parent [ChartContainer], which has (currently)
  /// members needed by children.
  ChartContainer _parentContainer;

  ChartAreaContainer({
    ChartContainer parentContainer,
    LayoutExpansion layoutExpansion,
  }) : super(layoutExpansion: layoutExpansion) {
    _parentContainer = parentContainer;
  }

  ChartContainer get parentContainer => _parentContainer;
}

/// Manages the core chart area which displays, overlayed:
///   - Data - as columns of bar chart, line chart, or other chart type
///   - The grid (this includes the X and Y axis).
class DataContainer extends ChartAreaContainer {
  GridLinesContainer _xGridLinesContainer;
  GridLinesContainer _yGridLinesContainer;

  /// Columns of presenters.
  ///
  /// Presenters may be:
  ///   - points and lines in line chart
  ///   - bars (stacked or grouped) in bar chart
  ///
  /// todo 0 replace with getters; see if members can be made private,  manipulated via YLabelContainer.
  PresentersColumns presentersColumns;

  DataContainer({
    ChartContainer parentContainer,
    LayoutExpansion layoutExpansion,
  }) : super(
          layoutExpansion: layoutExpansion,
          parentContainer: parentContainer,
        );

  void layout() {
    _layoutGrid();

    // Scale the [pointsColumns] to the [YContainer] 's scale.
    scalePointsColumns();
  }

  void _layoutGrid() {
    // Vars that layout needs from the [_chartContainer] passed to constructor
    ChartOptions options = parentContainer.options;
    bool isStacked = parentContainer.isStacked;
    double xGridStep = parentContainer.gridStepWidth;
    ChartContainer chartContainer = parentContainer;

    // ### 1. Vertical Grid (yGrid) layout:

    // For each already layed out X labels in [xLabelContainers],
    // create one [LineContainer] and add it to [yGridLinesContainer]

    this._yGridLinesContainer = new GridLinesContainer();

    chartContainer.xTickXs.forEach((xTickX) {
      // Add vertical yGrid line in the middle or on the left
      double lineX = isStacked ? xTickX - xGridStep / 2 : xTickX;

      LineContainer yLineContainer = new LineContainer(
        lineFrom: new ui.Offset(lineX, 0.0),
        lineTo: new ui.Offset(lineX, layoutSize.height),
        linePaint: gridLinesPaint(options),
      );

      // Add a new vertical grid line - yGrid line.
      this._yGridLinesContainer.addLine(yLineContainer);
    });

    // For stacked, we need to add last right vertical yGrid line
    if (isStacked && chartContainer.xTickXs.isNotEmpty) {
      double x = chartContainer.xTickXs.last + xGridStep / 2;
      LineContainer yLineContainer = new LineContainer(
          lineFrom: new ui.Offset(x, 0.0),
          lineTo: new ui.Offset(x, layoutSize.height),
          linePaint: gridLinesPaint(options));
      this._yGridLinesContainer.addLine(yLineContainer);
    }

    // ### 2. Horizontal Grid (xGrid) layout:

    // Iterate yLabels and for each add a horizontal grid line
    // When iterating Y labels, also create the horizontal lines - xGridLines
    this._xGridLinesContainer = new GridLinesContainer();

    // Position the horizontal xGrid at mid-points of labels at yTickY.
    chartContainer.yTickYs.forEach((yTickY) {
      LineContainer xLineContainer = new LineContainer(
          lineFrom: new ui.Offset(0.0, yTickY),
          lineTo: new ui.Offset(this._layoutExpansion._width, yTickY),
          linePaint: gridLinesPaint(options));

      // Add a new horizontal grid line - xGrid line.
      this._xGridLinesContainer._lineContainers.add(xLineContainer);
    });
  }

  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);

    // Move all container atomic elements - lines, labels, circles etc
    this._xGridLinesContainer.applyParentOffset(offset);

    // draw vertical grid
    this._yGridLinesContainer.applyParentOffset(offset);

    // Apply offset to lines and bars.
    parentContainer.pointsColumns.applyParentOffset(offset);

    // Any time offset of [_chartContainer.pointsColumns] has changed,
    //   we have to recreate the absolute positions
    //   of where to draw data points, data lines and data bars.
    setupPresentersColumns();
  }

  ui.Size get layoutSize {
    return new ui.Size(_layoutExpansion._width, _layoutExpansion._height);
  }

  void paint(ui.Canvas canvas) {
    // draw horizontal grid
    this._xGridLinesContainer.paint(canvas);

    // draw vertical grid
    this._yGridLinesContainer.paint(canvas);

    // todo 0-layout move here painting of lines and bars.
    //         Look at VerticalBarChartPainter extends ChartPainter
    //         and rename drawPresentersColumns to paint
    //         But needs to take care of some things
  }

  // ##### Scaling and layout methods of [_chartContainer.pointsColumns]
  //       and [presentersColumns]

  /// Scales all data stored in leafs of columns and rows
  /// as [StackableValuePoint]. Depending on whether we are layouting
  /// a stacked or unstacked chart, scaling is done on stacked or unstacked
  /// values.
  ///
  /// Must be called before [setupPresentersColumns] as [setupPresentersColumns]
  /// uses the  absolute scaled [parentContainer.pointsColumns].
  void scalePointsColumns() {
    parentContainer.pointsColumns.scale();
  }

  /// Creates from [ChartData] (model for this container),
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
      pointsColumns: parentContainer.pointsColumns,
      container: parentContainer,
      presenterCreator: parentContainer.presenterCreator,
    );
  }
}

class GridLinesContainer extends Container {
  List<LineContainer> _lineContainers = new List();

  void addLine(LineContainer lineContainer) {
    _lineContainers.add(lineContainer);
  }

  // #####  Implementors of method in superclass [Container].

  void layout() {
    _lineContainers.forEach((lineContainer) => lineContainer.layout());
  }

  /// Overriden from super. Applies offset on all members.
  void applyParentOffset(ui.Offset offset) {
    _lineContainers
        .forEach((lineContainer) => lineContainer.applyParentOffset(offset));
  }

  void paint(ui.Canvas canvas) {
    _lineContainers.forEach((lineContainer) => lineContainer.paint(canvas));
  }

  /// Implementor of method in superclass [Container].
  ///
  /// Return the size of the outhermost rectangle which contains all lines
  ///   in the member _xLineContainers.
  // ui.Size get layoutSize => _xLineContainers.reduce((lineContainer.+));
  ui.Size get layoutSize => throw new StateError("todo-2 implement this.");
}

/// Represents one layed out item of the legend:  The rectangle for the color
/// indicator, [_indicatorRect], followed by the series label text.
class LegendItemContainer extends Container {
  /// Container of label
  LabelContainer _labelContainer;

  /// Tectangle of the legend color square series indicator
  ui.Rect _indicatorRect;

  /// Paint used to paint the indicator
  ui.Paint _indicatorPaint;

  ChartOptions _options;

  LabelStyle _labelStyle;
  String _label;
  ui.Size _layoutSize;

  LegendItemContainer({
    String label,
    LabelStyle labelStyle,
    ui.Paint indicatorPaint,
    ChartOptions options,
    LayoutExpansion layoutExpansion,
    ChartContainer parentContainer,
  }) : super(
          layoutExpansion: layoutExpansion,
        ) {
    // We want to only create as much as we can in layout for clarity,
    // as a price, need to hold on on label and style from constructor
    _label = label;
    _labelStyle = labelStyle;
    _indicatorPaint = indicatorPaint;
    _options = options;
    _layoutExpansion = layoutExpansion;

    // There is no need to create the _indicatorRect in the constructor,
    // as layout will move it, recreating it.
    // So _indicatorPaint is argument, _indicatorRect is created in layout().
  }

  void layout() {
    // Save a few repeated values, calculated the width given to LabelContainer,
    //   and create the LabelContainer.
    double indicatorSquareSide = _options.legendColorIndicatorWidth;
    double indicatorToLabelPad = _options.legendItemIndicatorToLabelPad;
    double betweenLegendItemsPadding = _options.betweenLegendItemsPadding;
    double labelMaxWidth = _layoutExpansion.width -
        (indicatorSquareSide + indicatorToLabelPad + betweenLegendItemsPadding);
    if (enableSkipOnDistressedSize && labelMaxWidth <= 0.0) {
      _isDistressed = true;
      _layoutSize = new ui.Size(0.0, 0.0);
      return;
    }
    _labelContainer = new LabelContainer(
      label: _label,
      labelMaxWidth: labelMaxWidth,
      labelTiltMatrix: new vector_math.Matrix2.identity(),
      canvasTiltMatrix: new vector_math.Matrix2.identity(),
      labelStyle: _labelStyle,
    );

    // Layout legend item elements (indicator, pad, label) flowing from left:

    // 1. layout the _labelContainer - this also provides height
    _labelContainer.layout();

    ui.Size labelContainerSize = _labelContainer.layoutSize;
    // 2. Y Center the indicator and label on same horizontal Y level
    //   ind stands for "indicator" - the series color indicator square
    double indAndLabelCenterY = math.max(
          labelContainerSize.height,
          indicatorSquareSide,
        ) /
        2.0;
    double indOffsetY = indAndLabelCenterY - indicatorSquareSide / 2.0;
    double labelOffsetY = indAndLabelCenterY - labelContainerSize.height / 2.0;

    // 3. Calc the X offset to both indicator and label, so indicator is left,
    //    then padding, then the label
    double indOffsetX = 0.0; // indicator starts on the left
    double labelOffsetX =
        indOffsetX + indicatorSquareSide + indicatorToLabelPad;

    // 4. Create the indicator square, and place it within this container
    //   (this is applyParentOffset for the indicator, if it was an object)
    _indicatorRect = new ui.Rect.fromLTWH(
      indOffsetX,
      indOffsetY,
      indicatorSquareSide,
      indicatorSquareSide,
    );

    // 5. Place the label within this container
    _labelContainer.applyParentOffset(new ui.Offset(
      labelOffsetX,
      labelOffsetY,
    ));

    // 6. And store the layout size on member
    _layoutSize = new ui.Size(
      _indicatorRect.width +
          indicatorToLabelPad +
          _labelContainer.layoutSize.width +
          betweenLegendItemsPadding,
      math.max(
        labelContainerSize.height,
        _indicatorRect.height,
      ),
    );

    // Make sure we fit all available width
    assert(_layoutExpansion.width + 1.0 >=
        _layoutSize.width); // todo-2 within epsilon
  }

  /// Overriden super's [paint] to also paint the rectangle indicator square.
  void paint(ui.Canvas canvas) {
    if (_isDistressed)
      return; // todo-10 this should not be, only if distress actually happens

    _labelContainer.paint(canvas);
    canvas.drawRect(_indicatorRect, _indicatorPaint);
  }

  void applyParentOffset(ui.Offset offset) {
    if (_isDistressed)
      return; // todo-10 this should not be, only if distress actually happens

    super.applyParentOffset(offset);
    _indicatorRect = _indicatorRect.translate(offset.dx, offset.dy);
    _labelContainer.applyParentOffset(offset);
  }

  ui.Size get layoutSize => _layoutSize;
}

/// Lays out the legend area for the chart.
///
/// The legend area contains individual legend items. Each legend item
/// has a color square and text, which describes one data row (that is,
/// one data series).
///
/// Currently, each individual legend item is given the same size, so legends
/// texts should be short.
///
/// This [ChartAreaContainer] operates as follows:
/// - Horizontally available space is all used (filled).
/// - Vertically available space is used only as much as needed.
/// The used amount is given by the maximum label or series indicator height,
/// plus extra spacing.

class LegendContainer extends ChartAreaContainer {
  // ### calculated values

  /// Results of laying out the legend labels. Each member is one series label.
  List<LegendItemContainer> _legendItemContainers;

  ui.Size _layoutSize;

  /// Constructs the container that holds the data series legends labels and
  /// color indicators.
  ///
  /// The passed [LayoutExpansion] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  LegendContainer({
    ChartContainer parentContainer,
    LayoutExpansion layoutExpansion,
    double availableWidth,
  }) : super(
          layoutExpansion: layoutExpansion,
          parentContainer: parentContainer,
        );

  /// Lays out the legend area.
  ///
  /// Evenly divides the [availableWidth] to all legend items.
  layout() {
    ChartOptions options = _parentContainer.options;
    double containerMarginTB = options.legendContainerMarginTB;
    double containerMarginLR = options.legendContainerMarginLR;

    List<String> dataRowsLegends = _parentContainer.data.dataRowsLegends;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = new LabelStyle(
      textStyle: options.labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.legendTextAlign, // keep left, close to indicator
      textScaleFactor: options.labelTextScaleFactor,
    );

    // First paint all legends, to figure out max height of legends to center all
    // legends label around common center.

    double legendItemWidth = (layoutExpansion.width - 2.0 * containerMarginLR) /
        dataRowsLegends.length;

    _legendItemContainers = new List<LegendItemContainer>();

    // Layout legend core: for each row, create and position
    //   - an indicator rectangle and it's paint
    //   - label painter
    for (var index = 0; index < dataRowsLegends.length; index++) {
      ui.Paint indicatorPaint = new ui.Paint();
      indicatorPaint.color = _parentContainer.data
          .dataRowsColors[index % _parentContainer.data.dataRowsColors.length];

      var legendItemContainer = new LegendItemContainer(
        label: dataRowsLegends[index],
        labelStyle: labelStyle,
        indicatorPaint: indicatorPaint,
        options: options,
        layoutExpansion: this.layoutExpansion.cloneWith(
              width: legendItemWidth,
            ),
      );

      legendItemContainer.layout();

      legendItemContainer.applyParentOffset(
        new ui.Offset(
          containerMarginLR + index * legendItemWidth,
          containerMarginTB,
        ),
      );

      _legendItemContainers.add(legendItemContainer);
    }

    _layoutSize = new ui.Size(
      _layoutExpansion._width,
      _legendItemContainers
              .map((legendItemContainer) =>
                  legendItemContainer.layoutSize.height)
              .reduce(math.max) +
          (2.0 * containerMarginTB),
    );
  }

  void applyParentOffset(ui.Offset offset) {
    // super not really needed - only child containers are offset.
    super.applyParentOffset(offset);

    _legendItemContainers.forEach((LegendItemContainer legendItemContainer) {
      legendItemContainer.applyParentOffset(offset);
    });
  }

  ui.Size get layoutSize {
    return _layoutSize;
  }

  void paint(ui.Canvas canvas) {
    for (var legendItemContainer in _legendItemContainers) {
      legendItemContainer.paint(canvas);
    }
  }
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

    // todo-1 validate: check if both points y is same sign or zero
    this.fromY = predecessorPoint != null ? predecessorPoint.toY : 0.0;
    this.toY = this.fromY + this.y;

    return this;
  }

  /// Stacks this point on top of the passed [predecessorPoint].
  ///
  /// Points are constructed unstacked. Depending on chart type,
  /// a later processing can stack points using this method
  /// (if chart type is [ChartContainer.isStacked].
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
/// Represents one column of data across [ChartData.dataRows],
/// scaled to Y axis, inverted, and stacked
/// (if the type of chart requires stacking).
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
    // todo-1 add validation that points are not stacked
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
  Iterable<StackableValuePoint> allPoints() {
    return []
      ..addAll(points)
      ..addAll(stackedNegativePoints)
      ..addAll(stackedPositivePoints);
  }
}

/// A list of [PointsColumn] instances.
///
/// Passed to [Presenter] instances, which use this instance's data to
/// paint the values in areas above labels,
/// in the appropriate presentation (point and line chart, column chart, etc)
///
/// Manages value point structure as column based (currently supported)
/// or row based (not supported).
///
/// A (single instance per chart) is used to create [PresentersColumns]
/// instance, managed in [DataContainer].
class PointsColumns extends custom_collection.CustomList<PointsColumn> {
  ///Data points managed row - major. Internal only, not used in chart.
  List<List<StackableValuePoint>> _valuePointArrInRows;

  /// Data points managed column - major. Internal only, not used in chart.
  List<List<StackableValuePoint>> _valuePointArrInColumns;

  /// Parent chart container.
  ChartContainer _container;

  /// True if chart type presents values stacked.
  bool _isStacked;

  /// Constructor creates a [PointsColumns] instance from values in
  /// the passed [container.data.dataRows].
  PointsColumns({
    ChartContainer container,
    PresenterCreator presenterCreator,
    bool isStacked,
  }) {
    _container = container;
    _valuePointArrInRows = new List();
    _isStacked = isStacked;

    ChartData chartData = container.data;

    /// Transposes the passed data in [container.data.dataRows]
    /// to [_valuePointArrInRows] to [_valuePointArrInColumns].
    ///
    /// Manages "predecessor in stack" points - each element is the per column point
    /// below the currently processed point. The currently processed point is
    /// (potentially) stacked on it's predecessor.
    List<StackableValuePoint> rowOfPredecessorPoints =
        new List(chartData.dataRows[0].length); // todo 0 deal with no data rows
    for (int col = 0; col < rowOfPredecessorPoints.length; col++)
      rowOfPredecessorPoints[col] = null;

    for (int row = 0; row < chartData.dataRows.length; row++) {
      List<num> dataRow = chartData.dataRows[row];
      List<StackableValuePoint> pointsRow = new List<StackableValuePoint>();
      _valuePointArrInRows.add(pointsRow);
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
    _valuePointArrInRows.toList();
    _valuePointArrInColumns = util.transpose(_valuePointArrInRows);
    // also OK: _valuePointArrInColumns = util.transpose<StackableValuePoint>(_valuePointArrInRows);

    /// convert "column oriented" _valuePointArrInColumns
    /// to a column, and add the columns to this instance
    PointsColumn leftColumn;

    _valuePointArrInColumns.forEach((columnPoints) {
      var pointsColumn = new PointsColumn(points: columnPoints);
      this.add(pointsColumn);
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
  ///   - No scaling of the internal representation stored in [_valuePointArrInRows]
  ///   or [_valuePointArrInColumns].
  void scale() {
    int col = 0;
    this.forEach((PointsColumn column) {
      column.allPoints().forEach((StackableValuePoint point) {
        double scaledX = _container.xTickXs[col];
        point.scale(scaledX: scaledX, yScaler: _container.yScaler);
      });
      col++;
    });
  }

  void applyParentOffset(ui.Offset offset) {
    this.forEach((PointsColumn column) {
      column.allPoints().forEach((StackableValuePoint point) {
        point.applyParentOffset(offset);
      });
    });
  }

  List<num> flattenPointsValues() {
    if (_isStacked) return flattenStackedPointsYValues();

    return flattenUnstackedPointsYValues();
  }

  /// Flattens values of all unstacked data points.
  ///
  /// Use in containers for unstacked charts (e.g. line chart)
  List<num> flattenUnstackedPointsYValues() {
    // todo 1 replace with expand like in: dataRows.expand((i) => i).toList()

    List<num> flat = [];
    this.forEach((PointsColumn column) {
      column.points.forEach((StackableValuePoint point) {
        flat.add(point.toY);
      });
    });
    return flat;
  }

  /// Flattens values of all stacked data points.
  ///
  /// Use in containers for stacked charts (e.g. VerticalBar chart)
  List<num> flattenStackedPointsYValues() {
    List<num> flat = [];
    this.forEach((PointsColumn column) {
      column.stackedNegativePoints.forEach((StackableValuePoint point) {
        flat.add(point.toY);
      });
      column.stackedPositivePoints.forEach((StackableValuePoint point) {
        flat.add(point.toY);
      });
    });
    return flat;
  }
}
