import 'dart:ui' as ui show Size, Offset, Rect, Paint, Canvas;

import 'package:flutter_charts/src/chart/container_base.dart' show Container;

import 'package:flutter_charts/src/morphic/rendering/constraints.dart' show LayoutExpansion;

import 'package:flutter_charts/src/util/collection.dart' as custom_collection show CustomList;

import 'dart:math' as math show max, min;

import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;

import 'package:flutter/widgets.dart' as widgets show TextStyle;

import 'package:flutter_charts/src/chart/label_container.dart';

import 'package:flutter_charts/src/chart/options.dart';
import 'package:flutter_charts/src/chart/data.dart';

import 'presenter.dart';

import '../util/range.dart';
import '../util/util_dart.dart' as util;
import '../util/geometry.dart' as geometry;
import 'package:flutter_charts/src/chart/line_container.dart';
import 'package:flutter_charts/src/chart/iterative_layout_strategy.dart' as strategy;

import 'line/presenter.dart' as line_presenters;
import 'bar/presenter.dart' as bar_presenters;

/// Abstract class representing the [Container] of the whole chart.
///
/// Containers calculate coordinates of chart points
/// used for painting grid, labels, chart points etc.
///
/// Creates a simple chart container and call all needed [layout] methods.
///
/// Notes:
///   - [ChartContainer] and it's extensions,
///     such as [LineChartContainer] and [VerticalBarChartContainer]
///     are the only container which does not extend [Container]
///   - Related to above point, the [layout(num size)] is unrelated to
///     a same name method on [Container].
///
/// Terms used:
///   - `absolute positions` refer to positions
///      "in the coordinates of the chart area" - the full size given to the
///      ChartPainter by the application.
abstract class ChartContainer extends Container {
  /// Implements [Container.layoutSize()].
  // todo-00-last-layout-size-note-only : no change; ChartContainer is the only one overriding layoutSize setter, to express the layoutSize is fixed chartArea
  ui.Size get layoutSize => chartArea;

  // todo-11-last describe in detail how this is set in Painter and used in Paint (chart).
  /// [chartArea] is the chart area size of this container.
  /// In flutter_charts, this is guaranteed to be the same
  /// area on which the painter will paint.
  /// See the call to [layout()] of this class.
  /// [chartArea] marked late, as there is virtually no practical situation
  /// it can be known before runtime; it is required,
  /// but not set at construction time.
  ///
  late ui.Size chartArea;

  /// Base Areas of chart.
  late LegendContainer legendContainer;
  late YContainer yContainer;
  late XContainer xContainer;
  late DataContainer dataContainer;

  /// Layout strategy for XContainer labels.
  ///
  /// Cached from constructor here, until the late [xContainer] is created.
  strategy.LabelLayoutStrategy _cachedXContainerLabelLayoutStrategy;

  /// Scaler of data values to values on the Y axis.
  late YScalerAndLabelFormatter yScaler;

  /// ##### Abstract methods or subclasses-implemented getters

  /// Makes presenters, the visuals painted on each chart column that
  /// represent data, (points and lines for the line chart,
  /// rectangles for the bar chart, and so on).
  ///
  /// See [PresenterCreator] and [Presenter] for more details.
  /// todo 1 : There may be a question "why does a container need to
  /// know about Presenter, even indirectly"?
  late PresenterCreator presenterCreator;

  /// ##### Subclasses - aware members.

  /// Keeps data values grouped in columns.
  ///
  /// This column grouped data instance is managed here in the [ChartContainer],
  /// (immediate owner of [YContainer] and [DataContainer])
  /// as their data points are needed both during [YContainer.layout]
  /// to calculate scaling, and also in [DataContainer.layout] to create
  /// [PresentersColumns] instance.
  late PointsColumns pointsColumns;

  late bool isStacked;

