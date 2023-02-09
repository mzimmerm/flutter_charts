import 'dart:ui' as ui show Size, Offset, Rect, Paint, Canvas;
import 'dart:math' as math show max;
import 'package:flutter_charts/flutter_charts.dart';
import 'package:flutter_charts/src/chart/container_alignment.dart';
import 'package:flutter_charts/src/chart/container_edge_padding.dart';
import 'package:flutter_charts/src/chart/painter.dart';
import 'package:vector_math/vector_math.dart' as vector_math show Matrix2;
import 'package:flutter/widgets.dart' as widgets show TextStyle;

import '../container/container_key.dart';
import '../morphic/rendering/constraints.dart' show BoxContainerConstraints;
import '../util/collection.dart' as custom_collection show CustomList;
import '../chart/layouter_one_dimensional.dart';
import 'bar/presenter.dart' as bar_presenters; // or import 'package:flutter_charts/src/chart/bar/presenter.dart';
import 'iterative_layout_strategy.dart' as strategy;
import 'line_container.dart';
import 'line/presenter.dart' as line_presenters;
import 'presenter.dart';

import 'container_layouter_base.dart'
    show BoxContainer, BoxLayouter,
    BuilderOfChildrenDuringParentLayout,
    LayoutableBox, Column, Row, Greedy, Padder, Aligner,
    ConstraintsWeight;

import 'new_data_container.dart';
import 'package:flutter_charts/src/chart/model/new_data_model.dart';


/// Base class for classes that hold [chartData], [xContainerLabelLayoutStrategy], [isStacked],
/// members needed for late creation of the root of the chart container hierarchy, the [chartRootContainer].
///
/// [ChartAnchor] is not a [BoxContainer], it provides a 'link' between [FlutterChartPainter] which [paint] method
/// is called by the Flutter framework, and the root of the chart container hierarchy, the [chartRootContainer].
///
/// Core methods of [ChartAnchor] are
///   - [chartRootContainerCreateBuildLayoutPaint], which should be called in [FlutterChartPainter.paint];
///     this method creates, builds, lays out, and paints
///     the root of the chart container hierarchy, the [chartRootContainer].
///   - abstract [createRootContainer]; extensions of [ChartAnchor] (for example, [LineChartAnchor]) should create
///     and return an instance of the concrete [chartRootContainer] (for example [LineChartRootContainer]).
abstract class ChartAnchor {

  ChartAnchor({
    required this.chartData,
    this.isStacked = false,
    this.xContainerLabelLayoutStrategy,
  }) {
    print('Constructing ChartAnchor');
  }

  /// ChartData to hold on before member [chartRootContainer] is created late.
  ///
  /// After [chartRootContainer] is created and set, This [NewDataModel] type member [chartData]
  /// should be placed on the member [ChartRootContainer.data].
  NewDataModel chartData;
  strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy;
  bool isStacked = false;
  late ChartRootContainer chartRootContainer;
  // Keep track of first run.
  bool _isFirst = true;

  /// Extensions of this [ChartAnchor] (for example, [LineChartAnchor]) should
  /// create and return an instance of the concrete [chartRootContainer]
  /// (for example [LineChartRootContainer]), populated with it's children, but not
  /// children's children. The children's children hierarchy is assumed to
  /// be created in [chartRootContainerCreateBuildLayoutPaint] during
  /// it's call to [ChartRootContainer.layout].
  ///
  /// In the default implementations, the [chartRootContainer]'s children created are
  /// [ChartRootContainer.legendContainer],  [ChartRootContainer.yContainer],
  ///  [ChartRootContainer.xContainer], and  [ChartRootContainer.dataContainer].
  ///
  /// If an extension uses an implementation that does not adhere to the above
  /// description, the [ChartRootContainer.layout] should be overridden.
  ///
  /// Important notes:
  ///   - This controller (Anchor) can access both on ChartRootContainer and NewDataModel.
  //    - NewDataModel has ChartOptions
  ChartRootContainer createRootContainer({required ChartAnchor chartAnchor});

  void chartRootContainerCreateBuildLayoutPaint(ui.Canvas canvas, ui.Size size) {
    // Create the concrete [ChartRootContainer] for this concrete [ChartAnchor].
    // After this invocation, the created root container is populated with children
    // XContainer, YContainer, DataContainer and LegendContainer. Their children are partly populated,
    // depending on the concrete container. For example YContainer is populated with DataRangeLabelsGenerator.
    String isFirstStr = _debugPrintBegin();
    chartRootContainer = createRootContainer(chartAnchor: this); // also link from this Anchor to ChartRootContainer.

    // Only set `chartData.chartAnchor = this` ONCE. Reason: member chartData is created ONCE, same as this ANCHOR.
    // To have chartData late final, we have to keep track to only initialize chartData.chartAnchor = this on first run.
    if (_isFirst) {
      _isFirst = false;
      chartData.chartAnchor = this; // Because Data is created first, set self anchor late
    }

    // e.g. set background: canvas.drawPaint(ui.Paint()..color = material.Colors.green);

    // Apply constraints on root. Layout size and constraint size of the [ChartRootContainer] are the same, and
    // are equal to the full 'size' passed here from the framework via [FlutterChartPainter.paint].
    // This passed 'size' is guaranteed to be the same area on which the painter will paint.

    chartRootContainer.applyParentConstraints(
      chartRootContainer,
      BoxContainerConstraints.insideBox(
        size: ui.Size(
          size.width,
          size.height,
        ),
      ),
    );

    chartRootContainer.layout();

    chartRootContainer.paint(canvas);

    _debugPrintEnd(isFirstStr);
  }

  String _debugPrintBegin() {
    String isFirstStr = _isFirst ? '=== IS FIRST ===' : '=== IS SECOND ===';
    print('    ========== In $runtimeType.chartRootContainerCreateBuildLayoutPaint BEGIN BEGIN BEGIN, $isFirstStr');
    return isFirstStr;
  }

  void _debugPrintEnd(String isFirstStr) {
    print('    ========== In $runtimeType.chartRootContainerCreateBuildLayoutPaint END END END, $isFirstStr');
  }

}


/// The behavior mixin allows to plug in to the [ChartRootContainer] a behavior that is specific for a line chart
/// or vertical bar chart.
///
/// The behavior is plugged in the container, not the container owner chart.
abstract class ChartBehavior {
  /// Behavior allows to start Y axis at data minimum (rather than 0).
  ///
  /// The request is asked by [DataContainerOptions.extendAxisToOriginRequested],
  /// but the implementation of this behavior must confirm it.
  /// See the extensions of this class for overrides of this method.
  ///
  /// [ChartBehavior] is mixed in to [ChartRootContainer]. This method
  /// is implemented by concrete [LineChartRootContainer] and [VerticalBarChartRootContainer].
  /// - In the stacked containers, such as [VerticalBarChartRootContainer], it should return [false],
  ///   as stacked values should always start at zero, because stacked charts must show absolute values.
  ///   See [VerticalBarChartRootContainer.extendAxisToOrigin].
  /// - In the unstacked containers such as  [LineChartRootContainer], this is usually implemented to
  ///   return the option [DataContainerOptions.extendAxisToOriginRequested],
  ///   see [LineChartRootContainer.extendAxisToOrigin].
  ///
  bool get extendAxisToOrigin;
}

/// Abstract class representing the root [BoxContainer] of the whole chart.
///
/// Concrete [ChartRootContainer] instance is created new on every [FlutterChartPainter.paint] invocation
/// in the [ChartAnchor.chartRootContainerCreateBuildLayoutPaint]. Note that [ChartAnchor]
/// instance is created only once per chart, NOT recreated on every [FlutterChartPainter.paint] invocation.
///
/// Child containers calculate coordinates of chart points
/// used for painting grid, labels, chart points etc.
///
/// The lifecycle of [ChartRootContainer] follows the lifecycle of any [BoxContainer], the sequence of
/// method invocations should be as follows:
///   - todo-doc-01 : document here and in [BoxContainer]

abstract class ChartRootContainer extends BoxContainer with ChartBehavior {

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
  ChartRootContainer({
    required this.chartAnchor,
    required NewDataModel chartData,
    required this.isStacked,
    // List<BoxContainer>? children, // could add for extensibility by e.g. chart description
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  })  : data = chartData,
        _cachedXContainerLabelLayoutStrategy = xContainerLabelLayoutStrategy,
        super() {
    print('    Constructing ChartRootContainer');
    isUseOldDataContainer = const bool.fromEnvironment('USE_OLD_DATA_CONTAINER', defaultValue: true);

    // Create children and attach to self
    addChildren(_createChildrenOfRootContainer());

  }

  final ChartAnchor chartAnchor;

  // switch-from-command-arg : find usages to see where old/new DataContainer differs
  late final bool isUseOldDataContainer;

  /// Override [BoxContainerHierarchy.isRoot] to prevent checking this root container on parent,
  /// which is never set on instances of this [ChartRootContainer].
  @override
  bool get isRoot => true;

  /// Number of columns in the [DataContainer].

  /// Base Areas of chart.
  late BoxContainer legendContainer;
  late XContainer xContainer;
  late YContainer yContainer;
  late DataContainer dataContainer;

  /// Layout strategy for XContainer labels.
  ///
  /// Cached from constructor here, until the late [xContainer] is created.
  final strategy.LabelLayoutStrategy? _cachedXContainerLabelLayoutStrategy;

  /// ##### Abstract methods or subclasses-implemented getters

