import 'dart:ui' as ui show Size, Offset, Rect, Paint, Canvas, Color;
import 'dart:math' as math show max;
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'package:flutter/widgets.dart' as widgets show TextStyle;

import '../morphic/rendering/constraints.dart' show LayoutExpansion;
import '../util/collection.dart' as custom_collection show CustomList;
import '../util/y_labels.dart';
import '../util/geometry.dart' as geometry;
import '../util/util_dart.dart';
import 'bar/presenter.dart' as bar_presenters; // or import 'package:flutter_charts/src/chart/bar/presenter.dart';
import 'container_base.dart' show Container;
import 'data.dart';
import 'iterative_layout_strategy.dart' as strategy;
import 'label_container.dart';
import 'line_container.dart';
import 'line/presenter.dart' as line_presenters;
import 'options.dart';
import 'presenter.dart';

/// The behavior mixin allows to plug in to the [ChartTopContainer] a behavior that is specific for a line chart
/// or vertical bar chart.
///
/// The behavior is plugged in the container, not the container owner chart.
mixin ChartBehavior {
  /// Behavior allows to start Y axis at data minimum (rather than 0).
  ///
  /// The request is asked by [DataContainerOptions.startYAxisAtDataMinRequested],
  /// but the implementation of this behavior must confirm it.
  /// See the extensions of this class for overrides of this method.
  bool get startYAxisAtDataMinAllowed;
}

/// Abstract class representing the [Container] of the whole chart.
///
/// Containers calculate coordinates of chart points
/// used for painting grid, labels, chart points etc.
///
/// Creates a simple chart container and call all needed [layout] methods.
///
/// Notes:
/// - [ChartTopContainer] and it's extensions,
///   such as [LineChartContainer] and [VerticalBarChartContainer]
///   are the only container which does not extend [Container]
/// - Related to above point, the [layout(num size)] is unrelated to
///   a same name method on [Container].
///
abstract class ChartTopContainer extends Container with ChartBehavior {
  /// Implements [Container.layoutSize].
  /// [ChartTopContainer] is the only one overriding layoutSize setter, to express the layoutSize is fixed chartArea
  @override
  ui.Size get layoutSize => chartArea;

  /// [chartArea] is the chart area size of this container.
  /// In flutter_charts, this is guaranteed to be the same
  /// area on which the painter will paint.
  /// See the call to [layout] of this class.
  /// [chartArea] marked late, as there is virtually no practical situation
  /// it can be known before runtime; it is required,
  /// but not set at construction time.
  ///
  late ui.Size chartArea;

  /// Base Areas of chart.
  late LegendContainer legendContainer;
  late XContainer xContainer;
  late YContainer yContainer;
  late DataContainer dataContainer;

  /// Layout strategy for XContainer labels.
  ///
  /// Cached from constructor here, until the late [xContainer] is created.
  final strategy.LabelLayoutStrategy? _cachedXContainerLabelLayoutStrategy;

  /// Scaler of data values to values on the Y axis.
  late YLabelsCreatorAndPositioner yLabelsCreator;

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
  /// This column grouped data instance is managed here in the [ChartTopContainer],
  /// (immediate owner of [YContainer] and [DataContainer])
  /// as their data points are needed both during [YContainer.layout]
  /// to calculate scaling, and also in [DataContainer.layout] to create
  /// [PresentersColumns] instance.
  late PointsColumns pointsColumns;

  late bool isStacked;

  ChartData data;

  /// Simple Legend+X+Y+Data Container for a flutter chart.
  ///
  /// The simple flutter chart layout consists of only 2 major areas:
  /// - [YContainer] area manages and lays out the Y labels area, by calculating
  ///   sizes required for Y labels (in both X and Y direction).
  ///   The [YContainer]
  /// - [XContainer] area manages and lays out the
  ///   - X labels area, and the
  ///   - grid area.
  /// In the X direction, takes up all space left after the
  /// YContainer layes out the  Y labels area, that is, full width
  /// minus [YContainer.yLabelsContainerWidth].
  /// In the Y direction, takes
  /// up all available chart area, except a top horizontal strip,
  /// required to paint half of the topmost label.
  ChartTopContainer({
    required ChartData chartData,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  })  : data = chartData,
        _cachedXContainerLabelLayoutStrategy = xContainerLabelLayoutStrategy,
        super();