  ChartOptions options;
  ChartData data;

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
    required ChartData chartData,
    required ChartOptions chartOptions,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  })  : this.data = chartData,
        this.options = chartOptions,
        this._cachedXContainerLabelLayoutStrategy =
            xContainerLabelLayoutStrategy ?? strategy.DefaultIterativeLabelLayoutStrategy(options: chartOptions),
        super() {
    // Must initialize in body, as access to 'this' not available in initializer.
    // todo-11-last : check if needed :  this._cachedXContainerLabelLayoutStrategy.onContainer(this);
  }

  /// Implements [Container.layout()] for the chart as a whole.
  ///
  /// Uses this container's [chartArea] as available size
  ///
  /// Note: The [chartArea] was set in the [ChartPainter.paint(Canvas, Size)]
  /// just before calling this method:
  ///
  /// ```dart
  ///   void paint(ui.Canvas canvas, ui.Size size) {
  ///     ...
  ///     container.chartArea = size;
  ///     container.layout();
  ///     ...
  /// ```
  ///
  /// Layout proceeds scaling the Y values to fit the available size,
  /// then lays out the legend, Y axis and labels, X axis and labels,
  /// and the data area, giving each the size it needs.
  ///
  /// The actual layout algorithm should be made pluggable.
  ///
  void layout(LayoutExpansion parentLayoutExpansion) {
    // ### 1. Prepare early, from dataRows, the stackable points managed
    //        in [pointsColumns], as [YContainer] needs to scale y values and
    //        create labels from the stacked points (if chart is stacked).
    setupPointsColumns();

    // ### 2. Layout the legends on top
    var legendLayoutExpansion = LayoutExpansion(
      width: chartArea.width,
      height: chartArea.height,
    );
    legendContainer = LegendContainer(
      parentContainer: this,
    );

    legendContainer.layout(legendLayoutExpansion);
    ui.Size legendContainerSize = legendContainer.layoutSize;
    ui.Offset legendContainerOffset = ui.Offset.zero;
    legendContainer.applyParentOffset(legendContainerOffset);

    // ### 3. Ask [YContainer] to provide Y label container width.
    //        This provides the remaining width left for the [XContainer]
    //        (grid and X axis) to use. The yLabelsMaxHeightFromFirstLayout
    //        is not relevant in this first call.
    double yContainerHeight = chartArea.height - legendContainerSize.height;

    var yContainerLayoutExpansion = LayoutExpansion(
      width: chartArea.width,
      height: yContainerHeight,
    );
    var yContainerFirst = YContainer(
      parentContainer: this,
      yLabelsMaxHeightFromFirstLayout: 0.0,
    );

    yContainerFirst.layout(yContainerLayoutExpansion);
    double yLabelsMaxHeightFromFirstLayout = yContainerFirst.yLabelsMaxHeight;
    this.yContainer = yContainerFirst;
    ui.Size yContainerSize = yContainer.layoutSize;

    // ### 4. Knowing the width required by Y axis, layout X
    //        (from first [YContainer.layout] call).

    var xContainerLayoutExpansion = LayoutExpansion(
      width: chartArea.width - yContainerSize.width,
      height: chartArea.height - legendContainerSize.height,
    );
    xContainer = XContainer(
      parentContainer: this,
      xContainerLabelLayoutStrategy: _cachedXContainerLabelLayoutStrategy,
    );

    xContainer.layout(xContainerLayoutExpansion);

    ui.Size xContainerSize = xContainer.layoutSize;
    ui.Offset xContainerOffset = ui.Offset(yContainerSize.width, chartArea.height - xContainerSize.height);
    xContainer.applyParentOffset(xContainerOffset);

    // ### 5. Second call to YContainer is needed, as available height for Y
    //        is only known after XContainer provided required height of xLabels
    //        on the bottom .
    //        The [yLabelsMaxHeightFromFirstLayout] are used to scale
    //        data values to the y axis, and put labels on ticks.

    // On the second layout, make sure YContainer expand down only to
    //   the top of the XContainer area.
    yContainerLayoutExpansion = LayoutExpansion(
      width: chartArea.width,
      height: yContainerHeight - xContainerSize.height,
    );
    yContainer = YContainer(
      parentContainer: this,
      yLabelsMaxHeightFromFirstLayout: yLabelsMaxHeightFromFirstLayout,
    );

    yContainer.layout(yContainerLayoutExpansion);
    yContainerSize = yContainer.layoutSize;
    ui.Offset yContainerOffset = ui.Offset(0.0, legendContainerSize.height);
    yContainer.applyParentOffset(yContainerOffset);

    ui.Offset dataContainerOffset = ui.Offset(yContainerSize.width, legendContainerSize.height);

    // ### 6. Layout the data area, which included the grid
    // by calculating the X and Y positions of grid.
    // This must be done after X and Y are layed out - see xTickXs, yTickYs.
    var dataContainerLayoutExpansion = LayoutExpansion(
      width: chartArea.width - yContainerSize.width,
      height: chartArea.height - (legendContainerSize.height + xContainerSize.height),
    );
    this.dataContainer = createDataContainer(
      parentContainer: this,
    );

    // todo-00-last : this is where most non-Container elements are layed out.
    //                problem is, part of the layout happens in applyParentOffset!
    dataContainer.layout(dataContainerLayoutExpansion);
    dataContainer.applyParentOffset(dataContainerOffset);
  }

  /// Implements abstract [paint()] for the whole chart.
  /// Paints the chart on the passed [canvas], limited to the [size] area.
  ///
  /// This [paint()] method is the core method call of painting the chart.
  /// Called from the chart's painter baseclass, the [ChartPainter], which
  /// [paint(Canvas, Size)] is guaranteed to be called by the Flutter framework
  /// (see class comment), hence [ChartPainter.paint] starts the chart painting.
  ///
  /// In detail, this method paints all elements of the chart - the legend in [_paintLegend],
  /// the grid in [drawGrid], the x/y labels in [_paintXLabels] and [_paintYLabels],
  /// and the data values, column by column, in [drawDataPresentersColumns].
  ///
  /// Before the actual canvas painting,
  /// the operation with a call to [ChartContainer.layout()], then paints
  /// the lines, rectangles and circles of the child [containers.Container]s,
  /// according to their calculated layout positions.
  void paint(ui.Canvas canvas) {
    // Layout the whole chart container - provides all positions to paint and draw
    // all chart elements.
    layout(new LayoutExpansion(width: chartArea.width, height: chartArea.height));

    // Draws the Y labels area of the chart.
    yContainer.paint(canvas);
    // Draws the X labels area of the chart.
    xContainer.paint(canvas);
    // Draws the legend area of the chart.
    legendContainer.paint(canvas);
    // Draws the grid, then data area - bars (bar chart), lines and points (line chart).
    dataContainer.paint(canvas);

    // clip canvas to size - this does nothing
    // todo-1: THIS canvas.clipRect VVVV CAUSES THE PAINT() TO BE CALLED AGAIN. WHY??
    // canvas.clipRect(const ui.Offset(0.0, 0.0) & size); // Offset & Size => Rect
  }

  /// Abstract method creates the [DataContainer],
  /// for the particular chart type (line, bar).
  DataContainer createDataContainer({
    required ChartContainer parentContainer,
  });

  /// Create member [pointsColumns] from [data.dataRows].
  void setupPointsColumns() {
    this.pointsColumns = PointsColumns(
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
  List<double> get xTickXs =>
      xContainer._xLabelContainers.map((var xLabelContainer) => xLabelContainer.parentOffsetTick).toList();

  /// Y coordinates of y ticks (y tick - scaled value of data, also middle of label).
  /// Once [XContainer.layout] and [YContainer.layout] are complete,
  /// this list drives the layout of [DataContainer].
  ///
  /// See [AxisLabelContainer.parentOffsetTick] for details.
  List<double> get yTickYs {
    return yContainer._yLabelContainers.map((var yLabelContainer) => yLabelContainer.parentOffsetTick).toList();
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
  late List<AxisLabelContainer> _yLabelContainers;

  double _yLabelsMaxHeightFromFirstLayout;

  /// Constructs the container that holds Y labels.
  ///
  /// The passed [LayoutExpansion] is (assumed) to direct the expansion to fill
  /// all available vertical space, and only use necessary horizontal space.
  YContainer({
    required ChartContainer parentContainer,
    required double yLabelsMaxHeightFromFirstLayout,
  })   : _yLabelsMaxHeightFromFirstLayout = yLabelsMaxHeightFromFirstLayout,
        super(
          parentContainer: parentContainer,
        );

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
  void layout(LayoutExpansion parentLayoutExpansion) {
    // yAxisMin and yAxisMax define end points of the Y axis, in the YContainer
    //   coordinates.
    // todo 0-layout: layoutExpansion - max of yLabel height, and the 2 paddings

    // todo 0-layout flip Min and Max and find a place which reverses
    double yAxisMin = parentLayoutExpansion.height - (_parentContainer.options.xBottomMinTicksHeight);

    // todo 0-layout: max of this and some padding
    double yAxisMax = _yLabelsMaxHeightFromFirstLayout / 2;

    if (_parentContainer.options.useUserProvidedYLabels) {
      layoutManually(yAxisMin, yAxisMax);
    } else {
      layoutAutomatically(yAxisMin, yAxisMax);
    }

    double yLabelsContainerWidth =
        _yLabelContainers.map((yLabelContainer) => yLabelContainer.layoutSize.width).reduce(math.max) +
            2 * _parentContainer.options.yLabelsPadLR;

    layoutSize = ui.Size(yLabelsContainerWidth, parentLayoutExpansion.height);
  }

  /// Manually layout Y axis by evenly dividing available height to all Y labels.
  void layoutManually(double yAxisMin, double yAxisMax) {
    List<double> flatData =
        _parentContainer.pointsColumns.flattenPointsValues(); // todo-2 move to common layout, same for manual and auto

    List<String> yLabels = _parentContainer.data.yLabels;

    var yDataRange = Interval(flatData.reduce(math.min), flatData.reduce(math.max));
    double dataStepHeight = (yDataRange.max - yDataRange.min) / (yLabels.length - 1);

    Interval yAxisRange = Interval(yAxisMin, yAxisMax);

    double yGridStepHeight = (yAxisRange.max - yAxisRange.min) / (yLabels.length - 1);

    List<double> yLabelsDividedInYAxisRange = List.empty(growable: true);
    //var seq = new Iterable.generate(yLabels.length, (i) => i); // 0 .. length-1
    //for (var yIndex in seq) {
    for (var yIndex = 0; yIndex < yLabels.length; yIndex++) {
      yLabelsDividedInYAxisRange.add(yAxisRange.min + yGridStepHeight * yIndex);
    }

    List<num> yLabelsDividedInYDataRange = List.empty(growable: true);
    for (var yIndex = 0; yIndex < yLabels.length; yIndex++) {
      yLabelsDividedInYDataRange.add(yDataRange.min + dataStepHeight * yIndex);
    }

    var yScaler = YScalerAndLabelFormatter(
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
    List<double> flatData =
        geometry.iterableNumToDouble(_parentContainer.pointsColumns.flattenPointsValues()).toList(growable: true);

    Range range = Range(
      values: flatData,
      chartOptions: _parentContainer.options,
    );

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
    LabelStyle labelStyle = LabelStyle(
      textStyle: options.labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.labelTextAlign, // center text
      textScaleFactor: options.labelTextScaleFactor,
    );
    // Create one Y Label (yLabelContainer) for each labelInfo,
    // and add to yLabelContainers list.
    _yLabelContainers = List.empty(growable: true);

    for (LabelInfo labelInfo in yScaler.labelInfos) {
      // yTickY is both scaled data value and vertical (Y) center of the label.
      // It is kept alway relative to the immediate container - YContainer
      double yTickY = labelInfo.scaledLabelValue;
      var yLabelContainer = AxisLabelContainer(
        label: labelInfo.formattedYLabel,
        labelMaxWidth: double.infinity,
        labelTiltMatrix: vector_math.Matrix2.identity(),
        canvasTiltMatrix: vector_math.Matrix2.identity(),
        labelStyle: labelStyle,
      );
      // yLabelContainer.layout(LayoutExpansion.unused()); // todo-11-last consider if needed - no
      double labelTopY = yTickY - yLabelContainer.layoutSize.height / 2;

      yLabelContainer.parentOffsetTick = yTickY;

      // Move the contained LabelContainer to correct position
      yLabelContainer.applyParentOffset(
        ui.Offset(_parentContainer.options.yLabelsPadLR, labelTopY),
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

  void paint(ui.Canvas canvas) {
    for (var yLabelContainer in _yLabelContainers) {
      yLabelContainer.paint(canvas);
    }
  }

  double get yLabelsMaxHeight =>
      _yLabelContainers.map((yLabelContainer) => yLabelContainer.layoutSize.height).reduce(math.max);
}

/// Container of the X axis labels.
///
/// This [ChartAreaContainer] operates as follows:
/// - Horizontally available space is all used (filled).
/// - Vertically available space is used only as much as needed.
/// The used amount is given by maximum X label height, plus extra spacing.
/// - See [layout] and [layoutSize] for resulting size calculations.
/// - See the [XContainer] constructor for the assumption on [LayoutExpansion].

class XContainer extends AdjustableLabelsChartAreaContainer {
  /// X labels.
  List<AxisLabelContainer> _xLabelContainers = List.empty(growable: true);

  double _gridStepWidth = 0.0;

  /// Size allocated for each shown label (>= [_gridStepWidth]
  double _shownLabelsStepWidth = 0.0;

  /// Constructs the container that holds X labels.
  ///
  /// The passed [LayoutExpansion] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  XContainer({
    required ChartContainer parentContainer,
    required strategy.LabelLayoutStrategy xContainerLabelLayoutStrategy,
  }) : super(
          parentContainer: parentContainer,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        ) {
    // Must initialize in body, as access to 'this' not available in initializer.
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
  void layout(LayoutExpansion parentLayoutExpansion) {
    // First clear any children that could be created on nested re-layout
    _xLabelContainers = List.empty(growable: true);

    ChartOptions options = _parentContainer.options;

    List<String> xLabels = _parentContainer.data.xLabels;

    double yTicksWidth = options.yLeftMinTicksWidth + options.yRightMinTicksWidth;

    double availableWidth = parentLayoutExpansion.width - yTicksWidth;

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
    int numShownLabels = (xLabels.length ~/ labelLayoutStrategy.showEveryNthLabel);
    _shownLabelsStepWidth = availableWidth / numShownLabels;

    LabelStyle labelStyle = _styleForLabels(options);

    // Core layout loop, creates a AxisLabelContainer from each xLabel,
    //   and lays out the XLabelContainers along X in _gridStepWidth increments.

    for (var xIndex = 0; xIndex < xLabels.length; xIndex++) {
      var xLabelContainer = AxisLabelContainer(
        label: xLabels[xIndex],
        labelMaxWidth: double.infinity,
        labelTiltMatrix: labelLayoutStrategy.labelTiltMatrix,
        canvasTiltMatrix: labelLayoutStrategy.canvasTiltMatrix,
        labelStyle: labelStyle,
      );
      // force layout. lack of this causes _textPainter._text size to be 0, 1 always.
      //  xLabelContainer.layout(LayoutExpansion.unused()); // todo-11-last consider if needed - no

      xLabelContainer.skipByParent = !_isLabelOnIndexShown(xIndex);

      // Core of X layout calcs - lay out label to find the size that is takes,
      //   then find X middle of the bounding rectangle

      ui.Rect labelBound = ui.Offset.zero & xLabelContainer.layoutSize;
      double halfStepWidth = _gridStepWidth / 2;
      double atIndexOffset = _gridStepWidth * xIndex;
      double xTickX = halfStepWidth + atIndexOffset + options.yLeftMinTicksWidth;
      double labelTopY = options.xLabelsPadTB; // down by XContainer padding

      xLabelContainer.parentOffsetTick = xTickX;

      // tickX and label centers are same. labelLeftTop = label paint start.
      var labelLeftTop = ui.Offset(
        xTickX - labelBound.width / 2,
        labelTopY,
      );

      xLabelContainer.applyParentOffset(labelLeftTop);

      _xLabelContainers.add(xLabelContainer);
    }

    // xlabels area without padding
    double xLabelsMaxHeight =
        _xLabelContainers.map((xLabelContainer) => xLabelContainer.layoutSize.height).reduce(math.max);

    // Set the layout size calculated by this layout
    layoutSize = ui.Size(
      parentLayoutExpansion.width,
      xLabelsMaxHeight + 2 * options.xLabelsPadTB,
    );

    // This achieves auto-layout of labels to fit along X axis.
    // Iterative call to this layout method, until fit or max depth is reached,
    //   whichever comes first.
    labelLayoutStrategy.reLayout(parentLayoutExpansion);
  }

  LabelStyle _styleForLabels(ChartOptions options) {
    widgets.TextStyle labelTextStyle = widgets.TextStyle(
      color: options.labelTextStyle.color,
      fontSize: labelLayoutStrategy.labelFontSize,
    );

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
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

  void paint(ui.Canvas canvas) {
    if (labelLayoutStrategy.isRotateLabelsReLayout) {
      // Tilted X labels. Must use canvas and offset coordinate rotation.
      canvas.save();
      canvas.rotate(-1 * labelLayoutStrategy.labelTiltRadians);

      _rotateLabelContainersAsCanvas();
      _paintLabelContainers(canvas);

      canvas.restore();
    } else {
      // Horizontal X labels, potentially skipped or shrinked
      _paintLabelContainers(canvas);
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
    if (xIndex % labelLayoutStrategy.showEveryNthLabel == 0) return true;
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
        !axisLabelContainer.skipByParent && axisLabelContainer.layoutSize.width > _shownLabelsStepWidth)) {
      return true;
    }

    return false;
  }
}

/// A marker of container with adjustable contents,
/// such as labels that can be skipped.
// todo-2 LabelLayoutStrategy should be a member of AdjustableContect, not
//          in AdjustableLabelsChartAreaContainer
//          Also, AdjustableLabels should be a mixin.
//          But Dart bug #25742 does not allow mixins with named parameters.
abstract class AdjustableLabels {
  bool labelsOverlap();
}

/// Provides ability to connect [LabelLayoutStrategy] to [Container],
/// (actually currently the [ChartAreaContainer].
///
/// Requires a non-null [_labelLayoutStrategy] passed to this,
/// as this abstract should not guess any defaults for the layout strategies;
/// this abstract is serving too generic layouts to guess layout strategies.
/// Extensions can create layout strategy defaults.
abstract class AdjustableLabelsChartAreaContainer extends ChartAreaContainer implements AdjustableLabels {
  strategy.LabelLayoutStrategy _labelLayoutStrategy;

  strategy.LabelLayoutStrategy get labelLayoutStrategy => _labelLayoutStrategy;

  AdjustableLabelsChartAreaContainer({
    required ChartContainer parentContainer,
    required strategy.LabelLayoutStrategy xContainerLabelLayoutStrategy,
  })   : _labelLayoutStrategy = xContainerLabelLayoutStrategy,
        super(
          parentContainer: parentContainer,
        );
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
///   - [DataContainer] and extensions - manages the area which displays:
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
    required ChartContainer parentContainer,
  })   : _parentContainer = parentContainer,
        super();

  ChartContainer get parentContainer => _parentContainer;
}

/// Manages the core chart area which displays and paints (in this order):
///   - The grid (this includes the X and Y axis).
///   - Data - as columns of bar chart, line chart, or other chart type
abstract class DataContainer extends ChartAreaContainer {
  late GridLinesContainer _xGridLinesContainer;
  late GridLinesContainer _yGridLinesContainer;

  /// Columns of presenters.
  ///
  /// Presenters may be:
  ///   - points and lines in line chart
  ///   - bars (stacked or grouped) in bar chart
  ///
  /// todo 0 replace with getters; see if members can be made private,  manipulated via YLabelContainer.
  late PresentersColumns presentersColumns;

  DataContainer({
    required ChartContainer parentContainer,
  }) : super(
          parentContainer: parentContainer,
        );

  /// Implements [Container.layout()] for data area.
  ///
  /// Uses all available space in the passed [parentLayoutExpansion],
  /// which it divides between it's children.
  ///
  /// First lays out the Grid, then, based on the available size,
  /// scales the columns to the [YContainer]'s scale.
  void layout(LayoutExpansion parentLayoutExpansion) {
    layoutSize = ui.Size(parentLayoutExpansion.width, parentLayoutExpansion.height);

    _layoutGrid();

    // Scale the [pointsColumns] to the [YContainer]'s scale.
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

    this._yGridLinesContainer = GridLinesContainer();

    chartContainer.xTickXs.forEach((xTickX) {
      // Add vertical yGrid line in the middle or on the left
      double lineX = isStacked ? xTickX - xGridStep / 2 : xTickX;

      LineContainer yLineContainer = LineContainer(
        lineFrom: ui.Offset(lineX, 0.0),
        lineTo: ui.Offset(lineX, layoutSize.height),
        linePaint: gridLinesPaint(options),
      );

      // Add a new vertical grid line - yGrid line.
      this._yGridLinesContainer.addLine(yLineContainer);
    });

    // For stacked, we need to add last right vertical yGrid line
    if (isStacked && chartContainer.xTickXs.isNotEmpty) {
      double x = chartContainer.xTickXs.last + xGridStep / 2;
      LineContainer yLineContainer = LineContainer(
          lineFrom: ui.Offset(x, 0.0),
          lineTo: ui.Offset(x, layoutSize.height),
          linePaint: gridLinesPaint(options));
      this._yGridLinesContainer.addLine(yLineContainer);
    }

    // ### 2. Horizontal Grid (xGrid) layout:

    // Iterate yLabels and for each add a horizontal grid line
    // When iterating Y labels, also create the horizontal lines - xGridLines
    this._xGridLinesContainer = GridLinesContainer();

    // Position the horizontal xGrid at mid-points of labels at yTickY.
    chartContainer.yTickYs.forEach((yTickY) {
      LineContainer xLineContainer = LineContainer(
          lineFrom: ui.Offset(0.0, yTickY),
          lineTo: ui.Offset(this.layoutSize.width, yTickY),
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
    // todo-00-last : problem : this call actually sets absolute values on Presenters !!
    setupPresentersColumns();
  }

  /// Paints the Grid lines of the chart area.
  ///
  /// Note that the [super.paint()] remains not implemented in this class.
  /// Superclasses (for example the line chart data container) should
  /// call this method at the beginning of it's [paint()] implementation,
  /// followed by painting the [Presenter]s in [drawDataPresentersColumns()].
  ///
  void _paintGridLines(ui.Canvas canvas) {
    // draw horizontal grid
    this._xGridLinesContainer.paint(canvas);

    // draw vertical grid
    this._yGridLinesContainer.paint(canvas);
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
    this.presentersColumns = PresentersColumns(
      pointsColumns: parentContainer.pointsColumns,
      container: parentContainer,
      presenterCreator: parentContainer.presenterCreator,
    );
  }

  /// Optionally paint series in reverse order (first to last,
  /// vs last to first which is default).
  ///
  /// See [ChartOptions.dataRowsPaintingOrder].
  List<Presenter> optionalPaintOrderReverse(List<Presenter> presenters) {
    var options = this.parentContainer.options;
    if (options.dataRowsPaintingOrder == DataRowsPaintingOrder.FirstToLast) {
      presenters = presenters.reversed.toList();
    }
    return presenters;
  }

  /// Draws the actual data, either as lines with points (line chart),
  /// or bars/columns, stacked or grouped (bar/column charts).
  void _drawDataPresentersColumns(ui.Canvas canvas);
}

/// Provides the data area container for the bar chart.
///
/// The only role is to implement the abstract method of the baseclass,
/// [paint()] and [drawDataPresentersColumns()].
class VerticalBarChartDataContainer extends DataContainer {
  VerticalBarChartDataContainer({
    required ChartContainer parentContainer,
  }) : super(
          parentContainer: parentContainer,
        );

  void paint(ui.Canvas canvas) {
    _paintGridLines(canvas);
    _drawDataPresentersColumns(canvas);
  }

  /// See super [ChartPainter.drawDataPresentersColumns()].
  void _drawDataPresentersColumns(ui.Canvas canvas) {
    PresentersColumns presentersColumns = this.presentersColumns;

    presentersColumns.forEach((PresentersColumn presentersColumn) {
      // todo-2 do not repeat loop, collapse to one construct

      var positivePresenterList = presentersColumn.positivePresenters;
      positivePresenterList = optionalPaintOrderReverse(positivePresenterList);
      positivePresenterList.forEach((Presenter presenter) {
        bar_presenters.VerticalBarPresenter presenterCast = presenter as bar_presenters.VerticalBarPresenter;
        canvas.drawRect(
          presenterCast.presentedRect,
          presenterCast.dataRowPaint,
        );
      });

      var negativePresenterList = presentersColumn.negativePresenters;
      negativePresenterList = optionalPaintOrderReverse(negativePresenterList);
      negativePresenterList.forEach((Presenter presenter) {
        bar_presenters.VerticalBarPresenter presenterCast = presenter as bar_presenters.VerticalBarPresenter;
        canvas.drawRect(
          presenterCast.presentedRect,
          presenterCast.dataRowPaint,
        );
      });
    });
  }
}

/// Provides the data area container for the line chart.
///
/// The only role is to implement the abstract method of the baseclass,
/// [paint()] and [drawDataPresentersColumns()].
class LineChartDataContainer extends DataContainer {
  LineChartDataContainer({
    required ChartContainer parentContainer,
  }) : super(
          parentContainer: parentContainer,
        );

  void paint(ui.Canvas canvas) {
    _paintGridLines(canvas);
    _drawDataPresentersColumns(canvas);
  }

  /// See super [ChartPainter.drawDataPresentersColumns()].
  void _drawDataPresentersColumns(ui.Canvas canvas) {
    var presentersColumns = this.presentersColumns;
    presentersColumns.forEach((PresentersColumn presentersColumn) {
      var presenterList = presentersColumn.presenters;
      presenterList = optionalPaintOrderReverse(presenterList);
      presenterList.forEach((Presenter presenter) {
        line_presenters.LineAndHotspotPresenter presenterCast = presenter as line_presenters.LineAndHotspotPresenter;
        // todo 0-future-minor Use call to Container.paint
        canvas.drawLine(
          presenterCast.lineContainer.lineFrom,
          presenterCast.lineContainer.lineTo,
          presenterCast.lineContainer.linePaint,
        );
        // todo 0-future-medium Add hotspot as Container, use Container.paint
        canvas.drawCircle(
          presenterCast.offsetPoint,
          presenterCast.outerRadius,
          presenterCast.outerPaint,
        );
        canvas.drawCircle(
          presenterCast.offsetPoint,
          presenterCast.innerRadius,
          presenterCast.innerPaint,
        );
      });
    });
  }
}

///
class GridLinesContainer extends Container {
  List<LineContainer> _lineContainers = List.empty(growable: true);

  GridLinesContainer() : super();

  void addLine(LineContainer lineContainer) {
    _lineContainers.add(lineContainer);
  }

  /// Implements the abstract [Container.layout()].
  void layout(LayoutExpansion parentLayoutExpansion) {
    _lineContainers.forEach((lineContainer) => lineContainer.layout(parentLayoutExpansion));
  }

  /// Overridden from super. Applies offset on all members.
  void applyParentOffset(ui.Offset offset) {
    _lineContainers.forEach((lineContainer) => lineContainer.applyParentOffset(offset));
  }

  /// Implements the abstract [Container.layout()].
  void paint(ui.Canvas canvas) {
    _lineContainers.forEach((lineContainer) => lineContainer.paint(canvas));
  }

  /// Implementor of method in superclass [Container].
  ///
  /// Return the size of the outermost rectangle which contains all lines
  ///   in the member _xLineContainers.
  // ui.Size get layoutSize => _xLineContainers.reduce((lineContainer.+));
  // todo-00-last look into this
  ui.Size get layoutSize => throw StateError('todo-2 implement this.');
}

/// Represents one layed out item of the legend:  The rectangle for the color
/// indicator, [_indicatorRect], followed by the series label text.
class LegendItemContainer extends Container {
  /// Container of label
  late LabelContainer _labelContainer;

  /// Rectangle of the legend color square series indicator
  late ui.Rect _indicatorRect;

  /// Paint used to paint the indicator
  ui.Paint _indicatorPaint;

  ChartOptions _options;

  LabelStyle _labelStyle;
  String _label;

  LegendItemContainer({
    required String label,
    required LabelStyle labelStyle,
    required ui.Paint indicatorPaint,
    required ChartOptions options,
  })   :
        // We want to only create as much as we can in layout for clarity,
        // as a price, need to hold on on label and style from constructor
        _label = label,
        _labelStyle = labelStyle,
        _indicatorPaint = indicatorPaint,
        _options = options,
        super() {
    // There is no need to create the _indicatorRect in the constructor,
    // as layout will move it, recreating it.
    // So _indicatorPaint is argument, _indicatorRect is created in layout().
  }

  void layout(LayoutExpansion parentLayoutExpansion) {
    // Save a few repeated values, calculated the width given to LabelContainer,
    //   and create the LabelContainer.
    double indicatorSquareSide = _options.legendColorIndicatorWidth;
    double indicatorToLabelPad = _options.legendItemIndicatorToLabelPad;
    double betweenLegendItemsPadding = _options.betweenLegendItemsPadding;
    double labelMaxWidth =
        parentLayoutExpansion.width - (indicatorSquareSide + indicatorToLabelPad + betweenLegendItemsPadding);
    if (enableSkipOnDistressedSize && labelMaxWidth <= 0.0) {
      isDistressed = true;
      layoutSize = ui.Size(0.0, 0.0);
      return;
    }
    _labelContainer = LabelContainer(
      label: _label,
      labelMaxWidth: labelMaxWidth,
      labelTiltMatrix: vector_math.Matrix2.identity(),
      canvasTiltMatrix: vector_math.Matrix2.identity(),
      labelStyle: _labelStyle,
    );

    // Layout legend item elements (indicator, pad, label) flowing from left:

    // 1. layout the _labelContainer - this also provides height
    // _labelContainer.layout(LayoutExpansion.unused()); // todo-11-last consider if needed - no

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
    double labelOffsetX = indOffsetX + indicatorSquareSide + indicatorToLabelPad;

    // 4. Create the indicator square, and place it within this container
    //   (this is applyParentOffset for the indicator, if it was an object)
    _indicatorRect = ui.Rect.fromLTWH(
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
    layoutSize = ui.Size(
      _indicatorRect.width + indicatorToLabelPad + _labelContainer.layoutSize.width + betweenLegendItemsPadding,
      math.max(
        labelContainerSize.height,
        _indicatorRect.height,
      ),
    );

    // Make sure we fit all available width
    assert(parentLayoutExpansion.width + 1.0 >= layoutSize.width); // todo-2 within epsilon
  }

  /// Overridden super's [paint] to also paint the rectangle indicator square.
  void paint(ui.Canvas canvas) {
    if (isDistressed) return; // todo-10 this should not be, only if distress actually happens

    _labelContainer.paint(canvas);
    canvas.drawRect(
      _indicatorRect,
      _indicatorPaint,
    );
  }

  void applyParentOffset(ui.Offset offset) {
    if (isDistressed) return; // todo-10 this should not be, only if distress actually happens

    super.applyParentOffset(offset);
    _indicatorRect = _indicatorRect.translate(offset.dx, offset.dy);
    _labelContainer.applyParentOffset(offset);
  }
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
  late List<LegendItemContainer> _legendItemContainers;

  /// Constructs the container that holds the data series legends labels and
  /// color indicators.
  ///
  /// The passed [LayoutExpansion] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  LegendContainer({
    required ChartContainer parentContainer,
  }) : super(
          parentContainer: parentContainer,
        );

  /// Lays out the legend area.
  ///
  /// Evenly divides the [availableWidth] to all legend items.
  void layout(LayoutExpansion parentLayoutExpansion) {
    ChartOptions options = _parentContainer.options;
    double containerMarginTB = options.legendContainerMarginTB;
    double containerMarginLR = options.legendContainerMarginLR;

    List<String> dataRowsLegends = _parentContainer.data.dataRowsLegends;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
      textStyle: options.labelTextStyle,
      textDirection: options.labelTextDirection,
      textAlign: options.legendTextAlign, // keep left, close to indicator
      textScaleFactor: options.labelTextScaleFactor,
    );

    // First paint all legends, to figure out max height of legends to center all
    // legends label around common center.

    double legendItemWidth = (parentLayoutExpansion.width - 2.0 * containerMarginLR) / dataRowsLegends.length;

    _legendItemContainers = List<LegendItemContainer>.empty(growable: true);

    // Layout legend core: for each row, create and position
    //   - an indicator rectangle and it's paint
    //   - label painter
    for (var index = 0; index < dataRowsLegends.length; index++) {
      ui.Paint indicatorPaint = ui.Paint();
      indicatorPaint.color = _parentContainer.data.dataRowsColors[index % _parentContainer.data.dataRowsColors.length];

      var legendItemLayoutExpansion = parentLayoutExpansion.cloneWith(
        width: legendItemWidth,
      );
      var legendItemContainer = LegendItemContainer(
        label: dataRowsLegends[index],
        labelStyle: labelStyle,
        indicatorPaint: indicatorPaint,
        options: options,
      );

      legendItemContainer.layout(legendItemLayoutExpansion);

      legendItemContainer.applyParentOffset(
        ui.Offset(
          containerMarginLR + index * legendItemWidth,
          containerMarginTB,
        ),
      );

      _legendItemContainers.add(legendItemContainer);
    }

    layoutSize = ui.Size(
      parentLayoutExpansion.width,
      _legendItemContainers.map((legendItemContainer) => legendItemContainer.layoutSize.height).reduce(math.max) +
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
  // todo 0 check if this is unused; and why we need label in value?
  String xLabel;
  double y;
  int dataRowIndex; // series index
  StackableValuePoint? predecessorPoint;
  bool isStacked = false;

  // stacking - sets the y coordinate of range representing this point's value
  double fromY;
  double toY;

  /// Scaled values. All set lazily after [scale]
  double scaledX = 0.0;
  double scaledY = 0.0;
  double fromScaledY = 0.0;
  double toScaledY = 0.0;

  /// Scaled Offsets for painting in absolute chart coordinates.
  /// More precisely, offsets of the bottom and top of the presenter of this
  /// point - for example, for VerticalBar, bottom and top of each bar
  /// representing this value point (data point)
  ui.Offset scaledFrom = ui.Offset(0.0, 0.0);
  ui.Offset scaledTo = ui.Offset(0.0, 0.0);

  StackableValuePoint({
    required String xLabel,
    required double y,
    required int dataRowIndex,
    StackableValuePoint? predecessorPoint,
  })  : this.xLabel = xLabel,
        this.y = y,
        this.dataRowIndex = dataRowIndex,
        this.predecessorPoint = predecessorPoint,
        this.isStacked = false,
        this.fromY = 0.0,
        this.toY = y;

  /// Initial instance of a [StackableValuePoint].
  /// Forwarded to the default constructor.
  /// This should fail if it undergoes any processing such as layout
  StackableValuePoint.initial()
      : this(
          xLabel: 'initial',
          y: -1,
          dataRowIndex: -1,
          predecessorPoint: null,
        );

  StackableValuePoint stack() {
    this.isStacked = true;

    // todo-1 validate: check if both points y is same sign or zero
    this.fromY = predecessorPoint != null ? predecessorPoint!.toY : 0.0;
    this.toY = this.fromY + this.y;

    return this;
  }

  /// Stacks this point on top of the passed [predecessorPoint].
  ///
  /// Points are constructed unstacked. Depending on chart type,
  /// a later processing can stack points using this method
  /// (if chart type is [ChartContainer.isStacked].
  StackableValuePoint stackOnAnother(StackableValuePoint? predecessorPoint) {
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
  /// of the corresponding x label).
  ///
  StackableValuePoint scale({
    required double scaledX,
    required YScalerAndLabelFormatter yScaler,
  }) {
    this.scaledX = scaledX;
    this.scaledY = yScaler.scaleY(value: this.y);
    this.fromScaledY = yScaler.scaleY(value: this.fromY);
    this.toScaledY = yScaler.scaleY(value: this.toY);
    this.scaledFrom = ui.Offset(scaledX, this.fromScaledY);
    this.scaledTo = ui.Offset(scaledX, this.toScaledY);

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
      throw Exception('Cannot clone if already stacked');
    }

    StackableValuePoint clone = StackableValuePoint(
        xLabel: this.xLabel, y: this.y, dataRowIndex: this.dataRowIndex, predecessorPoint: this.predecessorPoint);

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
    clone.scaledFrom = ui.Offset(scaledFrom.dx, scaledFrom.dy);
    clone.scaledTo = ui.Offset(scaledTo.dx, scaledTo.dy);

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
///   [stackableValuePoints] that have values from [ChartData.dataRows].
///   - stacked (such as in the bar chart), in which case it manages
///   [stackableValuePoints] that have values added up from [ChartData.dataRows].
///
/// Negative and positive points must be stacked separately,
/// to support correctly displayed stacked values above and below zero.
class PointsColumn {
  /// List of charted values in this column
  late List<StackableValuePoint> stackableValuePoints;

  /// List of stacked positive or zero value points - support for stacked type charts,
  /// where negative and positive points must be stacked separately,
  /// above and below zero.
  late List<StackableValuePoint> stackedPositivePoints; // non-negative actually

  /// List of stacked negative value points - support for stacked type charts,
  /// where negative and positive points must be stacked separately,
  /// above and below zero.
  late List<StackableValuePoint> stackedNegativePoints;

  PointsColumn? nextRightPointsColumn;

  ///  Construct column from the passed [points].
  ///
  ///  Passed points are assumed to:
  ///    - Be configured with appropriate [predecessorPoint]
  ///    - Not stacked
  ///  Creates members [stackedNegativePoints], [stackedPositivePoints]
  ///  which exist only to be stacked, so the constructor stacks them
  ///  on creation.
  PointsColumn({
    required List<StackableValuePoint> points,
  }) {
    // todo-1 add validation that points are not stacked
    this.stackableValuePoints = points;

    this.stackedPositivePoints =
        this.selectThenCollectStacked(points: this.stackableValuePoints, selector: (point) => point.y >= 0);
    this.stackedNegativePoints =
        this.selectThenCollectStacked(points: this.stackableValuePoints, selector: (point) => point.y < 0);
  }

  // points are ordered in series order, first to last  (bottom to top),
  // and maintain their 0 based row (series) index
  /// todo 0 document

  List<StackableValuePoint> selectThenCollectStacked({
    required List<StackableValuePoint> points,
    required bool selector(StackableValuePoint point),
  }) {
    StackableValuePoint? predecessorPoint;
    List<StackableValuePoint> selected = this.stackableValuePoints.where((point) {
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
    return []..addAll(stackableValuePoints)..addAll(stackedNegativePoints)..addAll(stackedPositivePoints);
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
  /// Data points managed row - major. Internal only, not used in chart.
  List<List<StackableValuePoint>> _valuePointArrInRows;

  /// Data points managed column - major. Internal only, not used in chart.
  List<List<StackableValuePoint>>? _valuePointArrInColumns;

  /// Parent chart container.
  ChartContainer _container;

  /// True if chart type presents values stacked.
  bool _isStacked;

  /// Constructor creates a [PointsColumns] instance from values in
  /// the passed [container.data.dataRows].
  PointsColumns({
    required ChartContainer container,
    required PresenterCreator presenterCreator,
    required bool isStacked,
  })   : _container = container,
        _valuePointArrInRows = List.empty(growable: true),
        _isStacked = isStacked {
    ChartData chartData = container.data;

    /// Transposes the passed data in [container.data.dataRows]
    /// to [_valuePointArrInRows] to [_valuePointArrInColumns].
    ///
    /// Manages "predecessor in stack" points - each element is the per column point
    /// below the currently processed point. The currently processed point is
    /// (potentially) stacked on it's predecessor.

    List<StackableValuePoint?> rowOfPredecessorPoints =
        List.filled(chartData.dataRows[0].length, null); // todo 0 deal with no data rows
    for (int col = 0; col < chartData.dataRows[0].length; col++) {
      rowOfPredecessorPoints[col] = null; // new StackableValuePoint.initial(); // was:null
    }

    for (int row = 0; row < chartData.dataRows.length; row++) {
      List<num> dataRow = chartData.dataRows[row];
      List<StackableValuePoint> pointsRow = List<StackableValuePoint>.empty(growable: true);
      _valuePointArrInRows.add(pointsRow);
      for (int col = 0; col < dataRow.length; col++) {
        num colValue = dataRow[col];

        // Create all points unstacked. A later processing can stack them,
        // depending on chart type. See [StackableValuePoint.stackOnAnother]
        var thisPoint = StackableValuePoint(
            xLabel: 'initial', // todo-11-last : xLabel: null : consider
            y: colValue.toDouble(),
            dataRowIndex: row,
            predecessorPoint: rowOfPredecessorPoints[col]);

        pointsRow.add(thisPoint);
        rowOfPredecessorPoints[col] = thisPoint;
      }
    }
    _valuePointArrInRows.toList();
    _valuePointArrInColumns = transpose(_valuePointArrInRows);
    // also OK: _valuePointArrInColumns = transpose<StackableValuePoint>(_valuePointArrInRows);

    // convert "column oriented" _valuePointArrInColumns
    // to a column, and add the columns to this instance
    PointsColumn? leftColumn;

    // todo-11-last : can _valuePointArrInColumns be null?
    _valuePointArrInColumns?.forEach((columnPoints) {
      var pointsColumn = PointsColumn(points: columnPoints);
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
  ///   [PointsColumn.stackableValuePoints], and scales each point by
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

  List<double> flattenPointsValues() {
    if (_isStacked) return flattenStackedPointsYValues();

    return flattenUnstackedPointsYValues();
  }

  /// Flattens values of all unstacked data points.
  ///
  /// Use in containers for unstacked charts (e.g. line chart)
  List<double> flattenUnstackedPointsYValues() {
    // todo 1 replace with expand like in: dataRows.expand((i) => i).toList()
    List<double> flat = [];
    this.forEach((PointsColumn column) {
      column.stackableValuePoints.forEach((StackableValuePoint point) {
        flat.add(point.toY);
      });
    });
    return flat;
  }

  /// Flattens values of all stacked data points.
  ///
  /// Use in containers for stacked charts (e.g. VerticalBar chart)
  List<double> flattenStackedPointsYValues() {
    List<double> flat = [];
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

// todo-11 maybe replace.
// todo-11-last: In null safety, I had to replace T with a concrete StackableValuePoint.
//               can this be improved? This need may be a typing bug in Dart
/// Assuming even length 2D matrix [colsRows], return it's transpose copy.
List<List<StackableValuePoint>> transpose(
    List<List<StackableValuePoint>> colsInRows) {
  int nRows = colsInRows.length;
  if (colsInRows.length == 0) return colsInRows;

  int nCols = colsInRows[0].length;
  if (nCols == 0) throw StateError('Degenerate matrix');

  // Init the transpose to make sure the size is right
  List<List<StackableValuePoint>> rowsInCols = List.filled(nCols, []);
  for (int col = 0; col < nCols; col++) {
    rowsInCols[col] = List.filled(nRows, StackableValuePoint.initial());
  }

  // Transpose
  for (int row = 0; row < nRows; row++) {
    for (int col = 0; col < nCols; col++) {
      rowsInCols[col][row] = colsInRows[row][col];
    }
  }
  return rowsInCols;
}