  /// Makes pointPresenters, the visuals painted on each chart column that
  /// represent data, (points and lines for the line chart,
  /// rectangles for the bar chart, and so on).
  ///
  /// See [PointPresenterCreator] and [PointPresenter] for more details.
  /// todo-04 : There may be a question "why does a container which is a view, need to know about PointPresenter, which is a model, even indirectly"?
  late PointPresenterCreator pointPresenterCreator;

  /// ##### Subclasses - aware members.

  /// Keeps data values grouped in columns.
  ///
  /// This column grouped data instance is managed here in the [ChartRootContainer],
  /// (immediate owner of [YContainer] and [DataContainer])
  /// as their data points are needed both during [YContainer.layout]
  /// to calculate scaling, and also in [DataContainer.layout] to create
  /// [PointPresentersColumns] instance.
  late PointsColumns pointsColumns;

  late bool isStacked;

  NewDataModel data;

  /// Creates child containers for the chart root.
  ///
  /// It creates four chart areas container instances,
  /// and sets them on members
  /// [legendContainer], [xContainer], [yContainer] and [dataContainer], WITHOUT
  /// their children. Their children are created later in this [ChartRootContainer.layout] by calling
  /// the four chart areas containers' [buildAndAddChildren_DuringParentLayout] methods.
  /// The reason for late creation of their children is that number of their children is
  /// only knows after [yContainer] and [xContainer] are layed out (to fit labels).
  ///
  /// The [dataContainer] is created in the overridable [createDataContainer]
  /// which is overridden by extensions to create a line chart or a bar chart.
  ///
  List<BoxContainer> _createChildrenOfRootContainer() {

    // ### 1. construct [PointsColumns] later in [layout]
    // ### 2. Build the LegendContainer where series legend is shown
    legendContainer = LegendContainer(
      chartRootContainer: this,
    );

    // ### 3. No [yContainerFirst] creation or setup needed. All done in [layout]

    // ### 4. XContainer: Create and add

    xContainer = XContainer(
      chartRootContainer: this,
      xContainerLabelLayoutStrategy: _cachedXContainerLabelLayoutStrategy,
    );

    // ### 5. [YContainer]: YContainer create and add.

    yContainer = YContainer(
      chartRootContainer: this,
    );

    // ### 6. [DataContainer]: Construct a concrete (Line, Bar) DataContainer.

    dataContainer = createDataContainer(
      chartRootContainer: this,
    );

    // return the members which will also become [children].
    return [legendContainer, xContainer, yContainer, dataContainer];
  }

  /// Overrides [BoxLayouter.layout] for the chart as a whole.
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
  void layout() {

    // ### 1. Construct early, from dataRows, the [PointsColumns] object, managed
    //        in [ChartRootContainer.pointsColumns], representing list of columns on chart.
    //        First [YContainer] is first to need it, to display and scale y values and
    //        create labels from the stacked points (if chart is stacked).
    /// Create member [pointsColumns] from [data.dataRows].
    // todo-04 : can this be moved to DataContainer.layout?
    pointsColumns = PointsColumns(
      chartRootContainer: this,
      pointPresenterCreator: pointPresenterCreator,
      isStacked: isStacked,
      caller: this,
    );

    // ### 2. Layout the LegendContainer where series legend is shown
    var legendBoxConstraints = BoxContainerConstraints.insideBox(size: ui.Size(
      constraints.width,
      constraints.height,)
    );

    legendContainer.applyParentConstraints(this, legendBoxConstraints);
    legendContainer.layout();

    ui.Size legendContainerSize = legendContainer.layoutSize;
    ui.Offset legendContainerOffset = ui.Offset.zero;
    legendContainer.applyParentOffset(this, legendContainerOffset);

    // ### 3. Layout [yContainerFirst] to get Y container width
    //        that moves [XContainer] and [DataContainer].
    double yContainerHeight = constraints.height - legendContainerSize.height;
    var yContainerFirstBoxConstraints =  BoxContainerConstraints.insideBox(size: ui.Size(
      constraints.width,
      yContainerHeight,
    ));

    var yContainerFirst = YContainer(
      chartRootContainer: this,
      yLabelsMaxHeightFromFirstLayout: 0.0, // not relevant in this first layout
    );

    // Note: yContainerFirst._parent, checked in applyParentConstraints => assertCallerIsParent
    //       is not yet set here, as yContainerFirst never goes through addChildren which sets _parent on children.
    //       so _parent cannot be late final.
    yContainerFirst.applyParentConstraints(this, yContainerFirstBoxConstraints);
    yContainerFirst.buildAndAddChildren_DuringParentLayout(); // sets yContainerAxisPixelsYMin/Max, layout needs to scale labels
    yContainerFirst.layout();

    yContainer._yLabelsMaxHeightFromFirstLayout = yContainerFirst.yLabelsMaxHeight;

    // ### 4. XContainer: Given width of YContainerFirst, constraint, then layout XContainer

    ui.Size yContainerFirstSize = yContainerFirst.layoutSize;

    // xContainer layout width depends on yContainerFirst layout result.  But this dependency can be expressed
    // as a constraint on xContainer, so no need to implement [findSourceContainersReturnLayoutResultsToBuildSelf]
    var xContainerBoxConstraints =  BoxContainerConstraints.insideBox(size: ui.Size(
      constraints.width - yContainerFirstSize.width,
      constraints.height - legendContainerSize.height,
    ));

    xContainer.applyParentConstraints(this, xContainerBoxConstraints);
    xContainer.buildAndAddChildren_DuringParentLayout();
    xContainer.layout();

    // When we got here, xContainer layout is done, so set the late final layoutSize after re-layouts
    xContainer.layoutSize = xContainer.lateReLayoutSize;

    ui.Size xContainerSize = xContainer.layoutSize;
    ui.Offset xContainerOffset = ui.Offset(yContainerFirstSize.width, constraints.height - xContainerSize.height);
    xContainer.applyParentOffset(this, xContainerOffset);

    // ### 5. [YContainer]: The actual YContainer layout is needed, as height constraint for Y container
    //        is only known after XContainer layedout xUserLabels.  YContainer expands down to top of xContainer.
    //        The [yLabelsMaxHeightFromFirstLayout] is used to scale data values to the y axis, and put labels on ticks.

    // yContainer layout height depends on xContainer layout result.  But this dependency can be expressed
    // as a constraint on yContainer, so no need to implement [findSourceContainersReturnLayoutResultsToBuildSelf]
    var yConstraintsHeight = yContainerHeight - xContainerSize.height;
    var yContainerBoxConstraints = BoxContainerConstraints.insideBox(size: ui.Size(
      constraints.width,
      yConstraintsHeight,
    ));

    yContainer.applyParentConstraints(this, yContainerBoxConstraints);
    yContainer.buildAndAddChildren_DuringParentLayout(); // sets yContainerAxisPixelsYMin/Max, layout needs to scale labels
    yContainer.layout();

    var yContainerSize = yContainer.layoutSize;
    // The layout relies on YContainer width first time and second time to be the same, as width
    //    was used as remainder space for XContainer.
    // But height, will NOT be the same, it will be shorter second time.
    assert (yContainerFirstSize.width == yContainerSize.width);
    ui.Offset yContainerOffset = ui.Offset(0.0, legendContainerSize.height);
    yContainer.applyParentOffset(this, yContainerOffset);

    ui.Offset dataContainerOffset;

    // ### 6. Layout the data area, which included the grid
    // by calculating the X and Y positions of grid.
    // This must be done after X and Y are layed out - see xTickXs, yTickYs.
    // The [yContainer] internals and [yContainerSize] are both needed to offset and constraint the [dataContainer].
    BoxContainerConstraints dataContainerBoxConstraints;
    if (isUseOldDataContainer) {
      dataContainerBoxConstraints = BoxContainerConstraints.insideBox(
          size: ui.Size(
            constraints.width - yContainerSize.width,
            constraints.height - (legendContainerSize.height + xContainerSize.height),
          ));
      dataContainerOffset = ui.Offset(yContainerSize.width, legendContainerSize.height);
    } else {
      dataContainerBoxConstraints = BoxContainerConstraints.insideBox(
          size: ui.Size(
            constraints.width - yContainerSize.width,
            yContainer.axisPixelsRange.max - yContainer.axisPixelsRange.min,
          ));
      dataContainerOffset = ui.Offset(yContainerSize.width, legendContainerSize.height + yContainer.axisPixelsRange.min);
    }

    dataContainer.applyParentConstraints(this, dataContainerBoxConstraints);
    dataContainer.buildAndAddChildren_DuringParentLayout();
    dataContainer.layout();
    dataContainer.applyParentOffset(this, dataContainerOffset);
  }