  /// Implements [Container.layout] for the chart as a whole.
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
  @override
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
      chartTopContainer: this,
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
      chartTopContainer: this,
      yLabelsMaxHeightFromFirstLayout: 0.0,
    );

    yContainerFirst.layout(yContainerLayoutExpansion);
    double yLabelsMaxHeightFromFirstLayout = yContainerFirst.yLabelsMaxHeight;
    yContainer = yContainerFirst;
    ui.Size yContainerSize = yContainer.layoutSize;

    // ### 4. Knowing the width required by Y axis, layout X
    //        (from first [YContainer.layout] call).

    var xContainerLayoutExpansion = LayoutExpansion(
      width: chartArea.width - yContainerSize.width,
      height: chartArea.height - legendContainerSize.height,
    );
    xContainer = XContainer(
      chartTopContainer: this,
      xContainerLabelLayoutStrategy: _cachedXContainerLabelLayoutStrategy,
    );

    xContainer.layout(xContainerLayoutExpansion);

    ui.Size xContainerSize = xContainer.layoutSize;
    ui.Offset xContainerOffset = ui.Offset(yContainerSize.width, chartArea.height - xContainerSize.height);
    xContainer.applyParentOffset(xContainerOffset);

    // ### 5. Second call to YContainer is needed, as available height for Y
    //        is only known after XContainer provided required height of xUserLabels
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
      chartTopContainer: this,
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
    dataContainer = createDataContainer(
      chartTopContainer: this,
    );

    // todo-01-morph-layout : this is where most non-Container elements are layed out.
    //                problem is, part of the layout happens in applyParentOffset!
    dataContainer.layout(dataContainerLayoutExpansion);
    dataContainer.applyParentOffset(dataContainerOffset);
  }

  /// Implements abstract [paint] for the whole chart.
  /// Paints the chart on the passed [canvas], limited to the [size] area.
  ///
  /// This [paint] method is the core method call of painting the chart.
  /// Called from the chart's painter baseclass, the [ChartPainter], which
  /// [paint(Canvas, Size)] is guaranteed to be called by the Flutter framework
  /// (see class comment), hence [ChartPainter.paint] starts the chart painting.
  ///
  /// In detail, this method paints all elements of the chart - the legend in [_paintLegend],
  /// the grid in [drawGrid], the x/y labels in [_paintXLabels] and [_paintYLabels],
  /// and the data values, column by column, in [drawDataPresentersColumns].
  ///
  /// Before the actual canvas painting, at the beginning of this method,
  /// this class's [layout] is performed, which recursively lays out all member [Container]s.
  /// Once this top container is layed out, the [paint] is called on all
  /// member [Container]s ([YContainer],[XContainer] etc),
  /// which recursively paints the leaf [Container]s lines, rectangles and circles
  /// in their calculated layout positions.
  @override
  void paint(ui.Canvas canvas) {
    // Layout the whole chart container - provides all positions to paint and draw
    // all chart elements.
    layout(LayoutExpansion(width: chartArea.width, height: chartArea.height));

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
    // canvas.clipRect(const ui.Offset.zero & size); // Offset & Size => Rect
  }

  /// Abstract method creates the [DataContainer],
  /// for the particular chart type (line, bar).
  DataContainer createDataContainer({
    required ChartTopContainer chartTopContainer,
  });

  /// Create member [pointsColumns] from [data.dataRows].
  void setupPointsColumns() {
    pointsColumns = PointsColumns(
      chartTopContainer: this,
      presenterCreator: presenterCreator,
      isStacked: isStacked,
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

  final double _yLabelsMaxHeightFromFirstLayout;

  /// Constructs the container that holds Y labels.
  ///
  /// The passed [LayoutExpansion] is (assumed) to direct the expansion to fill
  /// all available vertical space, and only use necessary horizontal space.
  YContainer({
    required ChartTopContainer chartTopContainer,
    required double yLabelsMaxHeightFromFirstLayout,
  })  : _yLabelsMaxHeightFromFirstLayout = yLabelsMaxHeightFromFirstLayout,
        super(
          chartTopContainer: chartTopContainer,
        );

  /// Lays out the area containing the Y axis labels.
  ///
  /// Out of calls to all container's [layout] by the parent
  /// [ChartTopContainer.layout], the call to this object's [layout] is second,
  /// after [LegendContainer.layout].
  /// This [YContainer.layout] calculates [YContainer]'s labels width,
  /// the width taken by this container for the Y axis labels.
  ///
  /// The remaining horizontal width of [ChartTopContainer.chartArea] minus
  /// [YContainer]'s labels width provides remaining available
  /// horizontal space for the [GridLinesContainer] and [XContainer].
  @override
  void layout(LayoutExpansion parentLayoutExpansion) {
    // axisYMin and axisYMax define end points of the Y axis, in the YContainer
    //   coordinates.
    // todo 0-layout: layoutExpansion - max of yLabel height, and the 2 paddings

    // todo 0-layout flip Min and Max and find a place which reverses
    // Note: axisYMin > axisYMax ALWAYS.
    //       axisYMin should be called axisYBottom, and axisYMin should be called axisYTop,
    //       expressing the Y axis starts on top = 0.0, ends on bottom = 400 something.
    double axisYMin =
        parentLayoutExpansion.height - (chartTopContainer.data.chartOptions.xContainerOptions.xBottomMinTicksHeight);

    // todo 0-layout: max of this and some padding
    double axisYMax = _yLabelsMaxHeightFromFirstLayout / 2;

    // Even when Y container not shown and painted, this._yLabelContainers is needed later in yLabelsMaxHeight;
    //   and chartTopContainer.yLabelsCreator is needed in [PointsColumns.scale],
    //   so we cannot just skip layout completely at the beginning.
    if (!chartTopContainer.data.chartOptions.yContainerOptions.isYContainerShown) {
      _yLabelContainers = List.empty(growable: false);
      chartTopContainer.yLabelsCreator = _createLabelsAndPositionIn(axisYMin, axisYMax);
      return;
    }

    _createLabelsAndLayoutThisContainerWithLabels(axisYMin, axisYMax);

    double yLabelsContainerWidth =
        _yLabelContainers.map((yLabelContainer) => yLabelContainer.layoutSize.width).reduce(math.max) +
            2 * chartTopContainer.data.chartOptions.yContainerOptions.yLabelsPadLR;

    layoutSize = ui.Size(yLabelsContainerWidth, parentLayoutExpansion.height);
  }

  /// Generates scaled and spaced Y labels from data or from user defines labels, scales their position
  /// on the Y axis range [axisYMin] to [axisYMax], and lays them out
  /// in [_createContainerForLabelsInCreatorAndLayoutContainer].
  ///
  /// The data-generated label implementation smartly creates
  /// a limited number of Y labels from data, so that Y labels do not
  /// crowd, and little Y space is wasted on top.
  void _createLabelsAndLayoutThisContainerWithLabels(double axisYMin, double axisYMax) {
    YLabelsCreatorAndPositioner yLabelsCreator = _createLabelsAndPositionIn(axisYMin, axisYMax);

    // _createContainerForLabelsInCreatorAndLayoutContainer(yLabelsCreator);
    // todo-01-morph Rework to call layout on each AxisLabelContainer.
    /// Takes labels in the passed [yLabelsCreator], and creates a [AxisLabelContainer] from each label,
    /// then collects the created [AxisLabelContainer]s into the [_yLabelContainers] (member list of Y label containers).
    // Retain this scaler to be accessible to client code,
    // e.g. for coordinates of value points.
    chartTopContainer.yLabelsCreator = yLabelsCreator;
    ChartOptions options = chartTopContainer.data.chartOptions;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
      textStyle: options.labelCommonOptions.labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.labelCommonOptions.labelTextAlign, // center text
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );
    // Create one Y Label (yLabelContainer) for each labelInfo,
    // and add to yLabelContainers list.
    _yLabelContainers = List.empty(growable: true);

    for (LabelInfo labelInfo in yLabelsCreator.labelInfos) {
      // yTickY is the vertical center of the label on the Y axis.
      // It is equal to the Transformed and Scaled data value, calculated as LabelInfo.axisValue
      // It is kept always relative to the immediate container - YContainer
      double yTickY = labelInfo.axisValue.toDouble();
      var yLabelContainer = AxisLabelContainer(
        label: labelInfo.formattedLabel,
        labelMaxWidth: double.infinity,
        labelTiltMatrix: vector_math.Matrix2.identity(), // No tilted labels in YContainer
        labelStyle: labelStyle,
      );
      yLabelContainer.layout(LayoutExpansion.unused());

      double labelTopY = yTickY - yLabelContainer.layoutSize.height / 2;

      yLabelContainer.parentOffsetTick = yTickY;

      // Move the contained LabelContainer to correct position
      yLabelContainer.applyParentOffset(
        ui.Offset(chartTopContainer.data.chartOptions.yContainerOptions.yLabelsPadLR, labelTopY),
      );

      _yLabelContainers.add(yLabelContainer);
    }
  }

  /// Creates labels from Y data values in [PointsColumns], and positions the labels between [axisYMin], [axisYMax].
  YLabelsCreatorAndPositioner _createLabelsAndPositionIn(double axisYMin, double axisYMax) {
    // todo-04-later: place the utility geometry.iterableNumToDouble on ChartData and access here as _chartTopContainer.data (etc)
    List<double> dataYs = geometry.iterableNumToDouble(chartTopContainer.pointsColumns.flattenPointsValues()).toList();

    // Create formatted labels, with positions scaled to the [axisY] interval.
    YLabelsCreatorAndPositioner yLabelsCreator = YLabelsCreatorAndPositioner(
      dataYs: dataYs,
      axisY: Interval(axisYMin, axisYMax),
      chartBehavior: chartTopContainer,
      // only 'as ChartBehavior' mixin needed
      valueToLabel: chartTopContainer.data.chartOptions.yContainerOptions.valueToLabel,
      yInverseTransform: chartTopContainer.data.chartOptions.dataContainerOptions.yInverseTransform,
      yUserLabels: chartTopContainer.data.yUserLabels,
    );
    return yLabelsCreator;
  }

  @override
  void applyParentOffset(ui.Offset offset) {
    if (!chartTopContainer.data.chartOptions.yContainerOptions.isYContainerShown) {
      return;
    }
    // super not really needed - only child containers are offset.
    super.applyParentOffset(offset);

    for (AxisLabelContainer yLabelContainer in _yLabelContainers) {
      yLabelContainer.applyParentOffset(offset);
    }
  }

  @override
  void paint(ui.Canvas canvas) {
    if (!chartTopContainer.data.chartOptions.yContainerOptions.isYContainerShown) {
      return;
    }
    for (AxisLabelContainer yLabelContainer in _yLabelContainers) {
      yLabelContainer.paint(canvas);
    }
  }

  double get yLabelsMaxHeight {
    // todo-04-replace-this-pattern-with-fold - look for '? 0.0'
    return _yLabelContainers.isEmpty
        ? 0.0
        : _yLabelContainers.map((yLabelContainer) => yLabelContainer.layoutSize.height).reduce(math.max);
  }
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

  double _xGridStep = 0.0;

  double get xGridStep => _xGridStep;

  /// Size allocated for each shown label (>= [_xGridStep]
  double _shownLabelsStepWidth = 0.0;

  /// Constructs the container that holds X labels.
  ///
  /// The passed [LayoutExpansion] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  XContainer({
    required ChartTopContainer chartTopContainer,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartTopContainer: chartTopContainer,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        );

  /// Lays out the chart in horizontal (x) direction.
  ///
  /// Evenly divides the available width to all labels (spacing included).
  /// First / Last vertical line is at the center of first / last label.
  ///
  /// The layout is independent of whether the labels are tilted or not,
  ///   in the sense that all tilting logic is hidden in
  ///   [LabelContainer], and queried by [LabelContainer.layoutSize].
  @override
  void layout(LayoutExpansion parentLayoutExpansion) {
    // First clear any children that could be created on nested re-layout
    _xLabelContainers = List.empty(growable: true);

    ChartOptions options = chartTopContainer.data.chartOptions;

    List<String> xUserLabels = chartTopContainer.data.xUserLabels;

    double yTicksWidth = options.yContainerOptions.yLeftMinTicksWidth + options.yContainerOptions.yRightMinTicksWidth;

    double availableWidth = parentLayoutExpansion.width - yTicksWidth;

    double labelMaxAllowedWidth = availableWidth / xUserLabels.length;

    _xGridStep = labelMaxAllowedWidth;

    int numShownLabels = (xUserLabels.length ~/ labelLayoutStrategy.showEveryNthLabel);
    _shownLabelsStepWidth = availableWidth / numShownLabels;

    LabelStyle labelStyle = _styleForLabels(options);

    // Core layout loop, creates a AxisLabelContainer from each xLabel,
    //   and lays out the XLabelContainers along X in _gridStepWidth increments.

    for (int xIndex = 0; xIndex < xUserLabels.length; xIndex++) {
      var xLabelContainer = AxisLabelContainer(
        label: xUserLabels[xIndex],
        labelMaxWidth: double.infinity,
        labelTiltMatrix: labelLayoutStrategy.labelTiltMatrix, // Possibly tilted labels in XContainer
        labelStyle: labelStyle,
      );
      xLabelContainer.layout(LayoutExpansion.unused());
      xLabelContainer.skipByParent = !_isLabelOnIndexShown(xIndex);

      // Core of X layout calcs - lay out label to find the size that is takes,
      //   then find X middle of the bounding rectangle

      ui.Rect labelBound = ui.Offset.zero & xLabelContainer.layoutSize;
      double halfStepWidth = _xGridStep / 2;
      double atIndexOffset = _xGridStep * xIndex;
      double xTickX = halfStepWidth + atIndexOffset + options.yContainerOptions.yLeftMinTicksWidth;
      double labelTopY = options.xContainerOptions.xLabelsPadTB; // down by XContainer padding

      xLabelContainer.parentOffsetTick = xTickX;

      // tickX and label centers are same. labelLeftTop = label paint start.
      var labelLeftTop = ui.Offset(
        xTickX - labelBound.width / 2,
        labelTopY,
      );

      // labelLeftTop + offset for envelope
      xLabelContainer.applyParentOffset(labelLeftTop + xLabelContainer.tiltedLabelEnvelopeTopLeft);

      _xLabelContainers.add(xLabelContainer);
    }

    // Set the layout size calculated by this layout
    layoutSize = ui.Size(
      parentLayoutExpansion.width,
      xLabelsMaxHeight + 2 * options.xContainerOptions.xLabelsPadTB,
    );

    if (!chartTopContainer.data.chartOptions.xContainerOptions.isXContainerShown) {
      // Before re-layout, return and make the layout height (vertical-Y size) 0.
      // We cannot skip the code above entirely, as the xTickX are calculated from labesl, and used late in the
      // layout and painting of the DataContainer in ChartContainer - see xTickXs
      layoutSize = ui.Size(layoutSize.width, 0.0);
      return;
    }

    // This achieves auto-layout of labels to fit along X axis.
    // Iterative call to this layout method, until fit or max depth is reached,
    //   whichever comes first.
    labelLayoutStrategy.reLayout(parentLayoutExpansion);
  }

  // xlabels area without padding
  double get xLabelsMaxHeight {
    return _xLabelContainers.isEmpty
        ? 0.0
        : _xLabelContainers.map((xLabelContainer) => xLabelContainer.layoutSize.height).reduce(math.max);
  }

  LabelStyle _styleForLabels(ChartOptions options) {
    widgets.TextStyle labelTextStyle = widgets.TextStyle(
      color: options.labelCommonOptions.labelTextStyle.color,
      fontSize: labelLayoutStrategy.labelFontSize,
    );

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
      textStyle: labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.labelCommonOptions.labelTextAlign, // center text
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );
    return labelStyle;
  }

  @override
  void applyParentOffset(ui.Offset offset) {
    if (!chartTopContainer.data.chartOptions.xContainerOptions.isXContainerShown) {
      return;
    }
    // super not really needed - only child containers are offset.
    super.applyParentOffset(offset);

    for (AxisLabelContainer xLabelContainer in _xLabelContainers) {
      xLabelContainer.applyParentOffset(offset);
    }
  }

  /// Paints this [XContainer] on the passed [canvas].
  ///
  /// Delegates painting to all contained [LabelContainer]s.
  /// Any contained [LabelContainer] must have been offset to the appropriate position.
  ///
  /// A special situation is when the [LabelContainer]s are tilted, say counterclockwise.
  /// Because labels are always painted horizontally in the screen coordinate system, we much tilt them
  /// by painting them on a rotated position.
  /// This is achieved as follows: At the moment of calling this [paint],
  /// the top-left corner of the container (where the label will start painting), must be moved
  /// by rotation from the it's intended position clockwise. The [canvas]
  /// will be saved, then rotated, then labels painted horizontally into the offset,
  /// then the canvas rotated back for further painting.
  /// The canvas rotation back counterclockwise 'carries' with it the horizontally painted labels,
  /// which end up in the intended position but rotated counterclockwise.
  @override
  void paint(ui.Canvas canvas) {
    if (!chartTopContainer.data.chartOptions.xContainerOptions.isXContainerShown) {
      return;
    }
    if (labelLayoutStrategy.isRotateLabelsReLayout) {
      // Tilted X labels. Must use canvas and offset coordinate rotation.
      canvas.save();
      canvas.rotate(labelLayoutStrategy.labelTiltRadians);

      _paintLabelContainers(canvas);

      canvas.restore();
    } else {
      // Horizontal X labels, potentially skipped or shrinked
      _paintLabelContainers(canvas);
    }
  }

  void _paintLabelContainers(canvas) {
    for (AxisLabelContainer xLabelContainer in _xLabelContainers) {
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
  /// - [_xGridStep] is a limit for each label container width in the X direction.
  ///
  /// - Labels are layed out evenly, so if any label container's [layoutSize]
  /// in the X direction overflows the [_xGridStep],
  /// labels containers DO overlap. In such situation, the caller should
  /// take action to make labels smaller, tilt, or skip.
  ///
  @override
  bool labelsOverlap() {
    if (_xLabelContainers.any((axisLabelContainer) =>
        !axisLabelContainer.skipByParent && axisLabelContainer.layoutSize.width > _shownLabelsStepWidth)) {
      return true;
    }

    return false;
  }
}

/// A marker of container with adjustable contents,
/// such as labels that can be skipped.
// todo-01-morph LabelLayoutStrategy should be a member of AdjustableContainer, not
//          in AdjustableLabelsChartAreaContainer
//          Also, AdjustableLabels and perhaps AdjustableLabelsChartAreaContainer should be a mixin.
//          But Dart bug #25742 does not allow mixins with named parameters.
abstract class AdjustableLabels {
  bool labelsOverlap();
}

/// Provides ability to connect [LabelLayoutStrategy] to [Container],
/// (actually currently the [ChartAreaContainer].
///
/// Extensions can create [ChartAreaContainer]s with default or custom layout strategy.
abstract class AdjustableLabelsChartAreaContainer extends ChartAreaContainer implements AdjustableLabels {
  late final strategy.LabelLayoutStrategy _labelLayoutStrategy;

  strategy.LabelLayoutStrategy get labelLayoutStrategy => _labelLayoutStrategy;

  AdjustableLabelsChartAreaContainer({
    required ChartTopContainer chartTopContainer,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  })  : _labelLayoutStrategy = xContainerLabelLayoutStrategy ??
            strategy.DefaultIterativeLabelLayoutStrategy(options: chartTopContainer.data.chartOptions),
        super(
          chartTopContainer: chartTopContainer,
        ) {
    // Must initialize in body, as access to 'this' not available in initializer.
    _labelLayoutStrategy.onContainer(this);
  }
}

/// Base class which manages, lays out, moves, and paints
/// each top level block on the chart. The basic top level chart blocks are:
/// - [ChartTopContainer] - the whole chart
/// - [LegendContainer] - manages the legend
/// - [YContainer] - manages the Y labels layout, which defines:
///   - Y axis label sizes
///   - Y positions of Y axis labels, defined as yTickY.
///     yTicksY s are the Y points of scaled data values
///     and also Y points on which the Y labels are centered.
/// - [XContainer] - Equivalent to YContainer, but manages X direction
///   layout and labels.
/// - [DataContainer] and extensions - manages the area which displays:
///   - Data as bar chart, line chart, or other chart type.
///   - Grid (this includes the X and Y axis).
///
/// See [Container] for discussion of roles of this class.
/// This extension of  [Container] has the added ability
/// to access the container's parent, which is handled by
/// [chartTopContainer].
abstract class ChartAreaContainer extends Container {
  /// The chart top level.
  ///
  /// Departure from a top down approach, this allows to
  /// access the parent [ChartTopContainer], which has (currently)
  /// members needed by children.
  final ChartTopContainer chartTopContainer;

  ChartAreaContainer({
    required this.chartTopContainer,
  }) : super();
}

/// Manages the core chart area which displays and paints (in this order):
/// - The grid (this includes the X and Y axis).
/// - Data - as columns of bar chart, line chart, or other chart type
abstract class DataContainer extends ChartAreaContainer {
  late GridLinesContainer _xGridLinesContainer;
  late GridLinesContainer _yGridLinesContainer;

  /// Columns of presenters.
  ///
  /// Presenters may be:
  /// - points and lines in line chart
  /// - bars (stacked or grouped) in bar chart
  ///
  /// todo 0 replace with getters; see if members can be made private,  manipulated via YLabelContainer.
  late PresentersColumns presentersColumns;

  DataContainer({
    required ChartTopContainer chartTopContainer,
  }) : super(
          chartTopContainer: chartTopContainer,
        );

  /// Implements [Container.layout] for data area.
  ///
  /// Uses all available space in the passed [parentLayoutExpansion],
  /// which it divides between it's children.
  ///
  /// First lays out the Grid, then, based on the available size,
  /// scales the columns to the [YContainer]'s scale.
  @override
  void layout(LayoutExpansion parentLayoutExpansion) {
    layoutSize = ui.Size(parentLayoutExpansion.width, parentLayoutExpansion.height);

    _layoutGrid();

    // Scale the [pointsColumns] to the [YContainer]'s scale.
    scalePointsColumns();
  }

  /// Lays out the grid lines.
  void _layoutGrid() {
    // Vars that layout needs from the [chartTopContainer] passed to constructor
    ChartOptions chartOptions = chartTopContainer.data.chartOptions;
    bool isStacked = chartTopContainer.isStacked;
    double xGridStep = chartTopContainer.xContainer.xGridStep;
    List<double> xTickXs = chartTopContainer.xTickXs;
    List<double> yTickYs = chartTopContainer.yTickYs;

    // ### 1. Vertical Grid (yGrid) layout:

    // For each already layed out X labels in [xLabelContainers],
    // create one [LineContainer] and add it to [yGridLinesContainer]

    _yGridLinesContainer = GridLinesContainer();

    for (double xTickX in xTickXs) {
      // Add vertical yGrid line in the middle or on the left
      double lineX = isStacked ? xTickX - xGridStep / 2 : xTickX;

      LineContainer yLineContainer = LineContainer(
        lineFrom: ui.Offset(lineX, 0.0),
        lineTo: ui.Offset(lineX, layoutSize.height),
        linePaint: gridLinesPaint(chartOptions),
      );

      // Add a new vertical grid line - yGrid line.
      _yGridLinesContainer.addLine(yLineContainer);
    }

    // For stacked, we need to add last right vertical yGrid line
    if (isStacked && xTickXs.isNotEmpty) {
      double x = xTickXs.last + xGridStep / 2;
      LineContainer yLineContainer = LineContainer(
        lineFrom: ui.Offset(x, 0.0),
        lineTo: ui.Offset(x, layoutSize.height),
        linePaint: gridLinesPaint(chartOptions),
      );
      _yGridLinesContainer.addLine(yLineContainer);
    }

    // ### 2. Horizontal Grid (xGrid) layout:

    // Iterate yUserLabels and for each add a horizontal grid line
    // When iterating Y labels, also create the horizontal lines - xGridLines
    _xGridLinesContainer = GridLinesContainer();

    // Position the horizontal xGrid at mid-points of labels at yTickY.
    for (double yTickY in yTickYs) {
      LineContainer xLineContainer = LineContainer(
          lineFrom: ui.Offset(0.0, yTickY),
          lineTo: ui.Offset(layoutSize.width, yTickY),
          linePaint: gridLinesPaint(chartOptions));

      // Add a new horizontal grid line - xGrid line.
      _xGridLinesContainer._lineContainers.add(xLineContainer);
    }
  }

  @override
  void applyParentOffset(ui.Offset offset) {
    super.applyParentOffset(offset);

    // Move all container atomic elements - lines, labels, circles etc
    _xGridLinesContainer.applyParentOffset(offset);

    // draw vertical grid
    _yGridLinesContainer.applyParentOffset(offset);

    // Apply offset to lines and bars.
    chartTopContainer.pointsColumns.applyParentOffset(offset);

    // Any time offset of [_chartContainer.pointsColumns] has changed,
    //   we have to recreate the absolute positions
    //   of where to draw data points, data lines and data bars.
    // todo-01-morph-important : problem : this call actually sets absolute values on Presenters !!
    setupPresentersColumns();
  }

  /// Paints the Grid lines of the chart area.
  ///
  /// Note that the super [paint] remains not implemented in this class.
  /// Superclasses (for example the line chart data container) should
  /// call this method at the beginning of it's [paint] implementation,
  /// followed by painting the [Presenter]s in [_drawDataPresentersColumns].
  ///
  void _paintGridLines(ui.Canvas canvas) {
    // draw horizontal grid
    _xGridLinesContainer.paint(canvas);

    // draw vertical grid
    if (chartTopContainer.data.chartOptions.yContainerOptions.isYGridlinesShown) {
      _yGridLinesContainer.paint(canvas);
    }
  }

  // ##### Scaling and layout methods of [_chartContainer.pointsColumns]
  //       and [presentersColumns]

  /// Scales all data stored in leafs of columns and rows
  /// as [StackableValuePoint]. Depending on whether we are layouting
  /// a stacked or unstacked chart, scaling is done on stacked or unstacked
  /// values.
  ///
  /// Must be called before [setupPresentersColumns] as [setupPresentersColumns]
  /// uses the  absolute scaled [chartTopContainer.pointsColumns].
  void scalePointsColumns() {
    chartTopContainer.pointsColumns.scale();
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
    presentersColumns = PresentersColumns(
      pointsColumns: chartTopContainer.pointsColumns,
      chartTopContainer: chartTopContainer,
      presenterCreator: chartTopContainer.presenterCreator,
    );
  }

  /// Optionally paint series in reverse order (first to last,
  /// vs last to first which is default).
  ///
  /// See [DataContainerOptions.dataRowsPaintingOrder].
  List<Presenter> optionalPaintOrderReverse(List<Presenter> presenters) {
    var options = chartTopContainer.data.chartOptions;
    if (options.dataContainerOptions.dataRowsPaintingOrder == DataRowsPaintingOrder.firstToLast) {
      presenters = presenters.reversed.toList();
    }
    return presenters;
  }

  void _drawDataPresentersColumns(ui.Canvas canvas);
}

/// Provides the data area container for the bar chart.
///
/// The only role is to implement the abstract method of the baseclass,
/// [paint] and [_drawDataPresentersColumns].
class VerticalBarChartDataContainer extends DataContainer {
  VerticalBarChartDataContainer({
    required ChartTopContainer chartTopContainer,
  }) : super(
          chartTopContainer: chartTopContainer,
        );

  @override
  void paint(ui.Canvas canvas) {
    _paintGridLines(canvas);
    _drawDataPresentersColumns(canvas);
  }

  /// Draws the actual atomic visual elements representing data on the chart.
  ///
  /// The atomic visual elements are either  lines with points (on the line chart),
  /// or bars/columns, stacked or grouped (on the bar/column charts).
  @override
  void _drawDataPresentersColumns(ui.Canvas canvas) {
    PresentersColumns presentersColumns = this.presentersColumns;

    for (PresentersColumn presentersColumn in presentersColumns) {
      // todo-2 do not repeat loop, collapse to one construct

      var positivePresenterList = presentersColumn.positivePresenters;
      positivePresenterList = optionalPaintOrderReverse(positivePresenterList);
      for (Presenter presenter in positivePresenterList) {
        bar_presenters.VerticalBarPresenter presenterCast = presenter as bar_presenters.VerticalBarPresenter;
        canvas.drawRect(
          presenterCast.presentedRect,
          presenterCast.dataRowPaint,
        );
      }

      var negativePresenterList = presentersColumn.negativePresenters;
      negativePresenterList = optionalPaintOrderReverse(negativePresenterList);
      for (Presenter presenter in negativePresenterList) {
        bar_presenters.VerticalBarPresenter presenterCast = presenter as bar_presenters.VerticalBarPresenter;
        canvas.drawRect(
          presenterCast.presentedRect,
          presenterCast.dataRowPaint,
        );
      }
    }
  }
}

/// Provides the data area container for the line chart.
///
/// The only role is to implement the abstract method of the baseclass,
/// [paint] and [drawDataPresentersColumns].
class LineChartDataContainer extends DataContainer {
  LineChartDataContainer({
    required ChartTopContainer chartTopContainer,
  }) : super(
          chartTopContainer: chartTopContainer,
        );

  @override
  void paint(ui.Canvas canvas) {
    _paintGridLines(canvas);
    _drawDataPresentersColumns(canvas);
  }

  /// Draws the actual atomic visual elements representing data on the chart.
  ///
  /// The atomic visual elements are either  lines with points (on the line chart),
  /// or bars/columns, stacked or grouped (on the bar/column charts).
  @override
  void _drawDataPresentersColumns(ui.Canvas canvas) {
    var presentersColumns = this.presentersColumns;
    for (PresentersColumn presentersColumn in presentersColumns) {
      var presenterList = presentersColumn.presenters;
      presenterList = optionalPaintOrderReverse(presenterList);
      for (Presenter presenter in presenterList) {
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
      }
    }
  }
}

///
class GridLinesContainer extends Container {
  final List<LineContainer> _lineContainers = List.empty(growable: true);

  GridLinesContainer() : super();

  void addLine(LineContainer lineContainer) {
    _lineContainers.add(lineContainer);
  }

  /// Implements the abstract [Container.layout].
  @override
  void layout(LayoutExpansion parentLayoutExpansion) {
    for (LineContainer lineContainer in _lineContainers) {
      lineContainer.layout(parentLayoutExpansion);
    }
  }

  /// Overridden from super. Applies offset on all members.
  @override
  void applyParentOffset(ui.Offset offset) {
    for (LineContainer lineContainer in _lineContainers) {
      lineContainer.applyParentOffset(offset);
    }
  }

  /// Implements the abstract [Container.layout].
  @override
  void paint(ui.Canvas canvas) {
    for (LineContainer lineContainer in _lineContainers) {
      lineContainer.paint(canvas);
    }
  }

  /// Implementor of method in superclass [Container].
  ///
  /// Return the size of the outermost rectangle which contains all lines
  ///   in the member _xLineContainers.
  // ui.Size get layoutSize => _xLineContainers.reduce((lineContainer.+));
  // todo-01 look into this
  @override
  ui.Size get layoutSize => throw StateError('todo-2 implement this.');
}

/// Represents one layed out item of the legend:  The rectangle for the color
/// indicator, [_indicatorRect], followed by the series label text.
// todo-01-morph : should this extend ChartAreaContainer?
class LegendItemContainer extends Container {
  /// Container of label
  late LabelContainer _labelContainer;

  /// Rectangle of the legend color square series indicator
  late ui.Rect _indicatorRect;

  /// Paint used to paint the indicator
  final ui.Paint _indicatorPaint;

  final ChartOptions _options;

  final LabelStyle _labelStyle;
  final String _label;

  LegendItemContainer({
    required String label,
    required LabelStyle labelStyle,
    required ui.Paint indicatorPaint,
    required ChartOptions options,
  })  :
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

  @override
  void layout(LayoutExpansion parentLayoutExpansion) {
    // Save a few repeated values, calculated the width given to LabelContainer,
    //   and create the LabelContainer.
    double indicatorSquareSide = _options.legendOptions.legendColorIndicatorWidth;
    double indicatorToLabelPad = _options.legendOptions.legendItemIndicatorToLabelPad;
    double betweenLegendItemsPadding = _options.legendOptions.betweenLegendItemsPadding;
    double labelMaxWidth =
        parentLayoutExpansion.width - (indicatorSquareSide + indicatorToLabelPad + betweenLegendItemsPadding);
    if (enableSkipOnDistressedSize && labelMaxWidth <= 0.0) {
      isDistressed = true;
      layoutSize = ui.Size.zero;
      return;
    }
    _labelContainer = LabelContainer(
      label: _label,
      labelMaxWidth: labelMaxWidth,
      labelTiltMatrix: vector_math.Matrix2.identity(), // No tilted labels in LegendItemContainer
      labelStyle: _labelStyle,
    );
    _labelContainer.layout(LayoutExpansion.unused());

    // Layout legend item elements (indicator, pad, label) flowing from left:

    // 1. layout the _labelContainer - this also provides height
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
    _labelContainer.applyParentOffset(ui.Offset(
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
  @override
  void paint(ui.Canvas canvas) {
    if (isDistressed) return; // todo-10 this should not be, only if distress actually happens

    _labelContainer.paint(canvas);
    canvas.drawRect(
      _indicatorRect,
      _indicatorPaint,
    );
  }

  @override
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
    required ChartTopContainer chartTopContainer,
  }) : super(
          chartTopContainer: chartTopContainer,
        );

  /// Lays out the legend area.
  ///
  /// Evenly divides the [availableWidth] to all legend items.
  @override
  void layout(LayoutExpansion parentLayoutExpansion) {
    if (!chartTopContainer.data.chartOptions.legendOptions.isLegendContainerShown) {
      return;
    }
    ChartOptions options = chartTopContainer.data.chartOptions;
    double containerMarginTB = options.legendOptions.legendContainerMarginTB;
    double containerMarginLR = options.legendOptions.legendContainerMarginLR;

    List<String> dataRowsLegends = chartTopContainer.data.dataRowsLegends;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
      textStyle: options.labelCommonOptions.labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.legendOptions.legendTextAlign, // keep left, close to indicator
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );

    // First paint all legends, to figure out max height of legends to center all
    // legends label around common center.

    double legendItemWidth = (parentLayoutExpansion.width - 2.0 * containerMarginLR) / dataRowsLegends.length;

    _legendItemContainers = List<LegendItemContainer>.empty(growable: true);

    // Layout legend core: for each row, create and position
    //   - an indicator rectangle and it's paint
    //   - label painter
    for (int index = 0; index < dataRowsLegends.length; index++) {
      ui.Paint indicatorPaint = ui.Paint();
      List<ui.Color> dataRowsColors = chartTopContainer.data.dataRowsColors; //!;
      indicatorPaint.color = dataRowsColors[index % dataRowsColors.length];

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

  @override
  void applyParentOffset(ui.Offset offset) {
    if (!chartTopContainer.data.chartOptions.legendOptions.isLegendContainerShown) {
      return;
    }
    // super not really needed - only child containers are offset.
    super.applyParentOffset(offset);

    for (LegendItemContainer legendItemContainer in _legendItemContainers) {
      legendItemContainer.applyParentOffset(offset);
    }
  }

  @override
  void paint(ui.Canvas canvas) {
    if (!chartTopContainer.data.chartOptions.legendOptions.isLegendContainerShown) {
      return;
    }
    for (LegendItemContainer legendItemContainer in _legendItemContainers) {
      legendItemContainer.paint(canvas);
    }
  }
}

// todo-01 Try to make members final and private and class immutable
/// Represents one Y numeric value in the [ChartData.dataRows],
/// with added information about the X coordinate (display coordinate).
///
/// Instances are stacked if [isStacked] is true.
///
/// The members can be grouped in three groups.
///
/// 1. The [xLabel], [dataRowIndex] and [predecessorPoint] are initial variables along with [dataY].
///
/// 2. The [fromY] and [toY] and [dataY] are data-values representing this point's numeric value.
///   *This group's members do NOT change under [applyParentOffset] as they represent data, not coordinates;*
///   they must not change with container (display) size change.
///   - In addition, the [fromY] and [toY] are stacked, [dataY] is NOT stacked. Stacking is achieved by adding
///   the values of [dataY] from the bottom of the stacked values to this point,
///   by calling the [stackOnAnother] method.
///
/// 3. The [scaledX], [scaledY], [scaledFromY], [scaledToY], are scaled-coordinates -
///   represent members from group 2, scaled to the container coordinates (display coordinates).
///   *This group's members DO change under [applyParentOffset] as they represent coordinates.*
///   - The [scaledY], [scaledFromY], [scaledToY] are converted from the stacked data values [dataY], [fromY] and [toY].
///   - The [scaledX] is not converted from any data value (does not represent any data value).
///   - The [scaledFrom] and [scaledTo] are [ui.Offset] wrappers for [scaledX], [scaledFromY], [scaledToY].
///
/// Stacking management:
/// - This object does not manage it's stacking,
///   stacking is delegated to the container that manages this object along with
///   values before (below) and after (above). The managing object is [PointsColumn].
class StackableValuePoint {
  // ### 1. Group 1, initial values, but also includes [dataY] in group 2
  String xLabel;

  /// The transformed but NOT stacked Y data value.
  /// **ANY [dataYs] are 1. transformed, then 2. potentially stacked IN PLACE, then 3. potentially scaled IN A COPY!!**
  double dataY;

  /// The index of this point in the [PointsColumn] containing this point in it's
  /// [PointsColumn.stackableValuePoints] list.
  int dataRowIndex; // series index
  /// The predecessor point in the [PointsColumn] containing this point in it's [PointsColumn.stackableValuePoints] list.
  StackableValuePoint? predecessorPoint;

  /// True if data are stacked.
  bool isStacked = false;

  // ### 2. Group 2, are data-values representing this point's numeric value.
  /// The stacked-data-value where this point's Y value starts.
  /// Created, along with [toY] as follows:
  /// ```dart
  ///    fromY = predecessorPoint != null ? predecessorPoint!.toY : 0.0;
  ///     toY = fromY + dataY;
  /// ```
  /// This value is NOT coordinate based, so [applyParentOffset] is never applied to it.
  double fromY;

  /// The stacked-data-value where this point's Y value ends.
  /// See [fromY] for details.
  double toY;

  // ### 3. Group 3, are the scaled-coordinates - copy-converted from members from group 2,
  //        by scaling group 2 members to the container coordinates (display coordinates)

  /// The position in the topContainer, through the PointsColumns hierarchy.
  /// Not actually scaled (because it does not represent any X data), just
  /// always moved by offsetting by [applyParentOffset].
  double scaledX = 0.0;

  /// The position in the topContainer, representing the scaled value of [dataY].
  /// Initially scaled to available pixels on the Y axis,
  /// then moved by offsetting by [applyParentOffset].
  double scaledY = 0.0;

  /// The position in the top container, representing the scaled value of [fromY].
  /// Initially created as `yLabelsCreator.scaleY(value: fromY)`,
  /// then moved by offsetting by [applyParentOffset].
  double scaledFromY = 0.0;

  /// The position in the top container, representing the scaled value of [toY].
  /// Initially created as `yAxisdY = yLabelsCreator.scaleY(value: toY);`,
  /// then moved by offsetting by [applyParentOffset].
  double scaledToY = 0.0;

  /// The [scaledFrom] and [scaledTo] are the scaled Offsets for painting in absolute chart coordinates.
  /// More precisely, offsets of the bottom and top of the presenter of this
  /// point - for example, for VerticalBar, bottom left and top right of each bar
  /// representing this value point (data point).
  /// Wrapper for [scaledX], [scaledFromY]
  ui.Offset scaledFrom = ui.Offset.zero;

  /// Wrapper for [scaledX], [scaledToY]
  ui.Offset scaledTo = ui.Offset.zero;

  /// The generative constructor of objects for this class.
  StackableValuePoint({
    required this.xLabel,
    required this.dataY,
    required this.dataRowIndex,
    this.predecessorPoint,
  })  : isStacked = false,
        fromY = 0.0,
        toY = dataY;

  /// Initial instance of a [StackableValuePoint].
  /// Forwarded to the generative constructor.
  /// This should fail if it undergoes any processing such as layout
  StackableValuePoint.initial()
      : this(
          xLabel: 'initial',
          dataY: -1,
          dataRowIndex: -1,
          predecessorPoint: null,
        );

  StackableValuePoint stack() {
    isStacked = true;

    // todo-1 validate: check if both points y have the same sign or both zero
    fromY = predecessorPoint != null ? predecessorPoint!.toY : 0.0;
    toY = fromY + dataY;

    return this;
  }

  /// Stacks this point on top of the passed [predecessorPoint].
  ///
  /// Points are constructed unstacked. Depending on chart type,
  /// a later processing can stack points using this method
  /// (if chart type is [ChartTopContainer.isStacked].
  StackableValuePoint stackOnAnother(StackableValuePoint? predecessorPoint) {
    this.predecessorPoint = predecessorPoint;
    return stack();
  }

  /// Scales this point to the container coordinates (display coordinates).
  ///
  /// More explicitly, scales the data-members of this point to the said coordinates.
  ///
  /// See class documentation for which members are data-members and which are scaled-members.
  ///
  /// Note that the x values are not really scaled, as object does not
  /// manage the unscaled [x] (it manages the corresponding label only).
  /// For this reason, the [scaledX] value must be provided explicitly.
  /// The provided [scaledX] value should be the
  /// "within [ChartPainter] absolute" x coordinate (generally the center
  /// of the corresponding x label).
  ///
  // todo-01-morph : Calling this 'scale' is suspect - this does not do any X dimension scaling at all!
  //                Analyze the uses of the 'scale' term in the system, probably needs improvement.
  StackableValuePoint scale({
    required double scaledX,
    required YLabelsCreatorAndPositioner yLabelsCreator,
  }) {
    this.scaledX = scaledX;
    scaledY = yLabelsCreator.scaleY(value: dataY);
    scaledFromY = yLabelsCreator.scaleY(value: fromY);
    scaledToY = yLabelsCreator.scaleY(value: toY);
    // todo-01-morph : Can we remove scaledX, scaledFromY, scaledX, scaledToY and only maintain these offsets???
    scaledFrom = ui.Offset(scaledX, scaledFromY);
    scaledTo = ui.Offset(scaledX, scaledToY);

    return this;
  }

  void applyParentOffset(ui.Offset offset) {
    // only apply  offset on scaled values, those have chart coordinates that are painted.

    // not needed to offset : StackableValuePoint predecessorPoint;

    /// Scaled values represent screen coordinates, apply offset to all.
    scaledX += offset.dx;
    scaledY += offset.dy;
    scaledFromY += offset.dy;
    scaledToY += offset.dy;

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
        xLabel: xLabel, dataY: dataY, dataRowIndex: dataRowIndex, predecessorPoint: predecessorPoint);

    // numbers and Strings, being immutable, can be just assigned.
    // rest of objects (ui.Offset) must be created from immutable leafs.
    clone.xLabel = xLabel;
    clone.dataY = dataY;
    clone.predecessorPoint = null;
    clone.dataRowIndex = dataRowIndex;
    clone.isStacked = false;
    clone.fromY = fromY;
    clone.toY = toY;
    clone.scaledX = scaledX;
    clone.scaledY = scaledY;
    clone.scaledFromY = scaledFromY;
    clone.scaledToY = scaledToY;
    clone.scaledFrom = ui.Offset(scaledFrom.dx, scaledFrom.dy);
    clone.scaledTo = ui.Offset(scaledTo.dx, scaledTo.dy);

    return clone;
  }
}

/// Represents a column of [StackableValuePoint]s, with support for both stacked and non-stacked charts.
///
/// Corresponds to one column of data from [ChartData.dataRows], ready for presentation by [Presenter]s.
///
/// The
/// - unstacked (such as in the line chart),  in which case it manages
///   [stackableValuePoints] that have values from [ChartData.dataRows].
/// - stacked (such as in the bar chart), in which case it manages
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

  /// Construct column from the passed [points].
  ///
  /// Passed points are assumed to:
  /// - Be configured with appropriate [predecessorPoint]
  /// - Not stacked
  /// Creates members [stackedNegativePoints], [stackedPositivePoints]
  /// which exist only to be stacked, so the constructor stacks them
  /// on creation.
  PointsColumn({
    required List<StackableValuePoint> points,
  }) {
    // todo-1 add validation that points are not stacked
    stackableValuePoints = points;

    stackedPositivePoints =
        _selectThenCollectStacked(points: stackableValuePoints, selector: (point) => point.dataY >= 0);
    stackedNegativePoints =
        _selectThenCollectStacked(points: stackableValuePoints, selector: (point) => point.dataY < 0);
  }

  //// points are ordered in series order, first to last  (bottom to top),
  //// and maintain their 0 based row (series) index
  List<StackableValuePoint> _selectThenCollectStacked({
    required List<StackableValuePoint> points,
    required bool Function(StackableValuePoint point) selector,
  }) {
    StackableValuePoint? predecessorPoint;
    List<StackableValuePoint> selected = stackableValuePoints.where((point) {
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
    return [
      ...stackableValuePoints,
      ...stackedNegativePoints,
      ...stackedPositivePoints,
    ];
  }
}

/// A list of [PointsColumn] instances, created from user data rows [ChartData.dataRows].
///
/// Represents the chart data created from the [ChartData.dataRows], but is an internal format suitable for
/// presenting by the chart [Presenter] instances.
///
/// Passed to the [Presenter] instances, which use this instance's data to
/// paint the values in areas above the labels in the appropriate presentation (point and line chart, column chart, etc).
///
/// Manages value point structure as column based (currently supported) or row based (not supported).
///
/// A (single instance per chart) is used to create a [PresentersColumns] instance, managed in the [DataContainer].
class PointsColumns extends custom_collection.CustomList<PointsColumn> {
  /// Parent chart container.
  final ChartTopContainer chartTopContainer;

  /// True if chart type presents values stacked.
  final bool _isStacked;

  /// Constructor creates a [PointsColumns] instance from [ChartData.dataRows] values in
  /// the passed [ChartTopContainer.data].
  PointsColumns({
    required this.chartTopContainer,
    required PresenterCreator presenterCreator,
    required bool isStacked,
  }) : _isStacked = isStacked {
    ChartData chartData = chartTopContainer.data;

    _createStackableValuePointsFromChartData(chartData);
  }

  // todo-01-morph : Create this object, PointsColumns here and return. Maybe this should be converted to factory constructor?
  //                 Also, this class PointsColumns is a list, why do we need the nextRightPointsColumn at all???
  /// Constructs internals of this object, the [PointsColumns].
  ///
  /// Transposes data passed as rows in [chartData.dataRows]
  /// to [_valuePointArrInRows] and to [_valuePointArrInColumns].
  ///
  /// Creates links on "this column" to "successor in stack on the right",
  /// managed in [PointsColumn.nextRightPointsColumn].
  ///
  /// Each element is the per column point below the currently processed point.
  /// The currently processed point is (potentially) stacked on it's predecessor.
  void _createStackableValuePointsFromChartData(ChartData chartData) {
    List<StackableValuePoint?> rowOfPredecessorPoints =
        List.filled(chartData.dataRows[0].length, null); // todo 0 deal with no data rows
    for (int col = 0; col < chartData.dataRows[0].length; col++) {
      rowOfPredecessorPoints[col] = null; // new StackableValuePoint.initial(); // was:null
    }

    // Data points managed row.  Internal only, should be refactored away.
    List<List<StackableValuePoint>> valuePointArrInRows = List.empty(growable: true);

    for (int row = 0; row < chartData.dataRows.length; row++) {
      List<num> dataRow = chartData.dataRows[row];
      List<StackableValuePoint> pointsRow = List<StackableValuePoint>.empty(growable: true);
      valuePointArrInRows.add(pointsRow);
      for (int col = 0; col < dataRow.length; col++) {
        // yTransform data before placing data point on StackableValuePoint.
        num colValue = chartTopContainer.data.chartOptions.dataContainerOptions.yTransform(dataRow[col]);

        // Create all points unstacked. A later processing can stack them,
        // depending on chart type. See [StackableValuePoint.stackOnAnother]
        var thisPoint = StackableValuePoint(
            xLabel: 'initial', // todo-01-morph : xLabel: null : consider
            dataY: colValue.toDouble(),
            dataRowIndex: row,
            predecessorPoint: rowOfPredecessorPoints[col]);

        pointsRow.add(thisPoint); // Grow the row with thisPoint
        rowOfPredecessorPoints[col] = thisPoint;
      }
    }
    valuePointArrInRows.toList();

    // Data points managed column. Internal only, should be refactored away.
    List<List<StackableValuePoint>> valuePointArrInColumns = transpose(valuePointArrInRows);

    // convert "column oriented" _valuePointArrInColumns
    // to a column, and add the columns to this instance
    PointsColumn? leftColumn;

    for (List<StackableValuePoint> columnPoints in valuePointArrInColumns) {
      var pointsColumn = PointsColumn(points: columnPoints);
      add(pointsColumn);
      leftColumn?.nextRightPointsColumn = pointsColumn;
      leftColumn = pointsColumn;
    }
  }

  /// Scales this object's column values managed in [pointsColumns].
  ///
  /// This allows separation of creating this object with
  /// the original, unscaled data points, and apply scaling later
  /// on the stackable (stacked or unstacked) values.
  ///
  /// Notes:
  /// - Iterates this object's internal list of [PointsColumn], then the contained
  ///   [PointsColumn.stackableValuePoints], and scales each point by
  ///   applying its [StackableValuePoint.scale] method.
  /// - No scaling of the internal representation stored in [_valuePointArrInRows]
  ///   or [_valuePointArrInColumns].
  void scale() {
    int col = 0;
    for (PointsColumn column in this) {
      column.allPoints().forEach((StackableValuePoint point) {
        double scaledX = chartTopContainer.xTickXs[col];
        point.scale(scaledX: scaledX, yLabelsCreator: chartTopContainer.yLabelsCreator);
      });
      col++;
    }
  }

  void applyParentOffset(ui.Offset offset) {
    for (PointsColumn column in this) {
      column.allPoints().forEach((StackableValuePoint point) {
        point.applyParentOffset(offset);
      });
    }
  }

  List<double> flattenPointsValues() {
    if (_isStacked) return flattenStackedPointsDataYs();

    return flattenUnstackedPointsDataYs();
  }

  /// Flattens values of all unstacked data points.
  ///
  /// Use in containers for unstacked charts (e.g. line chart)
  List<double> flattenUnstackedPointsDataYs() {
    // todo 1 replace with expand like in: dataRows.expand((i) => i).toList()
    List<double> flat = [];
    for (PointsColumn column in this) {
      for (StackableValuePoint point in column.stackableValuePoints) {
        flat.add(point.toY);
      }
    }
    return flat;
  }

  /// Flattens values of all stacked data points.
  ///
  /// Use in containers for stacked charts (e.g. VerticalBar chart)
  List<double> flattenStackedPointsDataYs() {
    List<double> flat = [];
    for (PointsColumn column in this) {
      for (StackableValuePoint point in column.stackedNegativePoints) {
        flat.add(point.toY);
      }
      for (StackableValuePoint point in column.stackedPositivePoints) {
        flat.add(point.toY);
      }
    }
    return flat;
  }
}

// todo-01: In null safety, I had to replace T with a concrete StackableValuePoint.
//               can this be improved? This need may be a typing bug in Dart
/// Assuming even length 2D matrix [colsRows], return it's transpose copy.
List<List<StackableValuePoint>> transpose(List<List<StackableValuePoint>> colsInRows) {
  int nRows = colsInRows.length;
  if (colsInRows.isEmpty) return colsInRows;

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