  /// Implements abstract [paint] for the whole chart container hierarchy, the [ChartRootContainer].
  /// Paints the chart on the passed [canvas], limited to the [size] area,
  /// which must be set before invoking this [paint] method.
  ///
  /// Called from the chart's painter baseclass, the [ChartPainter], which
  /// [paint(Canvas, Size)] is guaranteed to be called by the Flutter framework
  /// (see class comment), hence [ChartPainter.paint] starts the chart painting.
  ///
  /// In detail, this method paints all elements of the chart - the legend in [_paintLegend],
  /// the grid in [drawGrid], the x/y labels in [_paintXLabels] and [_paintYLabels],
  /// and the data values, column by column, in [drawDataPointPresentersColumns].
  ///
  /// Before the actual canvas painting, at the beginning of this method,
  /// this class's [layout] is performed, which recursively lays out all member [BoxContainer]s.
  /// Once this top container is layed out, the [paint] is called on all
  /// member [BoxContainer]s ([YContainer],[XContainer] etc),
  /// which recursively paints the leaf [BoxContainer]s lines, rectangles and circles
  /// in their calculated layout positions.
  @override
  void paint(ui.Canvas canvas) {

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

  // Not needed for new layouter, OR for old. Override root of ContainerHierarchy to be self. Override parent to null. Override constraints
  // @override
  // BoxContainer get root => this;
  //
  // @override
  // BoxContainer? get parent => null;
  //
  // @override
  // BoxContainerConstraints get constraints => _beforeNewLayoutConstraints!;


  /// Abstract method constructs and returns the concrete [DataContainer] instance,
  /// for the chart type (line, bar) determined by this concrete [ChartRootContainer].
  DataContainer createDataContainer({
    required ChartRootContainer chartRootContainer,
  });

}

/// Container of the Y axis labels.
///
/// This [ChartAreaContainer] operates as follows:
/// - Vertically available space is all used (filled).
/// - Horizontally available space is used only as much as needed.
/// The used amount is given by maximum Y label width, plus extra spacing.
/// - See [layout] and [layoutSize] for resulting size calculations.
/// - See the [XContainer] constructor for the assumption on [BoxContainerConstraints].

class YContainer extends ChartAreaContainer with BuilderOfChildrenDuringParentLayout {

  /// Constructs the container that holds Y labels.
  ///
  /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
  /// all available vertical space, and only use necessary horizontal space.
  YContainer({
    required ChartRootContainer chartRootContainer,
    double yLabelsMaxHeightFromFirstLayout = 0.0,
  }) : super(
    chartRootContainer: chartRootContainer,
  ) {
    _yLabelsMaxHeightFromFirstLayout = yLabelsMaxHeightFromFirstLayout;

    // [yLabelsGenerator] instance depends on both NewDataModel and ChartRootContainer. We can construct the generator
    // anywhere in [ChartRootContainer] constructor or later.
    // As this [YContainer] constructor is invoked in [ChartRootContainer], this is a good place
    yLabelsGenerator = DataRangeLabelsGenerator(
      extendAxisToOrigin: chartRootContainer.extendAxisToOrigin,
      valueToLabel: chartRootContainer.data.chartOptions.yContainerOptions.valueToLabel,
      inverseTransform: chartRootContainer.data.chartOptions.dataContainerOptions.yInverseTransform,
      userLabels: chartRootContainer.data.yUserLabels,
      dataModel: chartRootContainer.data,
      isStacked: chartRootContainer.isStacked,
    );
    labelInfos = yLabelsGenerator.createLabelInfos();
  }

  /// Late calculated minimum and maximum pixels for the Y axis.
  ///
  /// [axisPixelsRange] does NOT start at zero, it contains the pixels from Y container top
  /// available to Y axis, after a half-label height is excluded on the top,
  /// and a vertical tick height is excluded on the bottom.
  ///
  /// At the same time, the difference between [axisPixelsRange] min and max is the height constraint
  /// on [NewDataContainer].
  ///
  /// Also [axisPixelsRange] is the interval to which the Y data values,
  /// stored in [yLabelsGenerator]'s member [DataRangeLabelsGenerator.dataRange]
  /// should be extrapolated.
  ///
  late final Interval axisPixelsRange;

  /// The generator and holder of labels and range of the Y axis.
  ///
  /// The [yLabelsGenerator]'s interval [DataRangeLabelsGenerator.dataRange]
  /// is the data range corresponding to the Y axis pixel range kept in [axisPixelsRange].
  late DataRangeLabelsGenerator yLabelsGenerator;

  // Describes layout pixel positions, so included in this view [YContainer], rather than model or controller.
  late FormattedLabelInfos labelInfos;

  /// Containers of Y labels.
  late List<YAxisLabelContainer> _yLabelContainers;

  /// Maximum label height found by the first layout (pre-layout),
  /// is ONLY used to 'shorten' YContainer constraints on top.
  double _yLabelsMaxHeightFromFirstLayout = 0.0;

  /// Overridden method creates this [YContainer]'s hierarchy-children Y labels
  /// (instances of [YAxisLabelContainer]) which are managed in this [YContainer._yLabelContainers].
  ///
  /// The reason the hierarchy-children Y labels are created late in this
  /// method [buildAndAddChildren_DuringParentLayout] is that we do not know until the parent
  /// [chartRootContainer] is being layed out, how much Y-space there is, therefore,
  /// how many Y labels would fit.
  ///
  /// The created Y labels should be layed out by invoking [layout]
  /// immediately after this method [buildAndAddChildren_DuringParentLayout]
  /// is invoked.
  @override
  void buildAndAddChildren_DuringParentLayout() {

    // Init the list of y label containers
    _yLabelContainers = [];

    // [_axisYMin] and [_axisYMax] define end points of the Y axis, in the YContainer coordinates.
    // The [_axisYMin] does not start at 0, but leaves space for half label height
    double axisPixelsMin = _yLabelsMaxHeightFromFirstLayout / 2;
    // The [_axisYMax] does not end at the constraint size, but leaves space for a vertical tick
    double axisPixelsMax =
        constraints.size.height - (chartRootContainer.data.chartOptions.xContainerOptions.xBottomMinTicksHeight);

    axisPixelsRange = Interval(axisPixelsMin, axisPixelsMax);

    // We now know how long the Y axis is in pixels,
    // so we can calculate pixel positions on labels in LabeInfos
    labelInfos.layoutByLerpToPixels(
      axisPixelsYMin: axisPixelsRange.min,
      axisPixelsYMax: axisPixelsRange.max,
    );


    // Code above MUST run for the side-effects of setting [axisPixels] and scaling the [labelInfos].
    // Now can check if labels are shown, set empty children and return.
    if (!chartRootContainer.data.chartOptions.yContainerOptions.isYContainerShown) {
      _yLabelContainers = List.empty(growable: false); // must be set for yLabelsMaxHeight to function
      addChildren(_yLabelContainers);
      return;
    }

    // Uses the prepared [chartRootContainer.yLabelsGenerator.labelInfos]
    // to create scaled Y labels from data or from user defined labels,
    // scales their position on the Y axis range [_axisYMin] to [_axisYMax].
    //
    // The data-generated label implementation smartly creates
    // a limited number of Y labels from data, so that Y labels do not
    // crowd, and little Y space is wasted on top.
    ChartOptions options = chartRootContainer.data.chartOptions;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
      textStyle: options.labelCommonOptions.labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.labelCommonOptions.labelTextAlign, // center text
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );

    for (LabelInfo labelInfo in labelInfos.labelInfoList) {
      // yTickY is the vertical center of the label on the Y axis.
      // It is equal to the Transformed and Scaled data value, calculated as LabelInfo.axisValue
      // It is kept always relative to the immediate container - YContainer
      var yLabelContainer = YAxisLabelContainer(
        label: labelInfo.formattedLabel,
        labelTiltMatrix: vector_math.Matrix2.identity(), // No tilted labels in YContainer
        labelStyle: labelStyle,
        options: options,
        labelInfo: labelInfo,
      );

      _yLabelContainers.add(yLabelContainer);
    }

    addChildren(_yLabelContainers);
  }

  /// Lays out this [YContainer] - the area containing the Y axis labels -
  /// which children were build during [buildAndAddChildren_DuringParentLayout].
  ///
  /// As this [YContainer] is [BuilderOfChildrenDuringParentLayout],
  /// this method should be called just after [buildAndAddChildren_DuringParentLayout]
  /// which builds hierarchy-children of this container.
  ///
  /// In the hierarchy-parent [ChartRootContainer.layout],
  /// the call to this object's [layout] is second, after [LegendContainer.layout].
  /// This [YContainer.layout] calculates [YContainer]'s labels width,
  /// the width taken by this container for the Y axis labels.
  ///
  /// The remaining horizontal width of [ChartRootContainer.chartArea] minus
  /// [YContainer]'s labels width provides remaining available
  /// horizontal space for the [GridLinesContainer] and [XContainer].
  @override
  void layout() {
    if (!chartRootContainer.data.chartOptions.yContainerOptions.isYContainerShown) {
      // Special no-labels branch must initialize the layoutSize
      layoutSize = const ui.Size(0.0, 0.0); // must be initialized
      return;
    }

    // labelInfos.scaleLabels(axisPixelsYMin: yContainerAxisPixelsYMin, axisPixelsYMax: yContainerAxisPixelsYMax);

    // Iterate, apply parent constraints, then layout all labels in [_yLabelContainers],
    //   which were previously created in [_createYLabelContainers]
    for (var yLabelContainer in _yLabelContainers) {
      // Constraint will allow to set labelMaxWidth which has been taken out of constructor.
      yLabelContainer.applyParentConstraints(this, BoxContainerConstraints.infinity());
      yLabelContainer.layout();

      double yTickY = yLabelContainer.labelInfo.pixelPositionOnAxis.toDouble();

      double labelTopY = yTickY - yLabelContainer.layoutSize.height / 2;

      yLabelContainer.parentOffsetTick = yTickY;

      // Move the contained LabelContainer to correct position
      yLabelContainer.applyParentOffset(this,
        ui.Offset(chartRootContainer.data.chartOptions.yContainerOptions.yLabelsPadLR, labelTopY),
      );
    }

    // Set the [layoutSize]
    double yLabelsContainerWidth =
        _yLabelContainers.map((yLabelContainer) => yLabelContainer.layoutSize.width).reduce(math.max) +
            2 * chartRootContainer.data.chartOptions.yContainerOptions.yLabelsPadLR;

    layoutSize = ui.Size(yLabelsContainerWidth, constraints.size.height);
  }

  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    if (!chartRootContainer.data.chartOptions.yContainerOptions.isYContainerShown) {
      return;
    }
    for (AxisLabelContainer yLabelContainer in _yLabelContainers) {
      yLabelContainer.applyParentOffset(this, offset);
    }
  }

  @override
  void paint(ui.Canvas canvas) {
    if (!chartRootContainer.data.chartOptions.yContainerOptions.isYContainerShown) {
      return;
    }
    for (AxisLabelContainer yLabelContainer in _yLabelContainers) {
      yLabelContainer.paint(canvas);
    }
  }

  double get yLabelsMaxHeight {
    // todo-04 replace-this-pattern-with-fold - look for '? 0.0'
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
/// - See the [XContainer] constructor for the assumption on [BoxContainerConstraints].

class XContainer extends AdjustableLabelsChartAreaContainer with BuilderOfChildrenDuringParentLayout {
  /// X labels. Can NOT be final or late, as the list changes on [reLayout]
  List<AxisLabelContainer> _xLabelContainers = List.empty(growable: true);

  double _xGridStep = 0.0;

  double get xGridStep => _xGridStep;

  /// Size allocated for each shown label (>= [_xGridStep]
  double _shownLabelsStepWidth = 0.0;

  /// Member to manage temporary layout size during relayout.
  ///
  /// Because [layoutSize] is late final, we cannot keep setting it during relayout.
  /// Instead, we set this member, and when relayouting is done, we use it to late-set [layoutSize] once.
  ui.Size lateReLayoutSize = const ui.Size(0.0, 0.0);

  /// Constructs the container that holds X labels.
  ///
  /// The passed [BoxContainerConstraints] is (assumed) to direct the expansion to fill
  /// all available horizontal space, and only use necessary vertical space.
  XContainer({
    required ChartRootContainer chartRootContainer,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  }) : super(
          chartRootContainer: chartRootContainer,
          xContainerLabelLayoutStrategy: xContainerLabelLayoutStrategy,
        );

  @override
  /// Builds the label containers for this [XContainer].
  void buildAndAddChildren_DuringParentLayout() {
    // First clear any children that could be created on nested re-layout
    _xLabelContainers = List.empty(growable: true);

    ChartOptions options = chartRootContainer.data.chartOptions;
    List<String> xUserLabels = chartRootContainer.data.xUserLabels;
    LabelStyle labelStyle = _styleForLabels(options);

    // Core layout loop, creates a AxisLabelContainer from each xLabel,
    //   and lays out the XLabelContainers along X in _gridStepWidth increments.

    for (int xIndex = 0; xIndex < xUserLabels.length; xIndex++) {
      var xLabelContainer = AxisLabelContainer(
        label: xUserLabels[xIndex],
        labelTiltMatrix: labelLayoutStrategy.labelTiltMatrix, // Possibly tilted labels in XContainer
        labelStyle: labelStyle,
        options: options,
      );
      _xLabelContainers.add(xLabelContainer);
    }
    addChildren(_xLabelContainers);
  }

  @override
  /// Lays out the chart in horizontal (x) direction.
  ///
  /// Evenly divides the available width to all labels (spacing included).
  /// First / Last vertical line is at the center of first / last label.
  ///
  /// The layout is independent of whether the labels are tilted or not,
  ///   in the sense that all tilting logic is in
  ///   [LabelContainer], and queried by [LabelContainer.layoutSize].
  void layout() {

    ChartOptions options = chartRootContainer.data.chartOptions;

    List<String> xUserLabels = chartRootContainer.data.xUserLabels;
    double       yTicksWidth = options.yContainerOptions.yLeftMinTicksWidth + options.yContainerOptions.yRightMinTicksWidth;
    double       availableWidth = constraints.size.width - yTicksWidth;
    double       labelMaxAllowedWidth = availableWidth / xUserLabels.length;
    int numShownLabels    = (xUserLabels.length ~/ labelLayoutStrategy.showEveryNthLabel);
    _xGridStep            = labelMaxAllowedWidth;
    _shownLabelsStepWidth = availableWidth / numShownLabels;

    // Layout all X labels in _xLabelContainers created and added in [buildAndAddChildrenLateDuringParentLayout]
    int xIndex = 0;
    for (AxisLabelContainer xLabelContainer in _xLabelContainers) {
      xLabelContainer.applyParentConstraints(this, BoxContainerConstraints.infinity());
      xLabelContainer.layout();

      // We only know if parent ordered skip after layout (because some size is too large)
      xLabelContainer.applyParentOrderedSkip(this, !_isLabelOnIndexShown(xIndex));

      // Core of X layout calcs - get the layed out label size,
      //   then find xTickX - the X middle of the label bounding rectangle in hierarchy-parent [XContainer]
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
      xLabelContainer.applyParentOffset(this, labelLeftTop + xLabelContainer.tiltedLabelEnvelopeTopLeft);

      xIndex++;
    }

    // Set the layout size calculated by this layout. This may be called multiple times during relayout.
    lateReLayoutSize = ui.Size(
      constraints.size.width,
      xLabelsMaxHeight + 2 * options.xContainerOptions.xLabelsPadTB,
    );

    if (!chartRootContainer.data.chartOptions.xContainerOptions.isXContainerShown) {
      // If not showing this container, no layout needed, just set size to 0.
      lateReLayoutSize = const ui.Size(0.0, 0.0);
      return;
    }

    // This achieves auto-layout of labels to fit along X axis.
    // Iterative call to this layout method, until fit or max depth is reached,
    //   whichever comes first.
    labelLayoutStrategy.reLayout(BoxContainerConstraints.unused());
  }

  /// Get the height of xlabels area without padding.
  double get xLabelsMaxHeight {
    return _xLabelContainers.isEmpty
        ? 0.0
        : _xLabelContainers.map((xLabelContainer) => xLabelContainer.layoutSize.height).reduce(math.max);
  }

  LabelStyle _styleForLabels(ChartOptions options) {
    // Use widgets.TextStyle obtained from ChartOptions and "extend it" as a copy, so a 
    //   (potentially modified) TextStyle from Options is used in all places in flutter_charts.

    widgets.TextStyle labelTextStyle = options.labelCommonOptions.labelTextStyle.copyWith(
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
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    if (!chartRootContainer.data.chartOptions.xContainerOptions.isXContainerShown) {
      return;
    }
    // super.applyParentOffset(caller, offset); // super did double-offset as xLabelContainer are on 2 places

    for (AxisLabelContainer xLabelContainer in _xLabelContainers) {
      xLabelContainer.applyParentOffset(this, offset);
    }
  }

  /// Paints this [XContainer] on the passed [canvas].
  ///
  /// Delegates painting to all contained [LabelContainerOriginalKeep]s.
  /// Any contained [LabelContainerOriginalKeep] must have been offset to the appropriate position.
  ///
  /// A special situation is when the [LabelContainerOriginalKeep]s are tilted, say counterclockwise.
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
    if (!chartRootContainer.data.chartOptions.xContainerOptions.isXContainerShown) {
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
      if (!xLabelContainer.orderedSkip) xLabelContainer.paint(canvas);
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
        !axisLabelContainer.orderedSkip && axisLabelContainer.layoutSize.width > _shownLabelsStepWidth)) {
      return true;
    }

    return false;
  }
}

/// Result object created after [XContainer] and [YContainer] layouts needed to build [DataContainer].
///
/// Carries the layout state during the [ChartRootContainer.layout] from 'sources' to 'sinks',
/// see the [BuilderOfChildrenDuringParentLayout.findSourceContainersReturnLayoutResultsToBuildSelf].
class _SourceYContainerAndYContainerToSinkDataContainer {
  final XContainer xContainer;
  final YContainer yContainer;

  _SourceYContainerAndYContainerToSinkDataContainer({
    required this.xContainer,
    required this.yContainer,
  });

  double get xGridStep => xContainer.xGridStep;

  /// X coordinates of x ticks (x tick - middle of column, also middle of label).
  /// Once [XContainer.layout] and [YContainer.layout] are complete,
  /// this list drives the layout of [DataContainer].
  ///
  /// xTickX are calculated from labels [XLabelContainer]s, and used late in the
  ///  layout and painting of the DataContainer in ChartContainer.
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


/// Manages the core chart area which displays and paints (in this order):
/// - The grid (this includes the X and Y axis).
/// - Data - as columns of bar chart, line chart, or other chart type
abstract class DataContainer extends ChartAreaContainer with BuilderOfChildrenDuringParentLayout {
  /// Container of gridlines parallel to X axis.
  ///
  /// The reason to separate [_xGridLinesContainer] and [_yGridLinesContainer] is for them to hide/show independently.
  late GridLinesContainer _xGridLinesContainer;
  late GridLinesContainer _yGridLinesContainer;

  /// Columns of pointPresenters.
  ///
  /// PointPresenters may be:
  /// - points and lines in line chart
  /// - bars (stacked or grouped) in bar chart
  ///
  /// todo 0 replace with getters; see if members can be made private,  manipulated via YLabelContainer.
  late PointPresentersColumns pointPresentersColumns;

  DataContainer({required ChartRootContainer chartRootContainer})
      : super(
    chartRootContainer: chartRootContainer,
  );

  @override
  _SourceYContainerAndYContainerToSinkDataContainer findSourceContainersReturnLayoutResultsToBuildSelf() {
    // DataContainer build (number of lines created) depends on XContainer and YContainer layout (number of labels),
    // This object moves the required information for the above into the DataContainer build.
    return _SourceYContainerAndYContainerToSinkDataContainer(
      xContainer: chartRootContainer.xContainer,
      yContainer: chartRootContainer.yContainer,
    );

  }

  /// Overridden builds children of self [DataContainer], the [_yGridLinesContainer] and [_xGridLinesContainer]
  /// and adds them as self children.
  @override
  void buildAndAddChildren_DuringParentLayout() {

    // Get information from layout of 'source siblings', which define this DataContainer xTickXs and yTickYs.
    _SourceYContainerAndYContainerToSinkDataContainer layoutDependency =
        findSourceContainersReturnLayoutResultsToBuildSelf();

    // Vars that layout needs from the [chartRootContainer] passed to constructor
    ChartOptions chartOptions = chartRootContainer.data.chartOptions;
    bool isStacked = chartRootContainer.isStacked;

    // ### 1. Vertical Grid (yGrid) layout:

    // Use this DataContainer layout dependency on [xTickXs] as guidelines for X labels
    // in [XContainer._xLabelContainers], for each create one [LineContainer] as child of [_yGridLinesContainer]

    // Initial values which will show as bad lines if not changed during layout.
    ui.Offset initLineFrom = const ui.Offset(0.0, 0.0);
    ui.Offset initLineTo = const ui.Offset(100.0, 100.0);

    // Construct the GridLinesContainer with children: [LineContainer]s
    _yGridLinesContainer = GridLinesContainer(
      children: layoutDependency.xTickXs.map((double xTickX) {
        // Add vertical yGrid line in the middle of label (stacked bar chart) or on label left edge (line chart)
        double lineX = isStacked ? xTickX - layoutDependency.xGridStep / 2 : xTickX;
        return LineContainer(
          lineFrom: initLineFrom,
          lineTo: initLineTo,
          linePaint: gridLinesPaint(chartOptions),
          manualLayedOutFromX: lineX,
          manualLayedOutFromY: 0.0,
          manualLayedOutToX: lineX,
          manualLayedOutToY: constraints.height,
        );
      }).toList(growable: false),
    );

    // For stacked, we need to add last right vertical yGrid line
    if (isStacked && layoutDependency.xTickXs.isNotEmpty) {
      double lineX = layoutDependency.xTickXs.last + layoutDependency.xGridStep / 2;

      _yGridLinesContainer.addChildren([
        LineContainer(
          lineFrom: initLineFrom,
          // ui.Offset(lineX, 0.0),
          lineTo: initLineTo,
          // ui.Offset(lineX, layoutSize.height),
          linePaint: gridLinesPaint(chartOptions),
          manualLayedOutFromX: lineX,
          manualLayedOutFromY: 0.0,
          manualLayedOutToX: lineX,
          manualLayedOutToY: constraints.height,
        ),
      ]);
    }
    // Add the constructed Y - parallel GridLinesContainer as child to self DataContainer
    addChildren([_yGridLinesContainer]);

    // ### 2. Horizontal Grid (xGrid) layout:

    // Use this DataContainer layout dependency on [yTickYs] as guidelines for Y labels
    // in [YContainer._yLabelContainers], for each create one [LineContainer] as child of [_xGridLinesContainer]

    // Construct the GridLinesContainer with children: [LineContainer]s
    _xGridLinesContainer = GridLinesContainer(
      children:
          // yTickYs create vertical xLineContainers
          // Position the horizontal xGrid at mid-points of labels at yTickY.
          layoutDependency.yTickYs.map((double yTickY) {
        return LineContainer(
          lineFrom: initLineFrom,
          lineTo: initLineTo,
          linePaint: gridLinesPaint(chartOptions),
          manualLayedOutFromX: 0.0,
          manualLayedOutFromY: yTickY,
          manualLayedOutToX: constraints.width,
          manualLayedOutToY: yTickY,
        );
      }).toList(growable: false),
    );

    // Add the constructed X - parallel GridLinesContainer as child to self DataContainer
    addChildren([_xGridLinesContainer]);
  }

  /// Overrides [BoxLayouter.layout] for data area.
  ///
  /// Uses all available space in the [constraints] set in parent [buildAndAddChildren_DuringParentLayout],
  /// which it divides evenly between it's children.
  ///
  /// First lays out the Grid, then, scales the columns to the [YContainer]'s scale
  /// based on the available size.
  @override
  void layout() {
    if (!chartRootContainer.isUseOldDataContainer) {
      super.layout();
      return;
    }

    // DataContainer uses it's full constraints to lay out it's grid and presenters!
    layoutSize = ui.Size(constraints.size.width, constraints.size.height);

    _SourceYContainerAndYContainerToSinkDataContainer layoutDependency =
      findSourceContainersReturnLayoutResultsToBuildSelf();

    // ### 1. Vertical Grid (yGrid) layout:

    // Position the vertical yGrid in the middle of labels (line chart) or on label left edge (stacked bar)
    _yGridLinesContainer.applyParentConstraints(this, constraints);
    _yGridLinesContainer.layout();

    // ### 2. Horizontal Grid (xGrid) layout:

    // Position the horizontal xGrid at mid-points of labels at yTickY.
    _xGridLinesContainer.applyParentConstraints(this, constraints);
    _xGridLinesContainer.layout();

    // Scale the [pointsColumns] to the [YContainer]'s scale.
    // This is effectively a [layout] of the lines and bars pointPresenters, currently
    //   done in [VerticalBarPointPresenter] and [LineChartPointPresenter]
    lerpPointsColumns(layoutDependency);
  }

  @override
  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    if (!chartRootContainer.isUseOldDataContainer) {
      super.applyParentOffset(caller, offset);
      return;
    }

    // Move all container atomic elements - lines, labels, circles etc
    _xGridLinesContainer.applyParentOffset(this, offset);

    // draw vertical grid
    _yGridLinesContainer.applyParentOffset(this, offset);

    // Apply offset to lines and bars.
    chartRootContainer.pointsColumns.applyParentOffset(this, offset);

    // Any time offset of [_chartContainer.pointsColumns] has changed,
    //   we have to recreate the absolute positions
    //   of where to draw data points, data lines and data bars.
    /// Creates from [ChartData] (model for this container),
    /// columns of leaf values encapsulated as [StackableValuePoint]s,
    /// and from the values, the columns of leaf pointPresenters,
    /// encapsulated as [PointPresenter]s.
    ///
    /// The resulting elements (points and pointPresenters) are
    /// stored in member [pointPresentersColumns].
    /// This is a core method that must run at the end of layout.
    /// Painters use the created leaf pointPresenters directly to draw lines, points,
    /// and bars from the pointPresenters' prepared ui elements:
    /// lines, points, bars, etc.
    // todo-04 : What is the difference between this PointPresentersColumns and constructing PointsColumns() which is called earlier in ChartRootContainer.layout?
    //                  PointsColumns is DATA, PointPresentersColumns should be converted to BoxContainer
    //                  Also : problem : this constructor actually creates absolute values on PointPresenters, no offsetting !!
    pointPresentersColumns = PointPresentersColumns(
      pointsColumns: chartRootContainer.pointsColumns,
      chartRootContainer: chartRootContainer,
      pointPresenterCreator: chartRootContainer.pointPresenterCreator,
    );
  }

  /// Paints the Grid lines of the chart area.
  ///
  /// Note that the super [paint] remains not implemented in this class.
  /// Superclasses (for example the line chart data container) should
  /// call this method at the beginning of it's [paint] implementation,
  /// followed by painting the [PointPresenter]s in [_drawDataPointPresentersColumns].
  ///
  void _paintGridLines(ui.Canvas canvas) {
    // draw horizontal grid
    _xGridLinesContainer.paint(canvas);

    // draw vertical grid
    if (chartRootContainer.data.chartOptions.yContainerOptions.isYGridlinesShown) {
      _yGridLinesContainer.paint(canvas);
    }
  }

  // paint(ui.Canvas canvas)  switch old and new DataContainer : super called in both

  // ##### Scaling and layout methods of [_chartContainer.pointsColumns]
  //       and [pointPresentersColumns]

  /// Scales all data stored in leafs of columns and rows
  /// as [StackableValuePoint]. Depending on whether we are layouting
  /// a stacked or unstacked chart, scaling is done on stacked or unstacked
  /// values.
  ///
  /// Must be called before [setupPointPresentersColumns] as [setupPointPresentersColumns]
  /// uses the  absolute scaled [chartRootContainer.pointsColumns].
  void lerpPointsColumns(_SourceYContainerAndYContainerToSinkDataContainer layoutDependency) {
    chartRootContainer.pointsColumns.lerpPointsColumns(layoutDependency);
  }

  /// Optionally paint series in reverse order (first to last,
  /// vs last to first which is default).
  ///
  /// See [DataContainerOptions.dataRowsPaintingOrder].
  List<PointPresenter> optionalPaintOrderReverse(List<PointPresenter> pointPresenters) {
    var options = chartRootContainer.data.chartOptions;
    if (options.dataContainerOptions.dataRowsPaintingOrder == DataRowsPaintingOrder.firstToLast) {
      pointPresenters = pointPresenters.reversed.toList();
    }
    return pointPresenters;
  }
}


/// A marker of container with adjustable contents,
/// such as labels that can be skipped.
// todo-04-morph LabelLayoutStrategy should be a member of AdjustableContainer, not
//          in AdjustableLabelsChartAreaContainer
//          Also, AdjustableLabels and perhaps AdjustableLabelsChartAreaContainer should be a mixin.
//          But Dart bug #25742 does not allow mixins with named parameters.

abstract class AdjustableLabels {
  bool labelsOverlap();
}

/// Provides ability to connect [LabelLayoutStrategy] to [BoxContainer],
/// (actually currently the [ChartAreaContainer].
///
/// Extensions can create [ChartAreaContainer]s with default or custom layout strategy.
abstract class AdjustableLabelsChartAreaContainer extends ChartAreaContainer implements AdjustableLabels {
  late final strategy.LabelLayoutStrategy _labelLayoutStrategy;

  strategy.LabelLayoutStrategy get labelLayoutStrategy => _labelLayoutStrategy;

  AdjustableLabelsChartAreaContainer({
    required ChartRootContainer chartRootContainer,
    strategy.LabelLayoutStrategy? xContainerLabelLayoutStrategy,
  })  : _labelLayoutStrategy = xContainerLabelLayoutStrategy ??
            strategy.DefaultIterativeLabelLayoutStrategy(options: chartRootContainer.data.chartOptions),
        super(
          chartRootContainer: chartRootContainer,
        ) {
    // Must initialize in body, as access to 'this' not available in initializer.
    // parent = chartRootContainer;
    _labelLayoutStrategy.onContainer(this);
  }
}

/// Base class which manages, lays out, moves, and paints
/// each top level block on the chart. The basic top level chart blocks are:
/// - [ChartRootContainer] - the whole chart
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
/// See [BoxContainer] for discussion of roles of this class.
/// This extension of  [BoxContainer] has the added ability
/// to access the container's parent, which is handled by
/// [chartRootContainer].
abstract class ChartAreaContainer extends BoxContainer {
  /// The chart top level.
  ///
  /// Departure from a top down approach, this allows to
  /// access the parent [ChartRootContainer], which has (currently)
  /// members needed by children.
  final ChartRootContainer chartRootContainer;

  ChartAreaContainer({
    required this.chartRootContainer,
    List<BoxContainer>? children,
    ContainerKey? key,
    ConstraintsWeight constraintsWeight = ConstraintsWeight.defaultWeight,
  }) : super(
          children: children,
          key: key,
          constraintsWeight: constraintsWeight,
        );
}

/// Provides the data area container for the bar chart.
///
/// The only role is to implement the abstract method of the baseclass,
/// [paint] and [_drawDataPointPresentersColumns].
class VerticalBarChartDataContainer extends DataContainer {
  VerticalBarChartDataContainer({
    required ChartRootContainer chartRootContainer,
  }) : super(
          chartRootContainer: chartRootContainer,
        );

  @override
  void paint(ui.Canvas canvas) {
    _paintGridLines(canvas);
    _drawDataPointPresentersColumns(canvas);
  }

  /// Draws the actual atomic visual elements representing data on the chart.
  ///
  /// The atomic visual elements are either  lines with points (on the line chart),
  /// or bars/columns, stacked or grouped (on the bar/column charts).
  void _drawDataPointPresentersColumns(ui.Canvas canvas) {
    PointPresentersColumns pointPresentersColumns = this.pointPresentersColumns;

    for (PointPresentersColumn pointPresentersColumn in pointPresentersColumns) {
      // todo-2 do not repeat loop, collapse to one construct

      var positivePointPresenterList = pointPresentersColumn.positivePointPresenters;
      positivePointPresenterList = optionalPaintOrderReverse(positivePointPresenterList);
      for (PointPresenter pointPresenter in positivePointPresenterList) {
        bar_presenters.VerticalBarPointPresenter presenterCast = pointPresenter as bar_presenters.VerticalBarPointPresenter;
        canvas.drawRect(
          presenterCast.presentedRect,
          presenterCast.dataRowPaint,
        );
      }

      var negativePointPresenterList = pointPresentersColumn.negativePointPresenters;
      negativePointPresenterList = optionalPaintOrderReverse(negativePointPresenterList);
      for (PointPresenter pointPresenter in negativePointPresenterList) {
        bar_presenters.VerticalBarPointPresenter presenterCast = pointPresenter as bar_presenters.VerticalBarPointPresenter;
        canvas.drawRect(
          presenterCast.presentedRect,
          presenterCast.dataRowPaint,
        );
      }
    }
  }
}

class VerticalBarChartNewDataContainer extends NewDataContainer {
  VerticalBarChartNewDataContainer({
    required ChartRootContainer chartRootContainer,
  }) : super(
    chartRootContainer: chartRootContainer,
  );
}

/// Provides the data area container for the line chart.
///
/// The only role is to implement the abstract method of the baseclass,
/// [paint] and [drawDataPointPresentersColumns].
class LineChartDataContainer extends DataContainer {
  LineChartDataContainer({
    required ChartRootContainer chartRootContainer,
  }) : super(
          chartRootContainer: chartRootContainer,
        );

  @override
  void paint(ui.Canvas canvas) {
    _paintGridLines(canvas);
    _drawDataPointPresentersColumns(canvas);
  }

  /// Draws the actual atomic visual elements representing data on the chart.
  ///
  /// The atomic visual elements are either  lines with points (on the line chart),
  /// or bars/columns, stacked or grouped (on the bar/column charts).
  void _drawDataPointPresentersColumns(ui.Canvas canvas) {
    var pointPresentersColumns = this.pointPresentersColumns;
    for (PointPresentersColumn pointPresentersColumn in pointPresentersColumns) {
      var pointPresenterList = pointPresentersColumn.pointPresenters;
      pointPresenterList = optionalPaintOrderReverse(pointPresenterList);
      for (PointPresenter pointPresenter in pointPresenterList) {
        line_presenters.LineAndHotspotPointPresenter pointPresenterCast = pointPresenter as line_presenters.LineAndHotspotPointPresenter;
        // todo 0-future-minor Use call to Container.paint
        canvas.drawLine(
          pointPresenterCast.lineContainer.lineFrom,
          pointPresenterCast.lineContainer.lineTo,
          pointPresenterCast.lineContainer.linePaint,
        );
        // todo 0-future-medium Add hotspot as Container, use Container.paint
        canvas.drawCircle(
          pointPresenterCast.offsetPoint,
          pointPresenterCast.outerRadius,
          pointPresenterCast.outerPaint,
        );
        canvas.drawCircle(
          pointPresenterCast.offsetPoint,
          pointPresenterCast.innerRadius,
          pointPresenterCast.innerPaint,
        );
      }
    }
  }
}

class LineChartNewDataContainer extends NewDataContainer {
  LineChartNewDataContainer({
    required ChartRootContainer chartRootContainer,
  }) : super(
    chartRootContainer: chartRootContainer,
  );
}

/// Represents a set of gridlines (either horizontal or vertical, but not both),
/// which draw the dotted grid lines in chart.
///
/// The grid lines are positioned in the middle of labels (Y labels, and X labels for non-stacked)
/// or on the left label edge (X labels for stacked).
///
/// Note: Methods [layout], [applyParentOffset], and [paint], use the default implementation.
///
class GridLinesContainer extends BoxContainer {

  /// Construct from children [LineContainer]s.
  GridLinesContainer({
    required List<LineContainer>? children,
  }) : super(children: children);

  /// Override from base class sets the layout size.
  ///
  /// This [GridLinesContainer] can be leaf if there are no labels or labels are not shown.
  /// Leaf containers which do not override [BoxLayouter.layout] must override this method,
  /// setting [layoutSize].
  @override
  void post_Leaf_SetSize_FromInternals() {
    if (!isLeaf) {
      throw StateError('Only a leaf can be sent this message.');
    }
    layoutSize = constraints.size;
  }

}

/// Represents one item of the legend:  The rectangle for the series color
/// indicator, followed by the series label text.
///
/// Two child containers are created during the [layout]:
///    - [LegendIndicatorRectContainer] indRectContainer for the series color indicator
///    - [LabelContainerOriginalKeep] labelContainer for the series label


/// Container of one item in the chart legend; each instance corresponds to one row (series) of data.
class LegendItemContainer extends BoxContainer {

  /// Rectangle of the legend color square series indicator

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
    // List<BoxContainer>? children, // could add for extensibility by e.g. chart description
  })  :
  // We want to only create as much as we can in layout for clarity,
  // as a price, need to hold on on label and style from constructor
        _label = label,
        _labelStyle = labelStyle,
        _indicatorPaint = indicatorPaint,
        _options = options,
        super() {
    // Create children and attach to self
    addChildren(_createChildrenOfLegendItemContainer());
  }


  /// Creates child of this [LegendItemContainer] a [Row] with two containers:
  ///   - the [LegendIndicatorRectContainer] which is a color square indicator for data series,
  ///   - the [LabelContainer] which describes the series.
  ///
  List<BoxContainer> _createChildrenOfLegendItemContainer() {

    // Pull out the creation, remember on this object as member _label,
    // set _labelMaxWidth on it in layout.

    BoxContainer layoutChild;
    var children = _itemIndAndLabel();
    switch (_options.legendOptions.legendAndItemLayoutEnum) {
    // **IFF* the returned layout is the topmost Row (Legend starts with Column),
    //        the passed Packing and Align values are used.
    // **ELSE* the values are irrelevant, will be replaced with Align.start, Packing.tight.
      case LegendAndItemLayoutEnum.legendIsColumnStartLooseItemIsRowStartLoose:
        layoutChild = Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.loose,
          children: children,
        );
        break;
      case LegendAndItemLayoutEnum.legendIsColumnStartTightItemIsRowStartTight:
      // default for legend column : Item row is top, so is NOT overridden, so must be set to intended!
        layoutChild = Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case LegendAndItemLayoutEnum.legendIsRowCenterLooseItemIsRowEndLoose:
        layoutChild = Row(
          mainAxisAlign: Align.end,
          mainAxisPacking: Packing.loose,
          children: children,
        );
        break;
      case LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTight:
      // default for legend row : desired and tested
        layoutChild = Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightSecondGreedy:
      // default for legend row : desired and tested
        layoutChild = Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenPadded:
      // create padded children
        children = _itemIndAndLabel(doPadIndAndLabel: true);
        // default for legend row : desired and tested
        layoutChild = Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
      case LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenAligned:
      // create padded children
        children = _itemIndAndLabel(doAlignIndAndLabel: true);
        // default for legend row : desired and tested
        layoutChild = Row(
          mainAxisAlign: Align.start,
          mainAxisPacking: Packing.tight,
          children: children,
        );
        break;
    }
    return [layoutChild];
  }


  /// Constructs the list with the legend indicator and legend label, which caller wraps
  /// in [RowLayout].
  List<BoxContainer> _itemIndAndLabel({bool doPadIndAndLabel = false, bool doAlignIndAndLabel = false}) {
    var indRect = LegendIndicatorRectContainer(
      indicatorPaint: _indicatorPaint,
      options: _options,
    );
    var label = LabelContainer(
      label: _label,
      labelTiltMatrix: vector_math.Matrix2.identity(), // No tilted labels in LegendItemContainer
      labelStyle: _labelStyle,
      options: _options,
    );

    if (doPadIndAndLabel) {
      EdgePadding edgePadding = const EdgePadding(
        start: 3,
        top: 10,
        end: 3,
        bottom: 20,
      );
      return [
        Padder(
          edgePadding: edgePadding,
          child: indRect,
        ),
        Padder(
          edgePadding: edgePadding,
          child: label,
        ),
      ];
    } else if (doAlignIndAndLabel) {
      return [
        Row(
          children: [
          Aligner(
            childHeightBy: 3,
            childWidthBy: 1.2,
            alignment: Alignment.startTop,
            child: indRect,
          ),
            Aligner(
              childHeightBy: 5,
              childWidthBy: 1.2,
              alignment: Alignment.endBottom,
              child: label,
            ),
          ]
        )
      ];

    } else {
      return [
        indRect,
        label,
      ];
    }
  }
}

/// Represents the series color indicator square in the legend.
class LegendIndicatorRectContainer extends BoxContainer {

  /// Rectangle of the legend color square series indicator.
  /// This is moved to offset then [paint]ed using rectangle paint primitive.
  late final ui.Size _indicatorSize;

  /// Paint used to paint the indicator
  final ui.Paint _indicatorPaint;

  LegendIndicatorRectContainer({
    required ui.Paint indicatorPaint,
    required ChartOptions options,
  })  :
        _indicatorPaint = indicatorPaint,
        // Create the indicator square, later offset in applyParentOffset
        _indicatorSize = ui.Size(
          options.legendOptions.legendColorIndicatorWidth,
          options.legendOptions.legendColorIndicatorWidth,
        ),
        super(); // {} or colon

  /// Overridden to set the concrete layout size on this leaf.
  ///
  /// Note: Alternatively, the same result would be achieved by overriding a getter, like so:
  ///    ``` dart
  ///       @override
  ///       ui.Size get layoutSize => ui.Size(
  ///         _indicatorSize.width,
  ///         _indicatorSize.height,
  ///       );
  ///    ```
  @override
  void post_Leaf_SetSize_FromInternals() {
    if (!isLeaf) {
      throw StateError('Only a leaf can be sent this message.');
    }
    layoutSize = ui.Size(
      _indicatorSize.width,
      _indicatorSize.height,
    );
  }

  /// Overridden super's [paint] to also paint the rectangle indicator square.
  @override
  void paint(ui.Canvas canvas) {
    ui.Rect indicatorRect = offset & _indicatorSize;
    canvas.drawRect(
      indicatorRect,
      _indicatorPaint,
    );
  }
}

/// Lays out the legend area for the chart.
///
/// The legend area contains individual legend items represented
/// by [LegendItemContainer]. Each legend item
/// has a color square and text, which describes one data row (that is,
/// one data series).
///
/// The legends label texts should be short as we use [Row] for the layout, which
/// may overflow to the right.
///
/// This extension of [ChartAreaContainer] operates as follows:
/// - Horizontally available space is all used (filled).
/// - Vertically available space is used only as much as needed.
/// The used amount is given by the maximum label or series indicator height,
/// plus extra spacing.
class LegendContainer extends ChartAreaContainer {
  // ### calculated values

  /// Constructs the container that holds the data series legends labels and
  /// color indicators.
  ///
  /// The passed [chartRootContainer] can be used to get both [ChartData] [data]
  /// and [ChartOptions] [options].
  LegendContainer({
    required ChartRootContainer chartRootContainer,
    // List<BoxContainer>? children, // could add for extensibility by e.g. add legend comment
  }) : super(
          chartRootContainer: chartRootContainer,
        ) {
    // Create children and attach to self
     addChildren(_createChildrenOfLegendContainer());

    // parent = null; We set isRoot to true, so this is not needed.
    // If option set to hide (not shown), set the member [orderedSkip = true],
    //  which will cause offset and paint of self and all children to be skipped by the default implementations
    //  of [paint] and [applyParentOffset].
    if (!chartRootContainer.data.chartOptions.legendOptions.isLegendContainerShown) {
      applyParentOrderedSkip(chartRootContainer, true);
    }
  }

  /// Builds the legend container contents below self,
  /// a child [Row] or [Column],
  /// which contains a list of [LegendItemContainer]s,
  /// created separately in [_legendItems].
  List<BoxContainer> _createChildrenOfLegendContainer() {
    ChartOptions options = chartRootContainer.data.chartOptions;

    List<String> dataRowsLegends = chartRootContainer.data.dataRowsLegends;

    // Initially all [LabelContainer]s share same text style object from options.
    LabelStyle labelStyle = LabelStyle(
      textStyle: options.labelCommonOptions.labelTextStyle,
      textDirection: options.labelCommonOptions.labelTextDirection,
      textAlign: options.legendOptions.legendTextAlign, // keep left, close to indicator
      textScaleFactor: options.labelCommonOptions.labelTextScaleFactor,
    );

    BoxContainer childLayout;
    // Create the list of [LegendItemContainer]s, each an indicator and label for one data series
    var children = _legendItems(dataRowsLegends, labelStyle, options);
    switch (options.legendOptions.legendAndItemLayoutEnum) {
      case LegendAndItemLayoutEnum.legendIsColumnStartLooseItemIsRowStartLoose:
        childLayout = Column(
            mainAxisAlign: Align.start,
            mainAxisPacking: Packing.loose,
            children: children,
        );
        break;
      case LegendAndItemLayoutEnum.legendIsColumnStartTightItemIsRowStartTight:
        // default for legend column : desired and tested
        childLayout = Column(
            mainAxisAlign: Align.start,
            mainAxisPacking: Packing.tight,
            children: children,
        );
        break;
      case LegendAndItemLayoutEnum.legendIsRowCenterLooseItemIsRowEndLoose:
        childLayout = Row(
            mainAxisAlign: Align.center,
            mainAxisPacking: Packing.loose,
            children: children,
        );
        break;
      case LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTight:
        // default for legend row : desired and tested
        childLayout = Row(
            mainAxisAlign: Align.start,
            mainAxisPacking: Packing.tight,
            children: children,
        );
        break;
      case LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightSecondGreedy:
        // wrap second item to Greedy to test Greedy layout
        children[1] = Greedy(child: children[1]);
        childLayout = Row(
            // Note: Attempt to make Align.center + Packing.loose shows no effect - the LegendItem inside Greedy
            //       remains start + tight. That make sense, as Greedy is non-positioning.
            //       If we wanted to center the LegendItem inside of Greedy, wrap the inside into Center.
            mainAxisAlign: Align.start,
            mainAxisPacking: Packing.tight,
            children: children,
        );
        break;
      case LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenPadded:
        // This option pads items inside LegendItem
        childLayout = Row(
            mainAxisAlign: Align.start,
            mainAxisPacking: Packing.tight,
            children: children,
        );
        break;
      case LegendAndItemLayoutEnum.legendIsRowStartTightItemIsRowStartTightItemChildrenAligned:
      // This option aligns items inside LegendItem
        childLayout = Row(
            mainAxisAlign: Align.start,
            mainAxisPacking: Packing.tight,
            children: children,
        );
        break;
    }
    return [childLayout];
  }

  List<BoxContainer> _legendItems(
    List<String> dataRowsLegends,
    LabelStyle labelStyle,
    ChartOptions options,
  ) {
    return [
      // Using collections-for to expand to list of LegendItems. But e cannot have a block in collections-for
      for (int index = 0; index < dataRowsLegends.length; index++)
        // ui.Paint indicatorPaint = ui.Paint();
        // List<ui.Color> dataRowsColors = chartRootContainer.data.dataRowsColors; //!;
        // indicatorPaint.color = dataRowsColors[index % dataRowsColors.length];
        LegendItemContainer(
          label: dataRowsLegends[index],
          labelStyle: labelStyle,
          indicatorPaint: (ui.Paint()
            ..color = chartRootContainer.data.dataRowsColors
                .elementAt(index % chartRootContainer.data.dataRowsColors.length)), //
          options: options,
        ),
    ];
  }

  /// Lays out the legend area.
  ///
  /// Lays out legend items, one for each data series.
  @override
  void layout() {
    // todo-021 : can we just call super? this appears needed, otherwise non-label results change slightly, but still correct
    //                we should probably remove this block orderedSkip - but check behavior in debugger, what
    //                happens to layoutSize, it may never be set?
    if (orderedSkip) {
      layoutSize = const ui.Size(0.0, 0.0);
      return;
    }
    // Important: This flips from using layout() on parents to using layout() on children
    super.layout();
  }
}

/// Represents one Y numeric value in the [DeprecatedChartData.dataRows],
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
/// 3. The [scaledFrom] and [scaledTo] type [ui.Offset] are scaled-coordinates -
///   represent members from group 2, scaled to the container coordinates (display coordinates).
///   *This group's members DO change under [applyParentOffset] as they represent coordinates.*
///
/// Stacking management:
/// - This object does not manage it's stacking,
///   stacking is delegated to the container that manages this object along with
///   values before (below) and after (above). The managing object is [PointsColumn].
class StackableValuePoint {

  /// The generative constructor of objects for this class.
  StackableValuePoint({
    required this.xLabel,
    required this.dataY,
    required this.dataRowIndex,
    required this.chartRootContainer,
    this.predecessorPoint,
  })  : isStacked = false,
        fromY = 0.0,
        toY = dataY;

  // ################## Members ###################
  // ### Group 0: Structural

  /// Root container added to access yContainer.axisPixels min / max
  late final ChartRootContainer chartRootContainer;

  // ### 1. Group 1, initial values, but also includes [dataY] in group 2

  late final String xLabel;

  /// The transformed but NOT stacked Y data value.
  /// **ANY [dataYs] are 1. transformed, then 2. potentially stacked IN PLACE, then 3. potentially scaled IN A COPY!!**
  late final double dataY;

  /// The index of this point in the [PointsColumn] containing this point in it's
  /// [PointsColumn.stackableValuePoints] list.
  late final int dataRowIndex; // series index

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

  /// The [scaledFrom] and [scaledTo] are the pixel (scaled) coordinates
  /// of (possibly stacked) data values in the [ChartRootContainer] coordinates.
  /// They are positions used by [PointPresenter] to paint the 'widget'
  /// that represents the (possibly stacked) data value.
  ///
  /// Initially scaled to available pixels on the Y axis,
  /// then moved by positioning by [applyParentOffset].
  ///
  /// In other words, they hold offsets of the bottom and top of the [PointPresenter] of this
  /// data value point.
  ///
  /// For example, for VerticalBar, [scaledFrom] is the bottom left and
  /// [scaledTo] is the top right of each bar representing this value point (data point).
  ui.Offset scaledFrom = ui.Offset.zero;

  /// See [scaledFrom].
  ui.Offset scaledTo = ui.Offset.zero;

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
  /// (if chart type is [ChartRootContainer.isStacked].
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
  /// manage the not-scaled [x] (it manages the corresponding label only).
  /// For this reason, the [scaledX] value must be *already scaled*!
  /// The provided [scaledX] value should be the
  /// "within [ChartPainter] absolute" x coordinate (generally the center
  /// of the corresponding x label).
  ///
  StackableValuePoint lerpToPixels({
    required double scaledX,
    required DataRangeLabelsGenerator yLabelsGenerator,
  }) {
    // Scales fromY of from the OLD [ChartData] BUT all the scaling domains in yLabelsGenerator
    // were calculated using the NEW [NewDataModel]

    double axisPixelsYMin = chartRootContainer.yContainer.axisPixelsRange.min;
    double axisPixelsYMax = chartRootContainer.yContainer.axisPixelsRange.max;

    scaledFrom = ui.Offset(
      scaledX,
      yLabelsGenerator.lerpValueToPixels(
        value: fromY,
        axisPixelsYMin: axisPixelsYMin,
        axisPixelsYMax: axisPixelsYMax,
        isAxisAndLabelsSameDirection: !yLabelsGenerator.isAxisAndLabelsSameDirection,
      ),
    );
    scaledTo = ui.Offset(
      scaledX,
      yLabelsGenerator.lerpValueToPixels(
        value: toY,
        axisPixelsYMin: axisPixelsYMin,
        axisPixelsYMax: axisPixelsYMax,
        isAxisAndLabelsSameDirection: !yLabelsGenerator.isAxisAndLabelsSameDirection,
      ),
    );

    return this;
  }

  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    // only apply  offset on scaled values, those have chart coordinates that are painted.

    // not needed to offset : StackableValuePoint predecessorPoint;

    /// Scaled values represent screen coordinates, apply offset to all.
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
      throw Exception('Cannot unstackedClone if already stacked');
    }

    StackableValuePoint unstackedClone = StackableValuePoint(
      chartRootContainer: chartRootContainer,
      xLabel: xLabel,
      dataY: dataY,
      dataRowIndex: dataRowIndex,
      predecessorPoint: predecessorPoint,
    );

    // nullify the predecessor Anything that we change here must not be final
    unstackedClone.predecessorPoint = null;
    unstackedClone.fromY = fromY;
    unstackedClone.toY = toY;
    unstackedClone.scaledFrom = ui.Offset(scaledFrom.dx, scaledFrom.dy);
    unstackedClone.scaledTo = ui.Offset(scaledTo.dx, scaledTo.dy);

    return unstackedClone;
  }
}

/// Represents a column of [StackableValuePoint]s, with support for both stacked and non-stacked charts.
///
/// Corresponds to one column of data from [DeprecatedChartData.dataRows], ready for presentation by [PointPresenter]s.
///
/// The
/// - unstacked (such as in the line chart),  in which case it manages
///   [stackableValuePoints] that have values from [DeprecatedChartData.dataRows].
/// - stacked (such as in the bar chart), in which case it manages
///   [stackableValuePoints] that have values added up from [DeprecatedChartData.dataRows].
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

/// A list of [PointsColumn] instances, created from user data rows [DeprecatedChartData.dataRows].
///
/// Represents the chart data created from the [DeprecatedChartData.dataRows], but is an internal format suitable for
/// presenting by the chart [PointPresenter] instances.
///
/// Passed to the [PointPresenter] instances, which use this instance's data to
/// paint the values in areas above the labels in the appropriate presentation (point and line chart, column chart, etc).
///
/// Manages value point structure as column based (currently supported) or row based (not supported).
///
/// A (single instance per chart) is used to create a [PointPresentersColumns] instance, managed in the [DataContainer].
// todo-04-note : PointsColumns IS A MODEL, NOT PRESENTER :
//                 Convert to BoxContainer, add 1) _createChildrenOfPointsColumns 2) buildAndAddChildren_DuringParentLayout 3) layout
//                 Each PointsColumn is a child in children.
class PointsColumns extends custom_collection.CustomList<PointsColumn> {
  /// Parent chart container.
  final ChartRootContainer chartRootContainer;

  /// True if chart type presents values stacked.
  final bool _isStacked;

  final LayoutableBox _caller;

  /// Constructor creates a [PointsColumns] instance from [DeprecatedChartData.dataRows] values in
  /// the passed [ChartRootContainer.data].
  PointsColumns({
    required this.chartRootContainer,
    required PointPresenterCreator pointPresenterCreator,
    required bool isStacked,
    required LayoutableBox caller,
  })  : _isStacked = isStacked,
        _caller = caller,
        super(growable: true) {
    _createStackableValuePointsFromChartData(chartRootContainer.data);
  }

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
  void _createStackableValuePointsFromChartData(NewDataModel chartData) {
    List<StackableValuePoint?> rowOfPredecessorPoints =
        List.filled(chartData.dataRows[0].length, null);
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
        num colValue = chartRootContainer.data.chartOptions.dataContainerOptions.yTransform(dataRow[col]);

        // Create all points unstacked. A later processing can stack them,
        // depending on chart type. See [StackableValuePoint.stackOnAnother]
        var thisPoint = StackableValuePoint(
            chartRootContainer: chartRootContainer,
            xLabel: 'initial',
            dataY: colValue.toDouble(),
            dataRowIndex: row,
            predecessorPoint: rowOfPredecessorPoints[col]);

        pointsRow.add(thisPoint); // Grow the row with thisPoint
        rowOfPredecessorPoints[col] = thisPoint;
      }
    }
    valuePointArrInRows.toList();

    // Data points managed column. Internal only, should be refactored away.
    List<List<StackableValuePoint>> valuePointArrInColumns = transposeRowsToColumns(valuePointArrInRows);

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
  /// the original, not-scaled data points, and apply scaling later
  /// on the stackable (stacked or unstacked) values.
  ///
  /// Notes:
  /// - Iterates this object's internal list of [PointsColumn], then the contained
  ///   [PointsColumn.stackableValuePoints], and scales each point by
  ///   applying its [StackableValuePoint.lerpToPixels] method.
  /// - No scaling of the internal representation stored in [_valuePointArrInRows]
  ///   or [_valuePointArrInColumns].
  void lerpPointsColumns(_SourceYContainerAndYContainerToSinkDataContainer layoutDependency) {
    int col = 0;
    for (PointsColumn column in this) {
      column.allPoints().forEach((StackableValuePoint point) {
        double scaledX = layoutDependency.xTickXs[col];
        point.lerpToPixels(
          scaledX: scaledX,
          yLabelsGenerator: chartRootContainer.yContainer.yLabelsGenerator,
        );
      });
      col++;
    }
  }

  void applyParentOffset(LayoutableBox caller, ui.Offset offset) {
    for (PointsColumn column in this) {
      column.allPoints().forEach((StackableValuePoint point) {
        point.applyParentOffset(_caller, offset);
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
